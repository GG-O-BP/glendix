//// Transforms Mendix widget editor property configuration.
////

/// A typed `Properties` value used by the editor config capability.
pub type Properties

/// Hides the property.
pub fn hide_property(
  properties properties: Properties,
  key key: String,
) -> Properties {
  hide_property_raw(properties, key)
}

/// Hides the properties.
pub fn hide_properties(
  properties properties: Properties,
  keys keys: String,
) -> Properties {
  hide_properties_raw(properties, keys)
}

/// Hides the nested property.
pub fn hide_nested_property(
  properties properties: Properties,
  key key: String,
  index index: Int,
  nested_key nested_key: String,
) -> Properties {
  hide_nested_property_raw(properties, key, index, nested_key)
}

/// Hides the nested properties.
pub fn hide_nested_properties(
  properties properties: Properties,
  key key: String,
  index index: Int,
  nested_keys nested_keys: String,
) -> Properties {
  hide_nested_properties_raw(properties, key, index, nested_keys)
}

/// Transforms the groups into tabs.
pub fn transform_groups_into_tabs(
  properties properties: Properties,
) -> Properties {
  transform_groups_into_tabs_raw(properties)
}

/// Moves the property.
pub fn move_property(
  properties properties: Properties,
  from_index from_index: Int,
  to_index to_index: Int,
) -> Properties {
  move_property_raw(properties, from_index, to_index)
}

// -- FFI --
@external(javascript, "./editor_config_ffi.mjs", "hide_property_in")
fn hide_property_raw(
  properties properties: Properties,
  key key: String,
) -> Properties

@external(javascript, "./editor_config_ffi.mjs", "hide_properties_in")
fn hide_properties_raw(
  properties properties: Properties,
  keys keys: String,
) -> Properties

@external(javascript, "./editor_config_ffi.mjs", "hide_nested_property_in")
fn hide_nested_property_raw(
  properties properties: Properties,
  key key: String,
  index index: Int,
  nested_key nested_key: String,
) -> Properties

@external(javascript, "./editor_config_ffi.mjs", "hide_nested_properties_in")
fn hide_nested_properties_raw(
  properties properties: Properties,
  key key: String,
  index index: Int,
  nested_keys nested_keys: String,
) -> Properties

@external(javascript, "./editor_config_ffi.mjs", "transform_groups_into_tabs")
fn transform_groups_into_tabs_raw(
  properties properties: Properties,
) -> Properties

@external(javascript, "./editor_config_ffi.mjs", "move_property")
fn move_property_raw(
  properties properties: Properties,
  from_index from_index: Int,
  to_index to_index: Int,
) -> Properties
