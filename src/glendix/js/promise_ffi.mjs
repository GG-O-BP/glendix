// Promise FFI
import { toList } from "../../gleam.mjs";
export function promise_resolve(value) {
  return Promise.resolve(value);
}
export function promise_reject(reason) {
  return Promise.reject(new Error(reason));
}
export function promise_then(promise, callback) {
  return promise.then(callback);
}
export function promise_catch(promise, callback) {
  return promise.catch(callback);
}
export function promise_map(promise, callback) {
  return promise.then(callback);
}
export function promise_all(promises) {
  return Promise.all(promises.toArray()).then((results) => toList(results));
}
export function promise_race(promises) {
  return Promise.race(promises.toArray());
}
export function promise_await(promise, callback) {
  promise.then(callback);
}
