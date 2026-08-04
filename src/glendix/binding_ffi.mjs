import { Ok, Error as GleamError } from "../gleam.mjs";
import { createElement } from "react";

export function get_module(name) {
  return new GleamError(
    `바인딩이 생성되지 않았습니다. 'gleam run -m glendix/install'을 실행하세요. (요청 모듈: ${name})`,
  );
}
export function resolve(_mod, name) {
  return new GleamError(
    `바인딩이 생성되지 않았습니다. 'gleam run -m glendix/install'을 실행하세요. (요청 컴포넌트: ${name})`,
  );
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
