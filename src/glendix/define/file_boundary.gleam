//// Provides typed filesystem operations for the widget definition editor.
////

import gleam/result

/// Describes a widget definition filesystem failure.
pub type FileError {
  /// The current package does not declare a widget name.
  WidgetNameWasNotDeclared(path: String)
  /// The expected widget XML file does not exist.
  WidgetXmlWasNotFound(path: String)
  /// A file could not be read.
  FileCouldNotBeRead(path: String, reason: String)
  /// A file could not be written.
  FileCouldNotBeWritten(path: String, reason: String)
}

/// Finds the widget XML path declared by the current package.
pub fn find_widget_xml() -> Result(String, FileError) {
  find_widget_xml_raw()
  |> result.map_error(map_raw_error)
}

/// Reads a UTF-8 text file.
pub fn read(path path: String) -> Result(String, FileError) {
  read_raw(path)
  |> result.map_error(map_raw_error)
}

/// Writes a UTF-8 text file.
pub fn write(
  path path: String,
  content content: String,
) -> Result(Nil, FileError) {
  write_raw(path, content)
  |> result.map_error(map_raw_error)
}

type RawFileError

fn map_raw_error(error: RawFileError) -> FileError {
  case raw_file_error_kind(error) {
    1 -> WidgetNameWasNotDeclared(path: raw_file_error_path(error))
    2 -> WidgetXmlWasNotFound(path: raw_file_error_path(error))
    3 ->
      FileCouldNotBeRead(
        path: raw_file_error_path(error),
        reason: raw_file_error_reason(error),
      )
    4 ->
      FileCouldNotBeWritten(
        path: raw_file_error_path(error),
        reason: raw_file_error_reason(error),
      )
    _ ->
      FileCouldNotBeRead(
        path: raw_file_error_path(error),
        reason: raw_file_error_reason(error),
      )
  }
}

// -- FFI --
@external(javascript, "./file_boundary_ffi.mjs", "find_widget_xml")
fn find_widget_xml_raw() -> Result(String, RawFileError)

@external(javascript, "./file_boundary_ffi.mjs", "read_file")
fn read_raw(path path: String) -> Result(String, RawFileError)

@external(javascript, "./file_boundary_ffi.mjs", "write_file")
fn write_raw(
  path path: String,
  content content: String,
) -> Result(Nil, RawFileError)

@external(javascript, "./file_boundary_ffi.mjs", "file_error_kind")
fn raw_file_error_kind(error: RawFileError) -> Int

@external(javascript, "./file_boundary_ffi.mjs", "file_error_path")
fn raw_file_error_path(error: RawFileError) -> String

@external(javascript, "./file_boundary_ffi.mjs", "file_error_reason")
fn raw_file_error_reason(error: RawFileError) -> String
