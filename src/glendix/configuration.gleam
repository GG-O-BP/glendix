//// Reads and interprets Glendix project configuration from `gleam.toml`.
////
//// Missing files and missing Glendix tables are valid and produce the same
//// defaults as an empty configuration. Present values are decoded strictly so
//// malformed TOML and schema mismatches cannot silently select tooling.

import gleam/dict
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import simplifile
import tom

/// A parsed project configuration.
pub opaque type Configuration {
  Configuration(document: dict.Dict(String, tom.Toml))
}

/// The compatibility mode selected by the project.
pub type Compatibility {
  /// Uses the package manager's standard command runner.
  Standard
  /// Runs Pluggable Widgets Tools through Glendix's native runtime adapter.
  ExperimentalNative
}

/// Describes a project configuration failure without discarding its cause.
pub type ConfigurationError {
  /// The configuration file exists but could not be read.
  ConfigurationCouldNotBeRead(path: String, reason: simplifile.FileError)
  /// The configuration file contains malformed TOML.
  ConfigurationCouldNotBeParsed(path: String, reason: tom.ParseError)
  /// A configured value does not have the schema's required TOML type.
  ConfiguredValueHasWrongType(key: List(String), expected: String, got: String)
  /// The configured compatibility mode is not supported.
  CompatibilityIsUnsupported(value: String)
}

/// Reads the current project's `gleam.toml`.
///
/// A missing file is represented by an empty configuration.
@internal
pub fn read() -> Result(Configuration, ConfigurationError) {
  read_from(configuration_path)
}

/// Reads a project configuration from a specific path.
///
/// This entry point supports focused tests without changing the process working
/// directory. A missing file is represented by an empty configuration.
@internal
pub fn read_from(
  path path: String,
) -> Result(Configuration, ConfigurationError) {
  case simplifile.read(from: path) {
    Ok(content) -> parse_from(content, path)
    Error(reason) ->
      case reason == simplifile.Enoent {
        True -> Ok(empty())
        False -> Error(ConfigurationCouldNotBeRead(path: path, reason: reason))
      }
  }
}

/// Parses a `gleam.toml` document for focused configuration tests.
@internal
pub fn parse(
  content content: String,
) -> Result(Configuration, ConfigurationError) {
  parse_from(content, configuration_path)
}

/// Returns the configured package-manager override when present.
@internal
pub fn package_manager(
  configuration configuration: Configuration,
) -> Result(option.Option(String), ConfigurationError) {
  use configured <- result.try(
    optional_string(configuration, ["tools", "glendix", "pm"]),
  )
  case configured {
    option.Some("") -> Ok(option.None)
    option.Some(value) -> Ok(option.Some(value))
    option.None -> Ok(option.None)
  }
}

/// Returns the configured compatibility mode.
@internal
pub fn compatibility(
  configuration configuration: Configuration,
) -> Result(Compatibility, ConfigurationError) {
  use configured <- result.try(
    optional_string(configuration, ["tools", "glendix", "compatibility"]),
  )
  case configured {
    option.None -> Ok(Standard)
    option.Some(value) ->
      case value == experimental_native_mode {
        True -> Ok(ExperimentalNative)
        False -> Error(CompatibilityIsUnsupported(value: value))
      }
  }
}

