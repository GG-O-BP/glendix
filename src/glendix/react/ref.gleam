// React Ref 접근자 — ref.current 읽기/쓰기

import glendix/react.{type Ref}

/// ref 현재 값 읽기
@external(javascript, "./hook_ffi.mjs", "get_ref_current")
pub fn current(from ref: Ref(a)) -> a

/// ref 현재 값 설정
@external(javascript, "./hook_ffi.mjs", "set_ref_current")
pub fn assign(of ref: Ref(a), with value: a) -> Nil
