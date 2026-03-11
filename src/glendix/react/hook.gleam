// React Hooks - useState, useEffect 등

import glendix/react.{type Context, type Promise, type Ref}

// === useState ===

/// 상태 훅. #(현재값, 세터함수) 튜플 반환
@external(javascript, "./hook_ffi.mjs", "use_state")
pub fn use_state(initial: a) -> #(a, fn(a) -> Nil)

/// useState 업데이터 함수 변형 (stale closure 방지)
/// 세터에 fn(prev) -> next 형태의 업데이터 함수를 전달
@external(javascript, "./hook_ffi.mjs", "use_state_updater")
pub fn use_state_(initial: a) -> #(a, fn(fn(a) -> a) -> Nil)

// === useEffect ===

/// 의존성 배열과 함께 실행
@external(javascript, "./hook_ffi.mjs", "use_effect")
pub fn use_effect(effect_fn: fn() -> Nil, deps: List(a)) -> Nil

/// 매 렌더링마다 실행 (deps 없음)
@external(javascript, "./hook_ffi.mjs", "use_effect_always")
pub fn use_effect_always(effect_fn: fn() -> Nil) -> Nil

/// 마운트 시 한 번만 실행 (deps = [])
@external(javascript, "./hook_ffi.mjs", "use_effect_once")
pub fn use_effect_once(effect_fn: fn() -> Nil) -> Nil

// === useEffect (cleanup 반환) ===
// Gleam fn() -> fn() -> Nil = JS에서 함수를 반환하는 함수 → React cleanup으로 인식

/// 의존성 배열과 함께 실행 (cleanup 함수 반환)
@external(javascript, "./hook_ffi.mjs", "use_effect")
pub fn use_effect_cleanup(setup: fn() -> fn() -> Nil, deps: List(a)) -> Nil

/// 매 렌더링마다 실행 + cleanup
@external(javascript, "./hook_ffi.mjs", "use_effect_always")
pub fn use_effect_always_cleanup(setup: fn() -> fn() -> Nil) -> Nil

/// 마운트 시 한 번만 실행 + cleanup
@external(javascript, "./hook_ffi.mjs", "use_effect_once")
pub fn use_effect_once_cleanup(setup: fn() -> fn() -> Nil) -> Nil

// === useLayoutEffect ===
// DOM 변경 후 브라우저 페인트 전 동기 실행

/// 의존성 배열과 함께 레이아웃 이펙트 실행
@external(javascript, "./hook_ffi.mjs", "use_layout_effect")
pub fn use_layout_effect(effect_fn: fn() -> Nil, deps: List(a)) -> Nil

/// 매 렌더링마다 레이아웃 이펙트 실행 (deps 없음)
@external(javascript, "./hook_ffi.mjs", "use_layout_effect_always")
pub fn use_layout_effect_always(effect_fn: fn() -> Nil) -> Nil

/// 마운트 시 한 번만 레이아웃 이펙트 실행 (deps = [])
@external(javascript, "./hook_ffi.mjs", "use_layout_effect_once")
pub fn use_layout_effect_once(effect_fn: fn() -> Nil) -> Nil

// === useLayoutEffect (cleanup 반환) ===

/// 의존성 배열과 함께 레이아웃 이펙트 실행 (cleanup 함수 반환)
@external(javascript, "./hook_ffi.mjs", "use_layout_effect")
pub fn use_layout_effect_cleanup(
  setup: fn() -> fn() -> Nil,
  deps: List(a),
) -> Nil

/// 매 렌더링마다 레이아웃 이펙트 실행 + cleanup
@external(javascript, "./hook_ffi.mjs", "use_layout_effect_always")
pub fn use_layout_effect_always_cleanup(setup: fn() -> fn() -> Nil) -> Nil

/// 마운트 시 한 번만 레이아웃 이펙트 실행 + cleanup
@external(javascript, "./hook_ffi.mjs", "use_layout_effect_once")
pub fn use_layout_effect_once_cleanup(setup: fn() -> fn() -> Nil) -> Nil

// === useInsertionEffect ===
// CSS-in-JS용. DOM 변경 전 실행

/// 의존성 배열과 함께 삽입 이펙트 실행
@external(javascript, "./hook_ffi.mjs", "use_insertion_effect")
pub fn use_insertion_effect(effect_fn: fn() -> Nil, deps: List(a)) -> Nil

/// 매 렌더링마다 삽입 이펙트 실행 (deps 없음)
@external(javascript, "./hook_ffi.mjs", "use_insertion_effect_always")
pub fn use_insertion_effect_always(effect_fn: fn() -> Nil) -> Nil

/// 마운트 시 한 번만 삽입 이펙트 실행 (deps = [])
@external(javascript, "./hook_ffi.mjs", "use_insertion_effect_once")
pub fn use_insertion_effect_once(effect_fn: fn() -> Nil) -> Nil

// === useInsertionEffect (cleanup 반환) ===

/// 의존성 배열과 함께 삽입 이펙트 실행 (cleanup 함수 반환)
@external(javascript, "./hook_ffi.mjs", "use_insertion_effect")
pub fn use_insertion_effect_cleanup(
  setup: fn() -> fn() -> Nil,
  deps: List(a),
) -> Nil

