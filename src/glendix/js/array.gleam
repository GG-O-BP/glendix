//// Converts between Gleam lists and JavaScript arrays.
////
//// The conversions delegate to `gleam/javascript/array`, so the standard
//// `Array(element)` type is the JavaScript array representation and Glendix no
//// longer owns equivalent runtime code. The former opaque `JsArray(element)`
//// type is removed; annotate values with `gleam/javascript/array.Array`
//// instead. See the repository README for the migration note.
////

import gleam/javascript/array as javascript_array

/// Converts a Gleam list into a JavaScript array, preserving element order.
pub fn from_list(list list: List(element)) -> javascript_array.Array(element) {
  javascript_array.from_list(list)
}

/// Converts a JavaScript array into a Gleam list, preserving element order.
pub fn to_list(array array: javascript_array.Array(element)) -> List(element) {
  javascript_array.to_list(array)
}
