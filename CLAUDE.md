# CLAUDE.md — glendix

## 프로젝트 개요

Gleam FFI 라이브러리. React 19 + Mendix Pluggable Widget API 바인딩을 제공한다.
JSX 없이 순수 Gleam으로 Mendix Pluggable Widget을 작성하는 것이 목적이다.

- 언어: **Gleam** (target: JavaScript)
- 빌드: `gleam build` / `gleam check`
- 의존성: `gleam_stdlib >= 0.44.0`
- Peer deps (위젯 프로젝트 측): `react ^19.0.0`, `big.js ^6.0.0`
- 라이선스: Apache-2.0

## Gleam 언어 레퍼런스

Gleam 문법과 언어 기능은 `./docs/gleam_language_tour.md`를 참조한다.

## 핵심 아키텍처 규칙

### FFI 경계 원칙 (절대 준수)

1. **FFI 어댑터는 얇게 유지한다.** `.mjs` 파일은 JS 런타임 접근만 담당하고, 비즈니스 로직/변환 로직은 반드시 `.gleam`에 작성한다.
2. **Opaque type으로 JS 값을 감싼다.** `ReactElement`, `JsProps`, `EditableValue` 등은 모두 opaque type이다. 내부 구조를 직접 접근하지 않는다.
3. **`undefined`/`null` ↔ `Option` 자동 변환.** FFI 경계에서 `to_option()`/`from_option()`으로 변환한다. Gleam 쪽에서 `undefined`를 직접 다루지 않는다.
4. **Gleam 튜플 = JS 배열.** `#(a, b)` = `[a, b]` 호환성을 활용한다 (예: `useState` 반환값).
5. **Gleam List ↔ JS Array 변환.** FFI 경계에서 `toList()`/`.toArray()`로 변환한다.

### 코드 작성 규칙

- **Attribute 리스트 API**: HTML 속성은 `[attribute.class("x"), event.on_click(handler)]` 패턴. `attribute.none()`으로 조건부 속성 처리. 여러 `attribute.class()` 호출 시 자동 병합.
- **조건부 렌더링**: `react.when(bool, fn)`, `react.when_some(option, fn)` — if/else 대신 사용
- **Context API**: `react.create_context(default)` → `react.provider(ctx, value, children)` → `hook.use_context(ctx)`
- **컴포넌트 정의**: `react.define_component("Name", render_fn)` → DevTools 이름 표시. `react.memo(comp)` → 리렌더 방지.
- **`@external` 어노테이션**: FFI 함수 선언 시 상대 경로로 `.mjs` 파일 참조
- **한국어 주석**: 주석과 doc comment는 한국어로 작성
- **모듈별 단일 책임**: 각 `.gleam` 파일은 하나의 Mendix/React 타입을 담당

### Date 모듈 주의사항

`glendix/mendix/date`에서 **월(month)은 1-based**(1=1월). JS의 0-based를 FFI에서 자동 변환한다.
이 변환은 `mendix_ffi.mjs`의 `date_create`와 `date_get_month`에서 처리된다.

## 소스 구조

