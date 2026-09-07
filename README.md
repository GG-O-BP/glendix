**English** | [Korean](README.ko.md) | [Japanese](README.ja.md)

# glendix

`glendix` is the JavaScript-target build and rendering bridge for Mendix
Pluggable Widgets written in Gleam.

Its package boundary is explicit:

- **glendix** owns Pluggable Widgets Tools orchestration, widget definition
  editing, external npm React bindings, and the Lustre-to-React bridge;
- **mendraw** owns Mendix client values and bindings generated from installed
  `.mpk` assets;
- **mxpak** owns Marketplace search, package download, cache, lockfiles, and
  workspace deduplication;
- **glendam** owns generic browser automation.

Glendix does not implement Marketplace access or browser automation.

## Install

```toml
[dependencies]
glendix = ">= 6.0.0 and < 7.0.0"
```

Add `mendraw` only when the project uses Mendix client values or installed MPK
components, and add/use `mxpak` only when package acquisition is required.

A widget project's `package.json` normally includes the Mendix Pluggable Widgets
Tools and their React peer dependencies.

## Typed JSON helpers

`glendix/js/json` delegates serialization and parsing to `gleam_json`.
Serialization remains source-compatible:

```gleam
import gleam/json
import glendix/js/json as glendix_json

glendix_json.stringify(value: json.int(42))
```

Starting with Glendix 6, parsing requires a decoder for the expected result
type:

```gleam
import gleam/dynamic/decode
import glendix/js/json as glendix_json

glendix_json.parse(
  from: "{\"name\":\"glendix\"}",
  using: {
    use name <- decode.field("name", decode.string)
    decode.success(name)
  },
)
```

Migrate a pre-6 call from `parse(from: source)` to
`parse(from: source, using: decoder)`. Invalid JSON returns `InvalidSyntax`,
while valid JSON that does not match the decoder returns `DecoderMismatch`.
Both error forms are deterministic and do not expose JavaScript-engine exception
messages.

## Experimental native package managers

Glendix can isolate Mendix Pluggable Widgets Tools from the project's package
manager and JavaScript runtime:

```toml
[javascript]
runtime = "bun"

[tools.glendix]
pm = "bun"
compatibility = "experimental-native"
```

| `pm` | Gleam runtime | Dependency install |
| --- | --- | --- |
| `npm` | `node` | `npm install` |
| `yarn` | `node` | `yarn install` |
| `pnpm` | `node` | `pnpm install` |
| `bun` | `bun` | `bun install` |
| `deno` | `deno` | hoisted manual `deno install` with the required lifecycle scripts allowed |

In this mode, Glendix invokes the installed Pluggable Widgets Tools CLI with the
selected runtime and places temporary `node`, `npm`, and `npx` compatibility
shims only on that child process's `PATH`. The shims satisfy the tool's hard
Node/npm checks and route supported install, run, and exec calls back to the
selected package manager. They are removed after the command; no global binary,
lockfile, or package-manager setting is replaced. Interactive npm lockfile
migration is disabled, so the selected manager's lockfile remains authoritative.

This is an explicit experimental compatibility mode, not a complete npm
emulator. npm and Bun projects must allow or trust the lifecycle scripts
required by the Mendix toolchain, Yarn projects must use the `node-modules`
linker, and pnpm projects must allow the same native build scripts. Deno
projects must grant their Gleam commands the required permissions and allow
those scripts during install. Invoke dependency modules with an explicit
matching runtime, for example
`gleam run -m glendix/build --runtime bun` or `--runtime deno`; use
`--runtime node` for npm, Yarn, and pnpm.

## Basic widget

```gleam
import mendraw/mendix
import redraw
import redraw/dom/attribute
import redraw/dom/html

pub fn widget(props: mendix.JsProps) -> redraw.Element {
  let title = mendix.get_string_prop(props, "title")
  html.section([attribute.class("widget")], [html.text(title)])
}
```

