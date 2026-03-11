// React 핵심 타입 + createElement + fragment/text/none

import gleam/dynamic.{type Dynamic}
import gleam/option.{type Option, None, Some}

// === Opaque 타입 ===

/// React가 렌더링하는 요소
pub type ReactElement

/// Mendix가 전달하는 props 객체
pub type JsProps

/// React 컴포넌트 참조
pub type Component

/// React ref 객체
pub type Ref(a)

/// React Context 타입
pub type Context(a)

/// JS Promise 타입 (React.use()와 함께 사용)
pub type Promise(a)

// === 요소 생성 (Attribute 리스트 기반) ===

/// 속성 리스트 기반 HTML 요소 생성
@external(javascript, "./react_ffi.mjs", "create_element_attrs")
pub fn element(
  tag: String,
  attrs: List(a),
  children: List(ReactElement),
) -> ReactElement

/// 속성 없이 자식만으로 요소 생성
@external(javascript, "./react_ffi.mjs", "create_element_no_props")
pub fn element_(tag: String, children: List(ReactElement)) -> ReactElement

/// self-closing 요소 (input, img, br 등)
@external(javascript, "./react_ffi.mjs", "create_void_attrs")
pub fn void_element(tag: String, attrs: List(a)) -> ReactElement

/// 속성 리스트 기반 React 컴포넌트 합성
@external(javascript, "./react_ffi.mjs", "create_component_attrs")
pub fn component_el(
  comp: Component,
  attrs: List(a),
  children: List(ReactElement),
) -> ReactElement

/// 속성 없이 자식만으로 컴포넌트 요소 생성
@external(javascript, "./react_ffi.mjs", "create_component_no_props")
pub fn component_el_(
  comp: Component,
  children: List(ReactElement),
) -> ReactElement

/// self-closing 컴포넌트 (children 없음)
@external(javascript, "./react_ffi.mjs", "create_component_void")
pub fn void_component_el(comp: Component, attrs: List(a)) -> ReactElement

// === Fragment / null / text ===

/// Fragment로 여러 자식을 감싸기
@external(javascript, "./react_ffi.mjs", "fragment")
pub fn fragment(children: List(ReactElement)) -> ReactElement

/// key가 있는 Fragment
@external(javascript, "./react_ffi.mjs", "keyed_fragment")
pub fn keyed_fragment(key: String, children: List(ReactElement)) -> ReactElement

/// 임의 부모 요소에 keyed children 전달
/// parent 함수에 key가 적용된 자식 리스트를 전달한다
pub fn keyed(
  parent: fn(List(ReactElement)) -> ReactElement,
  content: List(#(String, ReactElement)),
) -> ReactElement {
  parent(apply_keys(content))
}

@external(javascript, "./react_ffi.mjs", "apply_keys")
fn apply_keys(content: List(#(String, ReactElement))) -> List(ReactElement)

/// null 렌더링 (아무것도 표시하지 않음)
@external(javascript, "./react_ffi.mjs", "null_element")
pub fn none() -> ReactElement

/// 텍스트 노드
@external(javascript, "./react_ffi.mjs", "text")
pub fn text(content: String) -> ReactElement

// === Context API ===

/// Context 생성
@external(javascript, "./react_ffi.mjs", "create_context")
pub fn create_context(default: a) -> Context(a)

/// Provider 요소 생성
@external(javascript, "./react_ffi.mjs", "context_provider")
pub fn provider(
  context: Context(a),
  value: a,
  children: List(ReactElement),
) -> ReactElement

// === 컴포넌트 정의 ===

/// 이름 있는 React 컴포넌트 정의 (DevTools 표시, React.memo 가능)
@external(javascript, "./react_ffi.mjs", "define_component")
pub fn define_component(
  name: String,
  render: fn(props) -> ReactElement,
) -> Component

/// React.memo 적용 (props 동일 시 리렌더 방지)
@external(javascript, "./react_ffi.mjs", "memo_component")
pub fn memo(component: Component) -> Component

// === 순수 Gleam 헬퍼 ===

/// Bool 기반 조건부 렌더링
pub fn when(condition: Bool, element_fn: fn() -> ReactElement) -> ReactElement {
  case condition {
    True -> element_fn()
    False -> none()
  }
}

/// Option 기반 조건부 렌더링
pub fn when_some(
  option: Option(a),
  render_fn: fn(a) -> ReactElement,
) -> ReactElement {
  case option {
    Some(value) -> render_fn(value)
    None -> none()
  }
}

// === 고급 컴포넌트 ===

/// React.StrictMode (개발 모드 이중 렌더링 감지)
@external(javascript, "./react_ffi.mjs", "strict_mode")
pub fn strict_mode(children: List(ReactElement)) -> ReactElement

/// React.Suspense (비동기 경계)
@external(javascript, "./react_ffi.mjs", "suspense")
pub fn suspense(
  fallback: ReactElement,
  children: List(ReactElement),
) -> ReactElement

/// React.Profiler (렌더링 성능 측정)
@external(javascript, "./react_ffi.mjs", "profiler")
pub fn profiler(
  id: String,
  on_render: fn(String, String, Float, Float, Float, Float) -> Nil,
  children: List(ReactElement),
) -> ReactElement

/// ReactDOM.createPortal (모달/팝업 — 위젯 DOM 외부에 렌더링)
@external(javascript, "./react_ffi.mjs", "portal")
pub fn portal(element: ReactElement, container: Dynamic) -> ReactElement

/// React.forwardRef (부모 ref 전달)
@external(javascript, "./react_ffi.mjs", "forward_ref")
pub fn forward_ref(render: fn(props, Ref(a)) -> ReactElement) -> Component

/// React.memo 커스텀 비교 함수 적용
@external(javascript, "./react_ffi.mjs", "memo_custom")
pub fn memo_(component: Component, are_equal: fn(a, a) -> Bool) -> Component

/// React.startTransition (훅 없이 독립 함수로 사용)
@external(javascript, "./react_ffi.mjs", "start_transition")
pub fn start_transition(callback: fn() -> Nil) -> Nil

/// ReactDOM.flushSync — 동기 DOM 업데이트 강제 (상태 변경 후 DOM 측정 시 필요)
@external(javascript, "./react_ffi.mjs", "flush_sync")
pub fn flush_sync(callback: fn() -> Nil) -> Nil
