# glendix

Gleam FFI bindings for React and Mendix Pluggable Widget API.

**JSX 없이, 순수 Gleam으로 Mendix Pluggable Widget을 작성한다.**

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
import glendix/react/html
import glendix/react/prop

pub fn widget(props: JsProps) -> ReactElement {
  let name = mendix.get_string_prop(props, "sampleText")
  html.div(prop.new() |> prop.class("my-widget"), [
    react.text("Hello " <> name),
  ])
}
```

`fn(JsProps) -> ReactElement` — 이것이 Mendix Pluggable Widget의 전부입니다.

## Modules

### React

| Module | Description |
|---|---|
| `glendix/react` | 핵심 타입 (`ReactElement`, `JsProps`, `Props`) + `el`, `fragment`, `text`, `none`, `when`, `when_some` |
| `glendix/react/prop` | Props 파이프라인 빌더 — `prop.new() \|> prop.class("x") \|> prop.on_click(handler)` |
| `glendix/react/hook` | React Hooks — `use_state`, `use_effect`, `use_memo`, `use_callback`, `use_ref` |
| `glendix/react/event` | 이벤트 타입 + `target_value`, `prevent_default`, `key` |
| `glendix/react/html` | HTML 태그 편의 함수 — `div`, `span`, `input`, `button` 등 (순수 Gleam, FFI 없음) |
| `glendix/binding` | 외부 React 컴포넌트 바인딩 — `.mjs` 없이 `bindings.json`만으로 사용 |

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
| `glendix/mendix/reference` | 연관 관계 (단일 참조, 다중 참조) |
| `glendix/mendix/date` | JS Date opaque 래퍼 (월: Gleam 1-based ↔ JS 0-based 자동 변환) |
| `glendix/mendix/big` | Big.js 고정밀 십진수 래퍼 (`compare` → `gleam/order.Order`) |
| `glendix/mendix/file` | `FileValue`, `WebImage` |
| `glendix/mendix/icon` | `WebIcon` — Glyph, Image, IconFont |
| `glendix/mendix/formatter` | `ValueFormatter` — `format`, `parse` |
| `glendix/mendix/filter` | FilterCondition 빌더 — `and_`, `or_`, `equals`, `contains`, `attribute`, `literal` |

## Examples

### Props 파이프라인

```gleam
import glendix/react/prop

let props =
  prop.new()
  |> prop.class("btn btn-primary")
  |> prop.string("type", "submit")
  |> prop.bool("disabled", False)
  |> prop.on_click(fn(_event) { Nil })
```

### useState + useEffect

```gleam
import glendix/react
import glendix/react/hook
import glendix/react/html
import glendix/react/prop

pub fn counter(_props) -> react.ReactElement {
  let #(count, set_count) = hook.use_state(0)

  hook.use_effect_once(fn() {
    // 마운트 시 한 번 실행
    Nil
  })

  html.div_([
    html.button(
      prop.new() |> prop.on_click(fn(_) { set_count(count + 1) }),
      [react.text("Count: " <> int.to_string(count))],
    ),
  ])
}
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

**4. 순수 Gleam으로 사용:**

```gleam
import glendix/binding
import glendix/react
import glendix/react/prop

fn recharts() { binding.module("recharts") }

pub fn my_chart(data) -> react.ReactElement {
  react.component(
    binding.resolve(recharts(), "PieChart"),
    prop.new() |> prop.int("width", 400) |> prop.int("height", 300),
    [
      react.component(
        binding.resolve(recharts(), "Pie"),
        prop.new() |> prop.any("data", data) |> prop.string("dataKey", "value"),
        [],
      ),
    ],
  )
}
```

## Build Scripts

glendix에 내장된 빌드 스크립트로, 위젯 프로젝트에서 별도 스크립트 파일 없이 `gleam run -m`으로 실행한다.

| 명령어 | 설명 |
|--------|------|
| `gleam run -m glendix/install` | 의존성 설치 + 바인딩 생성 (PM 자동 감지) |
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
  react.gleam           ← 핵심 타입 + createElement
  react_ffi.mjs         ← React 원시 함수 (얇은 어댑터)
  react/
    prop.gleam           ← Props 빌더
    hook.gleam           ← React Hooks
    event.gleam          ← 이벤트 타입
    html.gleam           ← HTML 태그 (순수 Gleam)
  mendix.gleam           ← Mendix 핵심 타입 + Props 접근자
  mendix_ffi.mjs         ← Mendix 런타임 타입 접근 (얇은 어댑터)
  mendix/
    editable_value.gleam ← EditableValue
    action.gleam         ← ActionValue
    dynamic_value.gleam  ← DynamicValue
    list_value.gleam     ← ListValue + Sort + Filter
    list_attribute.gleam ← List-linked 타입
    selection.gleam      ← Selection
    reference.gleam      ← Reference
    date.gleam           ← JS Date 래퍼
    big.gleam            ← Big.js 래퍼
    file.gleam           ← File / Image
    icon.gleam           ← Icon
    formatter.gleam      ← ValueFormatter
    filter.gleam         ← FilterCondition 빌더
  binding.gleam          ← 외부 React 컴포넌트 바인딩 API
  binding_ffi.mjs        ← 바인딩 FFI (install 시 자동 교체)
  cmd.gleam              ← 셸 명령어 실행 + PM 감지 + 바인딩 생성
  cmd_ffi.mjs            ← Node.js child_process + fs FFI + 바인딩 생성
  build.gleam            ← 빌드 스크립트
  dev.gleam              ← 개발 서버 스크립트
  start.gleam            ← Mendix 연동 스크립트
  install.gleam          ← 의존성 설치 + 바인딩 생성 스크립트
  release.gleam          ← 릴리즈 빌드 스크립트
  lint.gleam             ← ESLint 스크립트
  lint_fix.gleam         ← ESLint 자동 수정 스크립트
```

## Design Principles

- **FFI는 얇은 어댑터일 뿐이다.** `react_ffi.mjs`는 React 원시 함수, `mendix_ffi.mjs`는 Mendix 런타임 타입 접근자를 노출할 뿐, 비즈니스 로직은 전부 Gleam으로 작성한다.
- **Opaque type으로 타입 안전성 보장.** `ReactElement`, `JsProps`, `EditableValue` 등 JS 값을 Gleam의 opaque type으로 감싸 잘못된 접근을 컴파일 타임에 차단한다.
- **`undefined` ↔ `Option` 자동 변환.** FFI 경계에서 JS `undefined`/`null`은 Gleam `None`으로, 값이 있으면 `Some(value)`으로 변환된다.
- **파이프라인 API.** Props는 `prop.new() |> prop.class("x") |> prop.on_click(handler)` 패턴으로 구성한다.
- **Gleam 튜플 = JS 배열.** `#(a, b)` = `[a, b]`이므로 `useState`의 반환값과 직접 호환된다.

## License

Apache-2.0
