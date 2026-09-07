//// Selects and invokes the JavaScript package manager used by Glendix.
////

import gleam/io
import gleam/list
import gleam/option
import gleam/result
import glendix/command
import glendix/configuration

/// Describes a JavaScript tooling failure.
pub type CommandError {
  /// A named command operation failed with the supplied JavaScript reason.
  CommandFailed(operation: String, reason: String)
}

/// Executes a command through the JavaScript process boundary.
pub fn exec(command command: String) -> Result(Nil, CommandError) {
  command.run(command)
  |> result.map_error(fn(error) {
    CommandFailed(
      operation: "execute command",
      reason: command.error_message(error),
    )
  })
}

/// Detects the configured or lockfile-selected JavaScript package manager.
pub fn detect_package_manager() -> Result(String, CommandError) {
  use project_configuration <- result.try(read_configuration(
    "read package-manager override",
  ))
  detect_package_manager_with(project_configuration)
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
  use project_configuration <- result.try(read_configuration(
    "read tool configuration",
  ))
  use package_manager <- result.try(detect_package_manager_with(
    project_configuration,
  ))
  use compatibility <- result.try(read_compatibility(project_configuration))
  case compatibility {
    configuration.ExperimentalNative ->
      run_experimental_native_raw(package_manager, args)
      |> map_raw_error("run experimental-native tool")
    configuration.Standard -> {
      use runner <- result.try(
        package_manager
        |> parse_package_manager
        |> result.map(package_manager_runner),
      )
      exec(runner <> " pluggable-widgets-tools " <> args)
    }
  }
}

/// Runs Pluggable Widgets Tools through the Glendix bridge.
pub fn run_tool_with_bridge(args args: String) -> Result(Nil, CommandError) {
  use project_configuration <- result.try(read_configuration(
    "read tool configuration",
  ))
  use package_manager <- result.try(detect_package_manager_with(
    project_configuration,
  ))
  use compatibility <- result.try(read_compatibility(project_configuration))
  use bindings <- result.try(read_bindings(project_configuration))
  case compatibility {
    configuration.ExperimentalNative ->
      run_experimental_native_with_bridge_raw(package_manager, args, bindings)
      |> map_raw_error("run experimental-native tool with bridge")
    configuration.Standard -> {
      use runner <- result.try(
        package_manager
        |> parse_package_manager
        |> result.map(package_manager_runner),
      )
      run_with_bridge(runner <> " pluggable-widgets-tools " <> args, bindings)
      |> map_raw_error("run tool with bridge")
    }
  }
}

/// Runs the web build in development mode through the Glendix bridge.
pub fn run_tool_dev() -> Result(Nil, CommandError) {
  use project_configuration <- result.try(read_configuration(
    "read tool configuration",
  ))
  use package_manager <- result.try(detect_package_manager_with(
    project_configuration,
  ))
  use compatibility <- result.try(read_compatibility(project_configuration))
  use bindings <- result.try(read_bindings(project_configuration))
  case compatibility {
    configuration.ExperimentalNative ->
      run_experimental_native_dev_with_bridge_raw(
        package_manager,
        "build:web",
        bindings,
      )
      |> map_raw_error("run experimental-native development tool with bridge")
    configuration.Standard -> {
      use runner <- result.try(
        package_manager
        |> parse_package_manager
        |> result.map(package_manager_runner),
      )
      run_dev_with_bridge(
        runner <> " pluggable-widgets-tools build:web",
        bindings,
      )
      |> map_raw_error("run development tool with bridge")
    }
  }
}

/// Generates Mendix widget bindings.
pub fn generate_bindings() -> Result(Nil, CommandError) {
  use project_configuration <- result.try(read_configuration(
    "generate JavaScript bindings",
  ))
  use bindings <- result.try(read_bindings(project_configuration))
  generate_bindings_raw(bindings)
  |> map_raw_error("generate JavaScript bindings")
}

