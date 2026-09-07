//// Tests dynamic JavaScript property, method, and constructor reflection.
////

import gleeunit/should
import glendix/js/object
import glendix/js/reflect

/// Verifies reflection reads existing values and preserves missing `undefined`.
pub fn get_reads_existing_and_missing_properties_test() -> Nil {
  let handle = object.from_entries([#("theme", object.string("dark"))])
  handle
  |> reflect.get(key: "theme")
  |> value_to_string
  |> should.equal("dark")
  handle
  |> reflect.get(key: "missing")
  |> value_is_undefined
  |> should.be_true
}

/// Verifies a set overwrites in place and returns the same object handle.
pub fn set_overwrites_and_returns_same_handle_test() -> Nil {
  let handle = object.from_entries([#("count", object.int(1))])
  let updated = reflect.set(on: handle, key: "count", to: object.int(7))
  same_object(handle, updated)
  |> should.be_true
  updated
  |> reflect.get(key: "count")
  |> value_to_string
  |> should.equal("7")
  updated
  |> reflect.set(key: "added", to: object.bool(object.TrueValue))
  |> reflect.get(key: "added")
  |> value_to_string
  |> should.equal("true")
}

/// Verifies deleting present or missing properties returns the same handle.
pub fn delete_removes_property_and_returns_same_handle_test() -> Nil {
  let handle = object.from_entries([#("theme", object.string("dark"))])
  let cleared = reflect.delete(from: handle, key: "theme")
  same_object(handle, cleared)
  |> should.be_true
  cleared
  |> reflect.has(key: "theme")
  |> should.be_false
  cleared
  |> reflect.delete(key: "missing")
  |> same_object(cleared)
  |> should.be_true
}

/// Verifies presence checks retain JavaScript prototype-chain semantics.
pub fn has_reports_own_missing_and_inherited_properties_test() -> Nil {
  let handle = object.from_entries([#("theme", object.string("dark"))])
  reflect.has(in: handle, key: "theme")
  |> should.be_true
  reflect.has(in: handle, key: "missing")
  |> should.be_false
  reflect.has(in: handle, key: "toString")
  |> should.be_true
}

/// Verifies method calls forward ordered arguments to the receiver.
pub fn call_method_passes_arguments_test() -> Nil {
  method_object()
  |> reflect.call_method(named: "add", with: [object.int(2), object.int(5)])
  |> value_to_string
  |> should.equal("10")
}

/// Verifies argument-free method calls bind the receiver as `this`.
pub fn call_method_without_arguments_reads_receiver_test() -> Nil {
  method_object()
  |> reflect.call_method_without_arguments(named: "describe")
  |> value_to_string
  |> should.equal("total:3")
}

/// Verifies construction forwards every argument and returns the built object.
pub fn new_instance_constructs_object_test() -> Nil {
  point_constructor()
  |> reflect.new_instance(with: [object.int(3), object.int(4)])
  |> point_summary
  |> should.equal("3,4")
}

// -- FFI --
@external(javascript, "./reflect_test_ffi.mjs", "value_to_string")
fn value_to_string(value: object.JsValue) -> String

@external(javascript, "./reflect_test_ffi.mjs", "value_is_undefined")
fn value_is_undefined(value: object.JsValue) -> Bool

@external(javascript, "./reflect_test_ffi.mjs", "method_object")
fn method_object() -> object.JsObject

@external(javascript, "./reflect_test_ffi.mjs", "point_constructor")
fn point_constructor() -> reflect.JsConstructor

@external(javascript, "./reflect_test_ffi.mjs", "same_object")
fn same_object(left: object.JsObject, right: object.JsObject) -> Bool

@external(javascript, "./reflect_test_ffi.mjs", "point_summary")
fn point_summary(handle: object.JsObject) -> String
