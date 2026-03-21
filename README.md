**English** | [한국어](README.ko.md) | [日本語](README.ja.md)

# glendix

Hello! This is glendix and it's ever so brilliant! It's a Gleam library for Mendix Pluggable Widgets.

**You can write proper Mendix widgets using only Gleam — no JSX needed at all, how lovely is that!**

React is handled by [redraw](https://github.com/ghivert/redraw)/[redraw_dom](https://github.com/ghivert/redraw), TEA pattern by [lustre](https://github.com/lustre-labs/lustre), and Mendix types/widgets/marketplace are delegated to [mendraw](https://github.com/GG-O-BP/mendraw).

## What's New in v4.0

v4.0 delegates Mendix API types, widget bindings (.mpk), classic widgets, and marketplace functionality to **mendraw**. glendix now focuses purely on build tooling, external React component bindings, and the Lustre bridge.

### What's Changed Then

- **Mendix types moved to mendraw**: `import glendix/mendix` → `import mendraw/mendix`, all submodules (`editable_value`, `action`, `list_value`, etc.) now under `mendraw/mendix/*`
- **Interop moved to mendraw**: `import glendix/interop` → `import mendraw/interop`
- **Widget moved to mendraw**: `import glendix/widget` → `import mendraw/widget`, TOML config `[tools.glendix.widgets.*]` → `[tools.mendraw.widgets.*]`
- **Classic moved to mendraw**: `import glendix/classic` → `import mendraw/classic`
- **Marketplace moved to mendraw**: `gleam run -m glendix/marketplace` → `gleam run -m mendraw/marketplace`
- **glendix/binding stays**: external React component bindings remain in glendix
- **glendix/lustre stays**: Lustre TEA bridge remains in glendix

### Migration Cheatsheet (v3 → v4)

| Before (v3) | After (v4) |
|---|---|
| `import glendix/mendix.{type JsProps}` | `import mendraw/mendix.{type JsProps}` |
| `import glendix/mendix/editable_value` | `import mendraw/mendix/editable_value` |
| `import glendix/mendix/action` | `import mendraw/mendix/action` |
| `import glendix/interop` | `import mendraw/interop` |
| `import glendix/widget` | `import mendraw/widget` |
| `import glendix/classic` | `import mendraw/classic` |
| `gleam run -m glendix/marketplace` | `gleam run -m mendraw/marketplace` |
| `[tools.glendix.widgets.X]` | `[tools.mendraw.widgets.X]` |

## How to Put It In Your Project

Pop this into your `gleam.toml`:

```toml
# gleam.toml
[dependencies]
glendix = ">= 4.0.1 and < 5.0.0"
mendraw = ">= 1.1.9 and < 2.0.0"
```

### Peer Dependencies

Your widget project's `package.json` needs these as well:

```json
{
  "dependencies": {
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "big.js": "^6.0.0"
  }
}
```

> `big.js` is only needed if your widget uses Decimal attributes. Skip it if you don't!

## Let's Get Started!

Here's a dead simple widget — look how short it is!

```gleam
import mendraw/mendix.{type JsProps}
import redraw.{type Element}
import redraw/dom/attribute
import redraw/dom/html

pub fn widget(props: JsProps) -> Element {
  let name = mendix.get_string_prop(props, "sampleText")
  html.div([attribute.class("my-widget")], [
    html.text("Hello " <> name),
  ])
}
```

`fn(JsProps) -> Element` — that's literally all a Mendix Pluggable Widget needs. Easy peasy!

### Using Lustre TEA Pattern

If you prefer The Elm Architecture, use the Lustre bridge — your `update` and `view` functions are 100% standard Lustre:

```gleam
import glendix/lustre as gl
import mendraw/mendix.{type JsProps}
import lustre/effect
import lustre/element/html
import lustre/event
import redraw.{type Element}

type Model { Model(count: Int) }
type Msg { Increment }

fn update(model, msg) {
  case msg {
    Increment -> #(Model(model.count + 1), effect.none())
  }
}

fn view(model: Model) {
  html.div([], [
    html.button([event.on_click(Increment)], [
      html.text("Count: " <> int.to_string(model.count)),
    ]),
  ])
}

pub fn widget(_props: JsProps) -> Element {
  gl.use_tea(#(Model(0), effect.none()), update, view)
}
```

## All the Modules

### React & Rendering (via redraw)

| Module | What It Does |
|---|---|
| `redraw` | Components, hooks, fragments, context — the full React API in Gleam |
| `redraw/dom/html` | HTML tags — `div`, `span`, `input`, `text`, `none`, and loads more |
| `redraw/dom/attribute` | Attribute type + HTML attribute functions — `class`, `id`, `style`, and more |
| `redraw/dom/events` | Event handlers — `on_click`, `on_change`, `on_input`, with capture variants |
| `redraw/dom/svg` | SVG elements — `svg`, `path`, `circle`, filter primitives, and more |
| `redraw/dom` | DOM utilities — `create_portal`, `flush_sync`, resource hints |

### glendix Bridges

| Module | What It Does |
|---|---|
| `glendix/lustre` | Lustre TEA bridge — `use_tea`, `use_simple`, `render`, `embed` |
| `glendix/binding` | For using other people's React components — configure in `gleam.toml [tools.glendix.bindings]` |
| `glendix/define` | Interactive TUI editor for widget property definitions |

### mendraw (Mendix API & Widgets)

| Module | What It Does |
|---|---|
| `mendraw/mendix` | Core Mendix types (`ValueStatus`, `ObjectItem`, `JsProps`) + props accessors |
| `mendraw/interop` | Renders external JS React components (from `widget`/`binding`) as `redraw.Element` |
| `mendraw/widget` | For using `.mpk` widgets — auto-downloaded via `gleam.toml` — `component`, `prop`, `editable_prop`, `action_prop` |
| `mendraw/classic` | Classic (Dojo) widget wrapper — `classic.render(widget_id, properties)` |
| `mendraw/marketplace` | Search and download widgets from the Mendix Marketplace |

### JS Interop Bits

| Module | What It Does |
|---|---|
| `glendix/js/array` | Gleam List ↔ JS Array conversion |
| `glendix/js/object` | Create objects, read/write/delete properties, call methods, `new` instances |
| `glendix/js/json` | `stringify` and `parse` (parse returns a proper `Result`!) |
| `glendix/js/promise` | Promise chaining (`then_`, `map`, `catch_`), `all`, `race`, `resolve`, `reject` |
| `glendix/js/dom` | DOM helpers — `focus`, `blur`, `click`, `scroll_into_view`, `query_selector` |
| `glendix/js/timer` | `set_timeout`, `set_interval`, `clear_timeout`, `clear_interval` |

## Examples

### Attribute Lists

This is how you make a button with attributes — it's like a shopping list!

```gleam
import redraw/dom/attribute
import redraw/dom/events
import redraw/dom/html

html.button(
  [
    attribute.class("btn btn-primary"),
    attribute.type_("submit"),
    attribute.disabled(False),
    events.on_click(fn(_event) { Nil }),
  ],
  [html.text("Submit")],
)
```

### useState + useEffect

Here's a counter! Every time you press the button, the number goes up by one — magic!

```gleam
import gleam/int
import redraw
import redraw/dom/attribute
import redraw/dom/events
import redraw/dom/html

pub fn counter(_props) -> redraw.Element {
  let #(count, set_count) = redraw.use_state(0)

  redraw.use_effect(fn() { Nil }, Nil)

  html.div([], [
    html.button(
      [events.on_click(fn(_) { set_count(count + 1) })],
      [html.text("Count: " <> int.to_string(count))],
    ),
  ])
}
```

### Reading and Writing Mendix Values

Here's how you get values out of Mendix and do things with them:

```gleam
import gleam/option.{None, Some}
import mendraw/mendix.{type JsProps}
import mendraw/mendix/editable_value as ev
import redraw.{type Element}
import redraw/dom/html

pub fn render_input(props: JsProps) -> Element {
  case mendix.get_prop(props, "myAttribute") {
    Some(attr) -> {
      let display = ev.display_value(attr)
      let editable = ev.is_editable(attr)
      // ...
    }
    None -> html.none()
  }
}
```

### Using Other People's React Components (Bindings)

You can use React libraries from npm without writing any `.mjs` files yourself — isn't that ace!

**1. Add bindings to `gleam.toml`:**

```toml
[tools.glendix.bindings]
recharts = ["PieChart", "Pie", "Cell", "Tooltip", "Legend"]
```

**2. Install the package:**

```bash
npm install recharts
```

**3. Run `gleam run -m glendix/install`**

**4. Write a nice Gleam wrapper:**

```gleam
// src/chart/recharts.gleam
import glendix/binding
import mendraw/interop
import redraw.{type Element}
import redraw/dom/attribute.{type Attribute}

fn m() { binding.module("recharts") }

pub fn pie_chart(attrs: List(Attribute), children: List(Element)) -> Element {
  interop.component_el(binding.resolve(m(), "PieChart"), attrs, children)
}

pub fn pie(attrs: List(Attribute), children: List(Element)) -> Element {
  interop.component_el(binding.resolve(m(), "Pie"), attrs, children)
}
```

**5. Use it in your widget:**

```gleam
import chart/recharts
import redraw/dom/attribute

pub fn my_chart(data) -> redraw.Element {
  recharts.pie_chart(
    [attribute.attribute("width", 400), attribute.attribute("height", 300)],
    [
      recharts.pie(
        [attribute.attribute("data", data), attribute.attribute("dataKey", "value")],
        [],
      ),
    ],
  )
}
```

### Using .mpk Widgets

You can use Marketplace widgets as React components — auto-downloaded via `gleam.toml`.

Register your widget in `gleam.toml` and run `gleam run -m glendix/install`:

```toml
[tools.mendraw.widgets.Charts]
version = "3.0.0"
# s3_id = "com/..."   ← if you have this, no auth needed!
```

It downloads to `build/widgets/` cache and generates everything automatically.

**Have a look at the auto-generated `src/widgets/*.gleam` files:**

```gleam
// src/widgets/switch.gleam (made automatically!)
import mendraw/mendix.{type JsProps}
import mendraw/interop
import mendraw/widget
import redraw.{type Element}
import redraw/dom/attribute

pub fn render(props: JsProps) -> Element {
  let boolean_attribute = mendix.get_prop_required(props, "booleanAttribute")
  let action = mendix.get_prop_required(props, "action")

  let comp = widget.component("Switch")
  interop.component_el(
    comp,
    [
      attribute.attribute("booleanAttribute", boolean_attribute),
      attribute.attribute("action", action),
    ],
    [],
  )
}
```

**4. Use it in your widget:**

You can pass Mendix props through directly, or create values from scratch using the widget prop helpers:

```gleam
// Creating values from scratch (e.g. in Lustre TEA views)
import mendraw/widget

widget.prop("caption", "Hello")                              // DynamicValue
widget.editable_prop("text", value, display, set_value)      // EditableValue
widget.action_prop("onClick", fn() { do_something() })       // ActionValue
```

```gleam
import widgets/switch

switch.render(props)
```

### Downloading Widgets from the Marketplace

You can search for widgets on the Mendix Marketplace and download them right from the terminal — it's dead handy!

**1. Put your Mendix PAT in `.env`:**

```
MENDIX_PAT=your_personal_access_token
```

> You can get a PAT from [Mendix Developer Settings](https://user-settings.mendix.com/link/developersettings) — click **New Token** under **Personal Access Tokens**. You'll need the `mx:marketplace-content:read` permission.

**2. Run this:**

```bash
gleam run -m mendraw/marketplace
```

**3. Use the lovely interactive menu:**

```
  ── Page 1/5+ ──

  [0] Star Rating (54611) v3.2.2 — Mendix
  [1] Switch (50324) v4.0.1 — Mendix
  ...

  Number: download | Search term: filter by name | n: next | p: previous | r: reset | q: quit

> 0              ← type a number to download it
> star           ← type a word to search
> 0,1,3          ← use commas to pick several at once
```

Downloaded widgets are cached in `build/widgets/` and automatically added to your `gleam.toml` — no need to commit `.mpk` files to source control!

## Build Scripts

| Command | What It Does |
|---------|-------------|
| `gleam run -m glendix/install` | Installs deps + downloads TOML widgets + makes bindings + generates widget files |
| `gleam run -m mendraw/marketplace` | Searches and downloads widgets from the Marketplace |
| `gleam run -m glendix/define` | Interactive TUI editor for widget property definitions |
| `gleam run -m glendix/build` | Makes a production build (.mpk file) |
| `gleam run -m glendix/dev` | Starts a dev server (with HMR) |
| `gleam run -m glendix/start` | Connects to a Mendix test project |
| `gleam run -m glendix/lint` | Checks your code with ESLint |
| `gleam run -m glendix/lint_fix` | Fixes ESLint problems automatically |
| `gleam run -m glendix/release` | Makes a release build |

## Why We Made It This Way

- **Delegate, don't duplicate.** React bindings belong to redraw. TEA belongs to lustre. Mendix types and widgets belong to mendraw. glendix only handles build tooling, external React component bindings, and the Lustre bridge.
- **Opaque types keep everything safe.** JS values like `JsProps` and `EditableValue` are wrapped up in Gleam types so you can't accidentally do something wrong — the compiler catches it!
- **`undefined` turns into `Option` automatically.** When JS gives us `undefined` or `null`, Gleam gets `None`. When there's a real value, it becomes `Some(value)`. No faffing about!
- **Two rendering paths.** Use redraw for direct React, or use the Lustre bridge for TEA — both output `redraw.Element`, so they compose freely.

## Thank You

glendix v4.0 is built on top of the brilliant [redraw](https://github.com/ghivert/redraw), [lustre](https://github.com/lustre-labs/lustre), and [mendraw](https://github.com/GG-O-BP/mendraw) ecosystems. Cheers to all projects!

## Licence

[Blue Oak Model Licence 1.0.0](LICENSE)
