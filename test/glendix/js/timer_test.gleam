//// Exercises the public timer API against the JavaScript global timer queue.
////

import gleam/javascript/promise
import gleeunit/should
import glendix/js/timer

/// Verifies a one-shot timer invokes its callback exactly once.
pub fn timeout_callback_runs_once_test() -> promise.Promise(Nil) {
  let counter = new_counter()
  let timer_id =
    timer.set_timeout(callback: fn() { increment_counter(counter) }, after: 0)

  promise.wait(20)
  |> promise.map(fn(_) {
    case timer_handle_is_defined(timer_id) {
      True -> counter_value(counter) |> should.equal(1)
      False -> should.fail()
    }
  })
}

/// Verifies clearing a one-shot timer prevents its callback.
pub fn clear_timeout_prevents_callback_test() -> promise.Promise(Nil) {
  let counter = new_counter()
  let timer_id =
    timer.set_timeout(callback: fn() { increment_counter(counter) }, after: 10)
  timer.clear_timeout(timer_id)

  promise.wait(30)
  |> promise.map(fn(_) { counter_value(counter) |> should.equal(0) })
}

/// Verifies an interval repeats and clearing it prevents later callbacks.
pub fn clear_interval_stops_repeating_callback_test() -> promise.Promise(Nil) {
  let counter = new_counter()
  let timer_id =
    timer.set_interval(callback: fn() { increment_counter(counter) }, every: 1)

  use _ <- promise.await(promise.wait(20))
  timer.clear_interval(timer_id)
  let count_after_clear = counter_value(counter)
  promise.wait(20)
  |> promise.map(fn(_) {
    case count_after_clear > 0 {
      True ->
        counter_value(counter)
        |> should.equal(count_after_clear)
      False -> should.fail()
    }
  })
}

type Counter

// -- FFI --
@external(javascript, "./timer_test_ffi.mjs", "new_counter")
fn new_counter() -> Counter

@external(javascript, "./timer_test_ffi.mjs", "increment_counter")
fn increment_counter(counter: Counter) -> Nil

@external(javascript, "./timer_test_ffi.mjs", "counter_value")
fn counter_value(counter: Counter) -> Int

@external(javascript, "./timer_test_ffi.mjs", "timer_handle_is_defined")
fn timer_handle_is_defined(timer_id: timer.TimerId) -> Bool
