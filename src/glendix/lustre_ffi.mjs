// Lustre Element/Attribute → React Element 변환 FFI
import { createElement, Fragment, useReducer, useEffect, useRef } from "react";

// HTML 속성명 → React prop명 매핑
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

// Lustre Attribute 리스트 → React props 객체
function convertAttrs(attrsList, dispatch) {
  const props = {};
  const classNames = [];

  for (const attr of attrsList.toArray()) {
    const ctor = attr.constructor?.name;

    if (ctor === "Attribute" || ctor === "Property") {
      const name = attr.name;
      const value = attr.value;

      if (name === "class") {
        if (value) classNames.push(value);
      } else if (name === "style" && value && typeof value.toArray === "function") {
        // Lustre style: List(#(String, String)) → React style 객체
        const styleObj = {};
        for (const pair of value.toArray()) {
          styleObj[camelize(pair[0])] = pair[1];
        }
        props.style = styleObj;
      } else {
        props[ATTR_MAP[name] || name] = value;
      }
    } else if (ctor === "Event") {
      // Lustre event name: "click" → React: "onClick"
      const eventName = attr.name.startsWith("on") ? attr.name.slice(2) : attr.name;
      const reactKey =
        "on" + eventName.charAt(0).toUpperCase() + eventName.slice(1);

      props[reactKey] = (event) => {
        // always (kind=2): 디코딩 결과와 무관하게 호출
        if (attr.prevent_default.kind === 2) event.preventDefault();
        if (attr.stop_propagation.kind === 2) event.stopPropagation();

        // handler는 Decoder(Handler(msg)) — Handler를 반환
        const decoded = attr.handler.function(event);
        if (!decoded[1].head) {
          const handler = decoded[0];
          // possible (kind=1): Handler의 boolean에 따라 결정
          if (attr.prevent_default.kind === 1 && handler.prevent_default) {
            event.preventDefault();
          }
          if (attr.stop_propagation.kind === 1 && handler.stop_propagation) {
            event.stopPropagation();
          }
          dispatch(handler.message);
        }
      };
    }
  }

  if (classNames.length > 0) props.className = classNames.join(" ");
  return props;
}

// redraw Element를 lustre 트리에 삽입하기 위한 마커
const REACT_EMBED = Symbol.for("glendix.react_embed");

export function embed(react_element) {
  return { [REACT_EMBED]: true, element: react_element };
}

// Lustre Element → React Element 재귀 변환
function convert(el, dispatch) {
  if (el == null) return null;
  if (typeof el === "string") return el;

  // 삽입된 redraw Element는 그대로 통과
  if (el[REACT_EMBED]) return el.element;

  const name = el.constructor?.name;

  switch (name) {
    case "Text":
      return el.content;

    case "Map": {
      const wrappedDispatch = (msg) => dispatch(el.mapper(msg));
      return convert(el.child, wrappedDispatch);
    }

    case "Element": {
      const props = convertAttrs(el.attributes, dispatch);
      if (el.key) props.key = el.key;
      const children = el.children.toArray().map((c) => convert(c, dispatch));
      return createElement(el.tag, props, ...children);
    }

    case "Fragment": {
      const children = el.children.toArray().map((c) => convert(c, dispatch));
      const fragmentProps = el.key ? { key: el.key } : null;
      return createElement(Fragment, fragmentProps, ...children);
    }

    case "UnsafeInnerHtml": {
      const props = convertAttrs(el.attributes, dispatch);
      if (el.key) props.key = el.key;
      props.dangerouslySetInnerHTML = { __html: el.inner_html };
      return createElement(el.tag, props);
    }

    case "Memo":
      return convert(el.view(), dispatch);

    default:
      return null;
  }
}

// Lustre Effect 실행
function runEffect(effect, dispatch) {
  const actions = {
    dispatch,
    emit: () => {},
    select: () => {},
    root: () => {},
    provide: () => {},
  };
  for (const fn of effect.synchronous.toArray()) fn(actions);
  for (const fn of effect.before_paint.toArray()) fn(actions);
  for (const fn of effect.after_paint.toArray()) fn(actions);
}

// Lustre Element를 React Element로 렌더링
export function render(element, dispatch) {
  return convert(element, dispatch);
}

// TEA 패턴 → useReducer + useEffect
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

  useEffect(() => {
    const effect = effectRef.current;
    effectRef.current = null;
    if (effect) {
      runEffect(effect, dispatch);
    }
  });

  return convert(view(model), dispatch);
}

// Simple TEA → useReducer (Effect 없음)
export function use_simple(init, update, view) {
  const [model, dispatch] = useReducer(
    (model, msg) => update(model, msg),
    init,
  );

  return convert(view(model), dispatch);
}
