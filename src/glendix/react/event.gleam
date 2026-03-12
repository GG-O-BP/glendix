// React 이벤트 타입 + 핸들러 Attribute + 값 추출 함수

import gleam/dynamic.{type Dynamic}
import glendix/react/attribute.{type Attribute}

// === 이벤트 타입 (opaque) ===

pub type Event

pub type MouseEvent

pub type ChangeEvent

pub type KeyboardEvent

pub type FormEvent

pub type FocusEvent

pub type InputEvent

pub type PointerEvent

pub type DragEvent

pub type ClipboardEvent

pub type TouchEvent

pub type WheelEvent

pub type AnimationEvent

pub type TransitionEvent

pub type CompositionEvent

// === 이벤트 핸들러 (Attribute 반환) ===

/// 범용 이벤트 핸들러 (escape hatch)
pub fn on(event_name: String, handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute(event_name, handler)
}

// 마우스 이벤트
pub fn on_click(handler: fn(MouseEvent) -> Nil) -> Attribute {
  attribute.attribute("onClick", handler)
}

pub fn on_double_click(handler: fn(MouseEvent) -> Nil) -> Attribute {
  attribute.attribute("onDoubleClick", handler)
}

pub fn on_context_menu(handler: fn(MouseEvent) -> Nil) -> Attribute {
  attribute.attribute("onContextMenu", handler)
}

pub fn on_mouse_down(handler: fn(MouseEvent) -> Nil) -> Attribute {
  attribute.attribute("onMouseDown", handler)
}

pub fn on_mouse_up(handler: fn(MouseEvent) -> Nil) -> Attribute {
  attribute.attribute("onMouseUp", handler)
}

pub fn on_mouse_enter(handler: fn(MouseEvent) -> Nil) -> Attribute {
  attribute.attribute("onMouseEnter", handler)
}

pub fn on_mouse_leave(handler: fn(MouseEvent) -> Nil) -> Attribute {
  attribute.attribute("onMouseLeave", handler)
}

pub fn on_mouse_move(handler: fn(MouseEvent) -> Nil) -> Attribute {
  attribute.attribute("onMouseMove", handler)
}

pub fn on_mouse_over(handler: fn(MouseEvent) -> Nil) -> Attribute {
  attribute.attribute("onMouseOver", handler)
}

pub fn on_mouse_out(handler: fn(MouseEvent) -> Nil) -> Attribute {
  attribute.attribute("onMouseOut", handler)
}

// 보조 버튼 클릭 (가운데 버튼 등)
pub fn on_aux_click(handler: fn(MouseEvent) -> Nil) -> Attribute {
  attribute.attribute("onAuxClick", handler)
}

// 키보드 이벤트
pub fn on_key_down(handler: fn(KeyboardEvent) -> Nil) -> Attribute {
  attribute.attribute("onKeyDown", handler)
}

pub fn on_key_up(handler: fn(KeyboardEvent) -> Nil) -> Attribute {
  attribute.attribute("onKeyUp", handler)
}

// 폼/입력 이벤트
pub fn on_change(handler: fn(ChangeEvent) -> Nil) -> Attribute {
  attribute.attribute("onChange", handler)
}

pub fn on_input(handler: fn(InputEvent) -> Nil) -> Attribute {
  attribute.attribute("onInput", handler)
}

pub fn on_submit(handler: fn(FormEvent) -> Nil) -> Attribute {
  attribute.attribute("onSubmit", handler)
}

pub fn on_reset(handler: fn(FormEvent) -> Nil) -> Attribute {
  attribute.attribute("onReset", handler)
}

// 포커스 이벤트
pub fn on_focus(handler: fn(FocusEvent) -> Nil) -> Attribute {
  attribute.attribute("onFocus", handler)
}

pub fn on_blur(handler: fn(FocusEvent) -> Nil) -> Attribute {
  attribute.attribute("onBlur", handler)
}

// 포인터 이벤트
pub fn on_pointer_down(handler: fn(PointerEvent) -> Nil) -> Attribute {
  attribute.attribute("onPointerDown", handler)
}

pub fn on_pointer_up(handler: fn(PointerEvent) -> Nil) -> Attribute {
  attribute.attribute("onPointerUp", handler)
}

