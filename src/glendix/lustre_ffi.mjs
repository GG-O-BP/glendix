// Lustre Element/Attribute → React Element 변환 FFI
import {
  createElement,
  Fragment,
  useReducer,
  useEffect,
  useLayoutEffect,
  useRef,
} from "react";

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

// ── Style 변환 ──

// Lustre style 문자열 "height:460px;width:300px;" → React style 객체
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

// ── Event debounce/throttle ──

// dispatch(useReducer에서 stable)를 키로 이벤트별 타이머 상태 보관
const _eventState = new WeakMap();

function getEventState(dispatch) {
  if (!_eventState.has(dispatch)) _eventState.set(dispatch, {});
  return _eventState.get(dispatch);
}

// Lustre Event의 debounce/throttle 필드에 따라 dispatch를 래핑
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

// ── Attribute 변환 ──

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
      } else if (name === "style" && value) {
        if (typeof value.toArray === "function") {
          // Gleam List(#(String, String)) → React style 객체
          const styleObj = {};
          for (const pair of value.toArray()) {
            styleObj[camelize(pair[0])] = pair[1];
          }
          props.style = styleObj;
        } else if (typeof value === "string") {
          props.style = parseStyleString(value);
        } else {
          // 이미 객체 (예: property("style", json.object([...])))
          props.style = value;
        }
      } else {
        props[ATTR_MAP[name] || name] = value;
      }
    } else if (ctor === "Event") {
      // Lustre event name: "click" → React: "onClick"
      const eventName = attr.name.startsWith("on")
        ? attr.name.slice(2)
        : attr.name;
      const reactKey =
        "on" + eventName.charAt(0).toUpperCase() + eventName.slice(1);

      // debounce/throttle: preventDefault/stopPropagation은 즉시, dispatch만 지연
      const wrappedDispatch = wrapDispatch(
        dispatch,
        attr.debounce || 0,
        attr.throttle || 0,
        attr.name,
      );

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
          wrappedDispatch(handler.message);
        }
      };
    }
  }

  if (classNames.length > 0) props.className = classNames.join(" ");
  return props;
}

// ── Element 변환 ──

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
      const children = el.children
        .toArray()
        .map((c) => convert(c, dispatch));
      return createElement(el.tag, props, ...children);
    }

    case "Fragment": {
      const children = el.children
        .toArray()
        .map((c) => convert(c, dispatch));
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

// ── Effect ──

// Lustre Effect Actions 생성
function makeActions(dispatch) {
  return {
    dispatch,
    emit: () => {},
    select: () => {},
    root: () => {},
    provide: () => {},
  };
}

// Lustre Element를 React Element로 렌더링
export function render(element, dispatch) {
  return convert(element, dispatch);
}

// TEA 패턴 → useReducer + useLayoutEffect/useEffect
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

  // synchronous + before_paint: DOM 변경 직후, 브라우저 페인트 전 실행
  useLayoutEffect(() => {
    const effect = effectRef.current;
    if (!effect) return;
    const actions = makeActions(dispatch);
    for (const fn of effect.synchronous.toArray()) fn(actions);
    for (const fn of effect.before_paint.toArray()) fn(actions);
  });

  // after_paint: 브라우저 페인트 후 실행
  useEffect(() => {
    const effect = effectRef.current;
    effectRef.current = null;
    if (!effect) return;
    const actions = makeActions(dispatch);
    for (const fn of effect.after_paint.toArray()) fn(actions);
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
