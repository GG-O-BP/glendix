//// Exercises Glendix pure domain logic and JavaScript FFI contracts.
////

import gleam/json
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import glendix/binding
import glendix/cmd
import glendix/define/file_boundary
import glendix/define/model
import glendix/define/ui
import glendix/js/array
import glendix/js/environment
import glendix/js/json as javascript_json
import glendix/js/object
import glendix/lustre
import lustre/attribute
import lustre/element
import lustre/element/html
import redraw
import redraw/dom/attribute as redraw_attribute

/// Runs the Glendix test suite.
pub fn main() -> Nil {
  gleeunit.main()
}

/// Verifies package-manager detection against the committed npm lockfile.
pub fn cmd_package_lock_selects_npm_test() -> Nil {
  cmd.detect_runner()
  |> should.be_ok
  |> should.equal("npx")
  cmd.detect_install_command()
  |> should.be_ok
  |> should.equal("npm install")
}

/// Verifies every supported manager has an explicit runner and installer.
pub fn cmd_supported_package_manager_commands_test() -> Nil {
  [
    #("npm", "npx", "npm install"),
    #("yarn", "yarn exec", "yarn install"),
    #("pnpm", "pnpm exec", "pnpm install"),
    #("bun", "bunx", "bun install"),
    #(
      "deno",
      "deno x -A -p @mendix/pluggable-widgets-tools",
      "deno install --node-modules-dir=manual --node-modules-linker=hoisted --allow-scripts=npm:@parcel/watcher,npm:@swc/core,npm:core-js,npm:unrs-resolver",
    ),
  ]
  |> list.each(fn(entry) {
    let #(package_manager, runner, installer) = entry
    cmd.package_manager_commands(package_manager)
    |> should.be_ok
    |> should.equal(#(runner, installer))
  })
}

/// Verifies unsupported package managers fail with actionable context.
pub fn cmd_unsupported_package_manager_error_test() -> Nil {
  case cmd.package_manager_commands("unknown") {
    Error(cmd.CommandFailed(operation, reason)) -> {
      operation
      |> should.equal("select package manager")
      reason
      |> string.contains("unknown")
      |> should.be_true
    }
    Ok(_) -> should.fail()
  }
}

/// Verifies generated Rollup configurations terminate after the final bundle.
pub fn cmd_generated_rollup_config_force_closes_test() -> Nil {
  [False, True]
  |> list.each(fn(with_secondary_widget) {
    let source = generated_rollup_config_source(with_secondary_widget)
    source
    |> string.contains("name: \"glendix-force-close\"")
    |> should.be_true
    source
    |> string.contains("return closeAfterBuild(result);")
    |> should.be_true
  })
}

/// Verifies generated Rollup configurations install WebAssembly asset support.
pub fn cmd_generated_rollup_config_includes_wasm_assets_test() -> Nil {
  [False, True]
  |> list.each(fn(with_secondary_widget) {
    let source = generated_rollup_config_source(with_secondary_widget)
    source
    |> string.contains("glendix-wasm-assets")
    |> should.be_true
    source
    |> string.contains("create_wasm_asset_plugin")
    |> should.be_true
  })
}

/// Verifies ES bundles emit one asset and preserve URL suffixes.
pub fn cmd_wasm_asset_es_transform_contract_test() -> Nil {
  let summary = wasm_asset_es_transform_summary()
  summary
  |> string.starts_with("1\nassets/engine-")
  |> should.be_true
  summary
  |> string.contains("/dist/example/widget/assets/engine-")
  |> should.be_true
  summary
  |> string.contains("?cache=1#ready")
  |> should.be_true
}

/// Verifies AMD bundles use the Mendix widget asset route.
pub fn cmd_wasm_asset_amd_transform_contract_test() -> Nil {
  wasm_asset_amd_transform_summary()
  |> string.contains("/widgets/example/widget/assets/engine-")
  |> should.be_true
}

/// Verifies modules without static WebAssembly references remain unchanged.
pub fn cmd_wasm_asset_noop_contract_test() -> Nil {
  wasm_asset_noop_contract()
  |> should.be_true
}

/// Verifies missing WebAssembly files fail with source and module context.
pub fn cmd_wasm_asset_missing_file_contract_test() -> Nil {
  let message = wasm_asset_missing_error()
  message
  |> string.contains("missing.wasm")
  |> should.be_true
  message
  |> string.contains("module.mjs")
  |> should.be_true
}

