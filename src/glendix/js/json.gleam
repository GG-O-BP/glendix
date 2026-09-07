//// Serializes `gleam/json` values and parses JSON into caller-selected types.
////

import gleam/dynamic/decode
import gleam/json
import gleam/result

/// Describes why JSON text could not be parsed into the requested type.
pub type JsonError {
  /// The input is not syntactically valid JSON.
  InvalidSyntax(reason: JsonSyntaxError)
  /// The JSON value does not match the requested decoder.
  DecoderMismatch(errors: List(decode.DecodeError))
}

/// Describes a deterministic JSON syntax failure.
pub type JsonSyntaxError {
  /// The input ended before the JSON value was complete.
  UnexpectedEndOfInput
  /// The parser encountered an invalid byte.
  UnexpectedByte(byte: String)
  /// The parser encountered an invalid sequence.
  UnexpectedSequence(sequence: String)
}

/// Serializes a JSON value.
pub fn stringify(value value: json.Json) -> String {
  json.to_string(value)
}

/// Parses JSON text with an explicit decoder for the expected result type.
///
/// Before Glendix 6, this function returned an untyped `json.Json` value.
/// Callers now provide a decoder so invalid value shapes fail at this boundary.
pub fn parse(
  from source: String,
  using decoder: decode.Decoder(value),
) -> Result(value, JsonError) {
  json.parse(from: source, using: decoder)
  |> result.map_error(map_decode_error)
}

fn map_decode_error(error: json.DecodeError) -> JsonError {
  case error {
    json.UnexpectedEndOfInput -> InvalidSyntax(reason: UnexpectedEndOfInput)
    json.UnexpectedByte(byte) ->
      InvalidSyntax(reason: UnexpectedByte(byte: byte))
    json.UnexpectedSequence(sequence) ->
      InvalidSyntax(reason: UnexpectedSequence(sequence: sequence))
    json.UnableToDecode(errors) -> DecoderMismatch(errors: errors)
  }
}
