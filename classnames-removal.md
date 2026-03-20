# classnames npm dependency removal

## Current state

The sample project's `package.json` includes `classnames` (^2.5.1) as a dependency, but it is not used in glendix itself. The `classnames` API is trivially replaceable with a Gleam utility function.

## classnames API surface

```js
classNames('foo', 'bar');                 // "foo bar"
classNames('foo', { bar: true });         // "foo bar"
classNames({ foo: true }, { bar: false }); // "foo"
classNames('foo', { bar: true, baz: false }, 'qux'); // "foo bar qux"
```

Only the conditional class joining pattern (`{ className: bool }`) is practically used in widget development. Static class names are just string concatenation.

## Proposed Gleam replacement

Add a `cx` utility to `glendix/mendix` (or a shared util module):

```gleam
import gleam/list
import gleam/string

/// Conditionally join CSS class names.
///
/// ```gleam
/// cx([#("btn", True), #("btn-primary", is_primary), #("disabled", !enabled)])
/// // => "btn btn-primary"
/// ```
pub fn cx(classes: List(#(String, Bool))) -> String {
  classes
  |> list.filter_map(fn(pair) {
    case pair.1 {
      True -> Ok(pair.0)
      False -> Error(Nil)
    }
  })
  |> string.join(" ")
}
```

Usage with `redraw/dom/attribute`:

```gleam
import redraw/dom/attribute
import glendix/mendix  // or wherever cx lives

html.div(
  [attribute.class(mendix.cx([
    #("widget-container", True),
    #("active", is_active),
    #("error", has_error),
  ]))],
  [..children],
)
```

## Migration steps

1. Add `cx` function to glendix (e.g., `src/glendix/mendix.gleam` or a new `src/glendix/util.gleam`)
2. Update `glendix_guide.md` with the `cx` pattern
3. Remove `classnames` from sample project `package.json`
4. Update any documentation referencing `classnames`

## Considerations

- No FFI or `.mjs` file needed — pure Gleam
- Zero runtime dependency added
- API is intentionally simpler than classnames (no nested objects, no arrays) — the tuple-based `#(String, Bool)` pattern covers all real-world Mendix widget use cases
- For static class names, plain string concatenation or `string.join` is sufficient