pub fn on_pointer_move(handler: fn(PointerEvent) -> Nil) -> Attribute {
  attribute.attribute("onPointerMove", handler)
}

pub fn on_pointer_enter(handler: fn(PointerEvent) -> Nil) -> Attribute {
  attribute.attribute("onPointerEnter", handler)
}

pub fn on_pointer_leave(handler: fn(PointerEvent) -> Nil) -> Attribute {
  attribute.attribute("onPointerLeave", handler)
}

pub fn on_pointer_over(handler: fn(PointerEvent) -> Nil) -> Attribute {
  attribute.attribute("onPointerOver", handler)
}

pub fn on_pointer_out(handler: fn(PointerEvent) -> Nil) -> Attribute {
  attribute.attribute("onPointerOut", handler)
}

pub fn on_pointer_cancel(handler: fn(PointerEvent) -> Nil) -> Attribute {
  attribute.attribute("onPointerCancel", handler)
}

pub fn on_got_pointer_capture(handler: fn(PointerEvent) -> Nil) -> Attribute {
  attribute.attribute("onGotPointerCapture", handler)
}

pub fn on_lost_pointer_capture(handler: fn(PointerEvent) -> Nil) -> Attribute {
  attribute.attribute("onLostPointerCapture", handler)
}

// 드래그 이벤트
pub fn on_drag(handler: fn(DragEvent) -> Nil) -> Attribute {
  attribute.attribute("onDrag", handler)
}

pub fn on_drag_start(handler: fn(DragEvent) -> Nil) -> Attribute {
  attribute.attribute("onDragStart", handler)
}

pub fn on_drag_end(handler: fn(DragEvent) -> Nil) -> Attribute {
  attribute.attribute("onDragEnd", handler)
}

pub fn on_drag_enter(handler: fn(DragEvent) -> Nil) -> Attribute {
  attribute.attribute("onDragEnter", handler)
}

pub fn on_drag_over(handler: fn(DragEvent) -> Nil) -> Attribute {
  attribute.attribute("onDragOver", handler)
}

pub fn on_drag_leave(handler: fn(DragEvent) -> Nil) -> Attribute {
  attribute.attribute("onDragLeave", handler)
}

pub fn on_drop(handler: fn(DragEvent) -> Nil) -> Attribute {
  attribute.attribute("onDrop", handler)
}

// 클립보드 이벤트
pub fn on_copy(handler: fn(ClipboardEvent) -> Nil) -> Attribute {
  attribute.attribute("onCopy", handler)
}

pub fn on_cut(handler: fn(ClipboardEvent) -> Nil) -> Attribute {
  attribute.attribute("onCut", handler)
}

pub fn on_paste(handler: fn(ClipboardEvent) -> Nil) -> Attribute {
  attribute.attribute("onPaste", handler)
}

// 터치 이벤트
pub fn on_touch_start(handler: fn(TouchEvent) -> Nil) -> Attribute {
  attribute.attribute("onTouchStart", handler)
}

pub fn on_touch_end(handler: fn(TouchEvent) -> Nil) -> Attribute {
  attribute.attribute("onTouchEnd", handler)
}

pub fn on_touch_move(handler: fn(TouchEvent) -> Nil) -> Attribute {
  attribute.attribute("onTouchMove", handler)
}

pub fn on_touch_cancel(handler: fn(TouchEvent) -> Nil) -> Attribute {
  attribute.attribute("onTouchCancel", handler)
}

// 스크롤/휠 이벤트
pub fn on_scroll(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onScroll", handler)
}

pub fn on_wheel(handler: fn(WheelEvent) -> Nil) -> Attribute {
  attribute.attribute("onWheel", handler)
}

// 애니메이션/트랜지션 이벤트
pub fn on_animation_start(handler: fn(AnimationEvent) -> Nil) -> Attribute {
  attribute.attribute("onAnimationStart", handler)
}

pub fn on_animation_end(handler: fn(AnimationEvent) -> Nil) -> Attribute {
  attribute.attribute("onAnimationEnd", handler)
}

pub fn on_animation_iteration(handler: fn(AnimationEvent) -> Nil) -> Attribute {
  attribute.attribute("onAnimationIteration", handler)
}

