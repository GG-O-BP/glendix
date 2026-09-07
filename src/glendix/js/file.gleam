//// Provides typed browser download resources and modern file selection.
////
//// Download resources use `gossamer/blob` for Blob construction and object-URL
//// lifetime. Render the returned URL and filename on a normal Lustre or Redraw
//// anchor; Glendix intentionally does not synthesize or programmatically click a
//// hidden anchor.
////
//// File selection uses Plinth's File System Access API bindings. Browsers
//// without `showOpenFilePicker` return `PickerUnsupported`; Glendix does not
//// emulate the capability with a hidden input. Applications that need a
//// fallback can render a visible file input with [`accepted_types`](#accepted_types)
//// and handle that input in their UI layer.
////
//// Application document parsing, persistence, extension policy, and filename
//// normalization remain outside this module.
////

import gleam/dynamic
import gleam/dynamic/decode
import gleam/javascript/array
import gleam/javascript/promise
import gleam/list
import gleam/string
import gossamer/blob
import plinth/browser/file as browser_file
import plinth/browser/file_system

/// Represents a declarative browser download and its object-URL resource.
pub opaque type Download {
  Download(filename: String, mime_type: String, url: String)
}

/// Represents invalid metadata supplied while creating a download.
pub type DownloadError {
  /// The suggested filename is empty after surrounding whitespace is removed.
  DownloadFilenameWasEmpty
  /// The MIME type is empty or does not contain a concrete `type/subtype`.
  DownloadMimeTypeWasInvalid(mime_type: String)
}

/// Represents availability of the modern browser file picker.
pub type PickerCapability {
  /// `showOpenFilePicker` is callable in the current browser.
  ModernPickerAvailable
  /// The current runtime does not expose `showOpenFilePicker`.
  ModernPickerUnavailable
}

/// Configures metadata validation for a selected browser file.
pub opaque type Picker {
  Picker(accepted_types: List(String), maximum_size_bytes: Int)
}

/// Represents invalid picker configuration.
pub type PickerConfigurationError {
  /// The maximum permitted file size must be greater than zero.
  MaximumSizeWasNotPositive(maximum_size_bytes: Int)
  /// An accepted type was neither a MIME type/range nor a file extension.
  AcceptedTypeWasInvalid(accepted_type: String)
}

/// Represents a browser-selected file whose bytes passed configured checks.
pub opaque type SelectedFile {
  SelectedFile(
    name: String,
    mime_type: String,
    bytes: BitArray,
    size_bytes: Int,
  )
}

/// Represents a modern file-picker or selected-file failure.
pub type PickerError {
  /// The current runtime does not support the modern file picker.
  PickerUnsupported
  /// The user cancelled selection or the browser returned no selected handle.
  SelectionCancelled
  /// The picker failed for a reason other than user cancellation.
  SelectionFailed(reason: String)
  /// The selected handle could not be opened as a browser file.
  SelectedFileCouldNotBeOpened(name: String, reason: String)
  /// The selected file contains no bytes.
  SelectedFileWasEmpty(name: String)
  /// The selected file is larger than the configured maximum.
  SelectedFileWasTooLarge(
    name: String,
    size_bytes: Int,
    maximum_size_bytes: Int,
  )
  /// The selected file does not match any configured MIME type or extension.
  SelectedFileTypeWasNotAccepted(
    name: String,
    mime_type: String,
    accepted_types: List(String),
  )
  /// The browser rejected reading the selected file's bytes.
  SelectedFileCouldNotBeRead(name: String, reason: String)
}

/// Creates a MIME-typed Blob and object URL for a declarative download link.
///
/// The filename is preserved exactly. Glendix only rejects an empty filename;
/// application-specific normalization and extension policy remain the caller's
/// responsibility. Release the resource with [`release`](#release) when its
/// anchor is removed or replaced.
pub fn download(
  from bytes: BitArray,
  named filename: String,
  with_mime_type mime_type: String,
) -> Result(Download, DownloadError) {
  case string.trim(filename), valid_download_mime_type(mime_type) {
    "", _ -> Error(DownloadFilenameWasEmpty)
    _, False -> Error(DownloadMimeTypeWasInvalid(mime_type:))
    _, True -> {
      let url =
        blob.from_bytes(bytes, content_type: mime_type)
        |> blob.to_object_url
      Ok(Download(filename:, mime_type:, url:))
    }
  }
}

/// Returns the filename to use on a declarative anchor's `download` attribute.
pub fn download_filename(resource resource: Download) -> String {
  resource.filename
}

/// Returns the validated MIME type associated with the download.
pub fn download_mime_type(resource resource: Download) -> String {
  resource.mime_type
}

/// Returns the object URL to use on a declarative anchor's `href` attribute.
pub fn download_url(resource resource: Download) -> String {
  resource.url
}

