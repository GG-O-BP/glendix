export function get_property(object, key) {
  return object[key];
}
export function set_property(object, key, value) {
  object[key] = value;
  return object;
}
export function delete_property(object, key) {
  delete object[key];
  return object;
}
export function has_property(object, key) {
  return key in object;
}
export function call_method(object, method, args) {
  return object[method](...args.toArray());
}
export function call_method_0(object, method) {
  return object[method]();
}
export function new_instance(constructor, args) {
  return new constructor(...args.toArray());
}
