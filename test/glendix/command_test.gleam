//// Verifies synchronous command execution and error contracts.
////

import gleam/string
import gleeunit/should
import glendix/cmd

/// Verifies an empty shell command preserves its successful no-op behavior.
pub fn empty_command_succeeds_test() -> Nil {
  cmd.exec(command: "")
  |> should.be_ok
}

/// Verifies command strings retain shell parsing and operator behavior.
pub fn shell_command_string_succeeds_test() -> Nil {
  cmd.exec(
    command: "node -e \"process.exit(0)\" && node -e \"process.exit(0)\"",
  )
  |> should.be_ok
}

/// Verifies a nonzero generic command returns the public command error.
pub fn shell_command_failure_surfaces_reason_test() -> Nil {
  let source = "node -e \"process.exit(7)\""
  case cmd.exec(command: source) {
    Error(cmd.CommandFailed(operation, reason)) -> {
      operation
      |> should.equal("execute command")
      reason
      |> should.equal("Command failed: " <> source)
    }
    Ok(_) -> should.fail()
  }
}

/// Verifies shellout's inherited-stream listener does not leak after commands.
pub fn shell_command_cleans_up_sigint_listeners_test() -> Nil {
  let initial_count = sigint_listener_count()
  cmd.exec(command: "")
  |> should.be_ok
  cmd.exec(command: "node -e \"process.exit(9)\"")
  |> should.be_error
  sigint_listener_count()
  |> should.equal(initial_count)
}

/// Verifies the filtered Gleam command path remains synchronous and successful.
pub fn filtered_gleam_command_succeeds_test() -> Nil {
  cmd.exec(command: "gleam --version")
  |> should.be_ok
}

/// Verifies the filtered Gleam command path preserves its failure message.
pub fn filtered_gleam_command_failure_surfaces_reason_test() -> Nil {
  let source = "gleam command-that-does-not-exist"
  case cmd.exec(command: source) {
    Error(cmd.CommandFailed(operation, reason)) -> {
      operation
      |> should.equal("execute command")
      reason
      |> string.contains(source)
      |> should.be_true
    }
    Ok(_) -> should.fail()
  }
}

@external(javascript, "./command_test_ffi.mjs", "sigint_listener_count")
fn sigint_listener_count() -> Int
