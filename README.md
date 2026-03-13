# glendix

Gleam FFI bindings for React 19 and Mendix Pluggable Widget API.

**JSX 없이, 순수 Gleam으로 Mendix Pluggable Widget을 작성한다.**

## What's new in v2.0

v2.0은 [redraw](https://github.com/ghivert/redraw) 프로젝트의 패턴을 참고하여 React 바인딩을 대폭 개선했다. redraw는 Gleam용 프로덕션 React 바인딩 라이브러리로, 타입 안전성과 모듈 구조가 잘 설계되어 있다. glendix는 Mendix Pluggable Widget 특화 라이브러리이므로 redraw의 범용 SPA 패턴(bootstrap/compose, jsx-runtime 등)은 채택하지 않고, 실질적으로 유용한 개선에 집중했다.

### 주요 변경사항

- **FFI 모듈 분리**: `react_ffi.mjs` 하나에 모여 있던 FFI를 `hook_ffi.mjs`, `event_ffi.mjs`, `attribute_ffi.mjs`로 분리하여 모듈별 단일 책임 달성
- **Attribute 리스트 API**: 기존 `prop.gleam` 파이프라인 빌더를 `attribute.gleam` 선언적 리스트 패턴으로 교체 — `[attribute.class("x"), event.on_click(handler)]`
- **39개 Hook**: `useLayoutEffect`, `useInsertionEffect`, `useImperativeHandle`, `useLazyState`, `useSyncExternalStore`, `useDebugValue`, `useOptimistic` (리듀서 변형 포함), `useAsyncTransition`, `useFormStatus` 및 cleanup 변형
- **154+ 이벤트 핸들러**: 캡처 단계, 컴포지션/미디어/UI/로드/에러/트랜지션 이벤트 + 82+ 접근자 + `persist`/`is_persistent` 유틸리티
- **108+ HTML 속성**: `dangerously_set_inner_html`, `popover`, `fetch_priority`, `enter_key_hint`, 마이크로데이터, Shadow DOM 등
- **85+ HTML 태그**: `fieldset`, `details`, `dialog`, `video`, `ruby`, `kbd`, `search`, `hgroup`, `meta`, `script`, `object` 등
- **58 SVG 요소**: 16개 필터 프리미티브 포함 (`fe_convolve_matrix`, `fe_diffuse_lighting` 등)
- **97+ SVG 속성**: 텍스트 렌더링, 마커, 마스크/클리핑 단위, 필터 속성 등
- **고급 컴포넌트**: `StrictMode`, `Suspense`, `Profiler`, `portal`, `forwardRef`, `memo_`, `startTransition`, `flushSync`

## Installation

```toml
# gleam.toml
[dependencies]
glendix = { path = "../glendix" }
```

> Hex 패키지 배포 전까지는 로컬 경로로 참조합니다.

### Peer Dependencies

위젯 프로젝트의 `package.json`에 다음이 필요합니다:

```json
{
  "dependencies": {
    "react": "^19.0.0",
    "big.js": "^6.0.0"
  }
}
```

## Quick Start

```gleam
import glendix/mendix
import glendix/react.{type JsProps, type ReactElement}
import glendix/react/attribute
import glendix/react/html

pub fn widget(props: JsProps) -> ReactElement {
  let name = mendix.get_string_prop(props, "sampleText")
  html.div([attribute.class("my-widget")], [
    react.text("Hello " <> name),
  ])
}
```

`fn(JsProps) -> ReactElement` — 이것이 Mendix Pluggable Widget의 전부입니다.

## Modules

### React

| Module | Description |
|---|---|
| `glendix/react` | 핵심 타입 (`ReactElement`, `JsProps`, `Component`, `Promise`) + `element`, `fragment`, `keyed`, `text`, `none`, `when`, `when_some`, Context API, `define_component`, `memo` (Gleam 구조 동등성 비교), `flush_sync` |
| `glendix/react/attribute` | Attribute 타입 + 108+ HTML 속성 함수 — `class`, `id`, `style`, `popover`, `fetch_priority`, `enter_key_hint`, 마이크로데이터, Shadow DOM 등 |
| `glendix/react/hook` | React Hooks 40개 — `use_state`, `use_effect`, `use_layout_effect`, `use_insertion_effect`, `use_memo`, `use_callback`, `use_ref`, `use_reducer`, `use_context`, `use_id`, `use_transition`, `use_async_transition`, `use_deferred_value`, `use_optimistic`/`use_optimistic_`, `use_imperative_handle`, `use_lazy_state`, `use_sync_external_store`, `use_debug_value`, `use_promise` (React.use), `use_form_status` |
| `glendix/react/ref` | Ref 접근자 — `current`, `assign` (hook 모듈에서 분리) |
| `glendix/react/event` | 16개 이벤트 타입 + 154+ 핸들러 (캡처 단계, 트랜지션 이벤트 포함) + 82+ 접근자 |
| `glendix/react/html` | 85+ HTML 태그 편의 함수 — `div`, `span`, `input`, `details`, `dialog`, `video`, `ruby`, `kbd`, `search`, `meta`, `script`, `object` 등 (순수 Gleam, FFI 없음) |
| `glendix/react/svg` | 58 SVG 요소 편의 함수 — `svg`, `path`, `circle`, 16 필터 프리미티브, `discard` 등 (순수 Gleam, FFI 없음) |
| `glendix/react/svg_attribute` | 97+ SVG 전용 속성 함수 — `view_box`, `fill`, `stroke`, 마커, 필터 속성 등 (순수 Gleam, FFI 없음) |
| `glendix/binding` | 외부 React 컴포넌트 바인딩 — `.mjs` 없이 `bindings.json`만으로 사용 |
| `glendix/widget` | .mpk 위젯 컴포넌트 바인딩 — `widgets/` 디렉토리의 Mendix 위젯을 React 컴포넌트로 사용 |
| `glendix/classic` | Classic (Dojo) 위젯 React 래퍼 — `classic.render(widget_id, properties)` 패턴 |
| `glendix/marketplace` | Mendix Marketplace 위젯 인터랙티브 검색·다운로드 — `gleam run -m glendix/marketplace` |

### Mendix

| Module | Description |
|---|---|
| `glendix/mendix` | 핵심 타입 (`ValueStatus`, `ObjectItem`) + JsProps 접근자 (`get_prop`, `get_string_prop`) |
| `glendix/mendix/editable_value` | 편집 가능한 값 — `value`, `set_value`, `set_text_value`, `display_value` |
| `glendix/mendix/action` | 액션 실행 — `can_execute`, `execute`, `execute_if_can` |
| `glendix/mendix/dynamic_value` | 동적 읽기 전용 값 (표현식 속성) |
| `glendix/mendix/list_value` | 리스트 데이터 — `items`, `set_filter`, `set_sort_order`, `reload` |
| `glendix/mendix/list_attribute` | 리스트 아이템별 접근 — `ListAttributeValue`, `ListActionValue`, `ListWidgetValue` |
| `glendix/mendix/selection` | 단일/다중 선택 |
| `glendix/mendix/reference` | 단일 연관 관계 (ReferenceValue) |
| `glendix/mendix/reference_set` | 다중 연관 관계 (ReferenceSetValue) |
| `glendix/mendix/date` | JS Date opaque 래퍼 (월: Gleam 1-based ↔ JS 0-based 자동 변환) |
| `glendix/mendix/big` | Big.js 고정밀 십진수 래퍼 (`compare` → `gleam/order.Order`) |
| `glendix/mendix/file` | `FileValue`, `WebImage` |
| `glendix/mendix/icon` | `WebIcon` — Glyph, Image, IconFont |
| `glendix/mendix/formatter` | `ValueFormatter` — `format`, `parse` |
| `glendix/mendix/filter` | FilterCondition 빌더 — `and_`, `or_`, `equals`, `contains`, `attribute`, `literal` |

## Examples

### Attribute 리스트

```gleam
import glendix/react/attribute
import glendix/react/event
import glendix/react/html

html.button(
  [
    attribute.class("btn btn-primary"),
    attribute.type_("submit"),
    attribute.disabled(False),
    event.on_click(fn(_event) { Nil }),
  ],
  [react.text("Submit")],
)
```

조건부 속성은 `attribute.none()`으로 처리한다:

```gleam
html.input([
  attribute.class("input"),
  case is_error {
    True -> attribute.class("input-error")
    False -> attribute.none()
  },
])
```

### useState + useEffect

```gleam
import gleam/int
import glendix/react
import glendix/react/attribute
import glendix/react/event
import glendix/react/hook
import glendix/react/html

pub fn counter(_props) -> react.ReactElement {
  let #(count, set_count) = hook.use_state(0)

  hook.use_effect_once(fn() {
    // 마운트 시 한 번 실행
    Nil
  })

  html.div_([
    html.button(
      [event.on_click(fn(_) { set_count(count + 1) })],
      [react.text("Count: " <> int.to_string(count))],
    ),
  ])
}
```

### useLayoutEffect (레이아웃 측정)

```gleam
import glendix/react/hook

// DOM 변경 후 브라우저 페인트 전 동기 실행
let ref = hook.use_ref(0.0)

hook.use_layout_effect_cleanup(
  fn() {
    // 레이아웃 측정 로직
    fn() { Nil }  // cleanup
  },
  [some_dep],
)
```

### Mendix EditableValue 읽기/쓰기

```gleam
import gleam/option.{None, Some}
import glendix/mendix
import glendix/mendix/editable_value as ev

pub fn render_input(props: react.JsProps) -> react.ReactElement {
  case mendix.get_prop(props, "myAttribute") {
    Some(attr) -> {
      let display = ev.display_value(attr)
      let editable = ev.is_editable(attr)
      // ...
    }
    None -> react.none()
  }
}
```

### 조건부 렌더링

```gleam
import glendix/react
import glendix/react/html

// Bool 기반
react.when(is_visible, fn() {
  html.div_([react.text("Visible!")])
})

// Option 기반
react.when_some(maybe_user, fn(user) {
  html.span_([react.text(user.name)])
})
```

### 외부 React 컴포넌트 사용 (바인딩)

`.mjs` 파일 작성 없이 외부 React 라이브러리를 사용합니다.

**1. `bindings.json` 작성:**

```json
{
  "recharts": {
    "components": ["PieChart", "Pie", "Cell", "Tooltip", "Legend"]
  }
}
```

**2. 패키지 설치** — `bindings.json`에 등록한 패키지는 `node_modules`에 설치되어 있어야 합니다:

```bash
npm install recharts
```

**3. `gleam run -m glendix/install` 실행** (바인딩 자동 생성)

**4. 순수 Gleam 래퍼 모듈 작성** (html.gleam과 동일한 호출 패턴):

```gleam
// src/chart/recharts.gleam
import glendix/binding
import glendix/react.{type ReactElement}
import glendix/react/attribute.{type Attribute}

fn m() { binding.module("recharts") }

pub fn pie_chart(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.component_el(binding.resolve(m(), "PieChart"), attrs, children)
}

pub fn pie(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.component_el(binding.resolve(m(), "Pie"), attrs, children)
}
```

**5. 위젯에서 사용:**

```gleam
import chart/recharts
import glendix/react/attribute

pub fn my_chart(data) -> react.ReactElement {
  recharts.pie_chart(
    [attribute.attribute("width", 400), attribute.attribute("height", 300)],
    [
      recharts.pie(
        [attribute.attribute("data", data), attribute.attribute("dataKey", "value")],
        [],
      ),
    ],
  )
}
```

### .mpk 위젯 컴포넌트 사용

`widgets/` 디렉토리의 `.mpk` 파일을 React 컴포넌트로 import하여 사용합니다.

**1. `widgets/` 디렉토리에 `.mpk` 파일 배치**

**2. `gleam run -m glendix/install` 실행** (위젯 바인딩 자동 생성)

install 시 두 가지가 자동 수행됩니다:
- `.mpk`에서 `.mjs`/`.css` 추출 + `widget_ffi.mjs` 생성
- `.mpk` XML의 `<property>` 정의를 파싱하여 `src/widgets/`에 바인딩 `.gleam` 파일 자동 생성 (이미 존재하면 건너뜀)

**3. 자동 생성된 `src/widgets/*.gleam` 파일 확인:**

```gleam
// src/widgets/switch.gleam (자동 생성)
import glendix/mendix
import glendix/react.{type JsProps, type ReactElement}
import glendix/react/attribute
import glendix/widget

/// Switch 위젯 렌더링 - props에서 속성을 읽어 위젯에 전달
pub fn render(props: JsProps) -> ReactElement {
  let boolean_attribute = mendix.get_prop_required(props, "booleanAttribute")
  let action = mendix.get_prop_required(props, "action")

  let comp = widget.component("Switch")
  react.component_el(
    comp,
    [
      attribute.attribute("booleanAttribute", boolean_attribute),
      attribute.attribute("action", action),
    ],
    [],
  )
}
```

required/optional 속성이 자동 구분되며, 필요에 따라 생성된 파일을 자유롭게 수정할 수 있습니다.

**4. 위젯에서 사용:**

```gleam
import widgets/switch

// 컴포넌트 내부에서
switch.render(props)
```

### Marketplace 위젯 다운로드

Mendix Marketplace에서 위젯(.mpk)을 인터랙티브하게 검색·다운로드합니다. 다운로드 완료 후 `src/widgets/`에 바인딩 `.gleam` 파일이 자동 생성됩니다.

**1. `.env` 파일에 Mendix PAT 설정:**

```
MENDIX_PAT=your_personal_access_token
```

> PAT는 Mendix Portal → Settings → Personal Access Tokens에서 발급합니다. 필요한 scope: `mx:marketplace-content:read`

**2. 실행:**

```bash
gleam run -m glendix/marketplace
```

**3. 인터랙티브 TUI 사용:**

```
  ── 페이지 1/5+ ──

  [0] Star Rating (54611) v3.2.2 — Mendix
  [1] Switch (50324) v4.0.0 — Mendix
  ...

  번호: 다운로드 | 검색어: 이름 검색 | n: 다음 | p: 이전 | r: 초기화 | q: 종료

> 0              ← 번호 입력으로 다운로드
> star           ← 검색어로 필터링
> 0,1,3          ← 쉼표로 여러 위젯 동시 다운로드
```

위젯 선택 시 버전 목록이 표시되며, Pluggable/Classic 타입이 자동 구분됩니다. 다운로드된 `.mpk`는 `widgets/` 디렉토리에 저장되고, `cmd.generate_widget_bindings()`가 자동 호출되어 `src/widgets/`에 바인딩 코드가 생성됩니다.

> 버전 정보 조회 시 Playwright(chromium)를 사용합니다. 첫 다운로드 시 브라우저 로그인이 필요하며, 세션은 `.marketplace-cache/session.json`에 저장됩니다.

## Build Scripts

glendix에 내장된 빌드 스크립트로, 위젯 프로젝트에서 별도 스크립트 파일 없이 `gleam run -m`으로 실행한다.

| 명령어 | 설명 |
|--------|------|
| `gleam run -m glendix/install` | 의존성 설치 + 바인딩 생성 + 위젯 바인딩 생성 + 위젯 `.gleam` 파일 생성 (PM 자동 감지) |
| `gleam run -m glendix/marketplace` | Mendix Marketplace 위젯 검색·다운로드 (인터랙티브 TUI) |
| `gleam run -m glendix/build` | 프로덕션 빌드 (.mpk 생성) |
| `gleam run -m glendix/dev` | 개발 서버 (HMR, port 3000) |
| `gleam run -m glendix/start` | Mendix 테스트 프로젝트 연동 |
| `gleam run -m glendix/lint` | ESLint 실행 |
| `gleam run -m glendix/lint_fix` | ESLint 자동 수정 |
| `gleam run -m glendix/release` | 릴리즈 빌드 |

패키지 매니저는 lock 파일 기반으로 자동 감지된다:
- `pnpm-lock.yaml` → pnpm
- `bun.lockb` / `bun.lock` → bun
- 기본값 → npm

## Architecture

```
glendix/
  react.gleam              ← 핵심 타입 + createElement + Context + keyed + 컴포넌트 정의 + flushSync
  react_ffi.mjs            ← 요소 생성, Fragment, Context, 고급 컴포넌트 어댑터, Gleam 구조 동등성 memo
  react/
    attribute.gleam         ← Attribute 타입 + 108+ HTML 속성 함수
    attribute_ffi.mjs       ← Attribute → React props 변환
    hook.gleam              ← React Hooks (40개, use_promise, use_form_status 포함)
    hook_ffi.mjs            ← Hooks FFI 어댑터
    ref.gleam               ← Ref 접근자 (current, assign)
    event.gleam             ← 16 이벤트 타입 + 154+ 핸들러 + 82+ 접근자
    event_ffi.mjs           ← 이벤트 접근자 FFI 어댑터
    html.gleam              ← 85+ HTML 태그 (순수 Gleam)
    svg.gleam               ← 58 SVG 요소 (순수 Gleam)
    svg_attribute.gleam     ← 97+ SVG 전용 속성 (순수 Gleam)
  mendix.gleam              ← Mendix 핵심 타입 + Props 접근자
  mendix_ffi.mjs            ← Mendix 런타임 타입 접근 어댑터
  mendix/
    editable_value.gleam    ← EditableValue
    action.gleam            ← ActionValue
    dynamic_value.gleam     ← DynamicValue
    list_value.gleam        ← ListValue + Sort + Filter
    list_attribute.gleam    ← List-linked 타입
    selection.gleam         ← Selection
    reference.gleam         ← ReferenceValue (단일 참조)
    reference_set.gleam     ← ReferenceSetValue (다중 참조)
    date.gleam              ← JS Date 래퍼
    big.gleam               ← Big.js 래퍼
    file.gleam              ← File / Image
    icon.gleam              ← Icon
    formatter.gleam         ← ValueFormatter
    filter.gleam            ← FilterCondition 빌더
  binding.gleam             ← 외부 React 컴포넌트 바인딩 API
  binding_ffi.mjs           ← 바인딩 FFI (install 시 자동 교체)
  widget.gleam              ← .mpk 위젯 컴포넌트 바인딩 API
  widget_ffi.mjs            ← 위젯 바인딩 FFI (install 시 자동 교체)
  classic.gleam             ← Classic (Dojo) 위젯 React 래퍼
  classic_ffi.mjs           ← Classic 위젯 바인딩 FFI (install 시 자동 교체)
  marketplace.gleam         ← Marketplace 위젯 검색·다운로드
  marketplace_ffi.mjs       ← Content API + Playwright + S3 다운로드 FFI 어댑터
  cmd.gleam                 ← 셸 명령어 실행 + PM 감지 + 바인딩/위젯 바인딩 생성
  cmd_ffi.mjs               ← Node.js child_process + fs + ZIP 파싱 FFI + 바인딩/위젯 바인딩 생성 + 위젯 .gleam 파일 생성
  build.gleam               ← 빌드 스크립트
  dev.gleam                 ← 개발 서버 스크립트
  start.gleam               ← Mendix 연동 스크립트
  install.gleam             ← 의존성 설치 + 바인딩/위젯 바인딩 생성 스크립트
  release.gleam             ← 릴리즈 빌드 스크립트
  lint.gleam                ← ESLint 스크립트
  lint_fix.gleam            ← ESLint 자동 수정 스크립트
```

## Design Principles

- **FFI는 얇은 어댑터일 뿐이다.** `.mjs` 파일은 JS 런타임 접근만 담당하고, 비즈니스 로직은 전부 Gleam으로 작성한다. 모듈별 단일 책임 — `react_ffi.mjs`(요소 생성), `hook_ffi.mjs`(훅), `event_ffi.mjs`(이벤트 접근자).
- **Opaque type으로 타입 안전성 보장.** `ReactElement`, `JsProps`, `EditableValue` 등 JS 값을 Gleam의 opaque type으로 감싸 잘못된 접근을 컴파일 타임에 차단한다.
- **`undefined` ↔ `Option` 자동 변환.** FFI 경계에서 JS `undefined`/`null`은 Gleam `None`으로, 값이 있으면 `Some(value)`으로 변환된다.
- **Attribute 리스트 API.** HTML 속성은 `[attribute.class("x"), event.on_click(handler)]` 선언적 리스트 패턴. `attribute.none()`으로 조건부 속성 처리. 여러 `attribute.class()` 호출 시 자동 병합.
- **Gleam 튜플 = JS 배열.** `#(a, b)` = `[a, b]`이므로 `useState`의 반환값과 직접 호환된다.

## Acknowledgments

v2.0의 React 바인딩 개선은 [redraw](https://github.com/ghivert/redraw) 프로젝트의 설계 패턴을 참고했다. FFI 모듈 분리, Hook 변형 패턴, 이벤트 시스템 구조 등에서 영감을 받았다.

## License

Apache-2.0
