//// Exercises strict Glendix project configuration parsing and defaults.

import gleam/option
import gleam/string
import gleeunit/should
import glendix/configuration

/// Verifies a missing configuration file keeps all absence defaults.
pub fn missing_configuration_uses_defaults_test() -> Nil {
  let parsed =
    configuration.read_from("test/fixtures/does-not-exist.toml")
    |> should.be_ok

  configuration.package_manager(parsed)
  |> should.be_ok
  |> should.equal(option.None)
  configuration.compatibility(parsed)
  |> should.be_ok
  |> should.equal(configuration.Standard)
  configuration.bindings(parsed)
  |> should.be_ok
  |> should.equal([])
}

/// Verifies unrelated TOML without Glendix tables keeps all absence defaults.
pub fn missing_glendix_tables_use_defaults_test() -> Nil {
  let parsed =
    configuration.parse("name = \"example\"\nversion = \"1.0.0\"\n")
    |> should.be_ok

  configuration.package_manager(parsed)
  |> should.be_ok
  |> should.equal(option.None)
  configuration.compatibility(parsed)
  |> should.be_ok
  |> should.equal(configuration.Standard)
  configuration.bindings(parsed)
  |> should.be_ok
  |> should.equal([])
}

/// Verifies package-manager strings use TOML quoting and comment semantics.
pub fn package_manager_override_is_parsed_with_toml_rules_test() -> Nil {
  let parsed =
    configuration.parse("[tools.glendix]\npm = \"bun\" # selected runtime\n")
    |> should.be_ok

  configuration.package_manager(parsed)
  |> should.be_ok
  |> should.equal(option.Some("bun"))
}

/// Verifies an empty override preserves the previous no-override behavior.
pub fn empty_package_manager_override_is_absent_test() -> Nil {
  let parsed =
    configuration.parse("[tools.glendix]\npm = \"\"\n")
    |> should.be_ok

  configuration.package_manager(parsed)
  |> should.be_ok
  |> should.equal(option.None)
}

/// Verifies the supported compatibility string selects native execution.
pub fn experimental_native_compatibility_is_parsed_test() -> Nil {
  let parsed =
    configuration.parse(
      "[tools.glendix]\ncompatibility = 'experimental-native'\n",
    )
    |> should.be_ok

  configuration.compatibility(parsed)
  |> should.be_ok
  |> should.equal(configuration.ExperimentalNative)
}

/// Verifies scalar, array, quoted-key, and empty binding forms are preserved.
pub fn bindings_are_parsed_and_ordered_deterministically_test() -> Nil {
  let parsed =
    configuration.parse(
      "[tools.glendix.bindings]\n"
      <> "zebra = \"Zebra\"\n"
      <> "\"@scope/components\" = [\"Button\", \"Panel\"] # public widgets\n"
      <> "empty = []\n",
    )
    |> should.be_ok

  configuration.bindings(parsed)
  |> should.be_ok
  |> should.equal([
    #("@scope/components", ["Button", "Panel"]),
    #("empty", []),
    #("zebra", ["Zebra"]),
  ])
}

/// Verifies extended bindings preserve initialization and retry configuration.
pub fn extended_bindings_parse_initialization_policy_test() -> Nil {
  let parsed =
    configuration.parse(
      "[tools.glendix.bindings]\n"
      <> "legacy = \"LegacyComponent\"\n"
      <> "\"@ironcalc/workbook\" = { exports = [\"Workbook\"], initializer = \"init\", retry = \"on-failure\" }\n"
      <> "\"api-only\" = { initializer = \"initialize\" }\n",
    )
    |> should.be_ok

  configuration.binding_configurations(parsed)
  |> should.be_ok
  |> should.equal([
    configuration.BindingConfiguration(
      "@ironcalc/workbook",
      ["Workbook"],
      configuration.Initialize("init", configuration.RetryFailure),
    ),
    configuration.BindingConfiguration(
      "api-only",
      [],
      configuration.Initialize("initialize", configuration.CacheFailure),
    ),
    configuration.BindingConfiguration(
      "legacy",
      ["LegacyComponent"],
      configuration.NoInitialization,
    ),
  ])
  configuration.bindings(parsed)
  |> should.be_ok
  |> should.equal([
    #("@ironcalc/workbook", ["Workbook"]),
    #("api-only", []),
    #("legacy", ["LegacyComponent"]),
  ])
}

/// Verifies nested tables support a scalar export and default failure caching.
pub fn nested_binding_table_is_parsed_test() -> Nil {
  let parsed =
    configuration.parse(
      "[tools.glendix.bindings.chart]\n"
      <> "exports = \"Chart\"\n"
      <> "initializer = \"prepare\"\n",
    )
    |> should.be_ok

  configuration.binding_configurations(parsed)
  |> should.be_ok
  |> should.equal([
    configuration.BindingConfiguration(
      "chart",
      ["Chart"],
      configuration.Initialize("prepare", configuration.CacheFailure),
    ),
  ])
}

