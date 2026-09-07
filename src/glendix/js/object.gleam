//// Builds plain, prototype-safe JavaScript data objects from typed entries.
////
//// This module owns *data-only* object construction. It converts typed Gleam
//// scalars into opaque JavaScript values and assembles them into plain objects
//// whose keys are always ordinary own data properties. Dynamic interop such as
//// property reads and writes, method calls, and constructor invocation lives in
//// the separate `glendix/js/reflect` module, so this data boundary never
//// depends on arbitrary reflection.
////
//// Construction keeps a small bespoke FFI (`Object.fromEntries`) on purpose: no
//// ecosystem package builds a live, prototype-pollution-safe plain object.
//// `gleam/javascript` only covers arrays, promises, and symbols, and a
//// `gleam/json` round-trip would be indirect and lossy for live handles. The
//// retained FFI guarantees that even a `__proto__` entry is stored as ordinary
//// own data instead of invoking the legacy prototype setter.
////

/// Represents a JavaScript value whose runtime shape is intentionally opaque.
pub type JsValue

/// Represents a JavaScript object handle.
pub type JsObject

/// Represents a JavaScript boolean value.
pub type JsBoolean {
  /// JavaScript `true`.
  TrueValue
  /// JavaScript `false`.
  FalseValue
}

/// Converts a string into a JavaScript value.
pub fn string(value value: String) -> JsValue {
  string_raw(value)
}

/// Converts an integer into a JavaScript value.
pub fn int(value value: Int) -> JsValue {
  int_raw(value)
}

/// Converts a float into a JavaScript value.
pub fn float(value value: Float) -> JsValue {
  float_raw(value)
}

/// Converts a typed JavaScript boolean into a JavaScript value.
pub fn bool(value value: JsBoolean) -> JsValue {
  bool_raw(case value {
    TrueValue -> True
    FalseValue -> False
  })
}

/// Converts an object handle into a JavaScript value.
pub fn from_object(object object: JsObject) -> JsValue {
  object_value_raw(object)
}

/// Creates an object from ordered key-value entries.
///
/// The typed input prevents malformed entry shapes. JavaScript property
/// enumeration rules preserve the order of ordinary string keys, duplicate
/// keys keep their last value, and special keys such as `__proto__` are stored
/// as own data properties.
pub fn from_entries(entries entries: List(#(String, JsValue))) -> JsObject {
  create_object_raw(entries)
}

/// Creates an empty object.
pub fn empty() -> JsObject {
  empty_object_raw()
}

// -- FFI --
@external(javascript, "./object_ffi.mjs", "identity")
fn string_raw(value: String) -> JsValue

@external(javascript, "./object_ffi.mjs", "identity")
fn int_raw(value: Int) -> JsValue

@external(javascript, "./object_ffi.mjs", "identity")
fn float_raw(value: Float) -> JsValue

@external(javascript, "./object_ffi.mjs", "identity")
fn bool_raw(value: Bool) -> JsValue

@external(javascript, "./object_ffi.mjs", "identity")
fn object_value_raw(value: JsObject) -> JsValue

@external(javascript, "./object_ffi.mjs", "create_object")
fn create_object_raw(entries: List(#(String, JsValue))) -> JsObject

@external(javascript, "./object_ffi.mjs", "empty_object")
fn empty_object_raw() -> JsObject
