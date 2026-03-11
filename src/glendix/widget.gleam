//// .mpk 위젯 컴포넌트 바인딩
//// widgets/ 디렉토리의 Mendix 위젯을 React 컴포넌트로 사용한다.
//// gleam run -m glendix/install 실행 시 바인딩이 자동 생성된다.
////
//// ```gleam
//// import glendix/widget
//// import glendix/react
//// import glendix/react/attribute
////
//// let switch_comp = widget.component("Switch")
//// react.component_el(switch_comp, [
////   attribute.attribute("booleanAttribute", my_editable_value),
////   attribute.attribute("action", my_action),
//// ], [])
//// ```

import glendix/react.{type Component}

/// .mpk 위젯의 React 컴포넌트를 가져온다
@external(javascript, "./widget_ffi.mjs", "get_widget")
pub fn component(name: String) -> Component