pub fn on_transition_end(handler: fn(TransitionEvent) -> Nil) -> Attribute {
  attribute.attribute("onTransitionEnd", handler)
}

pub fn on_transition_run(handler: fn(TransitionEvent) -> Nil) -> Attribute {
  attribute.attribute("onTransitionRun", handler)
}

pub fn on_transition_start(handler: fn(TransitionEvent) -> Nil) -> Attribute {
  attribute.attribute("onTransitionStart", handler)
}

pub fn on_transition_cancel(handler: fn(TransitionEvent) -> Nil) -> Attribute {
  attribute.attribute("onTransitionCancel", handler)
}

// === 캡처 단계 이벤트 핸들러 ===

// 마우스 캡처
pub fn on_click_capture(handler: fn(MouseEvent) -> Nil) -> Attribute {
  attribute.attribute("onClickCapture", handler)
}

pub fn on_double_click_capture(handler: fn(MouseEvent) -> Nil) -> Attribute {
  attribute.attribute("onDoubleClickCapture", handler)
}

pub fn on_context_menu_capture(handler: fn(MouseEvent) -> Nil) -> Attribute {
  attribute.attribute("onContextMenuCapture", handler)
}

pub fn on_mouse_down_capture(handler: fn(MouseEvent) -> Nil) -> Attribute {
  attribute.attribute("onMouseDownCapture", handler)
}

pub fn on_mouse_up_capture(handler: fn(MouseEvent) -> Nil) -> Attribute {
  attribute.attribute("onMouseUpCapture", handler)
}

pub fn on_mouse_move_capture(handler: fn(MouseEvent) -> Nil) -> Attribute {
  attribute.attribute("onMouseMoveCapture", handler)
}

pub fn on_mouse_over_capture(handler: fn(MouseEvent) -> Nil) -> Attribute {
  attribute.attribute("onMouseOverCapture", handler)
}

pub fn on_mouse_out_capture(handler: fn(MouseEvent) -> Nil) -> Attribute {
  attribute.attribute("onMouseOutCapture", handler)
}

pub fn on_aux_click_capture(handler: fn(MouseEvent) -> Nil) -> Attribute {
  attribute.attribute("onAuxClickCapture", handler)
}

// 키보드 캡처
pub fn on_key_down_capture(handler: fn(KeyboardEvent) -> Nil) -> Attribute {
  attribute.attribute("onKeyDownCapture", handler)
}

pub fn on_key_up_capture(handler: fn(KeyboardEvent) -> Nil) -> Attribute {
  attribute.attribute("onKeyUpCapture", handler)
}

// 폼/입력 캡처
pub fn on_change_capture(handler: fn(ChangeEvent) -> Nil) -> Attribute {
  attribute.attribute("onChangeCapture", handler)
}

pub fn on_input_capture(handler: fn(InputEvent) -> Nil) -> Attribute {
  attribute.attribute("onInputCapture", handler)
}

pub fn on_submit_capture(handler: fn(FormEvent) -> Nil) -> Attribute {
  attribute.attribute("onSubmitCapture", handler)
}

pub fn on_reset_capture(handler: fn(FormEvent) -> Nil) -> Attribute {
  attribute.attribute("onResetCapture", handler)
}

// 포커스 캡처
pub fn on_focus_capture(handler: fn(FocusEvent) -> Nil) -> Attribute {
  attribute.attribute("onFocusCapture", handler)
}

pub fn on_blur_capture(handler: fn(FocusEvent) -> Nil) -> Attribute {
  attribute.attribute("onBlurCapture", handler)
}

// 포인터 캡처 (enter/leave 제외 — W3C 스펙상 캡처 미지원)
pub fn on_pointer_down_capture(handler: fn(PointerEvent) -> Nil) -> Attribute {
  attribute.attribute("onPointerDownCapture", handler)
}

pub fn on_pointer_up_capture(handler: fn(PointerEvent) -> Nil) -> Attribute {
  attribute.attribute("onPointerUpCapture", handler)
}

pub fn on_pointer_move_capture(handler: fn(PointerEvent) -> Nil) -> Attribute {
  attribute.attribute("onPointerMoveCapture", handler)
}

