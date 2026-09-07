export function create_object(entries) {
  // Object.fromEntries defines every key as an own data property. In
  // particular, "__proto__" remains ordinary user data instead of invoking
  // Object.prototype's legacy prototype setter.
  return Object.fromEntries(entries.toArray());
}
export function empty_object() {
  return {};
}
export function get_property(obj, key) {
  return obj[key];
}
export function set_property(obj, key, value) {
  obj[key] = value;
  return obj;
}
export function delete_property(obj, key) {
  delete obj[key];
  return obj;
}
export function has_property(obj, key) {
  return key in obj;
}
export function call_method(obj, method, args) {
  return obj[method](...args.toArray());
}
export function call_method_0(obj, method) {
  return obj[method]();
}
export function new_instance(constructor, args) {
  return new constructor(...args.toArray());
}
export function identity(value) {
  return value;
}