/// Verifies command reporting marks the JavaScript process as failed.
pub fn cmd_report_marks_process_failure_test() -> Nil {
  cmd.report(Error(cmd.CommandFailed("test operation", "test reason")))
  process_exit_code()
  |> should.equal(1)
  reset_process_exit_code()
}

/// Verifies missing generated bindings return a typed error.
pub fn binding_missing_module_contract_test() -> Nil {
  case binding.module("missing-module") {
    Error(binding.ModuleWasNotFound(name, reason)) -> {
      name
      |> should.equal("missing-module")
      reason
      |> should.not_equal("")
    }
    Ok(_) -> should.fail()
    Error(_) -> should.fail()
  }
}

/// Verifies Glendix can render configured JavaScript components without Mendraw.
pub fn binding_element_contract_test() -> Nil {
  binding.element(test_component(), [redraw_attribute.id("binding-test")], [])
  |> rendered_tree_summary
  |> should.equal("section#binding-test")
}

/// Verifies property type conversion preserves all supported variants.
pub fn define_property_type_round_trip_test() -> Nil {
  model.all_types()
  |> list.each(fn(property_type) {
    property_type
    |> model.type_to_string
    |> model.string_to_type
    |> should.equal(Ok(property_type))
  })
}

/// Verifies the property editor renders a stable type-selection screen.
pub fn define_type_selection_render_test() -> Nil {
  ui.render_type_select_screen(0)
  |> should.not_equal("")
}

/// Verifies missing filesystem reads preserve the requested path and reason.
pub fn define_missing_file_read_contract_test() -> Nil {
  let path = "test/fixtures/does-not-exist.xml"
  case file_boundary.read(path) {
    Error(file_boundary.FileCouldNotBeRead(error_path, reason)) -> {
      error_path
      |> should.equal(path)
      reason
      |> should.not_equal("")
    }
    Ok(_) -> should.fail()
    Error(_) -> should.fail()
  }
}

/// Verifies failed filesystem writes preserve the requested path and reason.
pub fn define_failed_file_write_contract_test() -> Nil {
  let path = "test/fixtures/missing-directory/widget.xml"
  case file_boundary.write(path, "<widget />") {
    Error(file_boundary.FileCouldNotBeWritten(error_path, reason)) -> {
      error_path
      |> should.equal(path)
      reason
      |> should.not_equal("")
    }
    Ok(_) -> should.fail()
    Error(_) -> should.fail()
  }
}

/// Verifies the JavaScript array FFI preserves element order.
pub fn javascript_array_round_trip_test() -> Nil {
  [1, 2, 3]
  |> array.from_list
  |> array.to_list
  |> should.equal([1, 2, 3])
}