pub fn on_pointer_over_capture(handler: fn(PointerEvent) -> Nil) -> Attribute {
  attribute.attribute("onPointerOverCapture", handler)
}

pub fn on_pointer_out_capture(handler: fn(PointerEvent) -> Nil) -> Attribute {
  attribute.attribute("onPointerOutCapture", handler)
}

pub fn on_pointer_cancel_capture(
  handler: fn(PointerEvent) -> Nil,
) -> Attribute {
  attribute.attribute("onPointerCancelCapture", handler)
}

pub fn on_got_pointer_capture_capture(
  handler: fn(PointerEvent) -> Nil,
) -> Attribute {
  attribute.attribute("onGotPointerCaptureCapture", handler)
}

pub fn on_lost_pointer_capture_capture(
  handler: fn(PointerEvent) -> Nil,
) -> Attribute {
  attribute.attribute("onLostPointerCaptureCapture", handler)
}

// 드래그 캡처
pub fn on_drag_capture(handler: fn(DragEvent) -> Nil) -> Attribute {
  attribute.attribute("onDragCapture", handler)
}

pub fn on_drag_start_capture(handler: fn(DragEvent) -> Nil) -> Attribute {
  attribute.attribute("onDragStartCapture", handler)
}

pub fn on_drag_end_capture(handler: fn(DragEvent) -> Nil) -> Attribute {
  attribute.attribute("onDragEndCapture", handler)
}

pub fn on_drag_enter_capture(handler: fn(DragEvent) -> Nil) -> Attribute {
  attribute.attribute("onDragEnterCapture", handler)
}

pub fn on_drag_over_capture(handler: fn(DragEvent) -> Nil) -> Attribute {
  attribute.attribute("onDragOverCapture", handler)
}

pub fn on_drag_leave_capture(handler: fn(DragEvent) -> Nil) -> Attribute {
  attribute.attribute("onDragLeaveCapture", handler)
}

pub fn on_drop_capture(handler: fn(DragEvent) -> Nil) -> Attribute {
  attribute.attribute("onDropCapture", handler)
}

// 클립보드 캡처
pub fn on_copy_capture(handler: fn(ClipboardEvent) -> Nil) -> Attribute {
  attribute.attribute("onCopyCapture", handler)
}

pub fn on_cut_capture(handler: fn(ClipboardEvent) -> Nil) -> Attribute {
  attribute.attribute("onCutCapture", handler)
}

pub fn on_paste_capture(handler: fn(ClipboardEvent) -> Nil) -> Attribute {
  attribute.attribute("onPasteCapture", handler)
}

// 터치 캡처
pub fn on_touch_start_capture(handler: fn(TouchEvent) -> Nil) -> Attribute {
  attribute.attribute("onTouchStartCapture", handler)
}

pub fn on_touch_end_capture(handler: fn(TouchEvent) -> Nil) -> Attribute {
  attribute.attribute("onTouchEndCapture", handler)
}

pub fn on_touch_move_capture(handler: fn(TouchEvent) -> Nil) -> Attribute {
  attribute.attribute("onTouchMoveCapture", handler)
}

pub fn on_touch_cancel_capture(handler: fn(TouchEvent) -> Nil) -> Attribute {
  attribute.attribute("onTouchCancelCapture", handler)
}

// 스크롤/휠 캡처
pub fn on_scroll_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onScrollCapture", handler)
}

pub fn on_wheel_capture(handler: fn(WheelEvent) -> Nil) -> Attribute {
  attribute.attribute("onWheelCapture", handler)
}

// 애니메이션/트랜지션 캡처
pub fn on_animation_start_capture(
  handler: fn(AnimationEvent) -> Nil,
) -> Attribute {
  attribute.attribute("onAnimationStartCapture", handler)
}

pub fn on_animation_end_capture(
  handler: fn(AnimationEvent) -> Nil,
) -> Attribute {
  attribute.attribute("onAnimationEndCapture", handler)
}

pub fn on_animation_iteration_capture(
  handler: fn(AnimationEvent) -> Nil,
) -> Attribute {
  attribute.attribute("onAnimationIterationCapture", handler)
}

pub fn on_transition_end_capture(
  handler: fn(TransitionEvent) -> Nil,
) -> Attribute {
  attribute.attribute("onTransitionEndCapture", handler)
}