```
src/glendix/
├── react.gleam              # 핵심 타입 + element, element_, void_element, component_el, component_el_, void_component_el, fragment, keyed, text, none, when, when_some, Context, Promise, define_component, memo, StrictMode, Suspense, Profiler, portal, forwardRef, memo_, startTransition, flushSync
├── react_ffi.mjs            # React/ReactDOM 요소 생성, Fragment, Context, 컴포넌트 정의, Props 읽기, 고급 컴포넌트 어댑터, Gleam 구조 동등성 memo
├── react/
│   ├── attribute.gleam       # Attribute 타입 + 108+ HTML 속성 함수 (class, id, style, dangerouslySetInnerHTML, inputMode, inert, popover, fetchPriority 등)
│   ├── attribute_ffi.mjs     # Attribute → React props 변환 (className 자동 병합, style camelCase, dangerouslySetInnerHTML)
│   ├── hook.gleam            # useState, useEffect, useLayoutEffect, useInsertionEffect, useMemo, useCallback, useRef, useReducer, useContext, useId, useTransition, useAsyncTransition, useDeferredValue, useOptimistic, useOptimistic_, useImperativeHandle, useLazyState, useSyncExternalStore, useDebugValue, use_promise (React.use), useFormStatus
│   ├── hook_ffi.mjs          # React Hooks FFI 어댑터
│   ├── ref.gleam             # Ref 접근자 (current, assign) — hook에서 분리
│   ├── event.gleam           # 16개 이벤트 타입 + 154+ 핸들러 Attribute (캡처 단계 포함, 컴포지션/미디어/UI/로드/에러/트랜지션 이벤트) + 82+ 접근자
│   ├── event_ffi.mjs         # React 이벤트 접근자 FFI 어댑터
│   ├── html.gleam            # 85+ HTML 태그 편의 함수 (순수 Gleam, FFI 없음)
│   ├── svg.gleam             # 58 SVG 요소 편의 함수 (순수 Gleam, FFI 없음)
│   └── svg_attribute.gleam   # 97+ SVG 전용 속성 함수 (순수 Gleam, FFI 없음)
├── binding.gleam              # 외부 React 컴포넌트 바인딩 (JsModule, module, resolve)
├── binding_ffi.mjs            # 바인딩 FFI 스텁 (install 시 자동 교체)
├── widget.gleam               # .mpk Pluggable 위젯 컴포넌트 바인딩 (component)
├── widget_ffi.mjs             # Pluggable 위젯 바인딩 FFI 스텁 (install 시 자동 교체)
├── classic.gleam              # Classic (Dojo) 위젯 React 래퍼 (render, render_with_class)
├── classic_ffi.mjs            # Classic 위젯 바인딩 FFI 스텁 (install 시 자동 교체)
├── cmd.gleam                 # 셸 명령어 실행 + PM 감지 + 브릿지/바인딩 자동 생성 (exec, detect_runner, run_tool, run_tool_with_bridge, generate_bindings, generate_widget_bindings)
├── cmd_ffi.mjs               # Node.js child_process + fs + ZIP 파싱 FFI 어댑터 (exec, file_exists, run_with_bridge, generate_bindings, generate_widget_bindings, 위젯 속성 XML 주입)
├── build.gleam               # gleam run -m glendix/build (프로덕션 빌드)
├── dev.gleam                 # gleam run -m glendix/dev (개발 서버)
├── start.gleam               # gleam run -m glendix/start (Mendix 연동)
├── install.gleam             # gleam run -m glendix/install (의존성 설치 + 바인딩 생성)
├── marketplace.gleam         # gleam run -m glendix/marketplace (마켓플레이스 위젯 다운로드)
├── marketplace_ffi.mjs       # Marketplace Content API + S3 다운로드 FFI 어댑터
├── release.gleam             # gleam run -m glendix/release (릴리즈 빌드)
├── lint.gleam                # gleam run -m glendix/lint (ESLint)
├── lint_fix.gleam            # gleam run -m glendix/lint_fix (ESLint 자동 수정)
├── mendix.gleam              # ValueStatus, ObjectItem, JsProps 접근자
├── mendix_ffi.mjs            # Mendix 런타임 타입 접근 어댑터
└── mendix/
    ├── editable_value.gleam  # EditableValue (읽기/쓰기/유효성)
    ├── action.gleam          # ActionValue (실행/상태)
    ├── dynamic_value.gleam   # DynamicValue (표현식 속성)
    ├── list_value.gleam      # ListValue + SortInstruction + FilterCondition
    ├── list_attribute.gleam   # 리스트 아이템별 속성/액션/위젯 접근
    ├── selection.gleam        # 단일/다중 선택
    ├── reference.gleam        # 단일 연관 참조 (ReferenceValue)
    ├── reference_set.gleam    # 다중 연관 참조 (ReferenceSetValue)
    ├── date.gleam             # JS Date 래퍼 (월 1-based)
    ├── big.gleam              # Big.js 래퍼 (compare → gleam/order)
    ├── file.gleam             # FileValue, WebImage
    ├── icon.gleam             # WebIcon (Glyph, Image, IconFont)
    ├── formatter.gleam        # ValueFormatter (format, parse)
    └── filter.gleam           # FilterCondition 빌더 (mendix/filters/builders 래핑)
```

## 빌드 스크립트

`glendix/cmd` 모듈이 셸 명령어 실행과 패키지 매니저 감지를 담당한다. `cmd_ffi.mjs`가 Node.js `child_process.execSync`와 `fs.existsSync`를 제공한다.

PM 감지 메커니즘:
- `pnpm-lock.yaml` 존재 → pnpm
- `bun.lockb` 또는 `bun.lock` 존재 → bun
- 그 외 → npm (기본값)

