**English** | [한국어](README.ko.md) | [日本語](README.ja.md)

# glendix

Hello! This is glendix and it's ever so brilliant! It's a Gleam library that talks to React 19 and Mendix Pluggable Widgets.

**You can write proper Mendix widgets using only Gleam — no JSX needed at all, how lovely is that!**

## What's New in v2.0

Right, so v2.0 is loads better now! We had a good look at this clever project called [redraw](https://github.com/ghivert/redraw) and learnt quite a lot from it. redraw is a really proper React binding library for Gleam with lovely type safety and tidy modules. But since glendix is specially made for Mendix Pluggable Widgets, we didn't copy all of redraw's fancy SPA bits (like bootstrap/compose and jsx-runtime) — we just took the helpful parts!

### What's Changed Then

- **FFI modules got split up**: that big messy `react_ffi.mjs` file has been tidied into `hook_ffi.mjs`, `event_ffi.mjs`, and `attribute_ffi.mjs` — each one does just one job, which is much neater!
- **Attribute list API**: we swapped the old `prop.gleam` pipeline thing for a much nicer list pattern in `attribute.gleam` — you just go `[attribute.class("x"), event.on_click(handler)]` and it works!
- **39 Hooks**: we've got `useLayoutEffect`, `useInsertionEffect`, `useImperativeHandle`, `useLazyState`, `useSyncExternalStore`, `useDebugValue`, `useOptimistic` (even the reducer one!), `useAsyncTransition`, `useFormStatus`, and cleanup ones too
- **154+ event handlers**: capture phase, composition/media/UI/load/error/transition events + 82+ accessors + `persist`/`is_persistent` helpers — that's absolutely loads!
- **108+ HTML attributes**: `dangerously_set_inner_html`, `popover`, `fetch_priority`, `enter_key_hint`, microdata, Shadow DOM, and ever so many more
- **85+ HTML tags**: `fieldset`, `details`, `dialog`, `video`, `ruby`, `kbd`, `search`, `hgroup`, `meta`, `script`, `object`, and tonnes more
- **58 SVG elements**: including 16 filter thingies (`fe_convolve_matrix`, `fe_diffuse_lighting`, and such)
- **97+ SVG attributes**: text rendering, markers, mask/clipping units, filter attributes — it goes on and on!
- **Fancy components**: `StrictMode`, `Suspense`, `Profiler`, `portal`, `forwardRef`, `memo_`, `startTransition`, `flushSync` — all the grown-up bits!

## How to Put It In Your Project

Pop this into your `gleam.toml`:

```toml
# gleam.toml
[dependencies]
glendix = { path = "../glendix" }
```

> You've got to use a local path for now — it's not on Hex yet, sorry!

### Peer Dependencies

Your widget project's `package.json` needs these as well:

```json
{
  "dependencies": {
    "react": "^19.0.0",
    "big.js": "^6.0.0"
  }
}
```

## Let's Get Started!

Here's a dead simple widget — look how short it is!

```gleam
import glendix/mendix
import glendix/react.{type JsProps, type ReactElement}
import glendix/react/attribute
import glendix/react/html

pub fn widget(props: JsProps) -> ReactElement {
  let name = mendix.get_string_prop(props, "sampleText")
  html.div([attribute.class("my-widget")], [
    react.text("Hello " <> name),
  ])
}
```

`fn(JsProps) -> ReactElement` — that's literally all a Mendix Pluggable Widget needs. Easy peasy!

## All the Modules

### React Bits

| Module | What It Does |
|---|---|
| `glendix/react` | The main important bits — types like `ReactElement`, `JsProps`, `Component`, `Promise`, plus `element`, `fragment`, `keyed`, `text`, `none`, `when`, `when_some`, Context stuff, `define_component`, `memo` (uses Gleam's own equality checking, which is dead clever), `flush_sync` |
| `glendix/react/attribute` | Attribute type + 108+ HTML attribute functions — `class`, `id`, `style`, `popover`, `fetch_priority`, `enter_key_hint`, microdata, Shadow DOM, and loads more |
| `glendix/react/hook` | 40 React Hooks! — `use_state`, `use_effect`, `use_layout_effect`, `use_insertion_effect`, `use_memo`, `use_callback`, `use_ref`, `use_reducer`, `use_context`, `use_id`, `use_transition`, `use_async_transition`, `use_deferred_value`, `use_optimistic`/`use_optimistic_`, `use_imperative_handle`, `use_lazy_state`, `use_sync_external_store`, `use_debug_value`, `use_promise` (that's React.use!), `use_form_status` |
| `glendix/react/ref` | Ref helpers — `current` and `assign` (kept separate from hooks so it's tidy) |
| `glendix/react/event` | 16 event types + 154+ handlers (including capture phase and transition events!) + 82+ accessors |
| `glendix/react/html` | 85+ HTML tags — `div`, `span`, `input`, `details`, `dialog`, `video`, `ruby`, `kbd`, `search`, `meta`, `script`, `object`, and so on (pure Gleam, no FFI!) |
| `glendix/react/svg` | 58 SVG elements — `svg`, `path`, `circle`, 16 filter primitives, `discard`, and more (pure Gleam, no FFI!) |
| `glendix/react/svg_attribute` | 97+ SVG attribute functions — `view_box`, `fill`, `stroke`, markers, filter bits, etc. (pure Gleam, no FFI!) |
| `glendix/binding` | For using other people's React components — just write `bindings.json` and you're sorted, no `.mjs` needed! |
| `glendix/widget` | For using `.mpk` widgets from the `widgets/` folder as React components — brilliant! |
| `glendix/classic` | Classic (Dojo) widget wrapper — `classic.render(widget_id, properties)` — for the older widgets |
| `glendix/marketplace` | Search and download widgets from the Mendix Marketplace — `gleam run -m glendix/marketplace` |
| `glendix/define` | Interactive TUI editor for widget property definitions — add groups, set types, manage enums, all from the terminal! |

### Mendix Bits

| Module | What It Does |
|---|---|
| `glendix/mendix` | The core Mendix types (`ValueStatus`, `ObjectItem`) + how to get things from JsProps (`get_prop`, `get_string_prop`) |
| `glendix/mendix/editable_value` | For values you can change — `value`, `set_value`, `set_text_value`, `display_value` |
| `glendix/mendix/action` | For doing actions — `can_execute`, `execute`, `execute_if_can` |
| `glendix/mendix/dynamic_value` | For read-only values (expression attributes and that) |
| `glendix/mendix/list_value` | Lists of data — `items`, `set_filter`, `set_sort_order`, `reload` |
| `glendix/mendix/list_attribute` | Types that go with lists — `ListAttributeValue`, `ListActionValue`, `ListWidgetValue` |
| `glendix/mendix/selection` | For picking one thing or lots of things |
| `glendix/mendix/reference` | Single association (ReferenceValue) — like pointing to one friend |
| `glendix/mendix/reference_set` | Multiple associations (ReferenceSetValue) — like pointing to a whole group of friends! |
| `glendix/mendix/date` | A wrapper for JS Date (months go from 1 in Gleam to 0 in JS automatically — clever!) |
| `glendix/mendix/big` | Big.js wrapper for really precise numbers (`compare` gives you a proper `gleam/order.Order`) |
| `glendix/mendix/file` | `FileValue` and `WebImage` |
| `glendix/mendix/icon` | `WebIcon` — Glyph, Image, IconFont |
| `glendix/mendix/formatter` | `ValueFormatter` — `format` and `parse` |
| `glendix/mendix/filter` | FilterCondition builder — `and_`, `or_`, `equals`, `contains`, `attribute`, `literal` |
| `glendix/editor_config` | Editor helpers — hiding attributes, making tabs, reordering things (works with Jint!) |

### JS Interop Bits

| Module | What It Does |
|---|---|
| `glendix/js/array` | Gleam List ↔ JS Array conversion (reuses react_ffi.mjs — no extra FFI!) |
| `glendix/js/object` | Create objects, read/write/delete properties, call methods, `new` instances |
| `glendix/js/json` | `stringify` and `parse` (parse returns a proper `Result`!) |
| `glendix/js/promise` | Promise chaining (`then_`, `map`, `catch_`), `all`, `race`, `resolve`, `reject` — uses `react.Promise(a)` |
| `glendix/js/dom` | DOM helpers — `focus`, `blur`, `click`, `scroll_into_view`, `query_selector` (returns `Option`!) |
| `glendix/js/timer` | `set_timeout`, `set_interval`, `clear_timeout`, `clear_interval` — opaque `TimerId` so you can't muck about with it |

> These are escape hatches for when you need to talk to JS libraries directly (like SpreadJS). Everything uses `Dynamic` — no type safety, but loads of flexibility! If you can use `glendix/binding` instead, that's usually better.

## Examples

### Attribute Lists

This is how you make a button with attributes — it's like a shopping list!

```gleam
import glendix/react/attribute
import glendix/react/event
import glendix/react/html

html.button(
  [
    attribute.class("btn btn-primary"),
    attribute.type_("submit"),
    attribute.disabled(False),
    event.on_click(fn(_event) { Nil }),
  ],
  [react.text("Submit")],
)
```

And if you only want an attribute sometimes, use `attribute.none()` — it's like saying "actually, never mind":

```gleam
html.input([
  attribute.class("input"),
  case is_error {
    True -> attribute.class("input-error")
    False -> attribute.none()
  },
])
```

### useState + useEffect

Here's a counter! Every time you press the button, the number goes up by one — magic!

```gleam
import gleam/int
import glendix/react
import glendix/react/attribute
import glendix/react/event
import glendix/react/hook
import glendix/react/html

pub fn counter(_props) -> react.ReactElement {
  let #(count, set_count) = hook.use_state(0)

  hook.use_effect_once(fn() {
    // Runs once when it first appears
    Nil
  })

  html.div_([
    html.button(
      [event.on_click(fn(_) { set_count(count + 1) })],
      [react.text("Count: " <> int.to_string(count))],
    ),
  ])
}
```

### useLayoutEffect (Measuring the Page)

This one runs right after the page changes but before you can see it — it's dead quick!

```gleam
import glendix/react/hook

let ref = hook.use_ref(0.0)

hook.use_layout_effect_cleanup(
  fn() {
    // Measure things here
    fn() { Nil }  // tidy up after yourself
  },
  [some_dep],
)
```

### Reading and Writing Mendix Values

Here's how you get values out of Mendix and do things with them:

```gleam
import gleam/option.{None, Some}
import glendix/mendix
import glendix/mendix/editable_value as ev

pub fn render_input(props: react.JsProps) -> react.ReactElement {
  case mendix.get_prop(props, "myAttribute") {
    Some(attr) -> {
      let display = ev.display_value(attr)
      let editable = ev.is_editable(attr)
      // ...
    }
    None -> react.none()
  }
}
```

### Showing Things Sometimes

Sometimes you want to show something only when a condition is true — here's how!

```gleam
import glendix/react
import glendix/react/html

// When something is True
react.when(is_visible, fn() {
  html.div_([react.text("Visible!")])
})

// When you've got a Some value
react.when_some(maybe_user, fn(user) {
  html.span_([react.text(user.name)])
})
```

### Using Other People's React Components (Bindings)

You can use React libraries from npm without writing any `.mjs` files yourself — isn't that ace!

**1. Make a `bindings.json` file:**

```json
{
  "recharts": {
    "components": ["PieChart", "Pie", "Cell", "Tooltip", "Legend"]
  }
}
```

**2. Install the package** — whatever's in `bindings.json` needs to be in `node_modules`:

```bash
npm install recharts
```

**3. Run `gleam run -m glendix/install`** (it makes the bindings for you!)

**4. Write a nice Gleam wrapper** (works just like html.gleam does):

```gleam
// src/chart/recharts.gleam
import glendix/binding
import glendix/react.{type ReactElement}
import glendix/react/attribute.{type Attribute}

fn m() { binding.module("recharts") }

pub fn pie_chart(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.component_el(binding.resolve(m(), "PieChart"), attrs, children)
}

pub fn pie(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.component_el(binding.resolve(m(), "Pie"), attrs, children)
}
```

**5. Use it in your widget:**

```gleam
import chart/recharts
import glendix/react/attribute

pub fn my_chart(data) -> react.ReactElement {
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

You can put `.mpk` files in the `widgets/` folder and use them like React components — how cool is that!

**1. Pop your `.mpk` files into the `widgets/` folder**

**2. Run `gleam run -m glendix/install`** (it sorts out all the bindings for you!)

Two things happen automatically — isn't that nice:
- The `.mjs` and `.css` bits get pulled out of the `.mpk` files, and `widget_ffi.mjs` gets made
- The `.mpk` XML `<property>` bits get read and binding `.gleam` files appear in `src/widgets/` (if they're already there, they're left alone)

**3. Have a look at the auto-generated `src/widgets/*.gleam` files:**

```gleam
// src/widgets/switch.gleam (made automatically!)
import glendix/mendix
import glendix/react.{type JsProps, type ReactElement}
import glendix/react/attribute
import glendix/widget

/// Renders the Switch widget — reads the attributes from props and passes them along
pub fn render(props: JsProps) -> ReactElement {
  let boolean_attribute = mendix.get_prop_required(props, "booleanAttribute")
  let action = mendix.get_prop_required(props, "action")

  let comp = widget.component("Switch")
  react.component_el(
    comp,
    [
      attribute.attribute("booleanAttribute", boolean_attribute),
      attribute.attribute("action", action),
    ],
    [],
  )
}
```

It works out which attributes are required and which are optional all by itself! You can change the files afterwards if you like.

**4. Use it in your widget:**

```gleam
import widgets/switch

// Inside a component
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

When you choose one, it shows you all the versions and tells you if it's Pluggable or Classic. The `.mpk` files go into `widgets/` and the binding code gets made in `src/widgets/` — all automatic!

> It uses Playwright (Chromium) to check versions. You'll need to log in the first time, but after that it remembers you in `.marketplace-cache/session.json`.

## Build Scripts

glendix comes with built-in scripts — no extra files needed! Just use `gleam run -m` and off you go!

| Command | What It Does |
|---------|-------------|
| `gleam run -m glendix/install` | Installs everything + makes bindings + generates widget files (works out your package manager by itself!) |
| `gleam run -m glendix/marketplace` | Searches and downloads widgets from the Marketplace (interactive!) |
| `gleam run -m glendix/define` | Interactive TUI editor for widget property definitions (groups, types, enums — all from the terminal!) |
| `gleam run -m glendix/build` | Makes a production build (.mpk file) |
| `gleam run -m glendix/dev` | Starts a dev server (with HMR on port 3000 — changes show up instantly!) |
| `gleam run -m glendix/start` | Connects to a Mendix test project |
| `gleam run -m glendix/lint` | Checks your code with ESLint |
| `gleam run -m glendix/lint_fix` | Fixes ESLint problems automatically |
| `gleam run -m glendix/release` | Makes a release build |

It works out which package manager you're using all by itself:
- Got a `pnpm-lock.yaml`? It'll use pnpm
- Got a `bun.lockb` or `bun.lock`? It'll use bun
- Otherwise it just uses npm — simple!

## How It's All Put Together

Here's what's inside — it's quite organised actually!

```
glendix/
  react.gleam              ← The main important bits — createElement, Context, keyed, components, flushSync
  react_ffi.mjs            ← The JS helper for elements, Fragment, Context, and clever memo stuff
  react/
    attribute.gleam         ← Attribute type + 108+ HTML attribute functions
    attribute_ffi.mjs       ← Turns attributes into React props
    hook.gleam              ← 40 React Hooks (including use_promise and use_form_status!)
    hook_ffi.mjs            ← Hooks JS helper
    ref.gleam               ← Ref helpers (current and assign)
    event.gleam             ← 16 event types + 154+ handlers + 82+ accessors
    event_ffi.mjs           ← Event accessor JS helper
    html.gleam              ← 85+ HTML tags (pure Gleam — no JS!)
    svg.gleam               ← 58 SVG elements (pure Gleam — no JS!)
    svg_attribute.gleam     ← 97+ SVG attributes (pure Gleam — no JS!)
  js/
    array.gleam             ← Gleam List ↔ JS Array (no FFI — reuses react_ffi.mjs!)
    object.gleam            ← Object creation, property access, method calls
    object_ffi.mjs          ← Object JS helper
    json.gleam              ← JSON stringify/parse
    json_ffi.mjs            ← JSON JS helper
    promise.gleam           ← Promise chaining, all, race
    promise_ffi.mjs         ← Promise JS helper
    dom.gleam               ← DOM focus/blur/click/scroll/query
    dom_ffi.mjs             ← DOM JS helper
    timer.gleam             ← setTimeout/setInterval with opaque TimerId
    timer_ffi.mjs           ← Timer JS helper
  mendix.gleam              ← Core Mendix types + Props accessors
  mendix_ffi.mjs            ← Mendix runtime type helper
  mendix/
    editable_value.gleam    ← EditableValue
    action.gleam            ← ActionValue
    dynamic_value.gleam     ← DynamicValue
    list_value.gleam        ← ListValue + Sort + Filter
    list_attribute.gleam    ← List-linked types
    selection.gleam         ← Selection
    reference.gleam         ← ReferenceValue (single association)
    reference_set.gleam     ← ReferenceSetValue (multiple associations)
    date.gleam              ← JS Date wrapper
    big.gleam               ← Big.js wrapper
    file.gleam              ← File / Image
    icon.gleam              ← Icon
    formatter.gleam         ← ValueFormatter
    filter.gleam            ← FilterCondition builder
  editor_config.gleam       ← Editor helpers (Jint compatible — no Lists!)
  editor_config_ffi.mjs     ← @mendix/pluggable-widgets-tools wrapper
  binding.gleam             ← External React component binding API
  binding_ffi.mjs           ← Binding JS helper (gets remade on install)
  widget.gleam              ← .mpk widget component binding API
  widget_ffi.mjs            ← Widget JS helper (gets remade on install)
  classic.gleam             ← Classic (Dojo) widget wrapper
  classic_ffi.mjs           ← Classic widget JS helper (gets remade on install)
  marketplace.gleam         ← Marketplace search and download
  marketplace_ffi.mjs       ← Content API + Playwright + S3 download helper
  define.gleam              ← Widget property definition TUI editor
  define_ffi.mjs            ← Terminal I/O + file read/write helper
  define/
    types.gleam             ← Property, PropertyGroup, WidgetMeta types
    ui.gleam                ← TUI rendering helpers (edit fields, layouts)
  cmd.gleam                 ← Shell commands + PM detection + binding generation
  cmd_ffi.mjs               ← Node.js child_process + fs + ZIP + binding + widget .gleam generation
  build.gleam               ← Build script
  dev.gleam                 ← Dev server script
  start.gleam               ← Mendix integration script
  install.gleam             ← Install + binding generation script
  release.gleam             ← Release build script
  lint.gleam                ← ESLint script
  lint_fix.gleam            ← ESLint auto-fix script
```

## Why We Made It This Way

- **FFI is just a thin wrapper, nothing fancy.** The `.mjs` files only talk to JS — all the clever stuff is written in Gleam. Each module does one thing: `react_ffi.mjs` makes elements, `hook_ffi.mjs` does hooks, `event_ffi.mjs` reads events.
- **Opaque types keep everything safe.** JS values like `ReactElement`, `JsProps`, and `EditableValue` are wrapped up in Gleam types so you can't accidentally do something wrong — the compiler catches it!
- **`undefined` turns into `Option` automatically.** When JS gives us `undefined` or `null`, Gleam gets `None`. When there's a real value, it becomes `Some(value)`. No faffing about!
- **Attributes are just lists.** You write `[attribute.class("x"), event.on_click(handler)]` and that's it. Use `attribute.none()` when you don't want one. If you write `attribute.class()` more than once, they get joined together — brilliant!
- **Gleam tuples are JS arrays.** `#(a, b)` is the same as `[a, b]` in JS — so `useState` just works!

## Thank You

The React bindings in v2.0 were inspired by the lovely [redraw](https://github.com/ghivert/redraw) project. We learnt a lot about how to split up FFI modules, hook patterns, and event systems from them. Cheers, redraw!

## Licence

[Blue Oak Model Licence 1.0.0](LICENSE)
