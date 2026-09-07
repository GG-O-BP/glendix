export function object_json(object) {
  return JSON.stringify(object);
}

export function proto_key_is_safe_data(object) {
  const property = Object.getOwnPropertyDescriptor(object, "__proto__");
  return (
    Object.getPrototypeOf(object) === Object.prototype &&
    property !== undefined &&
    property.value === "safe" &&
    property.enumerable === true &&
    property.writable === true &&
    property.configurable === true
  );
}

export function has_default_prototype(object) {
  return Object.getPrototypeOf(object) === Object.prototype;
}
