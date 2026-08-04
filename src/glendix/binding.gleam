//// Provides binding operations for Glendix.
////
//// ```gleam
//// import gleam/result
//// import glendix/binding
//// import redraw
//// import redraw/dom/attribute
////
//// pub fn pie_chart(
////   attrs attrs: List(attribute.Attribute),
////   children children: List(redraw.Element),
//// ) -> Result(redraw.Element, binding.BindingError) {
////   use module <- result.try(binding.module("recharts"))
////   use component <- result.try(binding.resolve(module, "PieChart"))
////   Ok(binding.element(component, attrs, children))
//// }
//// ```

import gleam/result
import redraw
import redraw/dom/attribute

/// A typed `JsModule` value used by the binding capability.
pub type JsModule

/// Represents one JavaScript component exported by a configured module.
pub type JsComponent

/// Describes a missing JavaScript binding.
pub type BindingError {
  /// The requested JavaScript module is not registered.
  ModuleWasNotFound(name: String, reason: String)
  /// The requested export is not available from the module.
  ExportWasNotFound(name: String, reason: String)
}

/// Returns a JavaScript module handle by name.
pub fn module(name name: String) -> Result(JsModule, BindingError) {
  module_raw(name)
  |> result.map_error(fn(error) {
    ModuleWasNotFound(name: name, reason: raw_binding_error_message(error))
  })
}

/// Resolves an exported JavaScript value from a module handle.
pub fn resolve(
  module module: JsModule,
  name name: String,
) -> Result(JsComponent, BindingError) {
  resolve_raw(module, name)
  |> result.map_error(fn(error) {
    ExportWasNotFound(name: name, reason: raw_binding_error_message(error))
  })
}

/// Creates an element from an external component, attributes, and children.
pub fn element(
  component component: JsComponent,
  attributes attributes: List(attribute.Attribute),
  children children: List(redraw.Element),
) -> redraw.Element {
  element_raw(component, attributes, children)
}

/// Creates an element from an external component and children.
pub fn element_(
  component component: JsComponent,
  children children: List(redraw.Element),
) -> redraw.Element {
  element_without_attributes_raw(component, children)
}

/// Creates an element from an external component without children.
pub fn void_element(
  component component: JsComponent,
  attributes attributes: List(attribute.Attribute),
) -> redraw.Element {
  void_element_raw(component, attributes)
}

type RawBindingError

// -- FFI --
@external(javascript, "./binding_ffi.mjs", "get_module")
fn module_raw(name name: String) -> Result(JsModule, RawBindingError)

@external(javascript, "./binding_ffi.mjs", "resolve")
fn resolve_raw(
  module module: JsModule,
  name name: String,
) -> Result(JsComponent, RawBindingError)

@external(javascript, "./binding_ffi.mjs", "component_element")
fn element_raw(
  component: JsComponent,
  attributes: List(attribute.Attribute),
  children: List(redraw.Element),
) -> redraw.Element

@external(javascript, "./binding_ffi.mjs", "component_element_without_attributes")
fn element_without_attributes_raw(
  component: JsComponent,
  children: List(redraw.Element),
) -> redraw.Element

@external(javascript, "./binding_ffi.mjs", "void_component_element")
fn void_element_raw(
  component: JsComponent,
  attributes: List(attribute.Attribute),
) -> redraw.Element

@external(javascript, "./binding_ffi.mjs", "binding_error_message")
fn raw_binding_error_message(error: RawBindingError) -> String
