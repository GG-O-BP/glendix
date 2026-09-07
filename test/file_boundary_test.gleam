//// Exercises the widget-definition filesystem boundary on JavaScript.
////

import gleam/json
import gleam/list
import gleeunit/should
import glendix/define/file_boundary
import simplifile

/// Verifies a missing package manifest is reported as a read failure.
pub fn missing_package_json_contract_test() -> Nil {
  in_temporary_directory(fn(_directory) {
    case file_boundary.find_widget_xml() {
      Error(file_boundary.FileCouldNotBeRead(path, reason)) -> {
        path
        |> should.equal("package.json")
        reason
        |> should.equal("No such file or directory")
      }
      Ok(_) -> should.fail()
      Error(_) -> should.fail()
    }
  })
}

/// Verifies an absent widgetName is reported with the public domain error.
pub fn missing_widget_name_contract_test() -> Nil {
  in_temporary_directory(fn(_directory) {
    write_package_json("{}")
    file_boundary.find_widget_xml()
    |> should.equal(
      Error(file_boundary.WidgetNameWasNotDeclared(path: "package.json")),
    )
  })
}

/// Verifies empty and whitespace-only widget names remain undeclared.
pub fn empty_widget_name_contract_test() -> Nil {
  ["", "   \n\t"]
  |> list.each(fn(name) {
    in_temporary_directory(fn(_directory) {
      write_widget_package(name)
      file_boundary.find_widget_xml()
      |> should.equal(
        Error(file_boundary.WidgetNameWasNotDeclared(path: "package.json")),
      )
    })
  })
}

/// Verifies null and non-string widget names remain undeclared.
pub fn non_string_widget_name_contract_test() -> Nil {
  [
    "{\"widgetName\": null}",
    "{\"widgetName\": 42}",
    "{\"widgetName\": false}",
  ]
  |> list.each(fn(package_json) {
    in_temporary_directory(fn(_directory) {
      write_package_json(package_json)
      file_boundary.find_widget_xml()
      |> should.equal(
        Error(file_boundary.WidgetNameWasNotDeclared(path: "package.json")),
      )
    })
  })
}

/// Verifies malformed JSON produces a deterministic package read reason.
pub fn malformed_package_json_contract_test() -> Nil {
  in_temporary_directory(fn(_directory) {
    write_package_json("{")
    file_boundary.find_widget_xml()
    |> should.equal(
      Error(file_boundary.FileCouldNotBeRead(
        path: "package.json",
        reason: "JSON ended unexpectedly",
      )),
    )
  })
}

/// Verifies non-object package values cannot declare a widget name.
pub fn non_object_package_json_contract_test() -> Nil {
  ["null", "[]", "42", "\"text\""]
  |> list.each(fn(package_json) {
    in_temporary_directory(fn(_directory) {
      write_package_json(package_json)
      file_boundary.find_widget_xml()
      |> should.equal(
        Error(file_boundary.WidgetNameWasNotDeclared(path: "package.json")),
      )
    })
  })
}

/// Verifies a missing declared XML path preserves the computed path.
pub fn missing_widget_xml_contract_test() -> Nil {
  in_temporary_directory(fn(_directory) {
    write_widget_package("Example")
    simplifile.create_directory("src")
    |> should.be_ok
    file_boundary.find_widget_xml()
    |> should.equal(
      Error(file_boundary.WidgetXmlWasNotFound(path: "src/Example.xml")),
    )
  })
}

/// Verifies a directory at the XML path is not accepted as a widget file.
pub fn widget_xml_directory_contract_test() -> Nil {
  in_temporary_directory(fn(_directory) {
    write_widget_package("Example")
    simplifile.create_directory("src")
    |> should.be_ok
    simplifile.create_directory("src/Example.xml")
    |> should.be_ok
    file_boundary.find_widget_xml()
    |> should.equal(
      Error(file_boundary.WidgetXmlWasNotFound(path: "src/Example.xml")),
    )
  })
}

/// Verifies XML existence-check errors retain the computed path and reason.
pub fn widget_xml_check_failure_contract_test() -> Nil {
  in_temporary_directory(fn(_directory) {
    write_widget_package("Example")
    simplifile.write("src", "not a directory")
    |> should.be_ok
    file_boundary.find_widget_xml()
    |> should.equal(
      Error(file_boundary.FileCouldNotBeRead(
        path: "src/Example.xml",
        reason: "Not a directory",
      )),
    )
  })
}

/// Verifies a declared widget XML file is found at the existing relative path.
pub fn find_widget_xml_success_contract_test() -> Nil {
  in_temporary_directory(fn(_directory) {
    write_widget_package("Example")
    simplifile.create_directory("src")
    |> should.be_ok
    simplifile.write("src/Example.xml", "<widget />")
    |> should.be_ok
    file_boundary.find_widget_xml()
    |> should.equal(Ok("src/Example.xml"))
  })
}

/// Verifies the public write and read functions preserve UTF-8 contents.
pub fn file_round_trip_contract_test() -> Nil {
  in_temporary_directory(fn(_directory) {
    let content = "<widget>한글</widget>\n"
    file_boundary.write("widget.xml", content)
    |> should.be_ok
    file_boundary.read("widget.xml")
    |> should.equal(Ok(content))
  })
}

/// Verifies invalid UTF-8 is mapped through simplifile's stable reason.
pub fn invalid_utf8_read_contract_test() -> Nil {
  in_temporary_directory(fn(_directory) {
    write_invalid_utf8("widget.xml")
    case file_boundary.read("widget.xml") {
      Error(file_boundary.FileCouldNotBeRead(path, reason)) -> {
        path
        |> should.equal("widget.xml")
        reason
        |> should.equal("File not UTF-8 encoded")
      }
      Ok(_) -> should.fail()
      Error(_) -> should.fail()
    }
  })
}

fn write_widget_package(widget_name: String) -> Nil {
  json.object([#("widgetName", json.string(widget_name))])
  |> json.to_string
  |> write_package_json
}

fn write_package_json(contents: String) -> Nil {
  simplifile.write("package.json", contents)
  |> should.be_ok
}

// -- FFI --
@external(javascript, "./file_boundary_test_ffi.mjs", "in_temporary_directory")
fn in_temporary_directory(action: fn(String) -> value) -> value

@external(javascript, "./file_boundary_test_ffi.mjs", "write_invalid_utf8")
fn write_invalid_utf8(path: String) -> Nil