`run_tool(args)` 함수가 감지된 runner + `pluggable-widgets-tools` + args를 조합하여 실행한다. `run_tool_with_bridge(args)`는 `package.json`의 `widgetName`과 `gleam.toml`의 `name`을 읽어 브릿지 JS 파일(`src/{WidgetName}.js`, `src/{WidgetName}.editorConfig.js`, `src/{WidgetName}.editorPreview.js`)을 자동 생성하고, 명령 완료 후 삭제한다. editorConfig과 editorPreview 브릿지는 각각 `src/editor_config.gleam`, `src/editor_preview.gleam` 존재 시에만 생성된다. `run_with_bridge`는 브릿지 생성 전에 `generate_bindings()`를 호출하여 바인딩을 자동 갱신하고, `gleam build`를 실행하여 Gleam 빌드 출력(.mjs)이 최신 상태임을 보장한다. 7개 스크립트 모듈(`build`, `dev`, `start`, `install`, `release`, `lint`, `lint_fix`)은 각각 `pub fn main()`을 노출하여 `gleam run -m glendix/<name>`으로 실행한다.

## 외부 React 컴포넌트 바인딩

`glendix/binding` 모듈로 외부 React 라이브러리의 컴포넌트를 **`.mjs` 파일 작성 없이** 순수 Gleam에서 사용할 수 있다.

### 동작 원리

1. 사용자가 프로젝트 루트에 `bindings.json`을 작성한다
2. `bindings.json`에 등록한 패키지를 `npm install`/`pnpm add`/`yarn add`/`bun add`로 설치한다 (생성된 `binding_ffi.mjs`가 해당 패키지를 직접 import하므로 `node_modules`에 존재해야 Rollup이 번들링할 수 있다)
3. `gleam run -m glendix/install` 실행 시 `binding_ffi.mjs`가 자동 생성된다
4. 생성된 파일은 glendix 빌드 경로(`build/packages/glendix/src/glendix/`, `build/dev/javascript/glendix/glendix/`)에 직접 배치된다
5. `run_with_bridge` (build/dev/start) 실행 시에도 자동 갱신된다

### bindings.json 형식

```json
{
  "recharts": {
    "components": ["PieChart", "Pie", "Cell", "LineChart", "Line", "XAxis", "YAxis", "CartesianGrid", "Tooltip", "Legend", "ResponsiveContainer"]
  },
  "@mui/material": {
    "components": ["Button", "TextField", "Dialog"]
  }
}
```

키는 npm 패키지명, `components`는 named export할 React 컴포넌트 목록이다.

### 사용자 코드 (순수 Gleam — html.gleam과 동일한 호출 패턴)

```gleam
import glendix/binding
import glendix/react.{type ReactElement}
import glendix/react/attribute.{type Attribute}

fn m() { binding.module("recharts") }

// attrs + children (html.div 패턴)
pub fn pie_chart(attrs: List(Attribute), children: List(ReactElement)) -> ReactElement {
  react.component_el(binding.resolve(m(), "PieChart"), attrs, children)
}

// children 없는 컴포넌트 (html.input 패턴)
pub fn tooltip(attrs: List(Attribute)) -> ReactElement {
  react.void_component_el(binding.resolve(m(), "Tooltip"), attrs)
}
```

### 생성되는 binding_ffi.mjs (자동)

```javascript
// @generated glendix/install — 직접 수정 금지
import { PieChart, Pie, Cell, ... } from "recharts";

const _modules = {
  "recharts": { PieChart, Pie, Cell, ... }
};

export function get_module(name) { return _modules[name]; }
export function resolve(mod, name) { return mod[name]; }
```

named import를 사용하므로 Rollup tree-shaking이 가능하다.

## Marketplace 위젯 다운로드

`glendix/marketplace` 모듈로 Mendix Marketplace에서 위젯(.mpk)을 인터랙티브하게 검색·다운로드할 수 있다.

### 사전 준비

`.env` 파일에 Mendix Personal Access Token 설정 (scope: `mx:marketplace-content:read`):
```
MENDIX_PAT=your_token_here
```

### 실행

```bash
gleam run -m glendix/marketplace
```

Content API(`GET /content?limit=100`)로 전체 목록을 로드한 뒤, 검색어 입력 시 이름/퍼블리셔로 클라이언트 필터링한다. 번호를 입력하면 S3에서 `.mpk`를 다운로드하고, 완료 후 `cmd.generate_widget_bindings()`를 자동 호출하여 `src/widgets/`에 바인딩 `.gleam` 파일도 생성한다.

### 다운로드 URL 규칙

`https://files.appstore.mendix.com/5/{contentId}/{version}/{FileName}.mpk` — S3 파일은 인증 불필요. `FileName`은 display name에서 공백 제거 PascalCase로 추측하고 HEAD 요청으로 검증한다.

## .mpk 위젯 바인딩

