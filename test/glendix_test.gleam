//// Exercises Glendix pure domain logic and JavaScript FFI contracts.
////

import gleam/dynamic
import gleam/javascript/array as javascript_array
import gleam/javascript/promise
import gleam/list
import gleam/option
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
import glendix/js/object
import glendix/js/promise as glendix_promise
import glendix/lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import redraw
import redraw/dom/attribute as redraw_attribute
import redraw/dom/html as redraw_html

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

/// Verifies generated lifecycle bindings use deterministic static imports.
pub fn binding_generator_uses_static_initializer_imports_test() -> Nil {
  let source =
    cmd.render_binding_source(bindings: [
      #("@ironcalc/workbook", ["Workbook", "Workbook"], "init", "on-failure"),
      #("component-only", ["Chart"], "", "never"),
      #("api-only", [], "initialize", "never"),
    ])

  source
  |> string.contains("from \"@ironcalc/workbook\";")
  |> should.be_true
  source
  |> string.contains("run: () => __glendix_module_0_export_1()")
  |> should.be_true
  source
  |> string.contains("\"Workbook\": __glendix_module_0_export_0")
  |> should.be_true
  source
  |> string.contains("import(")
  |> should.be_false
  source
  |> string.contains("\"api-only\": {")
  |> should.be_true
}

/// Verifies configurations with no usable exports preserve no-output behavior.
pub fn binding_generator_empty_configuration_has_no_output_test() -> Nil {
  cmd.render_binding_source(bindings: [
    #("empty", [], "", "never"),
  ])
  |> should.equal("")
}

/// Verifies modules without an initializer are immediately reusable.
pub fn binding_module_without_initializer_is_ready_test() -> promise.Promise(
  Nil,
) {
  let module = test_initialization_module("none", "never")
  let initialization = binding.initialization(module)
  binding.initialization_status(initialization)
  |> should.equal(binding.Ready)
  binding.initialized_module(initialization)
  |> should.equal(option.Some(module))
  let #(unchanged, attempt) = binding.initialize(initialization)
  binding.initialization_status(unchanged)
  |> should.equal(binding.Ready)
  attempt
  |> promise.map(fn(outcome) { should.equal(outcome, Ok(Nil)) })
}

/// Verifies successful initialization unlocks rendering and non-React reuse.
pub fn binding_initialization_success_reuses_ready_module_test() -> promise.Promise(
  Nil,
) {
  let module = test_initialization_module("success", "never")
  let initialization = binding.initialization(module)
  let #(loading, attempt) = binding.initialize(initialization)
  binding.initialization_status(loading)
  |> should.equal(binding.Initializing)
  use outcome <- promise.await(attempt)
  let ready = binding.settle_initialization(loading, with: outcome)
  binding.initialization_status(ready)
  |> should.equal(binding.Ready)
  initialization_attempt_count(module)
  |> should.equal(1)
  case binding.initialized_module(ready) {
    option.Some(ready_module) -> {
      binding.resolve(ready_module, "View")
      |> should.be_ok
      |> binding.element([], [])
      |> rendered_tree_summary
      |> should.equal("section")
      non_react_module_value(ready_module)
      |> should.equal(42)
    }
    option.None -> should.fail()
  }
  let #(reused, second) = binding.initialize(ready)
  binding.initialization_status(reused)
  |> should.equal(binding.Ready)
  initialization_attempt_count(module)
  |> should.equal(1)
  second
  |> promise.map(fn(second_outcome) { should.equal(second_outcome, Ok(Nil)) })
}

/// Verifies concurrent consumers receive the exact same in-flight Promise.
pub fn binding_initialization_concurrent_calls_share_one_flight_test() -> promise.Promise(
  Nil,
) {
  let module = test_initialization_module("controlled", "never")
  let #(loading, first) =
    module
    |> binding.initialization
    |> binding.initialize
  let #(shared, second) = binding.initialize(loading)
  initialization_attempt_count(module)
  |> should.equal(1)
  initialization_promises_are_same(first, second)
  |> should.be_true
  resolve_initialization(module)
  promise.await_list([first, second])
  |> promise.map(fn(outcomes) {
    outcomes
    |> should.equal([Ok(Nil), Ok(Nil)])
    binding.initialization_status(shared)
    |> should.equal(binding.Initializing)
  })
}

