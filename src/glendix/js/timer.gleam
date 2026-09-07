//// Provides typed JavaScript timer handles backed by Plinth.
////
//// Glendix's established timer handle stays public through identity adapters
//// so callers retain the original platform handle at the JavaScript boundary.
////

import plinth/javascript/global

/// Represents a JavaScript timer handle.
pub type TimerId

/// Starts a one-shot timer.
pub fn set_timeout(
  callback callback: fn() -> Nil,
  after milliseconds: Int,
) -> TimerId {
  global.set_timeout(milliseconds, callback)
  |> from_plinth_timer
}

/// Cancels a one-shot timer.
pub fn clear_timeout(timer timer: TimerId) -> Nil {
  global.clear_timeout(to_plinth_timer(timer))
}

/// Starts a repeating timer.
pub fn set_interval(
  callback callback: fn() -> Nil,
  every milliseconds: Int,
) -> TimerId {
  global.set_interval(milliseconds, callback)
  |> from_plinth_timer
}

/// Cancels a repeating timer.
pub fn clear_interval(timer timer: TimerId) -> Nil {
  global.clear_interval(to_plinth_timer(timer))
}

// -- FFI --
@external(javascript, "./timer_ffi.mjs", "identity")
fn from_plinth_timer(timer: global.TimerID) -> TimerId

@external(javascript, "./timer_ffi.mjs", "identity")
fn to_plinth_timer(timer: TimerId) -> global.TimerID
