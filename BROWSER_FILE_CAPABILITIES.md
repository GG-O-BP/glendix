# Browser file capability contract

Assessment date: 2026-09-07

Glendix exposes generic browser file operations through `glendix/js/file`.
Document parsing, persistence, filename normalization, and application-specific
extension rules remain application responsibilities.

## Capability matrix

| Responsibility | Implementation | Residual Glendix FFI |
| --- | --- | --- |
| Build a MIME-typed Blob from `BitArray` | `gossamer/blob.from_bytes` | None |
| Create and revoke an object URL | `gossamer/blob.to_object_url` and `revoke_object_url` | None |
| Render a download link | Lustre or Redraw `href` and `download` attributes | None; no hidden anchor or programmatic click |
| Detect the modern picker | `glendix/js/file.picker_capability` | One predicate in `file_ffi.mjs`, because Plinth 0.11.0 has no capability query |
| Open the modern picker | `plinth/browser/file_system.show_open_file_picker` | None |
| Open the selected handle | `plinth/browser/file_system.get_file` | None |
| Read name, MIME type, size, and bytes | `plinth/browser/file` | None |
| Convert a rejected byte read to a domain error | `gleam/javascript/promise.rescue` plus typed dynamic decoding | None |
| Legacy fallback picker | Visible Lustre/Redraw `<input type="file">` owned by the application | No imperative hidden-input adapter |

The capability predicate is the only production JavaScript added for this
feature. It does not perform selection or file access. Its retention rationale
and contract belong in the retained-FFI inventory tracked by issue #21.

## Download contract

`file.download`:

- rejects a filename that is empty after trimming;
- rejects an empty or malformed concrete MIME type;
- preserves every non-empty filename exactly, without sanitizing it;
- creates the Blob and object URL through Gossamer;
- exposes URL, filename, and MIME accessors for a declarative anchor.

Call `file.release` when the anchor is replaced or its component is disposed.
Repeated release is safe because Gossamer follows `URL.revokeObjectURL`
semantics.

```gleam
import gleam/bit_array
import gleam/result
import glendix/js/file
import lustre/attribute
import lustre/element
import lustre/element/html

pub fn download_link() -> Result(element.Element(message), file.DownloadError) {
  use resource <- result.try(file.download(
    from: bit_array.from_string("workbook bytes"),
    named: "workbook.ic",
    with_mime_type: "application/octet-stream",
  ))

  Ok(html.a(
    [
      attribute.href(file.download_url(resource)),
      attribute.download(file.download_filename(resource)),
    ],
    [html.text("Download")],
  ))
}
```

The component that stores `resource` must call `file.release(resource)` in its
disposal path. Redraw uses its equivalent `href` and `download` attributes.

## Picker contract

`file.picker` requires a positive maximum byte size. Accepted values can be:

- exact MIME types such as `application/json`;
- MIME wildcards such as `image/*`;
- dot-prefixed extensions such as `.ic`;
- an empty list, meaning any type.

Duplicates are removed in first-seen order. The stable list is available
through `file.accepted_types` for a visible fallback input's `accept`
attribute.

`file.pick` uses one file. Plinth 0.11.0 does not expose picker options, and the
browser call is single-select by default; if a browser returns several handles,
Glendix uses the first handle in browser order.

Validation occurs before reading bytes:

1. a zero-byte file returns `SelectedFileWasEmpty`;
2. a file larger than the maximum returns `SelectedFileWasTooLarge`;
3. a non-matching MIME type/extension returns
   `SelectedFileTypeWasNotAccepted`;
4. only a file that passes metadata checks is read.

A file exactly equal to the maximum is accepted. Picker cancellation and an
empty handle list return `SelectionCancelled`. Unsupported browsers return
`PickerUnsupported` without attempting the Plinth picker call. Other picker,
handle-open, and byte-read errors preserve their operation and reason.

## Fallback policy

Glendix does not claim a package-only cross-browser imperative picker.
Applications that support browsers without `showOpenFilePicker` must choose
one of these explicit policies:

1. require the modern picker and display an unsupported-capability message; or
2. render a visible Lustre/Redraw file input and process its event in the
   application UI layer.

Glendix does not create, click, or remove a hidden input, because Plinth 0.11.0
does not fully type `input.files`, programmatic click, one-shot listeners, and
cancellation as one portable operation.