/// Renders generated binding source for focused generator contract tests.
@internal
pub fn render_binding_source(
  bindings bindings: List(#(String, List(String), String, String)),
) -> String {
  render_binding_source_raw(bindings)
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

fn detect_package_manager_with(
  project_configuration: configuration.Configuration,
) -> Result(String, CommandError) {
  use override <- result.try(
    configuration.package_manager(project_configuration)
    |> map_configuration_error("read package-manager override"),
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

fn read_configuration(
  operation: String,
) -> Result(configuration.Configuration, CommandError) {
  configuration.read()
  |> map_configuration_error(operation)
}

fn read_compatibility(
  project_configuration: configuration.Configuration,
) -> Result(configuration.Compatibility, CommandError) {
  configuration.compatibility(project_configuration)
  |> map_configuration_error("read compatibility mode")
}

fn read_bindings(
  project_configuration: configuration.Configuration,
) -> Result(List(#(String, List(String), String, String)), CommandError) {
  configuration.binding_configurations(project_configuration)
  |> result.map(fn(bindings) { list.map(bindings, binding_input) })
  |> map_configuration_error("read binding configuration")
}

fn binding_input(
  binding: configuration.BindingConfiguration,
) -> #(String, List(String), String, String) {
  let configuration.BindingConfiguration(module_name, exports, initialization) =
    binding
  case initialization {
    configuration.NoInitialization -> #(module_name, exports, "", "never")
    configuration.Initialize(export_name, failure_policy) -> #(
      module_name,
      exports,
      export_name,
      failure_policy_name(failure_policy),
    )
  }
}

fn failure_policy_name(
  failure_policy: configuration.InitializationFailurePolicy,
) -> String {
  case failure_policy {
    configuration.CacheFailure -> "never"
    configuration.RetryFailure -> "on-failure"
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

fn map_configuration_error(
  configuration_result: Result(value, configuration.ConfigurationError),
  operation: String,
) -> Result(value, CommandError) {
  configuration_result
  |> result.map_error(fn(error) {
    CommandFailed(
      operation: operation,
      reason: configuration.error_message(error),
    )
  })
}

// -- FFI --
@external(javascript, "./cmd_ffi.mjs", "file_exists")
fn file_exists(path: String) -> Bool

@external(javascript, "./cmd_ffi.mjs", "run_with_bridge")
fn run_with_bridge(
  command: String,
  bindings: List(#(String, List(String), String, String)),
) -> Result(Nil, RawCommandError)

@external(javascript, "./cmd_ffi.mjs", "run_dev_with_bridge")
fn run_dev_with_bridge(
  build_command: String,
  bindings: List(#(String, List(String), String, String)),
) -> Result(Nil, RawCommandError)

@external(javascript, "./cmd_ffi.mjs", "generate_bindings")
fn generate_bindings_raw(
  bindings: List(#(String, List(String), String, String)),
) -> Result(Nil, RawCommandError)

@external(javascript, "./cmd_ffi.mjs", "render_binding_source")
fn render_binding_source_raw(
  bindings: List(#(String, List(String), String, String)),
) -> String

@external(javascript, "./cmd_ffi.mjs", "run_experimental_native")
fn run_experimental_native_raw(
  package_manager: String,
  args: String,
) -> Result(Nil, RawCommandError)

@external(javascript, "./cmd_ffi.mjs", "run_experimental_native_with_bridge")
fn run_experimental_native_with_bridge_raw(
  package_manager: String,
  args: String,
  bindings: List(#(String, List(String), String, String)),
) -> Result(Nil, RawCommandError)

@external(javascript, "./cmd_ffi.mjs", "run_experimental_native_dev_with_bridge")
fn run_experimental_native_dev_with_bridge_raw(
  package_manager: String,
  args: String,
  bindings: List(#(String, List(String), String, String)),
) -> Result(Nil, RawCommandError)

@external(javascript, "./cmd_ffi.mjs", "command_error_message")
fn raw_command_error_message(error: RawCommandError) -> String

@external(javascript, "./cmd_ffi.mjs", "fail_process")
fn fail_process() -> Nil
