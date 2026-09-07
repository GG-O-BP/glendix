//// Provides typed DOM operations delegated to Plinth.
////
//// Glendix's established element and rectangle handles stay public through
//// identity adapters. Native click and default scrolling remain minimal FFI
//// gaps because Plinth 0.11.0 does not provide equivalent operations.
////

import gleam/option
import plinth/browser/dom_rect
import plinth/browser/element

/// Represents a DOM element handle.
pub type DomElement

/// Represents a DOM rectangle returned by `getBoundingClientRect`.
pub type DomRect

/// Focuses a DOM element.
pub fn focus(element element: DomElement) -> Nil {
  element.focus(to_plinth_element(element))
}

/// Removes focus from a DOM element.
pub fn blur(element element: DomElement) -> Nil {
  element.blur(to_plinth_element(element))
}

/// Dispatches the element's native click behavior.
pub fn click(element element: DomElement) -> Nil {
  // Plinth 0.11.0 does not bind `HTMLElement.click`, so this remains the
  // smallest compatibility FFI required to preserve Glendix's public API.
  click_raw(element)
}

/// Scrolls an element into the viewport.
pub fn scroll_into_view(element element: DomElement) -> Nil {
  // Plinth 0.11.0 always requests smooth/nearest scrolling. Glendix has
  // historically used the platform defaults, so retain this one adapter.
  scroll_into_view_raw(element)
}

/// Reads the element's bounding client rectangle.
pub fn get_bounding_client_rect(element element: DomElement) -> DomRect {
  element.get_bounding_client_rect(to_plinth_element(element))
  |> from_plinth_dom_rect
}

/// Finds the first descendant matching a CSS selector.
pub fn query_selector(
  in element: DomElement,
  matching selector: String,
) -> option.Option(DomElement) {
  case element.query_selector(to_plinth_element(element), selector) {
    Ok(found) -> option.Some(from_plinth_element(found))
    Error(Nil) -> option.None
  }
}

// -- FFI --
@external(javascript, "./dom_ffi.mjs", "identity")
fn to_plinth_element(element: DomElement) -> element.Element

@external(javascript, "./dom_ffi.mjs", "identity")
fn from_plinth_element(element: element.Element) -> DomElement

@external(javascript, "./dom_ffi.mjs", "identity")
fn from_plinth_dom_rect(rectangle: dom_rect.DomRect) -> DomRect

@external(javascript, "./dom_ffi.mjs", "dom_click")
fn click_raw(element: DomElement) -> Nil

@external(javascript, "./dom_ffi.mjs", "dom_scroll_into_view")
fn scroll_into_view_raw(element: DomElement) -> Nil
