//// Reads browser environment preferences behind a typed boundary.
////
//// This module hides `window.matchMedia` so widgets never call it directly and
//// never keep an application-local FFI for reading the color-scheme preference.
//// The queries report the operating-system preference as a typed value, and a
//// separate query resolves what actually applies when the preference is left to
//// the system.
////
//// Dynamic preference-change subscriptions (`MediaQueryList` `change` events)
//// are intentionally out of scope. A widget re-queries these functions during
//// its own props- or revision-driven re-render; when and how to re-render, the
//// default theme, and the palette all remain application policy.
////
//// The color scheme is often built into a plain JavaScript object and passed to
//// an external React component as a single prop. `glendix/js/object` builds the
//// object from ordered typed entries, and `glendix/binding` passes it through a
//// Redraw attribute without any application-local React FFI:
////
//// ```gleam
//// import glendix/binding
//// import glendix/js/environment
//// import glendix/js/object
//// import redraw
//// import redraw/dom/attribute
////
//// pub fn themed_component(
////   component component: binding.JsComponent,
//// ) -> redraw.Element {
////   let theme = case environment.resolved_color_scheme() {
////     environment.ResolvedDark -> "dark"
////     environment.ResolvedLight -> "light"
////     environment.ResolutionUnavailable -> "light"
////   }
////   // `object.from_entries` preserves entry order and keeps the last value for
////   // a duplicate key; the object becomes one external-component prop.
////   let configuration =
////     object.from_entries([#("theme", object.string(theme))])
////   binding.element(
////     component,
////     [attribute.attribute("config", object.from_object(configuration))],
////     [],
////   )
//// }
//// ```
////

/// Represents the operating-system color-scheme preference.
pub type ColorScheme {
  /// The system explicitly prefers a light color scheme.
  Light
  /// The system explicitly prefers a dark color scheme.
  Dark
  /// No explicit preference is expressed, or the preference cannot be read.
  System
}

/// Represents the color scheme that actually applies after resolving `System`.
pub type ResolvedColorScheme {
  /// A light color scheme applies, including the default when no preference is
  /// expressed.
  ResolvedLight
  /// A dark color scheme applies.
  ResolvedDark
  /// The preference cannot be resolved because `matchMedia` is unavailable.
  ResolutionUnavailable
}

/// Reads the operating-system color-scheme preference.
///
/// Returns `System` both when no explicit preference is expressed and when
/// `matchMedia` is unavailable, because neither case names a concrete scheme.
pub fn color_scheme() -> ColorScheme {
  case match_media_is_available_raw() {
    False -> System
    True ->
      case prefers_dark_raw(), prefers_light_raw() {
        True, True -> Dark
        True, False -> Dark
        False, True -> Light
        False, False -> System
      }
  }
}

/// Resolves the color scheme that applies, treating `System` as light.
///
/// Returns `ResolutionUnavailable` when `matchMedia` cannot be queried, so an
/// unavailable environment is distinct from a resolved light preference.
pub fn resolved_color_scheme() -> ResolvedColorScheme {
  case match_media_is_available_raw() {
    False -> ResolutionUnavailable
    True ->
      case prefers_dark_raw() {
        True -> ResolvedDark
        False -> ResolvedLight
      }
  }
}

// -- FFI --
@external(javascript, "./environment_ffi.mjs", "match_media_is_available")
fn match_media_is_available_raw() -> Bool

@external(javascript, "./environment_ffi.mjs", "prefers_dark")
fn prefers_dark_raw() -> Bool

@external(javascript, "./environment_ffi.mjs", "prefers_light")
fn prefers_light_raw() -> Bool