/// Verifies the JavaScript JSON FFI parses and serializes typed JSON values.
pub fn javascript_json_round_trip_test() -> Nil {
  let original = json.object([#("name", json.string("glendix"))])
  original
  |> javascript_json.stringify
  |> javascript_json.parse
  |> should.be_ok
  |> javascript_json.stringify
  |> should.equal(javascript_json.stringify(original))
}

/// Verifies Lustre conversion uses stable discriminants instead of constructor names.
pub fn lustre_foreign_constructor_render_contract_test() -> Nil {
  let tree =
    html.section([attribute.id("foreign-root")], [
      html.h2([], [html.text("Foreign Lustre")]),
    ])
    |> clone_lustre_tree

  lustre.render(tree, fn(_message) { Nil })
  |> rendered_tree_summary
  |> should.equal("section#foreign-root|h2|Foreign Lustre")
}

/// Verifies a dark preference maps to the dark and resolved-dark schemes.
pub fn environment_dark_preference_is_dark_test() -> Nil {
  stub_prefers_dark()
  environment.color_scheme()
  |> should.equal(environment.Dark)
  environment.resolved_color_scheme()
  |> should.equal(environment.ResolvedDark)
}

/// Verifies a light preference maps to the light and resolved-light schemes.
pub fn environment_light_preference_is_light_test() -> Nil {
  stub_prefers_light()
  environment.color_scheme()
  |> should.equal(environment.Light)
  environment.resolved_color_scheme()
  |> should.equal(environment.ResolvedLight)
}

/// Verifies no explicit preference reports System and resolves to light.
pub fn environment_no_preference_resolves_to_light_test() -> Nil {
  stub_prefers_none()
  environment.color_scheme()
  |> should.equal(environment.System)
  environment.resolved_color_scheme()
  |> should.equal(environment.ResolvedLight)
}

/// Verifies an unavailable matchMedia reports System and stays unresolved.
pub fn environment_unavailable_match_media_is_unresolved_test() -> Nil {
  clear_match_media()
  environment.color_scheme()
  |> should.equal(environment.System)
  environment.resolved_color_scheme()
  |> should.equal(environment.ResolutionUnavailable)
}

/// Verifies object construction preserves entry order.
pub fn object_from_entries_preserves_entry_order_test() -> Nil {
  object.from_entries([
    #("theme", object.string("dark")),
    #("locale", object.string("en")),
    #("density", object.int(2)),
  ])
  |> object_json
  |> should.equal("{\"theme\":\"dark\",\"locale\":\"en\",\"density\":2}")
}

/// Verifies an empty entry list safely builds an empty object.
pub fn object_from_entries_without_entries_is_empty_object_test() -> Nil {
  object.from_entries([])
  |> object_json
  |> should.equal("{}")
}

/// Verifies a duplicate key keeps the last supplied value.
pub fn object_from_entries_duplicate_key_keeps_last_value_test() -> Nil {
  object.from_entries([
    #("theme", object.string("light")),
    #("theme", object.string("dark")),
  ])
  |> object_json
  |> should.equal("{\"theme\":\"dark\"}")
}

/// Verifies a prototype-looking key remains ordinary own object data.
pub fn object_from_entries_proto_key_is_safe_data_test() -> Nil {
  object.from_entries([#("__proto__", object.string("safe"))])
  |> object_json
  |> should.equal("{\"__proto__\":\"safe\"}")
}

/// Verifies an object passes through Glendix bindings as one intact prop.
pub fn binding_object_prop_preserves_object_test() -> Nil {
  let configuration =
    object.from_entries([
      #("theme", object.string("dark")),
      #("locale", object.string("en")),
    ])
  let rendered =
    binding.element(
      test_component(),
      [redraw_attribute.attribute("config", object.from_object(configuration))],
      [],
    )
  rendered
  |> element_prop_is("config", configuration)
  |> should.be_true
  rendered
  |> element_prop_json("config")
  |> should.equal("{\"theme\":\"dark\",\"locale\":\"en\"}")
}

// -- FFI --
@external(javascript, "./glendix_test_ffi.mjs", "clone_lustre_tree")
fn clone_lustre_tree(tree: element.Element(message)) -> element.Element(message)

@external(javascript, "./glendix_test_ffi.mjs", "rendered_tree_summary")
fn rendered_tree_summary(tree: redraw.Element) -> String

@external(javascript, "./glendix_test_ffi.mjs", "test_component")
fn test_component() -> binding.JsComponent

@external(javascript, "./glendix_test_ffi.mjs", "generated_rollup_config_source")
fn generated_rollup_config_source(with_secondary_widget: Bool) -> String

@external(javascript, "./glendix_test_ffi.mjs", "wasm_asset_es_transform_summary")
fn wasm_asset_es_transform_summary() -> String

@external(javascript, "./glendix_test_ffi.mjs", "wasm_asset_amd_transform_summary")
fn wasm_asset_amd_transform_summary() -> String

@external(javascript, "./glendix_test_ffi.mjs", "wasm_asset_noop_contract")
fn wasm_asset_noop_contract() -> Bool

@external(javascript, "./glendix_test_ffi.mjs", "wasm_asset_missing_error")
fn wasm_asset_missing_error() -> String

@external(javascript, "./glendix_test_ffi.mjs", "process_exit_code")
fn process_exit_code() -> Int

@external(javascript, "./glendix_test_ffi.mjs", "reset_process_exit_code")
fn reset_process_exit_code() -> Nil

@external(javascript, "./glendix_test_ffi.mjs", "stub_prefers_dark")
fn stub_prefers_dark() -> Nil

@external(javascript, "./glendix_test_ffi.mjs", "stub_prefers_light")
fn stub_prefers_light() -> Nil

@external(javascript, "./glendix_test_ffi.mjs", "stub_prefers_none")
fn stub_prefers_none() -> Nil

@external(javascript, "./glendix_test_ffi.mjs", "clear_match_media")
fn clear_match_media() -> Nil

@external(javascript, "./glendix_test_ffi.mjs", "object_json")
fn object_json(handle handle: object.JsObject) -> String

@external(javascript, "./glendix_test_ffi.mjs", "element_prop_json")
fn element_prop_json(element element: redraw.Element, key key: String) -> String

@external(javascript, "./glendix_test_ffi.mjs", "element_prop_is")
fn element_prop_is(
  element element: redraw.Element,
  key key: String,
  expected expected: object.JsObject,
) -> Bool
