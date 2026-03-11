// React FFI 어댑터 - 요소 생성, Fragment, Context, 컴포넌트 정의, Props 읽기
import * as React from "react";
import * as ReactDOM from "react-dom";
import { toList } from "../gleam.mjs";
import { to_props } from "./react/attribute_ffi.mjs";

// === 요소 생성 (Attribute 리스트 기반) ===

// List(Attribute) → React.createElement
export function create_element_attrs(tag, attrs, children) {
  return React.createElement(tag, to_props(attrs), ...children.toArray());
}

// props 없이 자식만
export function create_element_no_props(tag, children) {
  return React.createElement(tag, null, ...children.toArray());
}

// self-closing 요소 (input, img, br 등)
export function create_void_attrs(tag, attrs) {
  return React.createElement(tag, to_props(attrs));
}

// React 컴포넌트 합성 (Attribute 리스트 기반)
export function create_component_attrs(component, attrs, children) {
  return React.createElement(component, to_props(attrs), ...children.toArray());
}

// props 없이 자식만
export function create_component_no_props(component, children) {
  return React.createElement(component, null, ...children.toArray());
}

// self-closing 컴포넌트 (children 없음)
export function create_component_void(component, attrs) {
  return React.createElement(component, to_props(attrs));
}

// === Fragment / null / text ===

export function fragment(children) {
  return React.createElement(React.Fragment, null, ...children.toArray());
}

export function keyed_fragment(key, children) {
  return React.createElement(React.Fragment, { key }, ...children.toArray());
}

export function null_element() {
  return null;
}

export function text(content) {
  return content;
}

// === Context API ===

export function create_context(default_value) {
  return React.createContext(default_value);
}

export function context_provider(context, value, children) {
  return React.createElement(
    context.Provider,
    { value },
    ...children.toArray(),
  );
}

// === 컴포넌트 정의 ===

export function define_component(name, render) {
  const Component = (props) => render(props);
  Component.displayName = name;
  return Component;
}

export function memo_component(comp) {
  return React.memo(comp);
}

// === 유틸리티 ===

export function list_to_array(gleam_list) {
  return gleam_list.toArray();
}

export function array_to_list(js_array) {
  return toList(js_array);
}

// === 고급 컴포넌트 ===

export function strict_mode(children) {
  return React.createElement(React.StrictMode, null, ...children.toArray());
}

export function suspense(fallback, children) {
  return React.createElement(
    React.Suspense,
    { fallback },
    ...children.toArray(),
  );
}

export function profiler(id, on_render, children) {
  return React.createElement(
    React.Profiler,
    { id, onRender: on_render },
    ...children.toArray(),
  );
}

export function portal(element, container) {
  return ReactDOM.createPortal(element, container);
}

export function forward_ref(render) {
  return React.forwardRef(render);
}

export function memo_custom(comp, are_equal) {
  return React.memo(comp, are_equal);
}

export function start_transition(callback) {
  React.startTransition(callback);
}

export function flush_sync(callback) {
  ReactDOM.flushSync(callback);
}
