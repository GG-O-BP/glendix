// Lustre 브릿지 — Lustre 생태계를 React(redraw) 안에서 사용한다

import lustre/effect.{type Effect}
import lustre/element.{type Element as LustreElement}
import redraw.{type Element}

/// Lustre Element를 React Element로 변환한다
@external(javascript, "./lustre_ffi.mjs", "render")
pub fn render(element: LustreElement(msg), dispatch: fn(msg) -> Nil) -> Element

/// TEA 패턴 훅 — useReducer + Effect 실행
@external(javascript, "./lustre_ffi.mjs", "use_tea")
pub fn use_tea(
  init: #(model, Effect(msg)),
  update: fn(model, msg) -> #(model, Effect(msg)),
  view: fn(model) -> LustreElement(msg),
) -> Element

/// Simple TEA 훅 — Effect 없는 간단한 상태 관리
@external(javascript, "./lustre_ffi.mjs", "use_simple")
pub fn use_simple(
  init: model,
  update: fn(model, msg) -> model,
  view: fn(model) -> LustreElement(msg),
) -> Element

/// redraw Element를 lustre 트리 안에 삽입한다
/// lustre view 내에서 redraw 컴포넌트를 사용할 때 호출한다
@external(javascript, "./lustre_ffi.mjs", "embed")
pub fn embed(element: Element) -> LustreElement(msg)
