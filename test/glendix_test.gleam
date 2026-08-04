//// Exercises Glendix pure domain logic and JavaScript FFI contracts.
////

import gleam/json
import gleam/list
import gleeunit
import gleeunit/should
import glendix/binding
import glendix/cmd
import glendix/define/file_boundary
import glendix/define/model
import glendix/define/ui
import glendix/js/array
import glendix/js/json as javascript_json
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

// -- FFI --
@external(javascript, "./glendix_test_ffi.mjs", "clone_lustre_tree")
fn clone_lustre_tree(tree: element.Element(message)) -> element.Element(message)

@external(javascript, "./glendix_test_ffi.mjs", "rendered_tree_summary")
fn rendered_tree_summary(tree: redraw.Element) -> String

@external(javascript, "./glendix_test_ffi.mjs", "test_component")
fn test_component() -> binding.JsComponent
