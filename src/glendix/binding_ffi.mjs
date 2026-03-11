// 스텁 — gleam run -m glendix/install 시 자동 교체됨
// 직접 수정 금지

export function get_module(name) {
  throw new Error(
    `바인딩이 생성되지 않았습니다. 'gleam run -m glendix/install'을 실행하세요. (요청 모듈: ${name})`,
  );
}

export function resolve(_mod, name) {
  throw new Error(
    `바인딩이 생성되지 않았습니다. 'gleam run -m glendix/install'을 실행하세요. (요청 컴포넌트: ${name})`,
  );
}
