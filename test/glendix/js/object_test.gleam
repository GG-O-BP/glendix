//// Tests plain JavaScript data-object construction and value coercion.
////

import gleeunit/should
import glendix/js/object

/// Verifies object construction preserves the order of ordinary string keys.
pub fn from_entries_preserves_entry_order_test() -> Nil {
  object.from_entries([
    #("theme", object.string("dark")),
    #("locale", object.string("en")),
    #("density", object.int(2)),
  ])
  |> object_json
  |> should.equal("{\"theme\":\"dark\",\"locale\":\"en\",\"density\":2}")
}

/// Verifies an empty entry list safely builds an empty object.
pub fn from_entries_without_entries_is_empty_object_test() -> Nil {
  object.from_entries([])
  |> object_json
  |> should.equal("{}")
}

/// Verifies the dedicated empty constructor returns a normal plain object.
pub fn empty_builds_empty_plain_object_test() -> Nil {
  let handle = object.empty()
  handle
  |> object_json
  |> should.equal("{}")
  handle
  |> has_default_prototype
  |> should.be_true
}

/// Verifies a duplicate key keeps the last supplied value.
pub fn from_entries_duplicate_key_keeps_last_value_test() -> Nil {
  object.from_entries([
    #("theme", object.string("light")),
    #("theme", object.string("dark")),
  ])
  |> object_json
  |> should.equal("{\"theme\":\"dark\"}")
}

/// Verifies every typed value coercion preserves its JavaScript representation.
pub fn from_entries_preserves_supported_value_representations_test() -> Nil {
  let nested = object.from_entries([#("name", object.string("nested"))])
  object.from_entries([
    #("string", object.string("glendix")),
    #("int", object.int(42)),
    #("float", object.float(3.5)),
    #("true", object.bool(object.TrueValue)),
    #("false", object.bool(object.FalseValue)),
    #("object", object.from_object(nested)),
  ])
  |> object_json
  |> should.equal(
    "{\"string\":\"glendix\",\"int\":42,\"float\":3.5,\"true\":true,\"false\":false,\"object\":{\"name\":\"nested\"}}",
  )
}

/// Verifies `__proto__` remains own data without changing the object prototype.
pub fn from_entries_proto_key_is_safe_data_test() -> Nil {
  let handle = object.from_entries([#("__proto__", object.string("safe"))])
  handle
  |> object_json
  |> should.equal("{\"__proto__\":\"safe\"}")
  handle
  |> proto_key_is_safe_data
  |> should.be_true
}

// -- FFI --
@external(javascript, "./object_test_ffi.mjs", "object_json")
fn object_json(handle: object.JsObject) -> String

@external(javascript, "./object_test_ffi.mjs", "proto_key_is_safe_data")
fn proto_key_is_safe_data(handle: object.JsObject) -> Bool

@external(javascript, "./object_test_ffi.mjs", "has_default_prototype")
fn has_default_prototype(handle: object.JsObject) -> Bool
