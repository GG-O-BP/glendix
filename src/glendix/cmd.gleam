//// Selects and invokes the JavaScript package manager used by Glendix.
////

import gleam/io
import gleam/option
import gleam/result

/// Describes a JavaScript tooling failure.
pub type CommandError {
  /// A named command operation failed with the supplied JavaScript reason.
  CommandFailed(operation: String, reason: String)
}

/// Executes a command through the JavaScript process boundary.
pub fn exec(command command: String) -> Result(Nil, CommandError) {
  exec_raw(command)
  |> map_raw_error("execute command")
}

/// Detects the package-manager command used to run JavaScript tools.
pub fn detect_runner() -> Result(String, CommandError) {
  use override <- result.try(
    read_pm_override()
    |> map_raw_error("read package-manager override"),
  )
  case override {
    option.Some("pnpm") -> Ok("pnpm exec")
    option.Some("bun") -> Ok("bunx")
    option.Some("npm") -> Ok("npx")
    option.Some(_) | option.None -> detect_runner_from_lockfile()
  }
}

/// Detects the package-manager install command.
pub fn detect_install_command() -> Result(String, CommandError) {
  use override <- result.try(
    read_pm_override()
    |> map_raw_error("read package-manager override"),
  )
  case override {
    option.Some("pnpm") -> Ok("pnpm install")
    option.Some("bun") -> Ok("bun install")
    option.Some("npm") -> Ok("npm install")
    option.Some(_) | option.None -> detect_install_from_lockfile()
  }
}

/// Runs Pluggable Widgets Tools with the supplied arguments.
pub fn run_tool(args args: String) -> Result(Nil, CommandError) {
  use runner <- result.try(detect_runner())
  exec(runner <> " pluggable-widgets-tools " <> args)
}

/// Runs Pluggable Widgets Tools through the Glendix bridge.
pub fn run_tool_with_bridge(args args: String) -> Result(Nil, CommandError) {
  use runner <- result.try(detect_runner())
  run_with_bridge(runner <> " pluggable-widgets-tools " <> args)
  |> map_raw_error("run tool with bridge")
}

/// Runs the web build in development mode through the Glendix bridge.
pub fn run_tool_dev() -> Result(Nil, CommandError) {
  use runner <- result.try(detect_runner())
  run_dev_with_bridge(runner <> " pluggable-widgets-tools build:web")
  |> map_raw_error("run development tool with bridge")
}

/// Generates Mendix widget bindings.
pub fn generate_bindings() -> Result(Nil, CommandError) {
  generate_bindings_raw()
  |> map_raw_error("generate JavaScript bindings")
}

/// Prints a command error at a command-line boundary.
@internal
pub fn report(result result: Result(Nil, CommandError)) -> Nil {
  case result {
    Ok(Nil) -> Nil
    Error(CommandFailed(operation, reason)) -> {
      io.println_error(operation <> " failed: " <> reason)
      fail_process()
    }
  }
}

type RawCommandError

fn detect_runner_from_lockfile() -> Result(String, CommandError) {
  case file_exists("pnpm-lock.yaml") {
    True -> Ok("pnpm exec")
    False ->
      case file_exists("bun.lockb") || file_exists("bun.lock") {
        True -> Ok("bunx")
        False -> Ok("npx")
      }
  }
}

fn detect_install_from_lockfile() -> Result(String, CommandError) {
  case file_exists("pnpm-lock.yaml") {
    True -> Ok("pnpm install")
    False ->
      case file_exists("bun.lockb") || file_exists("bun.lock") {
        True -> Ok("bun install")
        False -> Ok("npm install")
      }
  }
}

fn map_raw_error(
  raw_result: Result(value, RawCommandError),
  operation: String,
) -> Result(value, CommandError) {
  raw_result
  |> result.map_error(fn(error) {
    CommandFailed(
      operation: operation,
      reason: raw_command_error_message(error),
    )
  })
}

// -- FFI --
@external(javascript, "./cmd_ffi.mjs", "exec")
fn exec_raw(command command: String) -> Result(Nil, RawCommandError)

@external(javascript, "./cmd_ffi.mjs", "file_exists")
fn file_exists(path: String) -> Bool

@external(javascript, "./cmd_ffi.mjs", "read_pm_override")
fn read_pm_override() -> Result(option.Option(String), RawCommandError)

@external(javascript, "./cmd_ffi.mjs", "run_with_bridge")
fn run_with_bridge(command: String) -> Result(Nil, RawCommandError)

@external(javascript, "./cmd_ffi.mjs", "run_dev_with_bridge")
fn run_dev_with_bridge(build_command: String) -> Result(Nil, RawCommandError)

@external(javascript, "./cmd_ffi.mjs", "generate_bindings")
fn generate_bindings_raw() -> Result(Nil, RawCommandError)

@external(javascript, "./cmd_ffi.mjs", "command_error_message")
fn raw_command_error_message(error: RawCommandError) -> String

@external(javascript, "./cmd_ffi.mjs", "fail_process")
fn fail_process() -> Nil
