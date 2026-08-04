export function set_timeout(callback, ms) {
  return setTimeout(callback, ms);
}
export function clear_timeout(id) {
  clearTimeout(id);
}
export function set_interval(callback, ms) {
  return setInterval(callback, ms);
}
export function clear_interval(id) {
  clearInterval(id);
}
