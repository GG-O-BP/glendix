//// Performs dynamic JavaScript reflection against object handles.
////
//// These operations are the interop boundary: they read and write arbitrary
//// properties, invoke methods, and call constructors by name at runtime. They
//// are inherently dynamic and unsafe in the sense that the caller, not the
//// type system, guarantees a property exists, a method is callable, or a value
//// is a constructor. Keep this surface minimal and prefer the data-only
//// `glendix/js/object` module whenever a plain data object is enough.
////
//// Object handles and values flow through `glendix/js/object`, so both modules
//// share one typed representation of JavaScript objects and values.
////

import glendix/js/object

/// Represents a JavaScript constructor handle.
pub type JsConstructor

/// Reads an object property.
pub fn get(from handle: object.JsObject, key key: String) -> object.JsValue {
  get_property_raw(handle, key)
}

/// Mutates an object property and returns the same object handle.
pub fn set(
  on handle: object.JsObject,
  key key: String,
  to value: object.JsValue,
) -> object.JsObject {
  set_property_raw(handle, key, value)
}

/// Deletes an object property and returns the same object handle.
pub fn delete(
  from handle: object.JsObject,
  key key: String,
) -> object.JsObject {
  delete_property_raw(handle, key)
}

/// Reports whether an object has the given property.
pub fn has(in handle: object.JsObject, key key: String) -> Bool {
  has_property_raw(handle, key)
}

/// Calls an object method with a list of arguments.
pub fn call_method(
  on handle: object.JsObject,
  named method: String,
  with arguments: List(object.JsValue),
) -> object.JsValue {
  call_method_raw(handle, method, arguments)
}

/// Calls an object method without arguments.
pub fn call_method_without_arguments(
  on handle: object.JsObject,
  named method: String,
) -> object.JsValue {
  call_method_without_arguments_raw(handle, method)
}

/// Creates an object with JavaScript's `new` operator.
pub fn new_instance(
  using constructor: JsConstructor,
  with arguments: List(object.JsValue),
) -> object.JsObject {
  new_instance_raw(constructor, arguments)
}

// -- FFI --
@external(javascript, "./reflect_ffi.mjs", "get_property")
fn get_property_raw(handle: object.JsObject, key: String) -> object.JsValue

@external(javascript, "./reflect_ffi.mjs", "set_property")
fn set_property_raw(
  handle: object.JsObject,
  key: String,
  value: object.JsValue,
) -> object.JsObject

@external(javascript, "./reflect_ffi.mjs", "delete_property")
fn delete_property_raw(handle: object.JsObject, key: String) -> object.JsObject

@external(javascript, "./reflect_ffi.mjs", "has_property")
fn has_property_raw(handle: object.JsObject, key: String) -> Bool

@external(javascript, "./reflect_ffi.mjs", "call_method")
fn call_method_raw(
  handle: object.JsObject,
  method: String,
  arguments: List(object.JsValue),
) -> object.JsValue

@external(javascript, "./reflect_ffi.mjs", "call_method_0")
fn call_method_without_arguments_raw(
  handle: object.JsObject,
  method: String,
) -> object.JsValue

@external(javascript, "./reflect_ffi.mjs", "new_instance")
fn new_instance_raw(
  constructor: JsConstructor,
  arguments: List(object.JsValue),
) -> object.JsObject
