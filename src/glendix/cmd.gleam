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

/// Detects the configured or lockfile-selected JavaScript package manager.
pub fn detect_package_manager() -> Result(String, CommandError) {
  use override <- result.try(
    read_pm_override()
    |> map_raw_error("read package-manager override"),
  )
  case override {
    option.Some(name) ->
      name
      |> parse_package_manager
      |> result.map(package_manager_name)
    option.None ->
      Ok(package_manager_name(detect_package_manager_from_lockfile()))
  }
}

/// Detects the package-manager command used to run JavaScript tools.
pub fn detect_runner() -> Result(String, CommandError) {
  use package_manager <- result.try(detect_package_manager())
  package_manager |> parse_package_manager |> result.map(package_manager_runner)
}

/// Detects the package-manager install command.
pub fn detect_install_command() -> Result(String, CommandError) {
  use package_manager <- result.try(detect_package_manager())
  package_manager
  |> parse_package_manager
  |> result.map(package_manager_install_command)
}

/// Returns the runner and install command for a package-manager name.
@internal
pub fn package_manager_commands(
  package_manager package_manager: String,
) -> Result(#(String, String), CommandError) {
  use parsed <- result.try(parse_package_manager(package_manager))
  Ok(#(package_manager_runner(parsed), package_manager_install_command(parsed)))
}

/// Runs Pluggable Widgets Tools with the supplied arguments.
pub fn run_tool(args args: String) -> Result(Nil, CommandError) {
  use package_manager <- result.try(detect_package_manager())
  use experimental_native <- result.try(read_experimental_native_mode())
  case experimental_native {
    True ->
      run_experimental_native_raw(package_manager, args)
      |> map_raw_error("run experimental-native tool")
    False -> {
      use runner <- result.try(detect_runner())
      exec(runner <> " pluggable-widgets-tools " <> args)
    }
  }
}

/// Runs Pluggable Widgets Tools through the Glendix bridge.
pub fn run_tool_with_bridge(args args: String) -> Result(Nil, CommandError) {
  use package_manager <- result.try(detect_package_manager())
  use experimental_native <- result.try(read_experimental_native_mode())
  case experimental_native {
    True ->
      run_experimental_native_with_bridge_raw(package_manager, args)
      |> map_raw_error("run experimental-native tool with bridge")
    False -> {
      use runner <- result.try(detect_runner())
      run_with_bridge(runner <> " pluggable-widgets-tools " <> args)
      |> map_raw_error("run tool with bridge")
    }
  }
}

/// Runs the web build in development mode through the Glendix bridge.
pub fn run_tool_dev() -> Result(Nil, CommandError) {
  use package_manager <- result.try(detect_package_manager())
  use experimental_native <- result.try(read_experimental_native_mode())
  case experimental_native {
    True ->
      run_experimental_native_dev_with_bridge_raw(package_manager, "build:web")
      |> map_raw_error("run experimental-native development tool with bridge")
    False -> {
      use runner <- result.try(detect_runner())
      run_dev_with_bridge(runner <> " pluggable-widgets-tools build:web")
      |> map_raw_error("run development tool with bridge")
    }
  }
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

type PackageManager {
  Npm
  Yarn
  Pnpm
  Bun
  Deno
}

fn parse_package_manager(name: String) -> Result(PackageManager, CommandError) {
  case name {
    "npm" -> Ok(Npm)
    "yarn" -> Ok(Yarn)
    "pnpm" -> Ok(Pnpm)
    "bun" -> Ok(Bun)
    "deno" -> Ok(Deno)
    unsupported ->
      Error(CommandFailed(
        operation: "select package manager",
        reason: "unsupported package manager '"
          <> unsupported
          <> "'; expected npm, yarn, pnpm, bun, or deno",
      ))
  }
}

fn package_manager_name(package_manager: PackageManager) -> String {
  case package_manager {
    Npm -> "npm"
    Yarn -> "yarn"
    Pnpm -> "pnpm"
    Bun -> "bun"
    Deno -> "deno"
  }
}

fn package_manager_runner(package_manager: PackageManager) -> String {
  case package_manager {
    Npm -> "npx"
    Yarn -> "yarn exec"
    Pnpm -> "pnpm exec"
    Bun -> "bunx"
    Deno -> "deno x -A -p @mendix/pluggable-widgets-tools"
  }
}

fn package_manager_install_command(package_manager: PackageManager) -> String {
  case package_manager {
    Npm -> "npm install"
    Yarn -> "yarn install"
    Pnpm -> "pnpm install"
    Bun -> "bun install"
    Deno ->
      "deno install --node-modules-dir=manual --node-modules-linker=hoisted --allow-scripts=npm:@parcel/watcher,npm:@swc/core,npm:core-js,npm:unrs-resolver"
  }
}

fn detect_package_manager_from_lockfile() -> PackageManager {
  case file_exists("pnpm-lock.yaml") {
    True -> Pnpm
    False ->
      case file_exists("yarn.lock") {
        True -> Yarn
        False ->
          case file_exists("bun.lockb") || file_exists("bun.lock") {
            True -> Bun
            False ->
              case file_exists("deno.lock") {
                True -> Deno
                False -> Npm
              }
          }
      }
  }
}

fn read_experimental_native_mode() -> Result(Bool, CommandError) {
  read_experimental_native_mode_raw()
  |> map_raw_error("read compatibility mode")
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

@external(javascript, "./cmd_ffi.mjs", "read_experimental_native_mode")
fn read_experimental_native_mode_raw() -> Result(Bool, RawCommandError)

@external(javascript, "./cmd_ffi.mjs", "run_with_bridge")
fn run_with_bridge(command: String) -> Result(Nil, RawCommandError)

@external(javascript, "./cmd_ffi.mjs", "run_dev_with_bridge")
fn run_dev_with_bridge(build_command: String) -> Result(Nil, RawCommandError)

@external(javascript, "./cmd_ffi.mjs", "generate_bindings")
fn generate_bindings_raw() -> Result(Nil, RawCommandError)

@external(javascript, "./cmd_ffi.mjs", "run_experimental_native")
fn run_experimental_native_raw(
  package_manager: String,
  args: String,
) -> Result(Nil, RawCommandError)

@external(javascript, "./cmd_ffi.mjs", "run_experimental_native_with_bridge")
fn run_experimental_native_with_bridge_raw(
  package_manager: String,
  args: String,
) -> Result(Nil, RawCommandError)

@external(javascript, "./cmd_ffi.mjs", "run_experimental_native_dev_with_bridge")
fn run_experimental_native_dev_with_bridge_raw(
  package_manager: String,
  args: String,
) -> Result(Nil, RawCommandError)

@external(javascript, "./cmd_ffi.mjs", "command_error_message")
fn raw_command_error_message(error: RawCommandError) -> String

@external(javascript, "./cmd_ffi.mjs", "fail_process")
fn fail_process() -> Nil
