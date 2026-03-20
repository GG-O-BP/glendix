//// 외부 React 컴포넌트 바인딩 (FFI 없이 순수 Gleam으로 사용)
////
//// gleam.toml [tools.glendix.bindings]에 등록된 라이브러리의 컴포넌트를 가져온다.
//// gleam run -m glendix/install 실행 시 바인딩이 자동 생성된다.
////
//// redraw/dom의 호출 패턴으로 래퍼를 작성하면 일관된 API를 제공할 수 있다:
//// ```gleam
//// import glendix/binding
//// import mendraw/interop
//// import redraw.{type Element}
//// import redraw/dom/attribute.{type Attribute}
////
//// fn m() { binding.module("recharts") }
////
//// // attrs + children 컴포넌트
//// pub fn pie_chart(attrs: List(Attribute), children: List(Element)) -> Element {
////   interop.component_el(binding.resolve(m(), "PieChart"), attrs, children)
//// }
////
//// // children만 받는 컴포넌트
//// pub fn pie_chart_(children: List(Element)) -> Element {
////   interop.component_el_(binding.resolve(m(), "PieChart"), children)
//// }
////
//// // children 없는 컴포넌트 (Cell, Tooltip 등)
//// pub fn cell(attrs: List(Attribute)) -> Element {
////   interop.void_component_el(binding.resolve(m(), "Cell"), attrs)
//// }
//// ```

import mendraw/interop.{type JsComponent}

/// 바인딩된 JS 모듈 네임스페이스
pub type JsModule

/// gleam.toml [tools.glendix.bindings]에 등록된 모듈을 가져온다
@external(javascript, "./binding_ffi.mjs", "get_module")
pub fn module(name: String) -> JsModule

/// 모듈에서 이름으로 React 컴포넌트를 가져온다
@external(javascript, "./binding_ffi.mjs", "resolve")
pub fn resolve(module: JsModule, name: String) -> JsComponent
