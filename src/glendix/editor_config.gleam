// Editor Configuration 헬퍼 — @mendix/pluggable-widgets-tools 래핑
// 사용: editor_config.gleam에서 조건부 속성 숨기기, 탭 변환, 속성 순서 변경
//
// 주의: Studio Pro는 Jint(.NET JS 엔진)로 editorConfig를 실행한다.
// Gleam List 런타임(WeakMap, Symbol.iterator, class inheritance)이 Jint 비호환이므로
// 이 모듈의 모든 함수는 Gleam List를 사용하지 않는다.
// 여러 키를 전달할 때는 콤마 구분 String을 사용한다.

/// Mendix PropertyGroup 배열 (Studio Pro가 getProperties에 전달)
pub type Properties

/// 단일 속성을 숨긴다
@external(javascript, "./editor_config_ffi.mjs", "hide_property_in")
pub fn hide_property(properties: Properties, key: String) -> Properties

/// 여러 속성을 한 번에 숨긴다 (콤마 구분 String)
/// 예: hide_properties(props, "key1,key2,key3")
@external(javascript, "./editor_config_ffi.mjs", "hide_properties_in")
pub fn hide_properties(properties: Properties, keys: String) -> Properties

/// 중첩 속성을 숨긴다 (배열 타입 속성의 특정 인덱스 내부)
@external(javascript, "./editor_config_ffi.mjs", "hide_nested_property_in")
pub fn hide_nested_property(
  properties: Properties,
  key: String,
  index: Int,
  nested_key: String,
) -> Properties

/// 여러 중첩 속성을 한 번에 숨긴다 (콤마 구분 String)
/// 예: hide_nested_properties(props, "series", 0, "key1,key2")
@external(javascript, "./editor_config_ffi.mjs", "hide_nested_properties_in")
pub fn hide_nested_properties(
  properties: Properties,
  key: String,
  index: Int,
  nested_keys: String,
) -> Properties

/// 속성 그룹을 탭으로 변환한다 (웹 플랫폼용)
@external(javascript, "./editor_config_ffi.mjs", "transform_groups_into_tabs")
pub fn transform_groups_into_tabs(properties: Properties) -> Properties

/// 속성 순서를 변경한다
@external(javascript, "./editor_config_ffi.mjs", "move_property")
pub fn move_property(
  properties: Properties,
  from_index: Int,
  to_index: Int,
) -> Properties
