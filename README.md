**English** | [한국어](README.ko.md) | [日本語](README.ja.md)

# glendix

Hello! This is glendix and it's ever so brilliant! It's a Gleam library for Mendix Pluggable Widgets.

**You can write proper Mendix widgets using only Gleam — no JSX needed at all, how lovely is that!**

React is handled by [redraw](https://github.com/ghivert/redraw)/[redraw_dom](https://github.com/ghivert/redraw), TEA pattern by [lustre](https://github.com/lustre-labs/lustre), and glendix focuses on the Mendix bits.

## What's New in v3.0

v3.0 is a big one! We've ripped out the entire `glendix/react` layer (14 files!) and delegated React bindings to **redraw** and **redraw_dom**. We've also added a **Lustre bridge** so you can use the TEA pattern inside Mendix widgets.

### What's Changed Then

- **React bindings removed**: `glendix/react`, `glendix/react/attribute`, `glendix/react/hook`, `glendix/react/html`, `glendix/react/event`, `glendix/react/svg`, `glendix/react/svg_attribute`, `glendix/react/ref` — all gone! Use `redraw` and `redraw_dom` directly instead.
- **New `glendix/interop`**: bridges external JS React components (from `widget` and `binding`) to `redraw.Element`
- **New `glendix/lustre`**: Lustre TEA bridge — `use_tea` and `use_simple` hooks let you write `update`/`view` functions in pure Lustre and render them as React elements
- **`JsProps` moved**: `glendix/mendix.{type JsProps}` instead of `glendix/react.{type JsProps}`
- **`ReactElement` → `Element`**: return type is now `redraw.{type Element}`

### Migration Cheatsheet

| Before (v2) | After (v3) |
|---|---|
| `import glendix/react.{type ReactElement}` | `import redraw.{type Element}` |
| `import glendix/react.{type JsProps}` | `import glendix/mendix.{type JsProps}` |
| `import glendix/react/html` | `import redraw/dom/html` |
| `import glendix/react/attribute` | `import redraw/dom/attribute` |
| `import glendix/react/event` | `import redraw/dom/events` |
| `import glendix/react/hook` | `import redraw` (hooks are in the main module) |
| `import glendix/react/svg` | `import redraw/dom/svg` |
| `import glendix/react/ref` | `import redraw/ref` |
| `react.text("hi")` | `html.text("hi")` |
| `react.none()` | `html.none()` |
| `react.fragment(children)` | `redraw.fragment(children)` |
| `react.define_component(name, render)` | `redraw.component_(name, render)` |
| `react.memo(component)` | `redraw.memoize_(component)` |
| `hook.use_state(0)` | `redraw.use_state(0)` |
| `hook.use_effect(fn, deps)` | `redraw.use_effect(fn, deps)` |
| `react.component_el(comp, attrs, children)` | `interop.component_el(comp, attrs, children)` |
| `react.when(cond, fn)` | `case cond { True -> fn() False -> html.none() }` |

## How to Put It In Your Project

Pop this into your `gleam.toml`:

```toml
# gleam.toml
[dependencies]
glendix = ">= 4.0.0 and < 5.0.0"
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
import glendix/mendix.{type JsProps}
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
import glendix/mendix.{type JsProps}
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
| `glendix/interop` | Renders external JS React components (from `widget`/`binding`) as `redraw.Element` |
| `glendix/lustre` | Lustre TEA bridge — `use_tea`, `use_simple`, `render`, `embed` |
| `glendix/binding` | For using other people's React components — configure in `gleam.toml` or `bindings.json` |
| `glendix/widget` | For using `.mpk` widgets — auto-downloaded via `gleam.toml` — `component`, `prop`, `editable_prop`, `action_prop` |
| `glendix/classic` | Classic (Dojo) widget wrapper — `classic.render(widget_id, properties)` |
| `glendix/marketplace` | Search and download widgets from the Mendix Marketplace (auto-saves to `gleam.toml`) |
| `glendix/define` | Interactive TUI editor for widget property definitions |

### Mendix Bits

| Module | What It Does |
|---|---|
| `glendix/mendix` | Core Mendix types (`ValueStatus`, `ObjectItem`, `JsProps`) + props accessors |
| `glendix/mendix/editable_value` | For values you can change — `value`, `set_value`, `set_text_value`, `display_value` |
| `glendix/mendix/action` | For doing actions — `can_execute`, `execute`, `execute_if_can` |
| `glendix/mendix/dynamic_value` | For read-only values (expression attributes and that) |
| `glendix/mendix/list_value` | Lists of data — `items`, `set_filter`, `set_sort_order`, `reload` |
| `glendix/mendix/list_attribute` | Types that go with lists — `ListAttributeValue`, `ListActionValue`, `ListWidgetValue` |
| `glendix/mendix/selection` | For picking one thing or lots of things |
| `glendix/mendix/reference` | Single association (ReferenceValue) |
| `glendix/mendix/reference_set` | Multiple associations (ReferenceSetValue) |
| `glendix/mendix/date` | A wrapper for JS Date (months go from 1 in Gleam to 0 in JS automatically) |
| `glendix/mendix/decimal` | Mendix Decimal boundary conversion (Big.js ↔ Gleam) |
| `glendix/mendix/file` | `FileValue` and `WebImage` |
| `glendix/mendix/icon` | `WebIcon` — Glyph, Image, IconFont |
| `glendix/mendix/formatter` | `ValueFormatter` — `format` and `parse` |
| `glendix/mendix/filter` | FilterCondition builder |
| `glendix/editor_config` | Editor helpers (Jint compatible) |

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
import glendix/mendix.{type JsProps}
import glendix/mendix/editable_value as ev
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

> You can also use a `bindings.json` file instead (it still works as a fallback).

**2. Install the package:**

```bash
npm install recharts
```

**3. Run `gleam run -m glendix/install`**

**4. Write a nice Gleam wrapper:**

```gleam
// src/chart/recharts.gleam
import glendix/binding
import glendix/interop
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
[tools.glendix.widgets.Charts]
version = "3.0.0"
# s3_id = "com/..."   ← if you have this, no auth needed!
```

It downloads to `build/widgets/` cache and generates everything automatically.

**Have a look at the auto-generated `src/widgets/*.gleam` files:**

```gleam
// src/widgets/switch.gleam (made automatically!)
import glendix/mendix.{type JsProps}
import glendix/interop
import glendix/widget
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
import glendix/widget

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
gleam run -m glendix/marketplace
```

**3. Use the lovely interactive menu:**

```
  ── Page 1/5+ ──

  [0] Star Rating (54611) v3.2.2 — Mendix
  [1] Switch (50324) v4.0.0 — Mendix
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
| `gleam run -m glendix/marketplace` | Searches and downloads widgets from the Marketplace |
| `gleam run -m glendix/define` | Interactive TUI editor for widget property definitions |
| `gleam run -m glendix/build` | Makes a production build (.mpk file) |
| `gleam run -m glendix/dev` | Starts a dev server (with HMR) |
| `gleam run -m glendix/start` | Connects to a Mendix test project |
| `gleam run -m glendix/lint` | Checks your code with ESLint |
| `gleam run -m glendix/lint_fix` | Fixes ESLint problems automatically |
| `gleam run -m glendix/release` | Makes a release build |

## Why We Made It This Way

- **Delegate, don't duplicate.** React bindings belong to redraw. TEA belongs to lustre. glendix only handles Mendix-specific concerns — interop, widgets, bindings, and build tooling.
- **Opaque types keep everything safe.** JS values like `JsProps` and `EditableValue` are wrapped up in Gleam types so you can't accidentally do something wrong — the compiler catches it!
- **`undefined` turns into `Option` automatically.** When JS gives us `undefined` or `null`, Gleam gets `None`. When there's a real value, it becomes `Some(value)`. No faffing about!
- **Two rendering paths.** Use redraw for direct React, or use the Lustre bridge for TEA — both output `redraw.Element`, so they compose freely.

## Thank You

glendix v3.0 is built on top of the brilliant [redraw](https://github.com/ghivert/redraw) and [lustre](https://github.com/lustre-labs/lustre) ecosystems. Cheers to both projects!

## Licence

[Blue Oak Model Licence 1.0.0](LICENSE)
