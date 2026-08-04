import {
  hidePropertyIn,
  hidePropertiesIn,
  hideNestedPropertiesIn,
  transformGroupsIntoTabs,
  moveProperty,
} from "@mendix/pluggable-widgets-tools";
export function hide_property_in(properties, key) {
  hidePropertyIn(properties, {}, key);
  return properties;
}
export function hide_nested_property_in(properties, key, index, nested_key) {
  hidePropertyIn(properties, {}, key, index, nested_key);
  return properties;
}
export function hide_properties_in(properties, csv_keys) {
  var keys = csv_keys.split(",");
  for (var i = 0; i < keys.length; i++) {
    var trimmed = keys[i].trim();
    if (trimmed) hidePropertyIn(properties, {}, trimmed);
  }
  return properties;
}
export function hide_nested_properties_in(
  properties,
  key,
  index,
  csv_nested_keys,
) {
  var keys = csv_nested_keys.split(",");
  for (var i = 0; i < keys.length; i++) {
    var trimmed = keys[i].trim();
    if (trimmed) hidePropertyIn(properties, {}, key, index, trimmed);
  }
  return properties;
}
export function transform_groups_into_tabs(properties) {
  transformGroupsIntoTabs(properties);
  return properties;
}
export function move_property(properties, from_index, to_index) {
  moveProperty(from_index, to_index, properties);
  return properties;
}
