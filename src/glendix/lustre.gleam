//// Adapts Lustre applications and effects to the Mendix widget runtime.
////

import lustre/effect
import lustre/element
import redraw

/// Renders an application inside a keyed React host.
///
/// The render callback receives fresh props on every parent render. React
/// preserves the hosted application while the key is unchanged and remounts it
/// when the key changes. Derive the key from application state; Glendix does
/// not interpret Mendix datasource or widget props.
pub fn keyed_host(
  key key: String,
  props props: properties,
  render render: fn(properties) -> redraw.Element,
) -> redraw.Element {
  redraw.keyed(redraw.fragment, [#(key, host_raw(props, render))])
}

/// Renders a Lustre application as a Mendix widget element.
pub fn render(
  element element: element.Element(msg),
  dispatch dispatch: fn(msg) -> Nil,
) -> redraw.Element {
  render_raw(element, dispatch)
}

/// Starts a Lustre TEA application inside a Mendix widget.
pub fn use_tea(
  init init: #(model, effect.Effect(msg)),
  update update: fn(model, msg) -> #(model, effect.Effect(msg)),
  view view: fn(model) -> element.Element(msg),
) -> redraw.Element {
  use_tea_raw(init, update, view)
}

/// Starts a simple Lustre component inside a Mendix widget.
pub fn use_simple(
  init init: model,
  update update: fn(model, msg) -> model,
  view view: fn(model) -> element.Element(msg),
) -> redraw.Element {
  use_simple_raw(init, update, view)
}

/// Embeds a Lustre component in a Mendix widget element.
pub fn embed(element element: redraw.Element) -> element.Element(msg) {
  embed_raw(element)
}

// -- FFI --
@external(javascript, "./lustre_ffi.mjs", "render")
fn render_raw(
  element element: element.Element(msg),
  dispatch dispatch: fn(msg) -> Nil,
) -> redraw.Element

@external(javascript, "./lustre_ffi.mjs", "use_tea")
fn use_tea_raw(
  init init: #(model, effect.Effect(msg)),
  update update: fn(model, msg) -> #(model, effect.Effect(msg)),
  view view: fn(model) -> element.Element(msg),
) -> redraw.Element

@external(javascript, "./lustre_ffi.mjs", "use_simple")
fn use_simple_raw(
  init init: model,
  update update: fn(model, msg) -> model,
  view view: fn(model) -> element.Element(msg),
) -> redraw.Element

@external(javascript, "./lustre_ffi.mjs", "embed")
fn embed_raw(element element: redraw.Element) -> element.Element(msg)

@external(javascript, "./lustre_ffi.mjs", "host")
fn host_raw(
  props props: properties,
  render render: fn(properties) -> redraw.Element,
) -> redraw.Element
