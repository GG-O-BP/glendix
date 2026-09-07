//// Provides typed filesystem operations for the widget definition editor.
////

import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import simplifile

/// Describes a widget definition filesystem failure.
pub type FileError {
  /// The current package does not declare a widget name.
  WidgetNameWasNotDeclared(path: String)
  /// The expected widget XML file does not exist.
  WidgetXmlWasNotFound(path: String)
  /// A file could not be read or decoded.
  ///
  /// Filesystem reasons come from `simplifile.describe_error`. JSON reasons
  /// use Glendix's stable description of `gleam_json.DecodeError`.
  FileCouldNotBeRead(path: String, reason: String)
  /// A file could not be written.
  ///
  /// The reason comes from `simplifile.describe_error`.
  FileCouldNotBeWritten(path: String, reason: String)
}

/// Finds the widget XML path declared by the current package.
pub fn find_widget_xml() -> Result(String, FileError) {
  let package_path = "package.json"
  use package_contents <- result.try(read(package_path))
  use widget_name <- result.try(widget_name(package_contents, package_path))
  let widget_path = "src/" <> widget_name <> ".xml"

  case simplifile.is_file(widget_path) {
    Ok(True) -> Ok(widget_path)
    Ok(False) -> Error(WidgetXmlWasNotFound(path: widget_path))
    Error(error) ->
      Error(FileCouldNotBeRead(
        path: widget_path,
        reason: simplifile.describe_error(error),
      ))
  }
}

/// Reads a UTF-8 text file.
pub fn read(path path: String) -> Result(String, FileError) {
  simplifile.read(from: path)
  |> result.map_error(fn(error) {
    FileCouldNotBeRead(path: path, reason: simplifile.describe_error(error))
  })
}

/// Writes a UTF-8 text file.
pub fn write(
  path path: String,
  content content: String,
) -> Result(Nil, FileError) {
  simplifile.write(to: path, contents: content)
  |> result.map_error(fn(error) {
    FileCouldNotBeWritten(path: path, reason: simplifile.describe_error(error))
  })
}

fn widget_name(
  package_contents: String,
  package_path: String,
) -> Result(String, FileError) {
  case json.parse(package_contents, package_widget_name_decoder()) {
    Error(error) ->
      Error(FileCouldNotBeRead(
        path: package_path,
        reason: json_decode_error_reason(error),
      ))
    Ok(option.None) -> Error(WidgetNameWasNotDeclared(path: package_path))
    Ok(option.Some(value)) ->
      case decode.run(value, decode.string) {
        Ok(name) ->
          case string.trim(name) {
            "" -> Error(WidgetNameWasNotDeclared(path: package_path))
            _ -> Ok(name)
          }
        Error(_) -> Error(WidgetNameWasNotDeclared(path: package_path))
      }
  }
}

fn package_widget_name_decoder() -> decode.Decoder(
  option.Option(dynamic.Dynamic),
) {
  let object_decoder = {
    use name <- decode.optional_field(
      "widgetName",
      option.None,
      decode.optional(decode.dynamic),
    )
    decode.success(name)
  }
  decode.one_of(object_decoder, or: [decode.success(option.None)])
}

fn json_decode_error_reason(error: json.DecodeError) -> String {
  case error {
    json.UnexpectedEndOfInput -> "JSON ended unexpectedly"
    json.UnexpectedByte(byte) -> "JSON contained unexpected byte: " <> byte
    json.UnexpectedSequence(sequence) ->
      "JSON contained unexpected sequence: " <> sequence
    json.UnableToDecode(errors) -> {
      let reasons =
        errors
        |> list.map(dynamic_decode_error_reason)
        |> string.join("; ")
      "JSON value could not be decoded: " <> reasons
    }
  }
}

fn dynamic_decode_error_reason(error: decode.DecodeError) -> String {
  let decode.DecodeError(expected, found, path) = error
  let location = case path {
    [] -> "root"
    [_, ..] -> string.join(path, ".")
  }
  location <> " expected " <> expected <> " but found " <> found
}