`glendix/widget` 모듈로 `widgets/` 디렉토리의 `.mpk` 파일(Mendix 위젯 빌드 결과물)을 React 컴포넌트로 사용할 수 있다.

### 동작 원리

1. `widgets/` 디렉토리에 `.mpk` 파일을 배치한다
2. `gleam run -m glendix/install` 실행 시:
   - `.mpk`에서 `.mjs`/`.css`를 추출하고 `widget_ffi.mjs`를 생성한다
   - `.mpk` XML의 `<property>` 정의를 파싱하여 `src/widgets/`에 바인딩 `.gleam` 파일을 자동 생성한다
   - 이미 동일 이름의 `.gleam` 파일이 존재하면 생성을 건너뛴다 (사용자 수정 보호)
3. 생성된 `widget_ffi.mjs`와 에셋은 glendix 빌드 경로에 배치된다
4. `run_with_bridge` (build/dev/start) 실행 시에도 자동 갱신된다

### 자동 생성되는 .gleam 파일 (src/widgets/)

`.mpk` XML의 `<property>` 정의에서 `key`와 `required` 속성을 파싱하여 바인딩 코드를 생성한다. 위젯 이름은 snake_case로 변환된다 ("Progress Bar" → `progress_bar.gleam`, "Switch" → `switch.gleam`).