pub fn on_transition_run_capture(
  handler: fn(TransitionEvent) -> Nil,
) -> Attribute {
  attribute.attribute("onTransitionRunCapture", handler)
}

pub fn on_transition_start_capture(
  handler: fn(TransitionEvent) -> Nil,
) -> Attribute {
  attribute.attribute("onTransitionStartCapture", handler)
}

pub fn on_transition_cancel_capture(
  handler: fn(TransitionEvent) -> Nil,
) -> Attribute {
  attribute.attribute("onTransitionCancelCapture", handler)
}

// === 이벤트 값 추출 (공통) ===

/// input/textarea의 현재 값 추출
@external(javascript, "./event_ffi.mjs", "get_target_value")
pub fn target_value(event: event) -> String

/// 기본 동작 방지
@external(javascript, "./event_ffi.mjs", "prevent_default")
pub fn prevent_default(event: event) -> Nil

/// 이벤트 전파 중지
@external(javascript, "./event_ffi.mjs", "stop_propagation")
pub fn stop_propagation(event: event) -> Nil

/// 키보드 이벤트의 키 값
@external(javascript, "./event_ffi.mjs", "get_event_key")
pub fn key(event: event) -> String

// === 공통 이벤트 속성 접근자 ===

/// 이벤트 대상 요소
@external(javascript, "./event_ffi.mjs", "get_target")
pub fn target(event: event) -> Dynamic

/// 이벤트 핸들러가 등록된 요소
@external(javascript, "./event_ffi.mjs", "get_current_target")
pub fn current_target(event: event) -> Dynamic

/// 이벤트 버블링 여부
@external(javascript, "./event_ffi.mjs", "get_bubbles")
pub fn bubbles(event: event) -> Bool

/// 이벤트 취소 가능 여부
@external(javascript, "./event_ffi.mjs", "get_cancelable")
pub fn cancelable(event: event) -> Bool

/// 사용자 발생 이벤트 여부
@external(javascript, "./event_ffi.mjs", "get_is_trusted")
pub fn is_trusted(event: event) -> Bool

/// 이벤트 발생 타임스탬프 (밀리초)
@external(javascript, "./event_ffi.mjs", "get_time_stamp")
pub fn time_stamp(event: event) -> Float

/// 이벤트 전파 단계 (0=None, 1=Capture, 2=Target, 3=Bubble)
@external(javascript, "./event_ffi.mjs", "get_event_phase")
pub fn event_phase(event: event) -> Int

/// 네이티브 브라우저 이벤트 객체
@external(javascript, "./event_ffi.mjs", "get_native_event")
pub fn native_event(event: event) -> Dynamic

/// 기본 동작이 방지되었는지 여부
@external(javascript, "./event_ffi.mjs", "get_is_default_prevented")
pub fn is_default_prevented(event: event) -> Bool

/// 전파가 중지되었는지 여부
@external(javascript, "./event_ffi.mjs", "get_is_propagation_stopped")
pub fn is_propagation_stopped(event: event) -> Bool

// === 마우스 이벤트 접근자 ===

@external(javascript, "./event_ffi.mjs", "get_client_x")
pub fn client_x(event: MouseEvent) -> Float

@external(javascript, "./event_ffi.mjs", "get_client_y")
pub fn client_y(event: MouseEvent) -> Float

@external(javascript, "./event_ffi.mjs", "get_page_x")
pub fn page_x(event: MouseEvent) -> Float

@external(javascript, "./event_ffi.mjs", "get_page_y")
pub fn page_y(event: MouseEvent) -> Float

@external(javascript, "./event_ffi.mjs", "get_offset_x")
pub fn offset_x(event: MouseEvent) -> Float

@external(javascript, "./event_ffi.mjs", "get_offset_y")
pub fn offset_y(event: MouseEvent) -> Float

@external(javascript, "./event_ffi.mjs", "get_button")
pub fn button(event: MouseEvent) -> Int

@external(javascript, "./event_ffi.mjs", "get_buttons")
pub fn buttons(event: MouseEvent) -> Int

// === 키보드 이벤트 접근자 ===

