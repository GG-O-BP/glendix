// Editor Configuration 헬퍼 FFI — @mendix/pluggable-widgets-tools 래핑
// mendix_ffi.mjs에서 분리: widget 런타임 번들에 포함되지 않도록 격리
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

export function hide_properties_in(properties, keys) {
  hidePropertiesIn(properties, {}, keys.toArray());
  return properties;
}

export function hide_nested_properties_in(properties, key, index, nested_keys) {
  hideNestedPropertiesIn(properties, {}, key, index, nested_keys.toArray());
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