/// Revokes a download's object URL.
///
/// The underlying Gossamer operation follows `URL.revokeObjectURL`: releasing
/// the same resource more than once is a safe no-op at the browser boundary.
pub fn release(resource resource: Download) -> Nil {
  blob.revoke_object_url(resource.url)
}

/// Creates picker validation configuration.
///
/// Accepted values may be exact MIME types (`application/json`), MIME wildcards
/// (`image/*`), or dot-prefixed extensions (`.ic`). An empty list accepts any
/// type. Duplicate values are removed while preserving first-seen order.
pub fn picker(
  accepting accepted_types: List(String),
  maximum_size_bytes maximum_size_bytes: Int,
) -> Result(Picker, PickerConfigurationError) {
  case maximum_size_bytes > 0 {
    False -> Error(MaximumSizeWasNotPositive(maximum_size_bytes:))
    True ->
      case first_invalid_accepted_type(accepted_types) {
        Ok(Nil) ->
          Ok(Picker(
            accepted_types: deduplicate_accepted_types(accepted_types),
            maximum_size_bytes:,
          ))
        Error(accepted_type) -> Error(AcceptedTypeWasInvalid(accepted_type:))
      }
  }
}

/// Returns accepted MIME types/extensions in stable first-seen order.
///
/// The result can be passed to Lustre or Redraw's `accept` attribute for a
/// visible declarative fallback input.
pub fn accepted_types(configuration configuration: Picker) -> List(String) {
  configuration.accepted_types
}

/// Reports whether the modern picker is available in the current runtime.
pub fn picker_capability() -> PickerCapability {
  case modern_picker_is_available_raw() {
    True -> ModernPickerAvailable
    False -> ModernPickerUnavailable
  }
}

/// Opens the modern picker and reads one validated file.
///
/// Plinth's current API does not expose picker options and the browser call is
/// single-select by default. If a browser nevertheless returns multiple
/// handles, the first handle in browser order is used.
pub fn pick(
  using configuration: Picker,
) -> promise.Promise(Result(SelectedFile, PickerError)) {
  case picker_capability() {
    ModernPickerUnavailable -> promise.resolve(Error(PickerUnsupported))
    ModernPickerAvailable ->
      file_system.show_open_file_picker()
      |> promise.await(fn(selection) {
        case selection {
          Error(reason) ->
            promise.resolve(Error(classify_selection_error(reason)))
          Ok(handles) ->
            case array.get(handles, 0) {
              Error(Nil) -> promise.resolve(Error(SelectionCancelled))
              Ok(handle) -> open_selected_file(configuration, handle)
            }
        }
      })
  }
}

/// Returns the selected browser filename.
pub fn selected_name(file file: SelectedFile) -> String {
  file.name
}

/// Returns the selected browser MIME type, which may be empty.
pub fn selected_mime_type(file file: SelectedFile) -> String {
  file.mime_type
}

/// Returns the selected file bytes.
pub fn selected_bytes(file file: SelectedFile) -> BitArray {
  file.bytes
}

/// Returns the selected file size in bytes.
pub fn selected_size_bytes(file file: SelectedFile) -> Int {
  file.size_bytes
}

fn open_selected_file(
  configuration: Picker,
  handle: file_system.FileHandle,
) -> promise.Promise(Result(SelectedFile, PickerError)) {
  let name = file_system.name(handle)
  file_system.get_file(handle)
  |> promise.await(fn(opened) {
    case opened {
      Error(reason) ->
        promise.resolve(Error(SelectedFileCouldNotBeOpened(name:, reason:)))
      Ok(file) -> validate_and_read(configuration, file)
    }
  })
}

fn validate_and_read(
  configuration: Picker,
  file: browser_file.File,
) -> promise.Promise(Result(SelectedFile, PickerError)) {
  let name = browser_file.name(file)
  let mime_type = browser_file.mime(file)
  let size_bytes = browser_file.size(file)
  case size_bytes {
    0 -> promise.resolve(Error(SelectedFileWasEmpty(name:)))
    size if size > configuration.maximum_size_bytes ->
      promise.resolve(
        Error(SelectedFileWasTooLarge(
          name:,
          size_bytes: size,
          maximum_size_bytes: configuration.maximum_size_bytes,
        )),
      )
    _ ->
      case
        selected_type_is_accepted(name, mime_type, configuration.accepted_types)
      {
        False ->
          promise.resolve(
            Error(SelectedFileTypeWasNotAccepted(
              name:,
              mime_type:,
              accepted_types: configuration.accepted_types,
            )),
          )
        True -> read_selected_file(file, name, mime_type, size_bytes)
      }
  }
}

