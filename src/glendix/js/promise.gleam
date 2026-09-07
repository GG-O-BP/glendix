//// Provides typed Promise composition at the JavaScript FFI boundary.
////
//// Compatible operations delegate to `gleam/javascript/promise` so their
//// behavior stays owned by that package. Only rejected-Promise construction
//// and Promise-returning recovery keep a minimal handwritten adapter, because
//// the package has no primitive that preserves their current contract.
////

import gleam/javascript/promise as javascript_promise

/// Represents a JavaScript Promise rejection reason.
pub type PromiseRejection

/// Creates an already fulfilled Promise.
pub fn resolve(value value: value) -> javascript_promise.Promise(value) {
  javascript_promise.resolve(value)
}

/// Creates a rejected Promise with an error message.
///
/// Keeps a custom adapter because `gleam/javascript/promise` exposes no
/// rejection constructor. The reason is wrapped in a JavaScript `Error`, which
/// is the contract callers depend on.
pub fn reject(reason reason: String) -> javascript_promise.Promise(value) {
  reject_raw(reason)
}

/// Chains a Promise-producing callback.
pub fn then_(
  promise promise: javascript_promise.Promise(value),
  with callback: fn(value) -> javascript_promise.Promise(next),
) -> javascript_promise.Promise(next) {
  javascript_promise.await(promise, callback)
}

/// Recovers from a Promise rejection.
///
/// Keeps a custom adapter because `gleam/javascript/promise.rescue` recovers
/// with a plain value, so it cannot preserve this helper's Promise-returning
/// recovery, its opaque `PromiseRejection` reason, or its automatic flattening.
pub fn catch_(
  promise promise: javascript_promise.Promise(value),
  with callback: fn(PromiseRejection) -> javascript_promise.Promise(value),
) -> javascript_promise.Promise(value) {
  catch_raw(promise, callback)
}

/// Maps a fulfilled Promise value.
pub fn map(
  promise promise: javascript_promise.Promise(value),
  with callback: fn(value) -> next,
) -> javascript_promise.Promise(next) {
  javascript_promise.map(promise, callback)
}

/// Waits for every Promise to fulfill, preserving input order.
pub fn all(
  promises promises: List(javascript_promise.Promise(value)),
) -> javascript_promise.Promise(List(value)) {
  javascript_promise.await_list(promises)
}

/// Resolves or rejects with the first completed Promise.
pub fn race(
  promises promises: List(javascript_promise.Promise(value)),
) -> javascript_promise.Promise(value) {
  javascript_promise.race_list(promises)
}

/// Runs a callback exactly once after a Promise fulfills without blocking.
pub fn await_(
  promise promise: javascript_promise.Promise(value),
  then callback: fn(value) -> Nil,
) -> Nil {
  javascript_promise.map(promise, callback)
  Nil
}

// -- FFI --
@external(javascript, "./promise_ffi.mjs", "promise_reject")
fn reject_raw(reason: String) -> javascript_promise.Promise(value)

@external(javascript, "./promise_ffi.mjs", "promise_catch")
fn catch_raw(
  promise: javascript_promise.Promise(value),
  callback: fn(PromiseRejection) -> javascript_promise.Promise(value),
) -> javascript_promise.Promise(value)
