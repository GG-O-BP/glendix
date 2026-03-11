// React Hooks FFI 어댑터
import * as React from "react";

// === useState ===

export function use_state(initial) {
  return React.useState(initial);
}

export function use_state_updater(initial) {
  const [state, setState] = React.useState(initial);
  return [state, (updater) => setState(updater)];
}

// === useEffect ===

export function use_effect(effect_fn, deps) {
  React.useEffect(effect_fn, deps.toArray());
}

export function use_effect_always(effect_fn) {
  React.useEffect(effect_fn);
}

export function use_effect_once(effect_fn) {
  React.useEffect(effect_fn, []);
}

// === useLayoutEffect ===

export function use_layout_effect(effect_fn, deps) {
  React.useLayoutEffect(effect_fn, deps.toArray());
}

export function use_layout_effect_always(effect_fn) {
  React.useLayoutEffect(effect_fn);
}

export function use_layout_effect_once(effect_fn) {
  React.useLayoutEffect(effect_fn, []);
}

// === useInsertionEffect ===

export function use_insertion_effect(effect_fn, deps) {
  React.useInsertionEffect(effect_fn, deps.toArray());
}

export function use_insertion_effect_always(effect_fn) {
  React.useInsertionEffect(effect_fn);
}

export function use_insertion_effect_once(effect_fn) {
  React.useInsertionEffect(effect_fn, []);
}

// === useMemo / useCallback ===

export function use_memo(compute_fn, deps) {
  return React.useMemo(compute_fn, deps.toArray());
}

export function use_callback(callback, deps) {
  return React.useCallback(callback, deps.toArray());
}

// === useRef ===

export function use_ref(initial) {
  return React.useRef(initial);
}

export function get_ref_current(ref) {
  return ref.current;
}

export function set_ref_current(ref, value) {
  ref.current = value;
}

// === useReducer ===

export function use_reducer(reducer, initial) {
  return React.useReducer(reducer, initial);
}

// === useContext ===

export function use_context(context) {
  return React.useContext(context);
}

// === useId ===

export function use_id() {
  return React.useId();
}

// === useTransition ===

export function use_transition() {
  return React.useTransition();
}

// === useDeferredValue ===

export function use_deferred_value(value) {
  return React.useDeferredValue(value);
}

// === useOptimistic (React 19) ===

export function use_optimistic(state) {
  return React.useOptimistic(state);
}

// === useImperativeHandle ===

export function use_imperative_handle(ref, create, deps) {
  React.useImperativeHandle(ref, create, deps.toArray());
}

// === useState (지연 초기화) ===

export function use_lazy_state(init_fn) {
  return React.useState(init_fn);
}

export function use_lazy_state_updater(init_fn) {
  const [state, setState] = React.useState(init_fn);
  return [state, (updater) => setState(updater)];
}

// === useSyncExternalStore ===

export function use_sync_external_store(subscribe, get_snapshot) {
  return React.useSyncExternalStore(subscribe, get_snapshot);
}

// === useDebugValue ===

export function use_debug_value(value) {
  React.useDebugValue(value);
}

export function use_debug_value_format(value, format) {
  React.useDebugValue(value, format);
}

// === useOptimistic (리듀서 변형) ===

export function use_optimistic_with_update(state, update_fn) {
  return React.useOptimistic(state, update_fn);
}
