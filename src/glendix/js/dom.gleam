//// Provides typed DOM element operations at the JavaScript FFI boundary.
////

import gleam/option

/// Represents a DOM element handle.
pub type DomElement

/// Represents a DOM rectangle returned by `getBoundingClientRect`.
pub type DomRect

/// Focuses a DOM element.
pub fn focus(element element: DomElement) -> Nil {
  focus_raw(element)
}

/// Removes focus from a DOM element.
pub fn blur(element element: DomElement) -> Nil {
  blur_raw(element)
}

/// Dispatches the element's native click behavior.
pub fn click(element element: DomElement) -> Nil {
  click_raw(element)
}

/// Scrolls an element into the viewport.
pub fn scroll_into_view(element element: DomElement) -> Nil {
  scroll_into_view_raw(element)
}

/// Reads the element's bounding client rectangle.
pub fn get_bounding_client_rect(element element: DomElement) -> DomRect {
  get_bounding_client_rect_raw(element)
}

/// Finds the first descendant matching a CSS selector.
pub fn query_selector(
  in element: DomElement,
  matching selector: String,
) -> option.Option(DomElement) {
  query_selector_raw(element, selector)
}

// -- FFI --
@external(javascript, "./dom_ffi.mjs", "dom_focus")
fn focus_raw(element: DomElement) -> Nil

@external(javascript, "./dom_ffi.mjs", "dom_blur")
fn blur_raw(element: DomElement) -> Nil

@external(javascript, "./dom_ffi.mjs", "dom_click")
fn click_raw(element: DomElement) -> Nil

@external(javascript, "./dom_ffi.mjs", "dom_scroll_into_view")
fn scroll_into_view_raw(element: DomElement) -> Nil

@external(javascript, "./dom_ffi.mjs", "dom_get_bounding_client_rect")
fn get_bounding_client_rect_raw(element: DomElement) -> DomRect

@external(javascript, "./dom_ffi.mjs", "dom_query_selector")
fn query_selector_raw(
  element: DomElement,
  selector: String,
) -> option.Option(DomElement)
