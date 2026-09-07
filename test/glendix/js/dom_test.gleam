//// Exercises Glendix DOM operations with deterministic element handles.
////

import gleam/option
import gleeunit/should
import glendix/js/dom

/// Verifies focus delegates to the element's native focus operation.
pub fn focus_invokes_element_method_test() -> Nil {
  let element = new_element_fixture()
  dom.focus(element)
  operation_count(element, "focus") |> should.equal(1)
}

/// Verifies blur delegates to the element's native blur operation.
pub fn blur_invokes_element_method_test() -> Nil {
  let element = new_element_fixture()
  dom.blur(element)
  operation_count(element, "blur") |> should.equal(1)
}

/// Verifies the retained click adapter invokes native click behavior.
pub fn click_invokes_element_method_test() -> Nil {
  let element = new_element_fixture()
  dom.click(element)
  operation_count(element, "click") |> should.equal(1)
}

/// Verifies scrolling retains the native no-options behavior.
pub fn scroll_into_view_uses_platform_defaults_test() -> Nil {
  let element = new_element_fixture()
  dom.scroll_into_view(element)
  operation_count(element, "scroll_into_view") |> should.equal(1)
  scroll_argument_count(element) |> should.equal(0)
}

/// Verifies bounding rectangles preserve the platform rectangle values.
pub fn get_bounding_client_rect_returns_element_rectangle_test() -> Nil {
  let element = new_element_fixture()
  let rectangle = dom.get_bounding_client_rect(element)
  rectangle_x(rectangle) |> should.equal(1.0)
  rectangle_y(rectangle) |> should.equal(2.0)
  rectangle_width(rectangle) |> should.equal(30.0)
  rectangle_height(rectangle) |> should.equal(40.0)
}

/// Verifies query selector converts a Plinth hit to `Some`.
pub fn query_selector_hit_returns_some_test() -> Nil {
  let element = new_element_fixture()

  case dom.query_selector(in: element, matching: ".child") {
    option.Some(child) -> is_fixture_child(element, child) |> should.be_true
    option.None -> should.fail()
  }
}

/// Verifies query selector converts a Plinth miss to `None`.
pub fn query_selector_miss_returns_none_test() -> Nil {
  let element = new_element_fixture()

  case dom.query_selector(in: element, matching: ".missing") {
    option.None -> Nil
    option.Some(_) -> should.fail()
  }
}

// -- FFI --
@external(javascript, "./dom_test_ffi.mjs", "new_element_fixture")
fn new_element_fixture() -> dom.DomElement

@external(javascript, "./dom_test_ffi.mjs", "operation_count")
fn operation_count(element: dom.DomElement, operation: String) -> Int

@external(javascript, "./dom_test_ffi.mjs", "scroll_argument_count")
fn scroll_argument_count(element: dom.DomElement) -> Int

@external(javascript, "./dom_test_ffi.mjs", "is_fixture_child")
fn is_fixture_child(element: dom.DomElement, candidate: dom.DomElement) -> Bool

@external(javascript, "./dom_test_ffi.mjs", "rectangle_x")
fn rectangle_x(rectangle: dom.DomRect) -> Float

@external(javascript, "./dom_test_ffi.mjs", "rectangle_y")
fn rectangle_y(rectangle: dom.DomRect) -> Float

@external(javascript, "./dom_test_ffi.mjs", "rectangle_width")
fn rectangle_width(rectangle: dom.DomRect) -> Float

@external(javascript, "./dom_test_ffi.mjs", "rectangle_height")
fn rectangle_height(rectangle: dom.DomRect) -> Float
