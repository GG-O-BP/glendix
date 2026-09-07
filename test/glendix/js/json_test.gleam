//// Tests typed JSON serialization, parsing, and deterministic error mapping.
////

import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option
import gleeunit/should
import glendix/js/json as glendix_json

/// Verifies serialization remains compact for null, scalars, arrays, and objects.
pub fn stringify_supported_values_test() -> Nil {
  [
    #(json.null(), "null"),
    #(json.string("line\n\"quoted\""), "\"line\\n\\\"quoted\\\"\""),
    #(json.int(42), "42"),
    #(json.float(3.5), "3.5"),
    #(json.bool(True), "true"),
    #(json.array(from: [1, 2, 3], of: json.int), "[1,2,3]"),
    #(
      json.object([
        #("name", json.string("glendix")),
        #("enabled", json.bool(True)),
      ]),
      "{\"name\":\"glendix\",\"enabled\":true}",
    ),
    #(json.array(from: [], of: json.int), "[]"),
    #(json.object([]), "{}"),
  ]
  |> list.each(fn(example) {
    let #(value, expected) = example
    glendix_json.stringify(value: value)
    |> should.equal(expected)
  })
}

/// Verifies null is accepted only through a decoder that models its absence.
pub fn parse_null_test() -> Nil {
  glendix_json.parse(from: "null", using: decode.optional(decode.string))
  |> should.equal(Ok(option.None))
}

/// Verifies typed scalar parsing covers escaped strings, numbers, and booleans.
pub fn parse_scalar_values_test() -> Nil {
  glendix_json.parse(from: "\"line\\n\\\"quoted\\\"\"", using: decode.string)
  |> should.equal(Ok("line\n\"quoted\""))

  glendix_json.parse(from: "42", using: decode.int)
  |> should.equal(Ok(42))

  glendix_json.parse(from: "3.5", using: decode.float)
  |> should.equal(Ok(3.5))

  glendix_json.parse(from: "true", using: decode.bool)
  |> should.equal(Ok(True))
}

/// Verifies typed array parsing preserves empty and ordered values.
pub fn parse_array_values_test() -> Nil {
  ["[]", "[1,2,3]"]
  |> list.map(fn(source) {
    glendix_json.parse(from: source, using: decode.list(of: decode.int))
  })
  |> should.equal([Ok([]), Ok([1, 2, 3])])
}

/// Verifies object fields are decoded into a caller-selected result type.
pub fn parse_object_value_test() -> Nil {
  glendix_json.parse(
    from: "{\"name\":\"glendix\",\"enabled\":true}",
    using: name_and_enabled_decoder(),
  )
  |> should.equal(Ok(#("glendix", True)))
}

/// Verifies malformed input has stable syntax errors without engine messages.
pub fn parse_malformed_json_test() -> Nil {
  ["", "["]
  |> list.each(fn(source) {
    glendix_json.parse(from: source, using: decode.list(of: decode.int))
    |> should.equal(
      Error(glendix_json.InvalidSyntax(
        reason: glendix_json.UnexpectedEndOfInput,
      )),
    )
  })
}

/// Verifies an invalid leading byte is reported without an exception string.
pub fn parse_unexpected_byte_test() -> Nil {
  case glendix_json.parse(from: "?", using: decode.int) {
    Error(glendix_json.InvalidSyntax(reason: glendix_json.UnexpectedByte(
      byte: _,
    ))) -> Nil
    Ok(_) -> should.fail()
    Error(_) -> should.fail()
  }
}

/// Verifies valid JSON with an incompatible decoder preserves typed details.
pub fn parse_decoder_mismatch_test() -> Nil {
  glendix_json.parse(from: "\"not an int\"", using: decode.int)
  |> should.equal(
    Error(
      glendix_json.DecoderMismatch(errors: [
        decode.DecodeError(expected: "Int", found: "String", path: []),
      ]),
    ),
  )
}

/// Verifies nested decoder errors preserve their deterministic field path.
pub fn parse_nested_decoder_mismatch_path_test() -> Nil {
  glendix_json.parse(from: "{\"count\":\"many\"}", using: count_decoder())
  |> should.equal(
    Error(
      glendix_json.DecoderMismatch(errors: [
        decode.DecodeError(expected: "Int", found: "String", path: ["count"]),
      ]),
    ),
  )
}

fn name_and_enabled_decoder() -> decode.Decoder(#(String, Bool)) {
  use name <- decode.field("name", decode.string)
  use enabled <- decode.field("enabled", decode.bool)
  decode.success(#(name, enabled))
}

fn count_decoder() -> decode.Decoder(Int) {
  use count <- decode.field("count", decode.int)
  decode.success(count)
}