fn read_selected_file(
  file: browser_file.File,
  name: String,
  mime_type: String,
  size_bytes: Int,
) -> promise.Promise(Result(SelectedFile, PickerError)) {
  file
  |> browser_file.bytes
  |> promise.map(fn(bytes) {
    Ok(SelectedFile(name:, mime_type:, bytes:, size_bytes:))
  })
  |> promise.rescue(fn(rejection) {
    Error(SelectedFileCouldNotBeRead(name:, reason: rejection_reason(rejection)))
  })
}

fn classify_selection_error(reason: String) -> PickerError {
  let normalized = string.lowercase(reason)
  case
    string.contains(normalized, "aborterror")
    || string.contains(normalized, "cancelled")
    || string.contains(normalized, "canceled")
    || string.contains(normalized, "aborted")
  {
    True -> SelectionCancelled
    False -> SelectionFailed(reason:)
  }
}

fn rejection_reason(rejection: dynamic.Dynamic) -> String {
  case decode.run(rejection, decode.at(["message"], decode.string)) {
    Ok(message) ->
      case string.trim(message) {
        "" -> "The browser rejected reading the selected file"
        _ -> message
      }
    Error(_) ->
      case decode.run(rejection, decode.string) {
        Ok(message) ->
          case string.trim(message) {
            "" -> "The browser rejected reading the selected file"
            _ -> message
          }
        Error(_) -> "The browser rejected reading the selected file"
      }
  }
}

fn first_invalid_accepted_type(
  accepted_types: List(String),
) -> Result(Nil, String) {
  case accepted_types {
    [] -> Ok(Nil)
    [accepted_type, ..rest] ->
      case valid_accepted_type(accepted_type) {
        True -> first_invalid_accepted_type(rest)
        False -> Error(accepted_type)
      }
  }
}

fn deduplicate_accepted_types(accepted_types: List(String)) -> List(String) {
  deduplicate_accepted_types_loop(accepted_types, [], [])
}

fn deduplicate_accepted_types_loop(
  accepted_types: List(String),
  normalized_seen: List(String),
  accumulated: List(String),
) -> List(String) {
  case accepted_types {
    [] -> list.reverse(accumulated)
    [accepted_type, ..rest] -> {
      let normalized = string.lowercase(accepted_type)
      case list.contains(normalized_seen, normalized) {
        True ->
          deduplicate_accepted_types_loop(rest, normalized_seen, accumulated)
        False ->
          deduplicate_accepted_types_loop(
            rest,
            [normalized, ..normalized_seen],
            [accepted_type, ..accumulated],
          )
      }
    }
  }
}

fn valid_accepted_type(accepted_type: String) -> Bool {
  case string.trim(accepted_type) == accepted_type {
    False -> False
    True ->
      case string.starts_with(accepted_type, ".") {
        True ->
          string.length(accepted_type) > 1
          && !string.contains(accepted_type, " ")
          && !string.contains(accepted_type, "/")
          && !string.contains(accepted_type, "\\")
        False -> valid_media_range(accepted_type)
      }
  }
}

fn valid_download_mime_type(mime_type: String) -> Bool {
  let base_type = case string.split_once(mime_type, on: ";") {
    Ok(#(base_type, _parameters)) -> string.trim(base_type)
    Error(Nil) -> string.trim(mime_type)
  }
  valid_media_range(base_type) && !string.ends_with(base_type, "/*")
}

fn valid_media_range(media_range: String) -> Bool {
  case string.split_once(media_range, on: "/") {
    Error(Nil) -> False
    Ok(#(type_, subtype)) ->
      type_ != ""
      && type_ != "*"
      && subtype != ""
      && !string.contains(type_, " ")
      && !string.contains(subtype, " ")
      && !string.contains(subtype, "/")
  }
}

fn selected_type_is_accepted(
  name: String,
  mime_type: String,
  accepted_types: List(String),
) -> Bool {
  case accepted_types {
    [] -> True
    _ -> {
      let normalized_name = string.lowercase(name)
      let normalized_mime_type = string.lowercase(mime_type)
      list.any(accepted_types, fn(accepted_type) {
        let normalized = string.lowercase(accepted_type)
        case string.starts_with(normalized, ".") {
          True -> string.ends_with(normalized_name, normalized)
          False ->
            case string.ends_with(normalized, "/*") {
              True ->
                case string.split_once(normalized, on: "/") {
                  Ok(#(type_, "*")) ->
                    string.starts_with(normalized_mime_type, type_ <> "/")
                  _ -> False
                }
              False -> normalized_mime_type == normalized
            }
        }
      })
    }
  }
}

// -- FFI --
@external(javascript, "./file_ffi.mjs", "modern_picker_is_available")
fn modern_picker_is_available_raw() -> Bool
