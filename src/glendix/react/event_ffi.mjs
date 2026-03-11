// React 이벤트 접근자 FFI 어댑터

// === 공통 이벤트 접근자 ===

export function get_target_value(event) {
  return event.target.value ?? "";
}

export function prevent_default(event) {
  event.preventDefault();
}

export function stop_propagation(event) {
  event.stopPropagation();
}

export function get_event_key(event) {
  return event.key;
}

// === 공통 속성 접근자 ===

export function get_target(event) {
  return event.target;
}

export function get_current_target(event) {
  return event.currentTarget;
}

export function get_bubbles(event) {
  return event.bubbles;
}

export function get_cancelable(event) {
  return event.cancelable;
}

export function get_is_trusted(event) {
  return event.isTrusted;
}

export function get_time_stamp(event) {
  return event.timeStamp;
}

export function get_event_phase(event) {
  return event.eventPhase;
}

export function get_native_event(event) {
  return event.nativeEvent;
}

export function get_is_default_prevented(event) {
  return event.isDefaultPrevented();
}

export function get_is_propagation_stopped(event) {
  return event.isPropagationStopped();
}

// === 마우스 이벤트 ===

export function get_client_x(e) {
  return e.clientX;
}

export function get_client_y(e) {
  return e.clientY;
}

export function get_page_x(e) {
  return e.pageX;
}

export function get_page_y(e) {
  return e.pageY;
}

export function get_offset_x(e) {
  return e.nativeEvent.offsetX;
}

export function get_offset_y(e) {
  return e.nativeEvent.offsetY;
}

export function get_button(e) {
  return e.button;
}

export function get_buttons(e) {
  return e.buttons;
}

// === 키보드 이벤트 ===

export function get_ctrl_key(e) {
  return e.ctrlKey;
}

export function get_shift_key(e) {
  return e.shiftKey;
}

export function get_alt_key(e) {
  return e.altKey;
}

export function get_meta_key(e) {
  return e.metaKey;
}

export function get_repeat(e) {
  return e.repeat;
}

export function get_code(e) {
  return e.code;
}

// === 마우스 추가 접근자 ===

export function get_screen_x(e) {
  return e.screenX;
}

export function get_screen_y(e) {
  return e.screenY;
}

export function get_movement_x(e) {
  return e.movementX;
}

export function get_movement_y(e) {
  return e.movementY;
}

export function get_mouse_related_target(e) {
  return e.relatedTarget;
}

export function get_modifier_state(e, key) {
  return e.getModifierState(key);
}

// === 휠 이벤트 ===

export function get_delta_x(e) {
  return e.deltaX;
}

export function get_delta_y(e) {
  return e.deltaY;
}

export function get_delta_z(e) {
  return e.deltaZ;
}

export function get_delta_mode(e) {
  return e.deltaMode;
}

// === 터치 이벤트 ===

export function get_touches(e) {
  return e.touches;
}

export function get_changed_touches(e) {
  return e.changedTouches;
}

export function get_target_touches(e) {
  return e.targetTouches;
}

// === 애니메이션 이벤트 ===

export function get_animation_name(e) {
  return e.animationName;
}

export function get_animation_elapsed_time(e) {
  return e.elapsedTime;
}

export function get_animation_pseudo_element(e) {
  return e.pseudoElement;
}

// === 트랜지션 이벤트 ===

export function get_property_name(e) {
  return e.propertyName;
}

export function get_transition_elapsed_time(e) {
  return e.elapsedTime;
}

export function get_transition_pseudo_element(e) {
  return e.pseudoElement;
}

// === 드래그 이벤트 ===

export function get_data_transfer(e) {
  return e.dataTransfer;
}

// === 포커스 이벤트 ===

export function get_focus_related_target(e) {
  return e.relatedTarget;
}

// === 컴포지션 이벤트 ===

export function get_composition_data(e) {
  return e.data;
}

// === 입력 이벤트 ===

export function get_input_data(e) {
  return e.data ?? "";
}

// === 클립보드 이벤트 ===

export function get_clipboard_data(e) {
  return e.clipboardData;
}

// === 포인터 이벤트 ===

export function get_pointer_id(e) {
  return e.pointerId;
}

export function get_pointer_width(e) {
  return e.width;
}

export function get_pointer_height(e) {
  return e.height;
}

export function get_pressure(e) {
  return e.pressure;
}

export function get_tilt_x(e) {
  return e.tiltX;
}

export function get_tilt_y(e) {
  return e.tiltY;
}

export function get_pointer_type(e) {
  return e.pointerType;
}

export function get_is_primary(e) {
  return e.isPrimary;
}

// === 이벤트 유틸리티 ===

export function persist(e) {
  e.persist();
}

export function get_is_persistent(e) {
  return typeof e.isPersistent === "function" ? e.isPersistent() : true;
}
