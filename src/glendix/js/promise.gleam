// Promise 유틸리티 — 체이닝, 에러 처리, 병렬 실행

import gleam/dynamic.{type Dynamic}
import gleam/javascript/promise.{type Promise}

/// 값을 즉시 이행된 Promise로 래핑
@external(javascript, "./promise_ffi.mjs", "promise_resolve")
pub fn resolve(value: a) -> Promise(a)

/// 거부된 Promise 생성
@external(javascript, "./promise_ffi.mjs", "promise_reject")
pub fn reject(reason: String) -> Promise(a)

/// Promise 체이닝 (flatMap)
@external(javascript, "./promise_ffi.mjs", "promise_then")
pub fn then_(
  promise: Promise(a),
  callback: fn(a) -> Promise(b),
) -> Promise(b)

/// Promise 에러 처리
@external(javascript, "./promise_ffi.mjs", "promise_catch")
pub fn catch_(
  promise: Promise(a),
  callback: fn(Dynamic) -> Promise(a),
) -> Promise(a)

/// Promise 값 변환 (map)
@external(javascript, "./promise_ffi.mjs", "promise_map")
pub fn map(promise: Promise(a), callback: fn(a) -> b) -> Promise(b)

/// 모든 Promise가 이행될 때까지 대기
@external(javascript, "./promise_ffi.mjs", "promise_all")
pub fn all(promises: List(Promise(a))) -> Promise(List(a))

/// 가장 먼저 이행/거부되는 Promise 반환
@external(javascript, "./promise_ffi.mjs", "promise_race")
pub fn race(promises: List(Promise(a))) -> Promise(a)

/// Promise 이행 시 콜백 실행 (반환값 무시)
@external(javascript, "./promise_ffi.mjs", "promise_await")
pub fn await_(promise: Promise(a), callback: fn(a) -> Nil) -> Nil
