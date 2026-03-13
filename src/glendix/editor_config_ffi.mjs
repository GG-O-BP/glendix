// Editor Configuration 헬퍼 FFI — @mendix/pluggable-widgets-tools 래핑
// mendix_ffi.mjs에서 분리: widget 런타임 번들에 포함되지 않도록 격리
//
// 주의: Studio Pro는 Jint(.NET JS 엔진)로 editorConfig를 실행한다.
// Gleam List 런타임(WeakMap, Symbol.iterator, class inheritance)이 Jint 비호환이므로
// 이 모듈의 모든 함수는 Gleam List를 사용하지 않는다.
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

// 콤마 구분 String → hidePropertyIn 반복 호출
export function hide_properties_in(properties, csv_keys) {
  var keys = csv_keys.split(",");
  for (var i = 0; i < keys.length; i++) {
    var trimmed = keys[i].trim();
    if (trimmed) hidePropertyIn(properties, {}, trimmed);
  }
  return properties;
}

// 콤마 구분 String → 중첩 속성 hidePropertyIn 반복 호출
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
