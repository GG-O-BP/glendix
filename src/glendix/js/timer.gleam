//// Provides typed JavaScript timer handles.
////

/// Represents a JavaScript timer handle.
pub type TimerId

/// Starts a one-shot timer.
pub fn set_timeout(
  callback callback: fn() -> Nil,
  after milliseconds: Int,
) -> TimerId {
  set_timeout_raw(callback, milliseconds)
}

/// Cancels a one-shot timer.
pub fn clear_timeout(timer timer: TimerId) -> Nil {
  clear_timeout_raw(timer)
}

/// Starts a repeating timer.
pub fn set_interval(
  callback callback: fn() -> Nil,
  every milliseconds: Int,
) -> TimerId {
  set_interval_raw(callback, milliseconds)
}

/// Cancels a repeating timer.
pub fn clear_interval(timer timer: TimerId) -> Nil {
  clear_interval_raw(timer)
}

// -- FFI --
@external(javascript, "./timer_ffi.mjs", "set_timeout")
fn set_timeout_raw(callback: fn() -> Nil, milliseconds: Int) -> TimerId

@external(javascript, "./timer_ffi.mjs", "clear_timeout")
fn clear_timeout_raw(timer: TimerId) -> Nil

@external(javascript, "./timer_ffi.mjs", "set_interval")
fn set_interval_raw(callback: fn() -> Nil, milliseconds: Int) -> TimerId

@external(javascript, "./timer_ffi.mjs", "clear_interval")
fn clear_interval_raw(timer: TimerId) -> Nil
