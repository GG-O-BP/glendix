// JS 객체 생성, 조작, 메서드 호출

import gleam/dynamic.{type Dynamic}

/// 키-값 쌍 리스트로 JS 객체 생성
@external(javascript, "./object_ffi.mjs", "create_object")
pub fn object(entries: List(#(String, Dynamic))) -> Dynamic

/// 빈 JS 객체 생성
@external(javascript, "./object_ffi.mjs", "empty_object")
pub fn empty() -> Dynamic

/// 객체 속성 읽기
@external(javascript, "./object_ffi.mjs", "get_property")
pub fn get(obj: Dynamic, key: String) -> Dynamic

/// 객체 속성 설정 (mutation, 원본 반환)
@external(javascript, "./object_ffi.mjs", "set_property")
pub fn set(obj: Dynamic, key: String, value: Dynamic) -> Dynamic

/// 객체 속성 삭제 (mutation, 원본 반환)
@external(javascript, "./object_ffi.mjs", "delete_property")
pub fn delete(obj: Dynamic, key: String) -> Dynamic

/// 속성 존재 확인
@external(javascript, "./object_ffi.mjs", "has_property")
pub fn has(obj: Dynamic, key: String) -> Bool

/// 메서드 호출 (인자 리스트)
@external(javascript, "./object_ffi.mjs", "call_method")
pub fn call_method(
  obj: Dynamic,
  method: String,
  args: List(Dynamic),
) -> Dynamic

/// 인자 없는 메서드 호출
@external(javascript, "./object_ffi.mjs", "call_method_0")
pub fn call_method_0(obj: Dynamic, method: String) -> Dynamic

/// new 연산자로 인스턴스 생성
@external(javascript, "./object_ffi.mjs", "new_instance")
pub fn new_instance(constructor: Dynamic, args: List(Dynamic)) -> Dynamic