/// 매 렌더링마다 삽입 이펙트 실행 + cleanup
@external(javascript, "./hook_ffi.mjs", "use_insertion_effect_always")
pub fn use_insertion_effect_always_cleanup(setup: fn() -> fn() -> Nil) -> Nil

/// 마운트 시 한 번만 삽입 이펙트 실행 + cleanup
@external(javascript, "./hook_ffi.mjs", "use_insertion_effect_once")
pub fn use_insertion_effect_once_cleanup(setup: fn() -> fn() -> Nil) -> Nil

// === useMemo / useCallback ===

/// 메모이제이션된 값 계산
@external(javascript, "./hook_ffi.mjs", "use_memo")
pub fn use_memo(compute: fn() -> a, deps: List(b)) -> a

/// 메모이제이션된 콜백
@external(javascript, "./hook_ffi.mjs", "use_callback")
pub fn use_callback(callback: fn(a) -> b, deps: List(c)) -> fn(a) -> b

// === useRef ===

/// ref 생성
@external(javascript, "./hook_ffi.mjs", "use_ref")
pub fn use_ref(initial: a) -> Ref(a)

/// ref 현재 값 읽기
/// @deprecated — `glendix/react/ref.current` 사용 권장
@external(javascript, "./hook_ffi.mjs", "get_ref_current")
pub fn get_ref(ref: Ref(a)) -> a

/// ref 현재 값 설정
/// @deprecated — `glendix/react/ref.assign` 사용 권장
@external(javascript, "./hook_ffi.mjs", "set_ref_current")
pub fn set_ref(ref: Ref(a), value: a) -> Nil

// === useReducer ===

/// 리듀서 기반 상태 관리
@external(javascript, "./hook_ffi.mjs", "use_reducer")
pub fn use_reducer(
  reducer: fn(state, action) -> state,
  initial: state,
) -> #(state, fn(action) -> Nil)

// === useContext ===

/// Context 값 읽기
@external(javascript, "./hook_ffi.mjs", "use_context")
pub fn use_context(context: Context(a)) -> a

// === useId ===

/// SSR-safe 고유 ID 생성
@external(javascript, "./hook_ffi.mjs", "use_id")
pub fn use_id() -> String

// === useTransition ===

/// 비긴급 상태 업데이트 표시
@external(javascript, "./hook_ffi.mjs", "use_transition")
pub fn use_transition() -> #(Bool, fn(fn() -> Nil) -> Nil)

// === useDeferredValue ===

/// 값 지연 처리
@external(javascript, "./hook_ffi.mjs", "use_deferred_value")
pub fn use_deferred_value(value: a) -> a

// === useOptimistic (React 19) ===

/// 낙관적 UI 업데이트
@external(javascript, "./hook_ffi.mjs", "use_optimistic")
pub fn use_optimistic(state: a) -> #(a, fn(a) -> Nil)

/// 낙관적 UI 업데이트 (리듀서 변형 — 업데이트 함수로 병합 로직 지정)
@external(javascript, "./hook_ffi.mjs", "use_optimistic_with_update")
pub fn use_optimistic_(state: a, update_fn: fn(a, b) -> a) -> #(a, fn(b) -> Nil)

// === useImperativeHandle ===

/// 부모에게 노출하는 ref 인스턴스 커스터마이징
@external(javascript, "./hook_ffi.mjs", "use_imperative_handle")
pub fn use_imperative_handle(
  ref: Ref(a),
  create: fn() -> a,
  deps: List(b),
) -> Nil

// === useState (지연 초기화) ===

/// 지연 초기화 useState (비싼 초기값 계산 방지, init_fn은 마운트 시 한 번만 호출)
@external(javascript, "./hook_ffi.mjs", "use_lazy_state")
pub fn use_lazy_state(init_fn: fn() -> a) -> #(a, fn(a) -> Nil)

/// 지연 초기화 useState + 업데이터 함수 변형
@external(javascript, "./hook_ffi.mjs", "use_lazy_state_updater")
pub fn use_lazy_state_(init_fn: fn() -> a) -> #(a, fn(fn(a) -> a) -> Nil)

// === useSyncExternalStore ===

/// 외부 스토어 구독 (Redux/Zustand 통합용)
@external(javascript, "./hook_ffi.mjs", "use_sync_external_store")
pub fn use_sync_external_store(
  subscribe: fn(fn() -> Nil) -> fn() -> Nil,
  get_snapshot: fn() -> a,
) -> a

// === useDebugValue ===

/// 커스텀 훅 디버그 값 (React DevTools에 표시)
@external(javascript, "./hook_ffi.mjs", "use_debug_value")
pub fn use_debug_value(value: a) -> Nil

/// 커스텀 훅 디버그 값 + 포맷 함수
@external(javascript, "./hook_ffi.mjs", "use_debug_value_format")
pub fn use_debug_value_(value: a, format: fn(a) -> String) -> Nil

// === React.use (React 19) ===

/// Suspense 경계 내에서 Promise를 소비하여 값을 반환
/// Promise가 미완료 시 React가 Suspense 폴백을 표시한다
@external(javascript, "./hook_ffi.mjs", "use_promise")
pub fn use_promise(promise: Promise(a)) -> a
