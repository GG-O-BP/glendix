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
unchanged key preserves the application while the callback receives fresh
props; a changed key remounts it. Directly keying an evaluated `use_tea` result
does not create the React component boundary that owns its hooks, and
`lustre/element/keyed` only affects children inside the running Lustre tree.

## External npm React components

Configure exports in `gleam.toml`:

```toml
[tools.glendix.bindings]
recharts = ["PieChart", "Pie"]
```

Install the npm package, then run `gleam run -m glendix/install`. Glendix owns
both component lookup and element construction; Mendraw is not required:

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

## Browser environment and object props

Use `glendix/js/environment` to read `prefers-color-scheme` without exposing
`window.matchMedia`. `color_scheme` returns `Light`, `Dark`, or `System`;
`resolved_color_scheme` returns `ResolvedLight`, `ResolvedDark`, or
`ResolutionUnavailable`. Dynamic preference-change subscriptions are
intentionally out of scope, so re-query during an application-driven
re-render.

Build one plain JavaScript configuration object from ordered typed entries and
pass it through a Redraw attribute to an external component:

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

`object.from_entries` preserves ordinary string-key order, keeps the last value
for duplicate keys, and safely stores special keys as data.

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
