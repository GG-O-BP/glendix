import {
  createElement,
  Fragment,
  useReducer,
  useEffect,
  useLayoutEffect,
  useRef,
} from "react";
import {
  attribute_kind,
  event_kind,
  property_kind,
} from "../../lustre/lustre/vdom/vattr.mjs";
import {
  element_kind,
  fragment_kind,
  map_kind,
  memo_kind,
  text_kind,
  unsafe_inner_html_kind,
} from "../../lustre/lustre/vdom/vnode.mjs";
const ATTR_MAP = {
  class: "className",
  for: "htmlFor",
  tabindex: "tabIndex",
  readonly: "readOnly",
  maxlength: "maxLength",
  minlength: "minLength",
  colspan: "colSpan",
  rowspan: "rowSpan",
  accesskey: "accessKey",
  contenteditable: "contentEditable",
  crossorigin: "crossOrigin",
  formaction: "formAction",
  novalidate: "noValidate",
  spellcheck: "spellCheck",
  autocomplete: "autoComplete",
  autofocus: "autoFocus",
  autoplay: "autoPlay",
};
function camelize(str) {
  return str.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
}
function parseStyleString(str) {
  const obj = {};
  for (const part of str.split(";")) {
    const trimmed = part.trim();
    if (!trimmed) continue;
    const colonIdx = trimmed.indexOf(":");
    if (colonIdx === -1) continue;
    const prop = trimmed.slice(0, colonIdx).trim();
    const val = trimmed.slice(colonIdx + 1).trim();
    if (prop && val) obj[camelize(prop)] = val;
  }
  return obj;
}
// -- Event Debounce/throttle --
const _eventState = new WeakMap();
function getEventState(dispatch) {
  if (!_eventState.has(dispatch)) _eventState.set(dispatch, {});
  return _eventState.get(dispatch);
}
function wrapDispatch(dispatch, debounceMs, throttleMs, eventName) {
  if (debounceMs <= 0 && throttleMs <= 0) return dispatch;
  const state = getEventState(dispatch);
  if (debounceMs > 0) {
    const key = "d_" + eventName;
    return function (msg) {
      clearTimeout(state[key]);
      state[key] = setTimeout(() => dispatch(msg), debounceMs);
    };
  }
  // throttle
  const key = "t_" + eventName;
  return function (msg) {
    const now = Date.now();
    if (!state[key] || now - state[key] >= throttleMs) {
      state[key] = now;
      dispatch(msg);
    }
  };
}
function convertAttrs(attrsList, dispatch) {
  const props = {};
  const classNames = [];
  for (const attr of attrsList.toArray()) {
    if (attr.kind === attribute_kind || attr.kind === property_kind) {
      const name = attr.name;
      const value = attr.value;
      if (name === "class") {
        if (value) classNames.push(value);
      } else if (name === "style" && value) {
        if (typeof value.toArray === "function") {
          const styleObj = {};
          for (const pair of value.toArray()) {
            styleObj[camelize(pair[0])] = pair[1];
          }
          props.style = styleObj;
        } else if (typeof value === "string") {
          props.style = parseStyleString(value);
        } else {
          props.style = value;
        }
      } else {
        props[ATTR_MAP[name] || name] = value;
      }
    } else if (attr.kind === event_kind) {
      // Lustre event name: "click" → React: "onClick"
      const eventName = attr.name.startsWith("on")
        ? attr.name.slice(2)
        : attr.name;
      const reactKey =
        "on" + eventName.charAt(0).toUpperCase() + eventName.slice(1);
      const wrappedDispatch = wrapDispatch(
        dispatch,
        attr.debounce || 0,
        attr.throttle || 0,
        attr.name,
      );
      props[reactKey] = (event) => {
        if (attr.prevent_default.kind === 2) event.preventDefault();
        if (attr.stop_propagation.kind === 2) event.stopPropagation();
        const decoded = attr.handler.function(event);
        if (!decoded[1].head) {
          const handler = decoded[0];
          if (attr.prevent_default.kind === 1 && handler.prevent_default) {
            event.preventDefault();
          }
          if (attr.stop_propagation.kind === 1 && handler.stop_propagation) {
            event.stopPropagation();
          }
          wrappedDispatch(handler.message);
        }
      };
    }
  }
  if (classNames.length > 0) props.className = classNames.join(" ");
  return props;
}
const REACT_EMBED = Symbol.for("glendix.react_embed");
export function embed(react_element) {
  return { [REACT_EMBED]: true, element: react_element };
}
function convert(el, dispatch) {
  if (el == null) return null;
  if (typeof el === "string") return el;
  if (el[REACT_EMBED]) return el.element;
  switch (el.kind) {
    case text_kind:
      return el.content;
    case map_kind: {
      const wrappedDispatch = (msg) => dispatch(el.mapper(msg));
      return convert(el.child, wrappedDispatch);
    }
    case element_kind: {
      const props = convertAttrs(el.attributes, dispatch);
      if (el.key) props.key = el.key;
      const children = el.children
        .toArray()
        .map((c) => convert(c, dispatch));
      return createElement(el.tag, props, ...children);
    }
    case fragment_kind: {
      const children = el.children
        .toArray()
        .map((c) => convert(c, dispatch));
      const fragmentProps = el.key ? { key: el.key } : null;
      return createElement(Fragment, fragmentProps, ...children);
    }
    case unsafe_inner_html_kind: {
      const props = convertAttrs(el.attributes, dispatch);
      if (el.key) props.key = el.key;
      props.dangerouslySetInnerHTML = { __html: el.inner_html };
      return createElement(el.tag, props);
    }
    case memo_kind:
      return convert(el.view(), dispatch);
    default:
      return null;
  }
}
// -- Effect --
function makeActions(dispatch) {
  return {
    dispatch,
    emit: () => {},
    select: () => {},
    root: () => {},
    provide: () => {},
  };
}
export function render(element, dispatch) {
  return convert(element, dispatch);
}
export function use_tea(init, update, view) {
  const effectRef = useRef(init[1]);
  const [model, dispatch] = useReducer(
    (model, msg) => {
      const result = update(model, msg);
      effectRef.current = result[1];
      return result[0];
    },
    init[0],
  );
  useLayoutEffect(() => {
    const effect = effectRef.current;
    if (!effect) return;
    const actions = makeActions(dispatch);
    for (const fn of effect.synchronous.toArray()) fn(actions);
    for (const fn of effect.before_paint.toArray()) fn(actions);
  });
  useEffect(() => {
    const effect = effectRef.current;
    effectRef.current = null;
    if (!effect) return;
    const actions = makeActions(dispatch);
    for (const fn of effect.after_paint.toArray()) fn(actions);
  });
  return convert(view(model), dispatch);
}
export function use_simple(init, update, view) {
  const [model, dispatch] = useReducer(
    (model, msg) => update(model, msg),
    init,
  );
  return convert(view(model), dispatch);
}
