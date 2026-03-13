//// Classic (Dojo 기반) Mendix 위젯을 React 내부에서 사용한다.
//// widgets/ 디렉토리의 Classic .mpk 위젯을 DOM 컨테이너에 임페러티브하게 마운트한다.
//// gleam run -m glendix/install 실행 시 바인딩이 자동 생성된다.
////
//// ```gleam
//// import gleam/dynamic
//// import glendix/classic
////
//// classic.render("CameraWidget.widget.CameraWidget", [
////   #("mfToExecute", dynamic.from(mf_value)),
////   #("preferRearCamera", dynamic.from(true)),
//// ])
//// ```

import gleam/dynamic.{type Dynamic}
import glendix/react.{type ReactElement}

/// Classic 위젯을 React 엘리먼트로 렌더링하는 편의 함수
/// DOM 컨테이너를 자동 생성하고, useEffect로 마운트/언마운트를 관리한다
@external(javascript, "./classic_ffi.mjs", "classic_widget_element")
pub fn render(
  widget_id: String,
  properties: List(#(String, Dynamic)),
) -> ReactElement

/// CSS 클래스를 지정하여 렌더링
@external(javascript, "./classic_ffi.mjs", "classic_widget_element_with_class")
pub fn render_with_class(
  widget_id: String,
  properties: List(#(String, Dynamic)),
  class_name: String,
) -> ReactElement
