//// 외부 React 컴포넌트 바인딩 (FFI 없이 순수 Gleam으로 사용)
////
//// bindings.json에 등록된 라이브러리의 컴포넌트를 가져온다.
//// gleam run -m glendix/install 실행 시 바인딩이 자동 생성된다.
////
//// 사용 예:
//// ```gleam
//// import glendix/binding
//// import glendix/react.{type Component}
////
//// fn m() { binding.module("recharts") }
//// pub fn pie_chart() -> Component { binding.resolve(m(), "PieChart") }
//// ```

import glendix/react.{type Component}

/// 바인딩된 JS 모듈 네임스페이스
pub type JsModule

/// bindings.json에 등록된 모듈을 가져온다
@external(javascript, "./binding_ffi.mjs", "get_module")
pub fn module(name: String) -> JsModule

/// 모듈에서 이름으로 React 컴포넌트를 가져온다
@external(javascript, "./binding_ffi.mjs", "resolve")
pub fn resolve(module: JsModule, name: String) -> Component
