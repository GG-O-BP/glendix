# glendix

Gleam FFI 라이브러리 — Mendix Pluggable Widget API 바인딩.
React는 redraw/redraw_dom, TEA 패턴은 lustre에 위임한다.

- 언어: Gleam (target: JavaScript)
- 의존성: gleam_stdlib, redraw, redraw_dom, lustre
- Peer deps (위젯 프로젝트): react ^19, react-dom ^19, big.js ^6

Gleam 문법은 docs/gleam_language_tour.md 를 참조한다.

## 빌드 & 검증

```bash
gleam build                          # 컴파일
gleam check                          # 타입 체크만
gleam run -m glendix/install         # 의존성 설치 + 바인딩 생성
gleam run -m glendix/dev             # 개발 서버 (HMR)
gleam run -m glendix/build           # 프로덕션 빌드 (.mpk)
gleam run -m glendix/start           # Mendix 테스트 프로젝트 연동
gleam run -m glendix/release         # 릴리즈 빌드
gleam run -m glendix/lint            # ESLint
gleam run -m glendix/lint_fix        # ESLint 자동 수정
gleam run -m glendix/marketplace     # 마켓플레이스 위젯 다운로드
```

변경 후 반드시 `gleam build`로 빌드 확인한다.

## FFI 경계 원칙 (절대 준수)

1. **비즈니스 로직은 `.gleam`에 작성.** `.mjs`는 JS 런타임 접근 담당. 외부 JS 라이브러리 연동 등 필요한 경우 FFI 어댑터가 두꺼워질 수 있다.
2. **Opaque type으로 JS 값을 감싼다.** 내부 구조 직접 접근 금지.
3. **`undefined`/`null` ↔ `Option`.** FFI 경계에서 `to_option()`/`from_option()` 변환. Gleam에서 `undefined` 직접 사용 금지.
4. **Gleam 튜플 = JS 배열.** `#(a, b)` ↔ `[a, b]` (useState 반환값 등).
5. **Gleam List ↔ JS Array.** FFI 경계에서 `toList()`/`.toArray()` 변환.

## 코드 스타일

- 주석과 doc comment는 **한국어**로 작성
- 모듈별 단일 책임: 각 `.gleam` 파일은 하나의 타입/도메인 담당
- `@external` 어노테이션: 상대 경로로 `.mjs` 파일 참조

## 핵심 API 패턴

```gleam
// React (redraw) 사용
import redraw
import redraw/dom/html
import redraw/dom/attribute
import redraw/dom/events

// 위젯 진입점
import glendix/mendix.{type JsProps}
import redraw.{type Element}

pub fn widget(props: JsProps) -> Element { ... }

// 외부 JS 컴포넌트 (widget/binding)
import glendix/interop
interop.component_el(comp, attrs, children)

// Lustre TEA 패턴
import glendix/lustre as gl
gl.use_tea(#(init_model, effect.none()), update, view)
gl.use_simple(init_model, update, view)
gl.embed(redraw_element)  // lustre view 안에 redraw 삽입
```

## 절대 하지 말 것

- FFI `.mjs`에 비즈니스 로직 넣기
- Gleam에서 JS `undefined` 직접 사용 (`Option` 변환 필수)
- `date.gleam` month를 JS 0-based로 전달 (FFI가 1↔0 자동 변환)
- 외부 React 컴포넌트/위젯에 수동 `.mjs` FFI 작성
- `binding.resolve()` / `widget.component()` 이름을 snake_case 변환 (JS PascalCase 유지)

## 바인딩 & 위젯

- **외부 React 컴포넌트**: `bindings.json` → `glendix/install` → `glendix/binding` 사용
- **Pluggable .mpk 위젯**: `widgets/` 디렉토리 → `glendix/widget.component("Name")`
- **위젯 prop 헬퍼**: `widget.prop(k, v)` / `widget.editable_prop(k, v, d, set)` / `widget.action_prop(k, fn)`
- **Classic Dojo .mpk 위젯**: `widgets/` 디렉토리 → `glendix/classic.render(widget_id, props)`
- `install` 시 `binding_ffi.mjs`, `widget_ffi.mjs`, `classic_ffi.mjs`, `src/widgets/*.gleam` 자동 생성

## Editor Configuration (Jint 호환)

`editor_config.gleam`은 Studio Pro의 Jint(.NET JS 엔진)에서 실행된다.
**Gleam List 사용 금지** — WeakMap, Symbol.iterator 미지원. 복수 키는 콤마 구분 String.

## PM 자동 감지

lock 파일 기반: `pnpm-lock.yaml` → pnpm / `bun.lockb`·`bun.lock` → bun / 기본값 → npm

## Mendix API 레퍼런스

Mendix 공식 문서(docs.mendix.com) 접근 불가. GitHub 소스 참조:
- API 문서: `github.com/mendix/docs` → `apidocs-mxsdk/apidocs/pluggable-widgets/`
- 위젯 예제: `github.com/mendix/web-widgets` → `packages/pluggableWidgets/`
- 빌드 도구: `github.com/mendix/widgets-tools`

핵심 개념:
- 위젯 진입점: `fn(JsProps) -> Element`
- `ValueStatus`: `Available | Loading | Unavailable` — 값 읽기 전 확인 필수
- `EditableValue.setValue()` 값 변경 / `ActionValue.execute()` 액션 실행
- `ListValue`: 페이징/정렬/필터 지원
- `mendix/filters/builders` → Rollup external 처리 필요

## 상세 가이드

- glendix_guide.md — 종합 사용 가이드
- README.md — 설치 및 빠른 시작