/// Verifies malformed TOML is rejected instead of being partially interpreted.
pub fn malformed_toml_returns_parse_error_test() -> Nil {
  case configuration.parse("[tools.glendix\npm = \"bun\"\n") {
    Error(configuration.ConfigurationCouldNotBeParsed(path, _reason)) ->
      path |> should.equal("gleam.toml")
    Ok(_) -> should.fail()
    Error(_) -> should.fail()
  }
}

/// Verifies present package-manager values must be TOML strings.
pub fn package_manager_with_wrong_type_returns_schema_error_test() -> Nil {
  let parsed =
    configuration.parse("[tools.glendix]\npm = 42\n")
    |> should.be_ok

  case configuration.package_manager(parsed) {
    Error(configuration.ConfiguredValueHasWrongType(key, expected, got)) -> {
      key |> should.equal(["tools", "glendix", "pm"])
      expected |> should.equal("String")
      got |> should.equal("Int")
    }
    Ok(_) -> should.fail()
    Error(_) -> should.fail()
  }
}

/// Verifies every binding array element must be a TOML string.
pub fn binding_component_with_wrong_type_returns_schema_error_test() -> Nil {
  let parsed =
    configuration.parse(
      "[tools.glendix.bindings]\ncomponents = [\"Button\", 1]\n",
    )
    |> should.be_ok

  case configuration.bindings(parsed) {
    Error(configuration.ConfiguredValueHasWrongType(key, expected, got)) -> {
      key |> should.equal(["tools", "glendix", "bindings", "components", "1"])
      expected |> should.equal("String")
      got |> should.equal("Int")
    }
    Ok(_) -> should.fail()
    Error(_) -> should.fail()
  }
}

/// Verifies extended export arrays retain indexed schema error paths.
pub fn extended_binding_export_with_wrong_type_returns_schema_error_test() -> Nil {
  let parsed =
    configuration.parse(
      "[tools.glendix.bindings]\n"
      <> "components = { exports = [\"Button\", false], initializer = \"init\" }\n",
    )
    |> should.be_ok

  case configuration.binding_configurations(parsed) {
    Error(configuration.ConfiguredValueHasWrongType(key, expected, got)) -> {
      key
      |> should.equal([
        "tools",
        "glendix",
        "bindings",
        "components",
        "exports",
        "1",
      ])
      expected |> should.equal("String")
      got |> should.equal("Bool")
    }
    Ok(_) -> should.fail()
    Error(_) -> should.fail()
  }
}

/// Verifies unsupported retry modes fail with the exact configured key.
pub fn unsupported_binding_retry_policy_returns_schema_error_test() -> Nil {
  let parsed =
    configuration.parse(
      "[tools.glendix.bindings]\n"
      <> "components = { initializer = \"init\", retry = \"always\" }\n",
    )
    |> should.be_ok

  case configuration.binding_configurations(parsed) {
    Error(configuration.ConfiguredValueHasWrongType(key, expected, got)) -> {
      key
      |> should.equal([
        "tools",
        "glendix",
        "bindings",
        "components",
        "retry",
      ])
      expected |> should.equal("\"never\" or \"on-failure\"")
      got |> should.equal("String(\"always\")")
    }
    Ok(_) -> should.fail()
    Error(_) -> should.fail()
  }
}

/// Verifies retry configuration cannot be silently ignored without an initializer.
pub fn retry_without_initializer_returns_schema_error_test() -> Nil {
  let parsed =
    configuration.parse(
      "[tools.glendix.bindings]\n"
      <> "components = { exports = [\"Button\"], retry = \"on-failure\" }\n",
    )
    |> should.be_ok

  case configuration.binding_configurations(parsed) {
    Error(_) -> Nil
    Ok(_) -> should.fail()
  }
}

/// Verifies misspelled extended keys are rejected instead of ignored.
pub fn unknown_extended_binding_key_returns_schema_error_test() -> Nil {
  let parsed =
    configuration.parse(
      "[tools.glendix.bindings]\n"
      <> "components = { exports = [\"Button\"], initialise = \"init\" }\n",
    )
    |> should.be_ok

  case configuration.binding_configurations(parsed) {
    Error(configuration.ConfiguredValueHasWrongType(key, _, _)) ->
      key
      |> should.equal([
        "tools",
        "glendix",
        "bindings",
        "components",
        "initialise",
      ])
    Ok(_) -> should.fail()
    Error(_) -> should.fail()
  }
}

/// Verifies unsupported compatibility values remain actionable command errors.
pub fn unsupported_compatibility_has_actionable_message_test() -> Nil {
  let parsed =
    configuration.parse("[tools.glendix]\ncompatibility = \"future-mode\"\n")
    |> should.be_ok

  case configuration.compatibility(parsed) {
    Error(error) ->
      configuration.error_message(error)
      |> string.contains("[tools.glendix].compatibility")
      |> should.be_true
    Ok(_) -> should.fail()
  }
}
