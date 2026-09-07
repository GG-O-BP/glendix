export function create_object(entries) {
  // Object.fromEntries defines every key as an own data property. In
  // particular, "__proto__" remains ordinary user data instead of invoking
  // Object.prototype's legacy prototype setter.
  return Object.fromEntries(entries.toArray());
}
export function empty_object() {
  return {};
}
export function identity(value) {
  return value;
}
