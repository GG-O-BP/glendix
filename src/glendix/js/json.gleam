//// Serializes and parses typed `gleam/json` values in JavaScript.
////

import gleam/json
import gleam/result

/// Represents a JSON parsing failure while preserving the JavaScript reason.
pub type JsonError {
  /// JavaScript rejected the supplied JSON text.
  InvalidJson(reason: String)
}

/// Serializes a JSON value.
pub fn stringify(value value: json.Json) -> String {
  stringify_raw(value)
}

/// Parses JSON text into a typed JSON value.
pub fn parse(from source: String) -> Result(json.Json, JsonError) {
  parse_raw(source)
  |> result.map_error(fn(error) {
    InvalidJson(reason: raw_json_error_message(error))
  })
}

type RawJsonError

// -- FFI --
@external(javascript, "./json_ffi.mjs", "json_stringify")
fn stringify_raw(value: json.Json) -> String

@external(javascript, "./json_ffi.mjs", "json_parse")
fn parse_raw(source: String) -> Result(json.Json, RawJsonError)

@external(javascript, "./json_ffi.mjs", "json_error_message")
fn raw_json_error_message(error: RawJsonError) -> String
