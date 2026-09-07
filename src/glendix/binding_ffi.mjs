import { Ok, Error as GleamError } from "../gleam.mjs";
import { createElement } from "react";

export function get_module(name) {
  return new GleamError(
    `바인딩이 생성되지 않았습니다. 'gleam run -m glendix/install'을 실행하세요. (요청 모듈: ${name})`,
  );
}
export function resolve(mod, name) {
  const value = mod?.exports?.[name];
  if (value !== undefined) return new Ok(value);
  return new GleamError(
    `바인딩이 생성되지 않았습니다. 'gleam run -m glendix/install'을 실행하세요. (요청 컴포넌트: ${name})`,
  );
}

export function module_name(mod) {
  return mod.name;
}

export function initialization_export_name(mod) {
  return mod.initialization?.exportName ?? "";
}

export function initialization_retry_policy(mod) {
  return mod.initialization?.retry ?? "never";
}

export function initialize_module(mod) {
  const initialization = mod.initialization;
  if (!initialization) {
    return new GleamError(
      `Module does not require asynchronous initialization: ${mod.name}`,
    );
  }
  try {
    const promise = initialization.run();
    if (!promise || typeof promise.then !== "function") {
      return new GleamError(
        `Initializer must return a Promise: ${initialization.exportName}`,
      );
    }
    return new Ok(promise);
  } catch (error) {
    return new GleamError(error);
  }
}

function toProps(attributes) {
  const props = {};
  const classNames = [];
  for (const attribute of attributes.toArray()) {
    if (attribute.key === "none_") continue;
    if (attribute.key === "className") {
      classNames.push(attribute.content);
    } else {
      props[attribute.key] = attribute.content;
    }
  }
  if (classNames.length > 0) props.className = classNames.join(" ");
  return props;
}

export function component_element(component, attributes, children) {
  return createElement(component, toProps(attributes), ...children.toArray());
}

export function component_element_without_attributes(component, children) {
  return createElement(component, null, ...children.toArray());
}

export function void_component_element(component, attributes) {
  return createElement(component, toProps(attributes));
}

export function binding_error_message(error) {
  return error instanceof globalThis.Error ? error.message : String(error);
}