@external(javascript, "./event_ffi.mjs", "get_ctrl_key")
pub fn ctrl_key(event: KeyboardEvent) -> Bool

@external(javascript, "./event_ffi.mjs", "get_shift_key")
pub fn shift_key(event: KeyboardEvent) -> Bool

@external(javascript, "./event_ffi.mjs", "get_alt_key")
pub fn alt_key(event: KeyboardEvent) -> Bool

@external(javascript, "./event_ffi.mjs", "get_meta_key")
pub fn meta_key(event: KeyboardEvent) -> Bool

@external(javascript, "./event_ffi.mjs", "get_repeat")
pub fn repeat(event: KeyboardEvent) -> Bool

@external(javascript, "./event_ffi.mjs", "get_code")
pub fn code(event: KeyboardEvent) -> String

// === 컴포지션 이벤트 핸들러 (CJK/IME 입력 — 한국어 입력에 필수) ===

pub fn on_composition_start(
  handler: fn(CompositionEvent) -> Nil,
) -> Attribute {
  attribute.attribute("onCompositionStart", handler)
}

pub fn on_composition_update(
  handler: fn(CompositionEvent) -> Nil,
) -> Attribute {
  attribute.attribute("onCompositionUpdate", handler)
}

pub fn on_composition_end(
  handler: fn(CompositionEvent) -> Nil,
) -> Attribute {
  attribute.attribute("onCompositionEnd", handler)
}

pub fn on_composition_start_capture(
  handler: fn(CompositionEvent) -> Nil,
) -> Attribute {
  attribute.attribute("onCompositionStartCapture", handler)
}

pub fn on_composition_update_capture(
  handler: fn(CompositionEvent) -> Nil,
) -> Attribute {
  attribute.attribute("onCompositionUpdateCapture", handler)
}

pub fn on_composition_end_capture(
  handler: fn(CompositionEvent) -> Nil,
) -> Attribute {
  attribute.attribute("onCompositionEndCapture", handler)
}

// === 미디어 이벤트 핸들러 (audio/video 위젯) ===

pub fn on_play(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onPlay", handler)
}

pub fn on_pause(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onPause", handler)
}

pub fn on_playing(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onPlaying", handler)
}

pub fn on_ended(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onEnded", handler)
}

pub fn on_time_update(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onTimeUpdate", handler)
}

pub fn on_volume_change(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onVolumeChange", handler)
}

pub fn on_waiting(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onWaiting", handler)
}

pub fn on_seeking(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onSeeking", handler)
}

pub fn on_seeked(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onSeeked", handler)
}

pub fn on_loaded_metadata(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onLoadedMetadata", handler)
}

pub fn on_loaded_data(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onLoadedData", handler)
}

pub fn on_can_play(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onCanPlay", handler)
}

pub fn on_can_play_through(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onCanPlayThrough", handler)
}

pub fn on_duration_change(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onDurationChange", handler)
}

pub fn on_rate_change(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onRateChange", handler)
}

pub fn on_suspend(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onSuspend", handler)
}

pub fn on_progress(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onProgress", handler)
}

pub fn on_stalled(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onStalled", handler)
}

pub fn on_abort(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onAbort", handler)
}

pub fn on_emptied(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onEmptied", handler)
}

/// 미디어 암호화 이벤트 (DRM 콘텐츠)
pub fn on_encrypted(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onEncrypted", handler)
}

// 미디어 이벤트 캡처
pub fn on_play_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onPlayCapture", handler)
}

pub fn on_pause_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onPauseCapture", handler)
}

pub fn on_playing_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onPlayingCapture", handler)
}

pub fn on_ended_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onEndedCapture", handler)
}

pub fn on_time_update_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onTimeUpdateCapture", handler)
}

pub fn on_volume_change_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onVolumeChangeCapture", handler)
}

pub fn on_waiting_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onWaitingCapture", handler)
}

pub fn on_seeking_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onSeekingCapture", handler)
}

pub fn on_seeked_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onSeekedCapture", handler)
}

pub fn on_loaded_metadata_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onLoadedMetadataCapture", handler)
}

pub fn on_loaded_data_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onLoadedDataCapture", handler)
}

pub fn on_can_play_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onCanPlayCapture", handler)
}