/// Returns configured JavaScript modules and their component names.
///
/// A scalar string selects one component. An array preserves component order,
/// and an empty array is retained so the JavaScript generation boundary can
/// preserve its established no-output behavior.
@internal
pub fn bindings(
  configuration configuration: Configuration,
) -> Result(List(#(String, List(String))), ConfigurationError) {
  let Configuration(document) = configuration
  case tom.get_table(document, ["tools", "glendix", "bindings"]) {
    Ok(table) ->
      table
      |> dict.to_list
      |> list.sort(by: fn(first, second) { string.compare(first.0, second.0) })
      |> list.try_map(parse_binding)
    Error(tom.NotFound(_key)) -> Ok([])
    Error(tom.WrongType(key, expected, got)) ->
      Error(ConfiguredValueHasWrongType(key: key, expected: expected, got: got))
  }
}

/// Formats a configuration error for a command-line failure.
@internal
pub fn error_message(error error: ConfigurationError) -> String {
  case error {
    ConfigurationCouldNotBeRead(path, reason) ->
      "Could not read " <> path <> ": " <> simplifile.describe_error(reason)
    ConfigurationCouldNotBeParsed(path, reason) ->
      "Could not parse " <> path <> " as TOML: " <> parse_error_message(reason)
    ConfiguredValueHasWrongType(key, expected, got) ->
      "Expected "
      <> string.join(key, ".")
      <> " to be "
      <> expected
      <> ", got "
      <> got
    CompatibilityIsUnsupported(value) ->
      "Unsupported [tools.glendix].compatibility value: " <> value
  }
}

const configuration_path = "gleam.toml"

const experimental_native_mode = "experimental-native"

fn empty() -> Configuration {
  Configuration(document: dict.new())
}

fn parse_from(
  content: String,
  path: String,
) -> Result(Configuration, ConfigurationError) {
  content
  |> tom.parse
  |> result.map(fn(document) { Configuration(document: document) })
  |> result.map_error(fn(reason) {
    ConfigurationCouldNotBeParsed(path: path, reason: reason)
  })
}

fn optional_string(
  configuration: Configuration,
  key: List(String),
) -> Result(option.Option(String), ConfigurationError) {
  let Configuration(document) = configuration
  case tom.get_string(document, key) {
    Ok(value) -> Ok(option.Some(value))
    Error(tom.NotFound(_key)) -> Ok(option.None)
    Error(tom.WrongType(key, expected, got)) ->
      Error(ConfiguredValueHasWrongType(key: key, expected: expected, got: got))
  }
}

fn parse_binding(
  entry: #(String, tom.Toml),
) -> Result(#(String, List(String)), ConfigurationError) {
  let #(module_name, configured_components) = entry
  let key = ["tools", "glendix", "bindings", module_name]
  case configured_components {
    tom.String(component) -> Ok(#(module_name, [component]))
    tom.Array(components) -> {
      use components <- result.try(
        components
        |> list.index_map(fn(component, index) { #(component, index) })
        |> list.try_map(fn(indexed_component) {
          let #(component, index) = indexed_component
          string_component(component, list.append(key, [int.to_string(index)]))
        }),
      )
      Ok(#(module_name, components))
    }
    tom.Int(_) -> binding_type_error(key, "Int")
    tom.Float(_) -> binding_type_error(key, "Float")
    tom.Infinity(_) -> binding_type_error(key, "Infinity")
    tom.Nan(_) -> binding_type_error(key, "NaN")
    tom.Bool(_) -> binding_type_error(key, "Bool")
    tom.Date(_) -> binding_type_error(key, "Date")
    tom.Time(_) -> binding_type_error(key, "Time")
    tom.DateTime(_, _, _) -> binding_type_error(key, "DateTime")
    tom.ArrayOfTables(_) -> binding_type_error(key, "Array")
    tom.Table(_) -> binding_type_error(key, "Table")
    tom.InlineTable(_) -> binding_type_error(key, "Table")
  }
}

fn string_component(
  component: tom.Toml,
  key: List(String),
) -> Result(String, ConfigurationError) {
  case component {
    tom.String(value) -> Ok(value)
    tom.Int(_) -> component_type_error(key, "Int")
    tom.Float(_) -> component_type_error(key, "Float")
    tom.Infinity(_) -> component_type_error(key, "Infinity")
    tom.Nan(_) -> component_type_error(key, "NaN")
    tom.Bool(_) -> component_type_error(key, "Bool")
    tom.Date(_) -> component_type_error(key, "Date")
    tom.Time(_) -> component_type_error(key, "Time")
    tom.DateTime(_, _, _) -> component_type_error(key, "DateTime")
    tom.Array(_) -> component_type_error(key, "Array")
    tom.ArrayOfTables(_) -> component_type_error(key, "Array")
    tom.Table(_) -> component_type_error(key, "Table")
    tom.InlineTable(_) -> component_type_error(key, "Table")
  }
}

fn binding_type_error(
  key: List(String),
  got: String,
) -> Result(#(String, List(String)), ConfigurationError) {
  Error(ConfiguredValueHasWrongType(
    key: key,
    expected: "String or Array(String)",
    got: got,
  ))
}

fn component_type_error(
  key: List(String),
  got: String,
) -> Result(String, ConfigurationError) {
  Error(ConfiguredValueHasWrongType(key: key, expected: "String", got: got))
}

fn parse_error_message(error: tom.ParseError) -> String {
  case error {
    tom.Unexpected(got, expected) ->
      "expected " <> expected <> ", got " <> string.inspect(got)
    tom.KeyAlreadyInUse(key) ->
      "key is already in use: " <> string.join(key, ".")
  }
}
