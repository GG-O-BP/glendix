export function new_counter() {
  return { value: 0 };
}

export function increment_counter(counter) {
  counter.value += 1;
}

export function counter_value(counter) {
  return counter.value;
}

export function timer_handle_is_defined(timerId) {
  return timerId !== null && timerId !== undefined;
}