pub fn on_can_play_through_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onCanPlayThroughCapture", handler)
}

pub fn on_duration_change_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onDurationChangeCapture", handler)
}

pub fn on_rate_change_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onRateChangeCapture", handler)
}

pub fn on_suspend_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onSuspendCapture", handler)
}

pub fn on_progress_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onProgressCapture", handler)
}

pub fn on_stalled_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onStalledCapture", handler)
}

pub fn on_abort_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onAbortCapture", handler)
}

pub fn on_emptied_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onEmptiedCapture", handler)
}

pub fn on_encrypted_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onEncryptedCapture", handler)
}

// === UI 이벤트 ===

pub fn on_toggle(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onToggle", handler)
}

pub fn on_close(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onClose", handler)
}

pub fn on_cancel(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onCancel", handler)
}

pub fn on_resize(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onResize", handler)
}

pub fn on_toggle_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onToggleCapture", handler)
}

pub fn on_close_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onCloseCapture", handler)
}

pub fn on_cancel_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onCancelCapture", handler)
}

pub fn on_resize_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onResizeCapture", handler)
}

// === 기타 이벤트 ===

pub fn on_select(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onSelect", handler)
}

pub fn on_invalid(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onInvalid", handler)
}

pub fn on_select_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onSelectCapture", handler)
}

pub fn on_invalid_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onInvalidCapture", handler)
}

// === 로드/에러 이벤트 ===

/// img/iframe/script 로드 완료
pub fn on_load(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onLoad", handler)
}

pub fn on_load_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onLoadCapture", handler)
}

/// 리소스 로드 실패
pub fn on_error(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onError", handler)
}

pub fn on_error_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onErrorCapture", handler)
}

// === 입력 전 이벤트 ===

/// 입력 값 변경 전 필터링
pub fn on_before_input(handler: fn(InputEvent) -> Nil) -> Attribute {
  attribute.attribute("onBeforeInput", handler)
}

pub fn on_before_input_capture(handler: fn(InputEvent) -> Nil) -> Attribute {
  attribute.attribute("onBeforeInputCapture", handler)
}

// === 미디어 로드 시작 ===

pub fn on_load_start(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onLoadStart", handler)
}

pub fn on_load_start_capture(handler: fn(Event) -> Nil) -> Attribute {
  attribute.attribute("onLoadStartCapture", handler)
}

// === 마우스 추가 접근자 ===

@external(javascript, "./event_ffi.mjs", "get_screen_x")
pub fn screen_x(event: MouseEvent) -> Float

@external(javascript, "./event_ffi.mjs", "get_screen_y")
pub fn screen_y(event: MouseEvent) -> Float

@external(javascript, "./event_ffi.mjs", "get_movement_x")
pub fn movement_x(event: MouseEvent) -> Float

@external(javascript, "./event_ffi.mjs", "get_movement_y")
pub fn movement_y(event: MouseEvent) -> Float

@external(javascript, "./event_ffi.mjs", "get_mouse_related_target")
pub fn mouse_related_target(event: MouseEvent) -> Dynamic

@external(javascript, "./event_ffi.mjs", "get_modifier_state")
pub fn get_modifier_state(event: MouseEvent, key: String) -> Bool

/// 마우스 이벤트 Ctrl 키 상태
@external(javascript, "./event_ffi.mjs", "get_ctrl_key")
pub fn mouse_ctrl_key(event: MouseEvent) -> Bool

/// 마우스 이벤트 Shift 키 상태
@external(javascript, "./event_ffi.mjs", "get_shift_key")
pub fn mouse_shift_key(event: MouseEvent) -> Bool

/// 마우스 이벤트 Alt 키 상태
@external(javascript, "./event_ffi.mjs", "get_alt_key")
pub fn mouse_alt_key(event: MouseEvent) -> Bool

/// 마우스 이벤트 Meta 키 상태
@external(javascript, "./event_ffi.mjs", "get_meta_key")
pub fn mouse_meta_key(event: MouseEvent) -> Bool

// === 휠 이벤트 접근자 ===

@external(javascript, "./event_ffi.mjs", "get_delta_x")
pub fn delta_x(event: WheelEvent) -> Float

