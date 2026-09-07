//// Terminal capability and raw-input boundary for the widget definition TUI.
////
//// Issue #18 spike outcome: the terminal size query delegates to the
//// `term_size` Hex package, which reads the size on every supported runtime.
//// Raw-mode toggling, the stdin lifecycle, and non-blocking one-shot key
//// polling have no reliable cross-runtime ecosystem equivalent, so they remain
//// custom FFI in `terminal_control_ffi.mjs`. Each retained external documents
//// why it stays custom. See `terminal-ffi-spike.md` for the full evaluation.
////

import gleam/javascript/promise
import term_size

/// Opaque handle for a raw-mode failure reported by the terminal runtime.
///
/// The value is produced by the FFI and carries the underlying runtime error so
/// callers can surface an exact reason instead of a generic sentinel.
pub type RawModeError

/// Selects whether terminal raw mode is turned on or off.
///
/// A dedicated type keeps the public boundary free of a positional `Bool` whose
/// meaning is easy to invert at a call site.
pub type RawMode {
  /// Raw mode is on, so individual keypresses arrive without line buffering.
  Enabled
  /// Raw mode is off, so the terminal returns to cooked line input.
  Disabled
}

/// Reports whether standard input is an interactive TTY.
///
/// Retained as custom FFI: no evaluated package exposes the runtime
/// `process.stdin.isTTY` probe the TUI needs before entering raw mode.
pub fn is_tty() -> Bool {
  is_tty_ffi()
}

/// Returns the terminal size as `#(columns, rows)`.
///
/// Delegates to `term_size` and falls back to the conventional 80x24 default
/// when either dimension is unavailable, preserving the previous FFI contract.
pub fn size() -> #(Int, Int) {
  size_from(term_size.get())
}

/// Resolves the package's `#(rows, columns)` result into the TUI contract.
///
/// The 80x24 fallback applies when the runtime cannot determine the size.
/// Non-positive dimensions also fall back independently, matching the previous
/// JavaScript `columns || 80` and `rows || 24` behavior.
pub fn size_from(using measurement: Result(#(Int, Int), Nil)) -> #(Int, Int) {
  case measurement {
    Ok(#(rows, columns)) -> #(
      positive_or_fallback(value: columns, fallback: 80),
      positive_or_fallback(value: rows, fallback: 24),
    )
    Error(Nil) -> #(80, 24)
  }
}

/// Enables or disables terminal raw mode.
///
/// Retained as custom FFI: toggling raw mode and resuming stdin are runtime
/// terminal-control effects no evaluated package provides safely. Returns a
/// `Result` carrying a `RawModeError` so the caller can report the exact runtime
/// reason, including the "stdin does not support raw mode" case.
pub fn set_raw_mode(to mode: RawMode) -> Result(Nil, RawModeError) {
  set_terminal_raw_mode(raw_mode_is_enabled(mode))
}

/// Describes a raw-mode failure in human-readable form.
pub fn raw_mode_error_message(for error: RawModeError) -> String {
  terminal_mode_error_message(error)
}

/// Polls for a single key press, waiting up to `timeout_milliseconds`.
///
/// Retained as custom FFI: the stdin lifecycle, non-blocking one-shot polling,
/// and UTF-8 aware key decoding have no ecosystem equivalent that preserves the
/// required behavior. The raw `#(code, text)` encoding is preserved so the TUI
/// key model stays unchanged, matching the issue #18 non-goals.
pub fn poll_key_raw(
  within timeout_milliseconds: Int,
) -> promise.Promise(#(Int, String)) {
  poll_key_raw_ffi(timeout_milliseconds)
}

/// Decodes one raw stdin chunk into the TUI's existing key-code contract.
///
/// Kept on the internal boundary so contract tests can cover every retained
/// key sequence without exposing a new package API.
pub fn decode_key(raw input: String) -> #(Int, String) {
  decode_key_ffi(input)
}

/// Applies the previous truthy-number fallback without JavaScript coercion.
fn positive_or_fallback(value value: Int, fallback fallback: Int) -> Int {
  case value > 0 {
    True -> value
    False -> fallback
  }
}

/// Translates the raw-mode selection into the boolean the runtime FFI expects.
fn raw_mode_is_enabled(mode: RawMode) -> Bool {
  case mode {
    Enabled -> True
    Disabled -> False
  }
}

// -- FFI --

@external(javascript, "./terminal_control_ffi.mjs", "is_tty")
fn is_tty_ffi() -> Bool

@external(javascript, "./terminal_control_ffi.mjs", "set_terminal_raw_mode")
fn set_terminal_raw_mode(enabled: Bool) -> Result(Nil, RawModeError)

@external(javascript, "./terminal_control_ffi.mjs", "terminal_mode_error_message")
fn terminal_mode_error_message(error: RawModeError) -> String

@external(javascript, "./terminal_control_ffi.mjs", "poll_key_raw")
fn poll_key_raw_ffi(timeout_ms: Int) -> promise.Promise(#(Int, String))

@external(javascript, "./terminal_control_ffi.mjs", "decode_key")
fn decode_key_ffi(input: String) -> #(Int, String)
