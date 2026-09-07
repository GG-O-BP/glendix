//// Exercises browser file capability validation and ecosystem boundaries.
////

import gleam/bit_array
import gleam/javascript/promise
import gleam/string
import gleeunit/should
import glendix/js/file

/// Verifies download metadata validation rejects empty filenames and MIME types.
pub fn download_invalid_metadata_test() -> Nil {
  file.download(
    from: bit_array.from_string("data"),
    named: " ",
    with_mime_type: "application/octet-stream",
  )
  |> should.equal(Error(file.DownloadFilenameWasEmpty))

  file.download(
    from: bit_array.from_string("data"),
    named: "data.bin",
    with_mime_type: "",
  )
  |> should.equal(Error(file.DownloadMimeTypeWasInvalid(mime_type: "")))

  file.download(
    from: bit_array.from_string("data"),
    named: "data.bin",
    with_mime_type: "application",
  )
  |> should.equal(
    Error(file.DownloadMimeTypeWasInvalid(mime_type: "application")),
  )
}

/// Verifies Gossamer owns object-URL creation and repeated cleanup is safe.
pub fn download_resource_lifetime_test() -> Nil {
  observe_object_url_lifetime(fn() {
    case
      file.download(
        from: bit_array.from_string("data"),
        named: "report.ic",
        with_mime_type: "application/octet-stream; charset=binary",
      )
    {
      Error(_) -> {
        should.fail()
        ""
      }
      Ok(resource) -> {
        file.download_filename(resource)
        |> should.equal("report.ic")
        file.download_mime_type(resource)
        |> should.equal("application/octet-stream; charset=binary")
        let url = file.download_url(resource)
        file.release(resource)
        file.release(resource)
        url
      }
    }
  })
  |> should.equal(#("blob:glendix-test-1", 1, 2))
}

/// Verifies picker validation and stable first-seen de-duplication.
pub fn picker_configuration_validation_test() -> Nil {
  file.picker(accepting: [], maximum_size_bytes: 0)
  |> should.equal(Error(file.MaximumSizeWasNotPositive(maximum_size_bytes: 0)))
  file.picker(accepting: ["json"], maximum_size_bytes: 10)
  |> should.equal(Error(file.AcceptedTypeWasInvalid(accepted_type: "json")))
  case
    file.picker(
      accepting: [
        "application/json",
        ".ic",
        "application/json",
        "image/*",
        ".IC",
      ],
      maximum_size_bytes: 10,
    )
  {
    Error(_) -> should.fail()
    Ok(configuration) ->
      file.accepted_types(configuration)
      |> should.equal(["application/json", ".ic", "image/*"])
  }
}

/// Verifies unsupported runtimes fail before Plinth attempts picker selection.
pub fn picker_unsupported_test() -> promise.Promise(Nil) {
  install_picker_scenario("unsupported")
  file.picker_capability()
  |> should.equal(file.ModernPickerUnavailable)
  case file.picker(accepting: [], maximum_size_bytes: 10) {
    Error(_) -> promise.resolve(should.fail())
    Ok(configuration) ->
      file.pick(using: configuration)
      |> promise.map(fn(result) {
        result
        |> should.equal(Error(file.PickerUnsupported))
        picker_invocation_count()
        |> should.equal(0)
      })
  }
}

/// Verifies AbortError and an empty handle list both report cancellation.
pub fn picker_cancellation_test() -> promise.Promise(Nil) {
  case file.picker(accepting: [], maximum_size_bytes: 10) {
    Error(_) -> promise.resolve(should.fail())
    Ok(configuration) -> {
      install_picker_scenario("cancel")
      file.pick(using: configuration)
      |> promise.await(fn(cancelled) {
        cancelled
        |> should.equal(Error(file.SelectionCancelled))
        install_picker_scenario("no_handles")
        file.pick(using: configuration)
      })
      |> promise.map(fn(no_handles) {
        no_handles
        |> should.equal(Error(file.SelectionCancelled))
      })
    }
  }
}

/// Verifies non-cancellation picker failures preserve their browser reason.
pub fn picker_selection_failure_test() -> promise.Promise(Nil) {
  install_picker_scenario("selection_failure")
  case file.picker(accepting: [], maximum_size_bytes: 10) {
    Error(_) -> promise.resolve(should.fail())
    Ok(configuration) ->
      file.pick(using: configuration)
      |> promise.map(fn(result) {
        case result {
          Error(file.SelectionFailed(reason)) ->
            reason
            |> string.contains("permission denied")
            |> should.be_true
          _ -> should.fail()
        }
      })
  }
}

/// Verifies a handle-open failure preserves the handle name and reason.
pub fn picker_open_failure_test() -> promise.Promise(Nil) {
  install_picker_scenario("open_failure")
  case file.picker(accepting: [], maximum_size_bytes: 10) {
    Error(_) -> promise.resolve(should.fail())
    Ok(configuration) ->
      file.pick(using: configuration)
      |> promise.map(fn(result) {
        case result {
          Error(file.SelectedFileCouldNotBeOpened(name, reason)) -> {
            name
            |> should.equal("broken.ic")
            reason
            |> string.contains("open failed")
            |> should.be_true
          }
          _ -> should.fail()
        }
      })
  }
}

/// Verifies empty files fail before a byte read is attempted.
pub fn picker_empty_file_test() -> promise.Promise(Nil) {
  install_picker_scenario("empty")
  case file.picker(accepting: [], maximum_size_bytes: 10) {
    Error(_) -> promise.resolve(should.fail())
    Ok(configuration) ->
      file.pick(using: configuration)
      |> promise.map(fn(result) {
        result
        |> should.equal(Error(file.SelectedFileWasEmpty(name: "empty.ic")))
        picker_read_count()
        |> should.equal(0)
      })
  }
}

/// Verifies a file exactly at the maximum is accepted and read once.
pub fn picker_exact_maximum_success_test() -> promise.Promise(Nil) {
  install_picker_scenario("exact")
  case file.picker(accepting: [".IC"], maximum_size_bytes: 4) {
    Error(_) -> promise.resolve(should.fail())
    Ok(configuration) ->
      file.pick(using: configuration)
      |> promise.map(fn(result) {
        case result {
          Error(_) -> should.fail()
          Ok(selected) -> {
            file.selected_name(selected)
            |> should.equal("workbook.ic")
            file.selected_mime_type(selected)
            |> should.equal("application/octet-stream")
            file.selected_size_bytes(selected)
            |> should.equal(4)
            file.selected_bytes(selected)
            |> bit_array.to_string
            |> should.equal(Ok("data"))
            picker_read_count()
            |> should.equal(1)
          }
        }
      })
  }
}

/// Verifies overflow fails from metadata without reading file contents.
pub fn picker_maximum_overflow_test() -> promise.Promise(Nil) {
  install_picker_scenario("overflow")
  case file.picker(accepting: [], maximum_size_bytes: 4) {
    Error(_) -> promise.resolve(should.fail())
    Ok(configuration) ->
      file.pick(using: configuration)
      |> promise.map(fn(result) {
        result
        |> should.equal(
          Error(file.SelectedFileWasTooLarge(
            name: "large.ic",
            size_bytes: 5,
            maximum_size_bytes: 4,
          )),
        )
        picker_read_count()
        |> should.equal(0)
      })
  }
}

/// Verifies MIME mismatch fails before reading and wildcard matching succeeds.
pub fn picker_type_validation_test() -> promise.Promise(Nil) {
  install_picker_scenario("image")
  case file.picker(accepting: ["application/json"], maximum_size_bytes: 10) {
    Error(_) -> promise.resolve(should.fail())
    Ok(rejecting_configuration) ->
      file.pick(using: rejecting_configuration)
      |> promise.await(fn(rejected) {
        rejected
        |> should.equal(
          Error(
            file.SelectedFileTypeWasNotAccepted(
              name: "pixel.png",
              mime_type: "image/png",
              accepted_types: ["application/json"],
            ),
          ),
        )
        picker_read_count()
        |> should.equal(0)
        install_picker_scenario("image")
        case file.picker(accepting: ["image/*"], maximum_size_bytes: 10) {
          Error(_) -> {
            should.fail()
            promise.resolve(rejected)
          }
          Ok(accepting_configuration) ->
            file.pick(using: accepting_configuration)
        }
      })
      |> promise.map(fn(accepted) {
        case accepted {
          Ok(selected) ->
            file.selected_name(selected)
            |> should.equal("pixel.png")
          Error(_) -> should.fail()
        }
      })
  }
}

/// Verifies byte-read rejection becomes a descriptive typed error.
pub fn picker_read_failure_test() -> promise.Promise(Nil) {
  install_picker_scenario("read_failure")
  case file.picker(accepting: [], maximum_size_bytes: 10) {
    Error(_) -> promise.resolve(should.fail())
    Ok(configuration) ->
      file.pick(using: configuration)
      |> promise.map(fn(result) {
        result
        |> should.equal(
          Error(file.SelectedFileCouldNotBeRead(
            name: "unreadable.ic",
            reason: "read failed",
          )),
        )
        picker_read_count()
        |> should.equal(1)
      })
  }
}

/// Verifies the first handle is selected when a browser returns several.
pub fn picker_first_handle_order_test() -> promise.Promise(Nil) {
  install_picker_scenario("multiple")
  case file.picker(accepting: [], maximum_size_bytes: 10) {
    Error(_) -> promise.resolve(should.fail())
    Ok(configuration) ->
      file.pick(using: configuration)
      |> promise.map(fn(result) {
        case result {
          Ok(selected) ->
            file.selected_name(selected)
            |> should.equal("first.ic")
          Error(_) -> should.fail()
        }
      })
  }
}

// -- FFI --
@external(javascript, "./file_test_ffi.mjs", "observe_object_url_lifetime")
fn observe_object_url_lifetime(callback: fn() -> String) -> #(String, Int, Int)

@external(javascript, "./file_test_ffi.mjs", "install_picker_scenario")
fn install_picker_scenario(scenario: String) -> Nil

@external(javascript, "./file_test_ffi.mjs", "picker_invocation_count")
fn picker_invocation_count() -> Int

@external(javascript, "./file_test_ffi.mjs", "picker_read_count")
fn picker_read_count() -> Int
