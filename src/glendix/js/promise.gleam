//// Provides typed Promise composition at the JavaScript FFI boundary.
////

import gleam/javascript/promise

/// Represents a JavaScript Promise rejection reason.
pub type PromiseRejection

/// Creates an already fulfilled Promise.
pub fn resolve(value value: value) -> promise.Promise(value) {
  resolve_raw(value)
}

/// Creates a rejected Promise with an error message.
pub fn reject(reason reason: String) -> promise.Promise(value) {
  reject_raw(reason)
}

/// Chains a Promise-producing callback.
pub fn then_(
  promise promise: promise.Promise(value),
  with callback: fn(value) -> promise.Promise(next),
) -> promise.Promise(next) {
  then_raw(promise, callback)
}

/// Recovers from a Promise rejection.
pub fn catch_(
  promise promise: promise.Promise(value),
  with callback: fn(PromiseRejection) -> promise.Promise(value),
) -> promise.Promise(value) {
  catch_raw(promise, callback)
}

/// Maps a fulfilled Promise value.
pub fn map(
  promise promise: promise.Promise(value),
  with callback: fn(value) -> next,
) -> promise.Promise(next) {
  map_raw(promise, callback)
}

/// Waits for every Promise to fulfill.
pub fn all(
  promises promises: List(promise.Promise(value)),
) -> promise.Promise(List(value)) {
  all_raw(promises)
}

/// Resolves or rejects with the first completed Promise.
pub fn race(
  promises promises: List(promise.Promise(value)),
) -> promise.Promise(value) {
  race_raw(promises)
}

/// Runs a callback after a Promise fulfills.
pub fn await_(
  promise promise: promise.Promise(value),
  then callback: fn(value) -> Nil,
) -> Nil {
  await_raw(promise, callback)
}

// -- FFI --
@external(javascript, "./promise_ffi.mjs", "promise_resolve")
fn resolve_raw(value: value) -> promise.Promise(value)

@external(javascript, "./promise_ffi.mjs", "promise_reject")
fn reject_raw(reason: String) -> promise.Promise(value)

@external(javascript, "./promise_ffi.mjs", "promise_then")
fn then_raw(
  promise: promise.Promise(value),
  callback: fn(value) -> promise.Promise(next),
) -> promise.Promise(next)

@external(javascript, "./promise_ffi.mjs", "promise_catch")
fn catch_raw(
  promise: promise.Promise(value),
  callback: fn(PromiseRejection) -> promise.Promise(value),
) -> promise.Promise(value)

@external(javascript, "./promise_ffi.mjs", "promise_map")
fn map_raw(
  promise: promise.Promise(value),
  callback: fn(value) -> next,
) -> promise.Promise(next)

@external(javascript, "./promise_ffi.mjs", "promise_all")
fn all_raw(
  promises: List(promise.Promise(value)),
) -> promise.Promise(List(value))

@external(javascript, "./promise_ffi.mjs", "promise_race")
fn race_raw(promises: List(promise.Promise(value))) -> promise.Promise(value)

@external(javascript, "./promise_ffi.mjs", "promise_await")
fn await_raw(promise: promise.Promise(value), callback: fn(value) -> Nil) -> Nil