/// Verifies the default policy caches a rejected attempt until explicit reset.
pub fn binding_initialization_cache_failure_requires_reset_test() -> promise.Promise(
  Nil,
) {
  let module = test_initialization_module("reject", "never")
  let #(loading, first) =
    module
    |> binding.initialization
    |> binding.initialize
  use first_outcome <- promise.await(first)
  let failed = binding.settle_initialization(loading, with: first_outcome)
  binding.initialization_status(failed)
  |> should.equal(
    binding.Failed(binding.InitializationRejected(
      "@test/async-module",
      "init",
      "WebAssembly load failed",
    )),
  )
  let #(cached, second) = binding.initialize(failed)
  initialization_attempt_count(module)
  |> should.equal(1)
  use second_outcome <- promise.await(second)
  second_outcome
  |> should.equal(first_outcome)
  let reset = binding.reset_initialization(cached)
  binding.initialization_status(reset)
  |> should.equal(binding.Uninitialized)
  let #(_retrying, third) = binding.initialize(reset)
  initialization_attempt_count(module)
  |> should.equal(2)
  third
  |> promise.map(fn(outcome) {
    case outcome {
      Error(_) -> Nil
      Ok(_) -> should.fail()
    }
  })
}

/// Verifies the retry policy starts a new attempt after a recorded failure.
pub fn binding_initialization_retry_policy_restarts_after_failure_test() -> promise.Promise(
  Nil,
) {
  let module = test_initialization_module("reject", "on-failure")
  let #(loading, first) =
    module
    |> binding.initialization
    |> binding.initialize
  use first_outcome <- promise.await(first)
  let failed = binding.settle_initialization(loading, with: first_outcome)
  let #(_retrying, second) = binding.initialize(failed)
  initialization_attempt_count(module)
  |> should.equal(2)
  second
  |> promise.map(fn(outcome) {
    case outcome {
      Error(_) -> Nil
      Ok(_) -> should.fail()
    }
  })
}

/// Verifies synchronous throws become start failures with retained context.
pub fn binding_initialization_synchronous_throw_is_typed_test() -> promise.Promise(
  Nil,
) {
  let module = test_initialization_module("throw", "never")
  let #(failed, attempt) =
    module
    |> binding.initialization
    |> binding.initialize
  binding.initialization_status(failed)
  |> should.equal(
    binding.Failed(binding.InitializationCouldNotStart(
      "@test/async-module",
      "init",
      "Initializer threw synchronously",
    )),
  )
  attempt
  |> promise.map(fn(outcome) {
    outcome
    |> should.equal(
      Error(binding.InitializationCouldNotStart(
        "@test/async-module",
        "init",
        "Initializer threw synchronously",
      )),
    )
  })
}

/// Verifies non-Promise initializer returns fail before entering flight state.
pub fn binding_initialization_non_promise_is_typed_test() -> promise.Promise(
  Nil,
) {
  let module = test_initialization_module("non-promise", "never")
  let #(_failed, attempt) =
    module
    |> binding.initialization
    |> binding.initialize
  attempt
  |> promise.map(fn(outcome) {
    outcome
    |> should.equal(
      Error(binding.InitializationCouldNotStart(
        "@test/async-module",
        "init",
        "Initializer must return a Promise: init",
      )),
    )
  })
}

/// Verifies reset cannot replace an in-flight attempt and create a race.
pub fn binding_initialization_reset_while_loading_is_ignored_test() -> Nil {
  let module = test_initialization_module("controlled", "never")
  let #(loading, _attempt) =
    module
    |> binding.initialization
    |> binding.initialize
  loading
  |> binding.reset_initialization
  |> binding.initialization_status
  |> should.equal(binding.Initializing)
  initialization_attempt_count(module)
  |> should.equal(1)
  resolve_initialization(module)
}

/// Verifies the Lustre helper dispatches one completion for the shared attempt.
pub fn binding_initialization_effect_dispatches_completion_test() -> promise.Promise(
  Nil,
) {
  let counter = new_promise_callback_counter()
  let module = test_initialization_module("success", "never")
  let #(_loading, initialization_effect) =
    module
    |> binding.initialization
    |> binding.initialization_effect(to_message: fn(outcome) { outcome })
  effect.perform(
    initialization_effect,
    fn(_message) { increment_promise_callback_counter(counter) },
    fn(_name, _data) { Nil },
    fn(_selector) { Nil },
    fn() { dynamic.string("") },
    fn(_name, _value) { Nil },
    fn(_name, _decoder) { Nil },
    fn(_name) { Nil },
  )
  promise.wait(0)
  |> promise.map(fn(_) {
    promise_callback_count(counter)
    |> should.equal(1)
  })
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
      |> should.equal("No such file or directory")
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
      |> should.equal("No such file or directory")
    }
    Ok(_) -> should.fail()
    Error(_) -> should.fail()
  }
}