This example composes Glendix with Mendraw in the application. Glendix itself
remains independently usable for external React bindings and Lustre rendering.

## Lustre bridge

```gleam
import glendix/lustre as glendix_lustre
import gleam/int
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import redraw

type Model { Model(count: Int) }
type Message { Increment }

fn update(model: Model, message: Message) -> #(Model, effect.Effect(Message)) {
  case message {
    Increment -> #(Model(model.count + 1), effect.none())
  }
}

fn view(model: Model) -> element.Element(Message) {
  html.button([event.on_click(Increment)], [
    html.text("Count: " <> int.to_string(model.count)),
  ])
}

pub fn component() -> redraw.Element {
  glendix_lustre.use_tea(#(Model(0), effect.none()), update, view)
}
```

### Props-driven remounts

Use `keyed_host` when a typed props-derived revision must restart the entire
Lustre application:

```gleam
pub fn component(props: Props) -> redraw.Element {
  glendix_lustre.keyed_host(
    key: props_revision(props),
    props: props,
    render: fn(current_props) {
      glendix_lustre.use_tea(
        init(current_props),
        update,
        view,
      )
    },
  )
}
```

Derive `props_revision` in pure Gleam from the application's typed state. An
unchanged key preserves the existing application while still passing fresh
props to the render callback; a changed key disposes and remounts the hosted
application.

`keyed_host` uses Redraw's React key support but also supplies the component
boundary that owns the Lustre hooks. Calling `redraw.keyed` around an already
evaluated `use_tea` result does not create that boundary.
`lustre/element/keyed` only controls children inside the running Lustre virtual
DOM and cannot remount the outer React host.

## External npm React components

Configure exports in `gleam.toml`:

```toml
[tools.glendix.bindings]
recharts = ["PieChart", "Pie"]
```

Install the npm package, then run `gleam run -m glendix/install`. Glendix owns
both component lookup and element construction; Mendraw is not required:

Glendix parses this configuration as standard TOML. Package-manager,
compatibility, module, and component names must be quoted TOML strings, and
each binding value must be either one string or an array of strings. Malformed
TOML, duplicate keys, and unquoted string-like values are rejected instead of
being partially interpreted. A missing `gleam.toml` or missing Glendix table
still means that no override or bindings are configured.

```gleam
import gleam/result
import glendix/binding
import redraw
import redraw/dom/attribute

pub fn pie_chart(
  attributes attributes: List(attribute.Attribute),
  children children: List(redraw.Element),
) -> Result(redraw.Element, binding.BindingError) {
  use module <- result.try(binding.module("recharts"))
  use component <- result.try(binding.resolve(module, "PieChart"))
  Ok(binding.element(component, attributes, children))
}
```

`binding.element_` creates an element with children only, and
`binding.void_element` creates one without children.

Modules that require asynchronous setup use the extended table form:

```toml
[tools.glendix.bindings."@ironcalc/workbook"]
exports = ["Workbook"]
initializer = "init"
retry = "on-failure"
```

`initializer` names a zero-argument export that must return a Promise. `retry`
is either `"never"` (the default, which caches a failure until explicit reset)
or `"on-failure"` (the next initialization call may start a new attempt after
the failed result has been recorded). `exports` may be omitted for modules used
only through non-React APIs. Legacy string and array values require no
initialization and remain ready immediately.

```gleam
import gleam/javascript/promise
import glendix/binding

pub fn load(
  module module: binding.JsModule,
) -> #(
  binding.ModuleInitialization,
  promise.Promise(Result(Nil, binding.InitializationError)),
) {
  module
  |> binding.initialization
  |> binding.initialize
}
```

