//// Runs synchronous shell commands while preserving Glendix CLI semantics.
////

import gleam/result
import gleam/string
import shellout

/// Describes a synchronous command execution failure.
@internal
pub type CommandFailure {
  /// A command failed with the supplied process-boundary reason.
  CommandFailed(command: String, reason: String)
}

/// Runs a shell command synchronously with inherited standard streams.
@internal
pub fn run(command command: String) -> Result(Nil, CommandFailure) {
  case string.starts_with(command, "gleam ") {
    True -> run_filtered(command)
    False -> run_with_shellout(command)
  }
}

/// Returns the compatibility error message for a failed command.
@internal
pub fn error_message(failure failure: CommandFailure) -> String {
  let CommandFailed(reason:, ..) = failure
  reason
}

type RawCommandError

type SigintListeners

fn run_with_shellout(command: String) -> Result(Nil, CommandFailure) {
  let listeners = capture_sigint_listeners()
  let execution =
    shellout.command(
      run: shell_executable(),
      with: shell_arguments(command),
      in: ".",
      opt: [shellout.LetBeStdout, shellout.LetBeStderr],
    )
  restore_sigint_listeners(listeners)
  execution
  |> result.map(fn(_) { Nil })
  |> result.map_error(fn(error) {
    let #(_status, output) = error
    CommandFailed(
      command: command,
      reason: shellout_error_message(command, output),
    )
  })
}

fn shell_executable() -> String {
  case is_windows() {
    True -> windows_shell()
    False -> "/bin/sh"
  }
}

fn shell_arguments(command: String) -> List(String) {
  case is_windows() {
    True -> ["/d", "/s", "/c", command]
    False -> ["-c", command]
  }
}

fn shellout_error_message(command: String, output: String) -> String {
  let summary = "Command failed: " <> command
  case string.trim(output) {
    "" -> summary
    detail -> summary <> "\n" <> detail
  }
}

fn run_filtered(command: String) -> Result(Nil, CommandFailure) {
  run_filtered_raw(command)
  |> result.map_error(fn(error) {
    CommandFailed(command: command, reason: raw_error_message(error))
  })
}

@external(javascript, "./command_ffi.mjs", "is_windows")
fn is_windows() -> Bool

@external(javascript, "./command_ffi.mjs", "windows_shell")
fn windows_shell() -> String

@external(javascript, "./command_ffi.mjs", "capture_sigint_listeners")
fn capture_sigint_listeners() -> SigintListeners

@external(javascript, "./command_ffi.mjs", "restore_sigint_listeners")
fn restore_sigint_listeners(listeners: SigintListeners) -> Nil

@external(javascript, "./command_ffi.mjs", "run_filtered")
fn run_filtered_raw(command: String) -> Result(Nil, RawCommandError)

@external(javascript, "./command_ffi.mjs", "error_message")
fn raw_error_message(error: RawCommandError) -> String
