export function create_object(entries) {
  const obj = {};
  for (const pair of entries.toArray()) {
    obj[pair[0]] = pair[1];
  }
  return obj;
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