Store the returned `ModuleInitialization` in the application model. Concurrent
calls made with its `Initializing` value return the same Promise. When that
Promise completes, pass its result to `binding.settle_initialization`; then
`binding.initialized_module` makes the same ready module available to rendering
and non-React consumers. `binding.initialization_effect` dispatches the result
through Lustre, while `binding.use_initialization` consumes the same attempt in
a React Suspense boundary. `binding.reset_initialization` explicitly clears a
settled failure (or reinitializes a ready configured module).

The installer retains one generated FFI boundary because the package and export
names are read from `gleam.toml` after Glendix itself has compiled; Gleam
`@external` package/export literals must exist before compilation. That boundary
contains deterministic static named imports, metadata lookup, and the direct
initializer call only. Promise creation, one-flight sharing, result mapping,
retry state, and completion dispatch are implemented in Gleam with
`gleam/javascript/promise`. No dynamic `import()` or generated Promise cache is
used, so Rollup can still discover module WebAssembly assets.


## Browser environment and object props

`glendix/js/environment` reads the browser color-scheme preference behind a
typed boundary, so widgets never call `window.matchMedia` from an
application-local FFI. `color_scheme` reports the operating-system preference as
`Light`, `Dark`, or `System`, and `resolved_color_scheme` resolves what applies
as `ResolvedLight`, `ResolvedDark`, or `ResolutionUnavailable` when `matchMedia`
cannot be queried. Dynamic preference-change subscriptions (`MediaQueryList`
`change` events) are intentionally out of scope; re-query during a
props- or revision-driven re-render.

`glendix/js/object` builds a plain JavaScript object from ordered typed entries,
preserving entry order and keeping the last value for a duplicate key. The
object passes to an external React component as one prop through a Redraw
attribute, without any application-local React FFI:

```gleam
import glendix/binding
import glendix/js/environment
import glendix/js/object
import redraw
import redraw/dom/attribute

pub fn themed_component(
  component component: binding.JsComponent,
) -> redraw.Element {
  let theme = case environment.resolved_color_scheme() {
    environment.ResolvedDark -> "dark"
    environment.ResolvedLight -> "light"
    environment.ResolutionUnavailable -> "light"
  }
  let configuration =
    object.from_entries([#("theme", object.string(theme))])
  binding.element(
    component,
    [attribute.attribute("config", object.from_object(configuration))],
    [],
  )
}
```

`glendix/js/object` is deliberately data-only. Dynamic interop — reading,
writing, or deleting arbitrary properties, calling methods, and invoking
constructors — lives in the separate `glendix/js/reflect` module. Reflection is
the unsafe/dynamic boundary where the caller, not the type system, guarantees a
property or method exists. The `__proto__`-as-data guarantee applies to
`object.from_entries`; reflective assignment retains ordinary JavaScript setter
semantics, so never pass untrusted property names to `reflect.set`.

## Browser file downloads and selection

`glendix/js/file` creates declarative download resources through
`gossamer/blob` and reads a modern browser file selection through
`plinth/browser/file_system` and `plinth/browser/file`.

Render downloads as normal Lustre or Redraw anchors with the resource's URL and
filename, then call `file.release` when the anchor is replaced or disposed.
Glendix does not create or click a hidden download anchor.

The picker reports `PickerUnsupported` when `showOpenFilePicker` is unavailable.
Applications that need broader browser support can render a visible file input
using the stable, de-duplicated `file.accepted_types` list; Glendix does not add
an imperative hidden-input fallback. Empty files, maximum-size overflow, type
mismatch, cancellation, handle failures, and read failures have distinct typed
errors. Application parsing and filename policy remain outside Glendix.

See [the browser file capability contract](BROWSER_FILE_CAPABILITIES.md) for
the API examples, validation order, fallback policy, and ecosystem/residual-FFI
matrix.

## WebAssembly dependencies

Glendix automatically packages browser WebAssembly modules referenced with the
standard static URL form used by browser toolchains:

```javascript
new URL("./engine_bg.wasm", import.meta.url)
```