/// Verifies Int list round trips preserve empty, singleton, and ordered values.
pub fn javascript_array_int_round_trip_test() -> Nil {
  let examples = [[], [1], [1, 2, 3]]
  list.each(examples, fn(example) {
    let standard_array: javascript_array.Array(Int) = array.from_list(example)
    standard_array
    |> array.to_list
    |> should.equal(example)
  })
}

/// Verifies the conversion is generic over the element type.
pub fn javascript_array_string_round_trip_test() -> Nil {
  ["glendix", "js", "array"]
  |> array.from_list
  |> array.to_list
  |> should.equal(["glendix", "js", "array"])
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

/// Verifies keyed hosts preserve state, receive fresh props, and remount once.
pub fn lustre_keyed_host_lifecycle_contract_test() -> Nil {
  keyed_host_lifecycle_summary(lustre.keyed_host, lifecycle_application)
  |> should.equal(
    "initial=1/0:first;unchanged=1/0:first;changed=2/1:replacement;props=first,fresh,replacement;cleanup=2",
  )
}

/// Verifies an empty key is stable and nested Redraw embedding still renders.
pub fn lustre_keyed_host_nested_embedding_contract_test() -> Nil {
  keyed_host_nested_summary(lustre.keyed_host, nested_application)
  |> should.equal("section|strong|nested")
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

/// Verifies resolve fulfills a Promise with the supplied value.
pub fn promise_resolve_yields_value_test() -> promise.Promise(Nil) {
  glendix_promise.resolve("glendix")
  |> glendix_promise.map(with: fn(value) { should.equal(value, "glendix") })
}

/// Verifies map transforms a fulfilled value without extra callbacks.
pub fn promise_map_transforms_value_test() -> promise.Promise(Nil) {
  glendix_promise.resolve(3)
  |> glendix_promise.map(with: fn(value) { value * 2 })
  |> glendix_promise.map(with: fn(value) { should.equal(value, 6) })
}

/// Verifies then_ chains a Promise-returning callback and flattens the result.
pub fn promise_then_chains_promise_test() -> promise.Promise(Nil) {
  glendix_promise.resolve(10)
  |> glendix_promise.then_(with: fn(value) {
    glendix_promise.resolve(value + 5)
  })
  |> glendix_promise.map(with: fn(value) { should.equal(value, 15) })
}

/// Verifies all resolves to a Gleam list in input order, not settle order.
pub fn promise_all_preserves_input_order_test() -> promise.Promise(Nil) {
  glendix_promise.all(promises: [
    promise.wait(30) |> promise.map(fn(_) { 1 }),
    glendix_promise.resolve(2),
    promise.wait(10) |> promise.map(fn(_) { 3 }),
  ])
  |> glendix_promise.map(with: fn(values) { should.equal(values, [1, 2, 3]) })
}

/// Verifies race settles with the first fulfilled Promise.
pub fn promise_race_returns_first_fulfilled_test() -> promise.Promise(Nil) {
  glendix_promise.race(promises: [
    promise.wait(50) |> promise.map(fn(_) { "slow" }),
    glendix_promise.resolve("fast"),
  ])
  |> glendix_promise.map(with: fn(winner) { should.equal(winner, "fast") })
}

/// Verifies race preserves first-settled behavior when the winner rejects.
pub fn promise_race_first_rejection_wins_test() -> promise.Promise(Nil) {
  glendix_promise.race(promises: [
    glendix_promise.reject("first"),
    promise.wait(50) |> promise.map(fn(_) { "slow" }),
  ])
  |> glendix_promise.catch_(with: fn(rejection) {
    glendix_promise.resolve(promise_rejection_message(rejection))
  })
  |> glendix_promise.map(with: fn(message) { should.equal(message, "first") })
}

/// Verifies reject surfaces its string reason as a JavaScript Error value.
pub fn promise_reject_surfaces_error_test() -> promise.Promise(Nil) {
  glendix_promise.reject("boom")
  |> glendix_promise.catch_(with: fn(rejection) {
    should.be_true(promise_rejection_is_error(rejection))
    glendix_promise.resolve(promise_rejection_message(rejection))
  })
  |> glendix_promise.map(with: fn(message) { should.equal(message, "boom") })
}

/// Verifies catch_ leaves a fulfilled Promise untouched and unrecovered.
pub fn promise_catch_passes_through_fulfilled_test() -> promise.Promise(Nil) {
  glendix_promise.resolve("ok")
  |> glendix_promise.catch_(with: fn(_rejection) {
    glendix_promise.resolve("recovered")
  })
  |> glendix_promise.map(with: fn(value) { should.equal(value, "ok") })
}

/// Verifies await_ runs its callback exactly once and does not block.
pub fn promise_await_runs_callback_once_test() -> promise.Promise(Nil) {
  let counter = new_promise_callback_counter()
  glendix_promise.await_(glendix_promise.resolve(Nil), then: fn(_value) {
    increment_promise_callback_counter(counter)
  })
  promise.wait(0)
  |> promise.map(fn(_) { should.equal(promise_callback_count(counter), 1) })
}

/// Represents a mutable count of one-shot Promise callback invocations.
type PromiseCallbackCounter

fn lifecycle_application(props: String) -> redraw.Element {
  record_keyed_host_props(props)
  track_keyed_host_lifecycle()
  lustre.use_simple(props, fn(model, _message) { model }, fn(model) {
    html.div([], [html.text(model)])
  })
}

fn nested_application(_props: Nil) -> redraw.Element {
  lustre.use_simple(Nil, fn(model, _message) { model }, fn(_model) {
    html.section([], [
      redraw_html.strong([], [redraw_html.text("nested")])
      |> lustre.embed,
    ])
  })
}

// -- FFI --
@external(javascript, "./glendix_test_ffi.mjs", "clone_lustre_tree")
fn clone_lustre_tree(tree: element.Element(message)) -> element.Element(message)

@external(javascript, "./glendix_test_ffi.mjs", "rendered_tree_summary")
fn rendered_tree_summary(tree: redraw.Element) -> String

@external(javascript, "./glendix_test_ffi.mjs", "test_component")
fn test_component() -> binding.JsComponent

@external(javascript, "./glendix_test_ffi.mjs", "test_initialization_module")
fn test_initialization_module(mode: String, retry: String) -> binding.JsModule

@external(javascript, "./glendix_test_ffi.mjs", "initialization_attempt_count")
fn initialization_attempt_count(module: binding.JsModule) -> Int

@external(javascript, "./glendix_test_ffi.mjs", "resolve_initialization")
fn resolve_initialization(module: binding.JsModule) -> Nil

@external(javascript, "./glendix_test_ffi.mjs", "initialization_promises_are_same")
fn initialization_promises_are_same(
  first: promise.Promise(Result(Nil, binding.InitializationError)),
  second: promise.Promise(Result(Nil, binding.InitializationError)),
) -> Bool

@external(javascript, "./glendix_test_ffi.mjs", "non_react_module_value")
fn non_react_module_value(module: binding.JsModule) -> Int

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

@external(javascript, "./glendix_test_ffi.mjs", "element_prop_json")
fn element_prop_json(element element: redraw.Element, key key: String) -> String

@external(javascript, "./glendix_test_ffi.mjs", "element_prop_is")
fn element_prop_is(
  element element: redraw.Element,
  key key: String,
  expected expected: object.JsObject,
) -> Bool

@external(javascript, "./glendix_test_ffi.mjs", "new_promise_callback_counter")
fn new_promise_callback_counter() -> PromiseCallbackCounter

@external(javascript, "./glendix_test_ffi.mjs", "increment_promise_callback_counter")
fn increment_promise_callback_counter(counter: PromiseCallbackCounter) -> Nil

@external(javascript, "./glendix_test_ffi.mjs", "promise_callback_count")
fn promise_callback_count(counter: PromiseCallbackCounter) -> Int

@external(javascript, "./glendix_test_ffi.mjs", "promise_rejection_is_error")
fn promise_rejection_is_error(
  rejection: glendix_promise.PromiseRejection,
) -> Bool

@external(javascript, "./glendix_test_ffi.mjs", "promise_rejection_message")
fn promise_rejection_message(
  rejection: glendix_promise.PromiseRejection,
) -> String

@external(javascript, "./glendix_test_ffi.mjs", "keyed_host_lifecycle_summary")
fn keyed_host_lifecycle_summary(
  keyed_host: fn(String, String, fn(String) -> redraw.Element) -> redraw.Element,
  render: fn(String) -> redraw.Element,
) -> String

@external(javascript, "./glendix_test_ffi.mjs", "keyed_host_nested_summary")
fn keyed_host_nested_summary(
  keyed_host: fn(String, Nil, fn(Nil) -> redraw.Element) -> redraw.Element,
  render: fn(Nil) -> redraw.Element,
) -> String

@external(javascript, "./glendix_test_ffi.mjs", "record_keyed_host_props")
fn record_keyed_host_props(props: String) -> Nil

@external(javascript, "./glendix_test_ffi.mjs", "track_keyed_host_lifecycle")
fn track_keyed_host_lifecycle() -> Nil
