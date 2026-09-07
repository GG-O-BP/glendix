//// Creates and manipulates typed JavaScript object handles.
////

/// Represents a JavaScript value whose runtime shape is intentionally opaque.
pub type JsValue

/// Represents a JavaScript object handle.
pub type JsObject

/// Represents a JavaScript constructor handle.
pub type JsConstructor

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

/// Reads an object property.
pub fn get(from object: JsObject, key key: String) -> JsValue {
  get_property_raw(object, key)
}

/// Mutates an object property and returns the same object handle.
pub fn set(
  on object: JsObject,
  key key: String,
  to value: JsValue,
) -> JsObject {
  set_property_raw(object, key, value)
}

/// Deletes an object property and returns the same object handle.
pub fn delete(from object: JsObject, key key: String) -> JsObject {
  delete_property_raw(object, key)
}

/// Reports whether an object has the given property.
pub fn has(in object: JsObject, key key: String) -> Bool {
  has_property_raw(object, key)
}

/// Calls an object method with a list of arguments.
pub fn call_method(
  on object: JsObject,
  named method: String,
  with arguments: List(JsValue),
) -> JsValue {
  call_method_raw(object, method, arguments)
}

/// Calls an object method without arguments.
pub fn call_method_without_arguments(
  on object: JsObject,
  named method: String,
) -> JsValue {
  call_method_without_arguments_raw(object, method)
}

/// Creates an object with JavaScript's `new` operator.
pub fn new_instance(
  using constructor: JsConstructor,
  with arguments: List(JsValue),
) -> JsObject {
  new_instance_raw(constructor, arguments)
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

@external(javascript, "./object_ffi.mjs", "get_property")
fn get_property_raw(object: JsObject, key: String) -> JsValue

@external(javascript, "./object_ffi.mjs", "set_property")
fn set_property_raw(object: JsObject, key: String, value: JsValue) -> JsObject

@external(javascript, "./object_ffi.mjs", "delete_property")
fn delete_property_raw(object: JsObject, key: String) -> JsObject

@external(javascript, "./object_ffi.mjs", "has_property")
fn has_property_raw(object: JsObject, key: String) -> Bool

@external(javascript, "./object_ffi.mjs", "call_method")
fn call_method_raw(
  object: JsObject,
  method: String,
  arguments: List(JsValue),
) -> JsValue

@external(javascript, "./object_ffi.mjs", "call_method_0")
fn call_method_without_arguments_raw(
  object: JsObject,
  method: String,
) -> JsValue

@external(javascript, "./object_ffi.mjs", "new_instance")
fn new_instance_raw(
  constructor: JsConstructor,
  arguments: List(JsValue),
) -> JsObject
