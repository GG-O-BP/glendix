//// Exercises the terminal control boundary: the delegated size fallback and
//// the retained raw-input FFI surface.
////

import gleam/javascript/promise
import gleam/list
import gleeunit/should
import glendix/internal/define/terminal_control

/// Verifies `term_size` row/column ordering is converted to the TUI contract.
pub fn size_from_available_measurement_swaps_to_columns_rows_test() -> Nil {
  terminal_control.size_from(using: Ok(#(42, 132)))
  |> should.equal(#(132, 42))
}

/// Verifies zero and negative dimensions use their independent fallbacks.
pub fn size_from_nonpositive_measurement_returns_fallbacks_test() -> Nil {
  terminal_control.size_from(using: Ok(#(0, -5)))
  |> should.equal(#(80, 24))
}

/// Verifies one invalid dimension does not replace the other valid dimension.
pub fn size_from_partially_invalid_measurement_falls_back_independently_test() -> Nil {
  terminal_control.size_from(using: Ok(#(32, 0)))
  |> should.equal(#(80, 32))
}

/// Verifies an unavailable terminal size falls back to 80 columns by 24 rows.
pub fn size_from_error_returns_80_by_24_fallback_test() -> Nil {
  terminal_control.size_from(using: Error(Nil))
  |> should.equal(#(80, 24))
}

/// Verifies the size query always reports positive columns and rows, so the
/// 80x24 fallback keeps the TUI layout valid when the runtime has no size.
pub fn size_always_returns_positive_dimensions_test() -> Nil {
  let #(columns, rows) = terminal_control.size()
  { columns > 0 }
  |> should.be_true
  { rows > 0 }
  |> should.be_true
}

/// Verifies the TTY probe reports a boolean capability without raising.
pub fn is_tty_reports_boolean_capability_test() -> Nil {
  let interactive = terminal_control.is_tty()
  { interactive == True || interactive == False }
  |> should.be_true
}

/// Verifies every retained navigation, control, character, and UTF-8 sequence.
pub fn decode_key_preserves_existing_key_semantics_test() -> Nil {
  [
    #("", #(0, "")),
    #("\u{1b}[A", #(1, "")),
    #("\u{1b}[B", #(2, "")),
    #("\u{1b}[C", #(3, "")),
    #("\u{1b}[D", #(4, "")),
    #("\r", #(5, "")),
    #("\n", #(5, "")),
    #("\u{1b}", #(6, "")),
    #("\u{1b}[Z", #(6, "")),
    #("\u{7f}", #(7, "")),
    #("\u{8}", #(7, "")),
    #("\u{3}", #(8, "")),
    #("a", #(9, "a")),
    #("é", #(9, "é")),
    #("한", #(9, "한")),
    #("😀", #(9, "😀")),
    #("\u{1b}[H", #(10, "")),
    #("\u{1b}[F", #(11, "")),
    #("\u{1b}[5~", #(12, "")),
    #("\u{1b}[6~", #(13, "")),
    #("\t", #(14, "")),
  ]
  |> list.each(fn(example) {
    terminal_control.decode_key(example.0)
    |> should.equal(example.1)
  })
}

/// Verifies unsupported stdin reports the required raw-mode error message.
pub fn set_raw_mode_without_support_preserves_error_message_test() -> Nil {
  case set_raw_mode_without_support() {
    Ok(Nil) -> False |> should.be_true
    Error(error) ->
      terminal_control.raw_mode_error_message(error)
      |> should.equal("stdin does not support raw mode")
  }
}

/// Verifies thrown runtime errors preserve their exact reason.
pub fn set_raw_mode_exception_preserves_error_message_test() -> Nil {
  case set_raw_mode_with_exception() {
    Ok(Nil) -> False |> should.be_true
    Error(error) ->
      terminal_control.raw_mode_error_message(error)
      |> should.equal("raw mode exploded")
  }
}

/// Verifies enabling raw mode resumes stdin while disabling it does not.
pub fn set_raw_mode_preserves_enable_disable_lifecycle_test() -> Nil {
  raw_mode_lifecycle()
  |> should.equal(#(True, True, True, False))
}

/// Verifies pending input, queued input, and timeout each resolve exactly once.
pub fn poll_key_raw_preserves_one_shot_queue_and_timeout_test() -> promise.Promise(
  Nil,
) {
  use results <- promise.await(poll_key_sequence())
  results
  |> should.equal(#(#(1, ""), #(9, "q"), #(0, "")))
  promise.resolve(Nil)
}

// -- FFI --

@external(javascript, "./terminal_control_test_ffi.mjs", "set_raw_mode_without_support")
fn set_raw_mode_without_support() -> Result(Nil, terminal_control.RawModeError)

@external(javascript, "./terminal_control_test_ffi.mjs", "set_raw_mode_with_exception")
fn set_raw_mode_with_exception() -> Result(Nil, terminal_control.RawModeError)

@external(javascript, "./terminal_control_test_ffi.mjs", "raw_mode_lifecycle")
fn raw_mode_lifecycle() -> #(Bool, Bool, Bool, Bool)

@external(javascript, "./terminal_control_test_ffi.mjs", "poll_key_sequence")
fn poll_key_sequence() -> promise.Promise(
  #(#(Int, String), #(Int, String), #(Int, String)),
)
