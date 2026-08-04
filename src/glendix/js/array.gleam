//// Converts between Gleam lists and JavaScript arrays at the FFI boundary.
////

/// Represents a JavaScript array whose elements have a known Gleam type.
pub type JsArray(element)

/// Converts a Gleam list into a JavaScript array.
pub fn from_list(list list: List(element)) -> JsArray(element) {
  list_to_array(list)
}

/// Converts a JavaScript array into a Gleam list.
pub fn to_list(array array: JsArray(element)) -> List(element) {
  array_to_list(array)
}

// -- FFI --
@external(javascript, "./array_ffi.mjs", "list_to_array")
fn list_to_array(list: List(element)) -> JsArray(element)

@external(javascript, "./array_ffi.mjs", "array_to_list")
fn array_to_list(array: JsArray(element)) -> List(element)
