// Promise FFI
//
// Only the adapters that `gleam/javascript/promise` cannot express are kept
// here. Every other Promise operation delegates to that package from
// `promise.gleam`.

// Rejected-Promise construction: the package has no rejection constructor, and
// the reason must surface as a JavaScript `Error`, not a plain string.
export function promise_reject(reason) {
  return Promise.reject(new Error(reason));
}

// Promise-returning recovery: the callback returns another Promise, and native
// `catch` flattening keeps the result a single-layer Promise of the value.
export function promise_catch(promise, callback) {
  return promise.catch(callback);
}