The generated Rollup configuration copies each binary into the widget
`assets/` directory with a deterministic content hash. It rewrites the runtime
URL to the correct Mendix route for both AMD and ES module outputs, so the same
MPK works in classic and modern web clients. Query strings and fragments are
preserved, and repeated references to one binary emit a single asset.

Only static relative `.wasm` references can be packaged automatically. A
missing referenced file fails the build with its module and resolved path.
Projects that replace Glendix's generated `rollup.config.mjs` must compose
equivalent asset handling in their custom configuration.

## Installed Marketplace widgets

Package acquisition is a separate step owned by mxpak:

```toml
[tools.mxpak]
mode = "extract"

[tools.mxpak.widgets.Charts]
version = "3.0.0"
```

```sh
mxp install
gleam run -m mendraw/install
gleam run -m glendix/install
gleam run -m glendix/build
```

- `mxp install` writes package assets to `build/widgets/`.
- `mendraw/install` generates typed MPK bindings.
- `glendix/install` installs JavaScript dependencies and generates Glendix npm
  bindings.
- `glendix/build` creates the production `.mpk`.

Projects that do not use Marketplace widgets omit the first two steps.

## Commands

| Command | Responsibility |
| --- | --- |
| `gleam run -m glendix/install` | Install JS dependencies and generate Glendix npm bindings |
| `gleam run -m glendix/define` | Edit widget property definitions |
| `gleam run -m glendix/dev` | Run the development build/server |
| `gleam run -m glendix/build` | Build a production `.mpk` |
| `gleam run -m glendix/start` | Connect to the configured Mendix test project |
| `gleam run -m glendix/lint` | Run lint checks |
| `gleam run -m glendix/lint_fix` | Apply lint fixes |
| `gleam run -m glendix/release` | Run the release build |

### Command execution boundary

`glendix/cmd.exec` remains a synchronous shell-command API with inherited
stdin, stdout, and stderr. Its generic process execution is implemented with
`shellout`; a small platform adapter selects `/bin/sh -c` on Unix systems and
`ComSpec /d /s /c` on Windows so existing command strings and shell operators
keep their behavior. `plinth/node/child_process` is not used here because its
current API does not provide synchronous completion, exit status, and standard
stream options as a typed result.

The custom command tooling retained in `cmd_ffi.mjs` is intentionally
Glendix-specific: bridge generation and cleanup, the development watcher,
experimental-native runtime setup, Node/npm compatibility shims, and
Rollup/WebAssembly handling. Gleam build commands also retain a narrow filtered
runner because `shellout` cannot separately capture and filter stderr while
preserving the existing inherited-stream behavior.

## Breaking changes in 6.0.0

`glendix/js/array` now delegates its conversions to `gleam/javascript/array`
and no longer ships a handwritten JavaScript adapter. The `from_list` and
`to_list` functions keep their names, labels, and element-order behavior, so the
common `list |> array.from_list |> array.to_list` usage is unchanged. The former
opaque `glendix/js/array.JsArray(element)` type is removed; annotate values with
`gleam/javascript/array.Array(element)` instead.

`glendix/js/object` is now data-only. Its reflection operations moved unchanged
to the new `glendix/js/reflect` module: `get`, `set`, `delete`, `has`,
`call_method`, `call_method_without_arguments`, and `new_instance`, together
with the `JsConstructor` type. Their names, labels, and behavior are preserved,
so migrate a pre-split call such as `object.get(from: handle, key: "x")` to
`reflect.get(from: handle, key: "x")` (add `import glendix/js/reflect`). Data
construction (`from_entries`, `empty`, `string`, `int`, `float`, `bool`,
`from_object`) stays in `glendix/js/object`, and `from_entries` keeps its
prototype-pollution-safe `Object.fromEntries` behavior for keys such as
`__proto__`.

## Development

```sh
gleam deps download
gleam format --check
gleam check
gleam build --warnings-as-errors
gleam docs build
gleam test --runtime bun
```

## License

[MIT License](LICENSE)