```gleam
// Switch 위젯 바인딩 컴포넌트

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

optional 속성이 있으면 `optional_attr` 헬퍼와 `gleam/option` import가 자동 추가된다. Gleam 예약어(`type` 등)는 접미사 `_`로 회피한다.

### 사용자 코드

생성된 `src/widgets/*.gleam` 파일을 import하여 사용한다. 필요에 따라 자유롭게 수정 가능하다.

```gleam
import widgets/switch

// 컴포넌트 내부에서
switch.render(props)
```

위젯 Props는 기존 `attribute.attribute(key, value)` 범용 함수로 전달한다. 위젯 이름은 `.mpk` 내부 XML의 `<name>` 태그 값을 그대로 사용한다. property key는 `.mpk` XML의 원본 key를 그대로 사용한다.

## Classic (Dojo) 위젯 바인딩

`glendix/classic` 모듈로 Classic (Dojo 기반) Mendix 위젯을 Pluggable Widget 내부에서 사용할 수 있다.

### 동작 원리

1. `widgets/` 디렉토리에 Classic `.mpk` 파일을 배치한다
2. `gleam run -m glendix/install` 실행 시:
   - `package.xml`의 `clientModule` 존재 여부로 Classic/Pluggable을 자동 감지한다
   - Classic `.mpk`에서 JS/HTML/CSS/lib 파일을 추출하고 `classic_ffi.mjs`를 생성한다
   - `src/widgets/`에 `classic.render()` 패턴의 바인딩 `.gleam` 파일을 자동 생성한다
3. 런타임에서 Mendix Dojo AMD 로더(`window.require`, `window.define`)를 활용하여:
   - CSS를 `<style>` 태그로 `document.head`에 주입 (한 번만)
   - 위젯 JS를 `<script>` 태그로 실행하여 AMD `define()` 호출로 모듈 등록
   - `dojo/text!` 캐시에 HTML 템플릿 등록
   - `React.useRef` + `React.useEffect`로 DOM 컨테이너에 위젯 인스턴스 생성/파괴

### 자동 생성되는 .gleam 파일 (src/widgets/)

Classic 위젯은 `classic.render(widget_id, properties)` 패턴을 사용한다:

```gleam
// CameraWidget Classic 위젯 바인딩 컴포넌트

import gleam/dynamic
import glendix/classic
import glendix/mendix
import glendix/react.{type JsProps, type ReactElement}

/// CameraWidget Classic 위젯 렌더링
pub fn render(props: JsProps) -> ReactElement {
  let mf_to_execute = mendix.get_prop_required(props, "mfToExecute")
  let prefer_rear_camera = mendix.get_prop_required(props, "preferRearCamera")

  classic.render("CameraWidget.widget.CameraWidget", [
    #("mfToExecute", dynamic.from(mf_to_execute)),
    #("preferRearCamera", dynamic.from(prefer_rear_camera)),
  ])
}
```

### 사용자 코드

```gleam
import widgets/camera_widget

// 컴포넌트 내부에서
camera_widget.render(props)
```

### 직접 사용 (바인딩 없이)

```gleam
import gleam/dynamic
import glendix/classic

classic.render("CameraWidget.widget.CameraWidget", [
  #("mfToExecute", dynamic.from(my_microflow)),
  #("preferRearCamera", dynamic.from(True)),
])
```

## 새 모듈 추가 시 패턴

### Gleam 모듈 (.gleam)
```gleam
// [한국어 설명]

import glendix/mendix  // 필요한 내부 import

// opaque type 선언
pub type MyType

// FFI 바인딩 — getter
@external(javascript, "../mendix_ffi.mjs", "get_my_value")
pub fn value(obj: MyType) -> a

// 순수 Gleam 헬퍼 (FFI 불필요한 로직)
pub fn is_available(obj: MyType) -> Bool {
  mendix.get_status(obj) == mendix.Available
}
```

### FFI 어댑터 (.mjs)
```javascript
// 기존 mendix_ffi.mjs, react_ffi.mjs, 또는 cmd_ffi.mjs에 추가
// Option 변환이 필요하면 to_option/from_option 사용
// List 변환이 필요하면 toList/toArray 사용
export function get_my_value(obj) {
  return to_option(obj.value);
}
```

## Mendix Pluggable Widget API 레퍼런스

Mendix 공식 문서(docs.mendix.com)는 접근 불가하므로 GitHub raw 소스 사용:

### 문서 (GitHub)
- **Base**: `https://github.com/mendix/docs/blob/development/content/en/docs`
- **Pluggable Widgets API**: `apidocs-mxsdk/apidocs/pluggable-widgets/`
  - Property types, Client APIs, ListValue APIs 등
- **How-to (위젯 빌드 튜토리얼)**: `howto/extensibility/`
  - `create-a-pluggable-widget-one.md`, `create-a-pluggable-widget-two.md`

### 소스 코드 (GitHub)
- **Widget 빌드 도구**: `https://github.com/mendix/widgets-tools`
  - Rollup 설정, widget XML 스키마, 빌드 파이프라인
- **공식 위젯 예제**: `https://github.com/mendix/web-widgets`
  - `packages/pluggableWidgets/` 아래 실제 프로덕션 위젯 코드
  - 파일 구조, 테스트 패턴, XML 속성 정의 참고

### Mendix 위젯 핵심 개념
- 위젯 진입점: `fn(JsProps) -> ReactElement`
- Props는 `.xml` 파일에 정의한 속성이 런타임에 주입됨
- `ValueStatus`: `Available | Loading | Unavailable` — 값을 읽기 전에 반드시 확인
- `EditableValue.setValue()`: 값 변경, `ActionValue.execute()`: Microflow/Nanoflow 실행
- `ListValue`: 페이징(`offset`/`limit`), 정렬(`setSortOrder`), 필터(`setFilter`) 지원
- 외부 모듈 `mendix/filters/builders`는 Rollup에서 external 처리 필요

## 자주 하는 실수 (반드시 피할 것)

- FFI `.mjs` 파일에 비즈니스 로직을 넣지 않는다
- Gleam에서 JS `undefined`를 직접 다루지 않는다 — 반드시 `Option`으로 변환
- `html.gleam`은 순수 Gleam이다 — FFI 함수를 추가하지 않는다
- `date.gleam`의 month를 JS 0-based로 전달하지 않는다 — FFI가 자동 변환함
- `react.none()` 대신 빈 문자열이나 빈 리스트로 "아무것도 안 보여주기"를 하지 않는다
- `attribute.class()`를 여러 번 호출해도 괜찮다 — 자동으로 공백 구분 병합된다
- 조건부 속성에는 `attribute.none()`을 사용한다 — 렌더링 시 무시된다
- 외부 React 컴포넌트를 사용할 때 수동으로 `.mjs` FFI를 작성하지 않는다 — `bindings.json` + `glendix/binding`을 사용한다
- `binding.resolve()`의 컴포넌트 이름은 JS 원본 이름(PascalCase)을 그대로 사용한다 — snake_case로 변환하지 않는다
- `.mpk` 위젯을 사용할 때 수동으로 `.mjs` FFI를 작성하지 않는다 — `widgets/` 디렉토리 + `glendix/widget` 또는 `glendix/classic`을 사용한다
- `widget.component()`의 위젯 이름은 `.mpk` XML의 `<name>` 값(PascalCase)을 그대로 사용한다
- Classic 위젯과 Pluggable 위젯을 혼동하지 않는다 — Classic은 `glendix/classic.render()`, Pluggable은 `glendix/widget.component()`를 사용한다
- `classic.render()`의 widget_id는 `.mpk` XML의 `widget id="..."` 속성값(dot notation, 예: `"CameraWidget.widget.CameraWidget"`)을 그대로 사용한다