@external(javascript, "./event_ffi.mjs", "get_delta_y")
pub fn delta_y(event: WheelEvent) -> Float

@external(javascript, "./event_ffi.mjs", "get_delta_z")
pub fn delta_z(event: WheelEvent) -> Float

@external(javascript, "./event_ffi.mjs", "get_delta_mode")
pub fn delta_mode(event: WheelEvent) -> Int

// === 터치 이벤트 접근자 ===

@external(javascript, "./event_ffi.mjs", "get_touches")
pub fn touches(event: TouchEvent) -> Dynamic

@external(javascript, "./event_ffi.mjs", "get_changed_touches")
pub fn changed_touches(event: TouchEvent) -> Dynamic

@external(javascript, "./event_ffi.mjs", "get_target_touches")
pub fn target_touches(event: TouchEvent) -> Dynamic

// === 애니메이션 이벤트 접근자 ===

@external(javascript, "./event_ffi.mjs", "get_animation_name")
pub fn animation_name(event: AnimationEvent) -> String

@external(javascript, "./event_ffi.mjs", "get_animation_elapsed_time")
pub fn animation_elapsed_time(event: AnimationEvent) -> Float

@external(javascript, "./event_ffi.mjs", "get_animation_pseudo_element")
pub fn animation_pseudo_element(event: AnimationEvent) -> String

// === 트랜지션 이벤트 접근자 ===

@external(javascript, "./event_ffi.mjs", "get_property_name")
pub fn property_name(event: TransitionEvent) -> String

@external(javascript, "./event_ffi.mjs", "get_transition_elapsed_time")
pub fn transition_elapsed_time(event: TransitionEvent) -> Float

@external(javascript, "./event_ffi.mjs", "get_transition_pseudo_element")
pub fn transition_pseudo_element(event: TransitionEvent) -> String

// === 드래그 이벤트 접근자 ===

@external(javascript, "./event_ffi.mjs", "get_data_transfer")
pub fn data_transfer(event: DragEvent) -> Dynamic

// === 포커스 이벤트 접근자 ===

@external(javascript, "./event_ffi.mjs", "get_focus_related_target")
pub fn focus_related_target(event: FocusEvent) -> Dynamic

// === 컴포지션 이벤트 접근자 ===

@external(javascript, "./event_ffi.mjs", "get_composition_data")
pub fn composition_data(event: CompositionEvent) -> String

// === 입력 이벤트 접근자 ===

@external(javascript, "./event_ffi.mjs", "get_input_data")
pub fn input_data(event: InputEvent) -> String

// === 클립보드 이벤트 접근자 ===

@external(javascript, "./event_ffi.mjs", "get_clipboard_data")
pub fn clipboard_data(event: ClipboardEvent) -> Dynamic

// === 포인터 이벤트 접근자 ===

@external(javascript, "./event_ffi.mjs", "get_pointer_id")
pub fn pointer_id(event: PointerEvent) -> Int

@external(javascript, "./event_ffi.mjs", "get_pointer_width")
pub fn pointer_width(event: PointerEvent) -> Float

@external(javascript, "./event_ffi.mjs", "get_pointer_height")
pub fn pointer_height(event: PointerEvent) -> Float

@external(javascript, "./event_ffi.mjs", "get_pressure")
pub fn pressure(event: PointerEvent) -> Float

@external(javascript, "./event_ffi.mjs", "get_tilt_x")
pub fn tilt_x(event: PointerEvent) -> Float

@external(javascript, "./event_ffi.mjs", "get_tilt_y")
pub fn tilt_y(event: PointerEvent) -> Float

@external(javascript, "./event_ffi.mjs", "get_pointer_type")
pub fn pointer_type(event: PointerEvent) -> String

@external(javascript, "./event_ffi.mjs", "get_is_primary")
pub fn is_primary(event: PointerEvent) -> Bool

// === 이벤트 유틸리티 ===

/// 이벤트 풀링 방지 (React 17+ 에서는 자동이지만 호환성 유지)
@external(javascript, "./event_ffi.mjs", "persist")
pub fn persist(event: event) -> Nil

/// 이벤트가 영속적인지 확인
@external(javascript, "./event_ffi.mjs", "get_is_persistent")
pub fn is_persistent(event: event) -> Bool
