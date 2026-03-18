[English](README.md) | **한국어** | [日本語](README.ja.md)

# glendix

안녕! 여기는 glendix야! 진짜진짜 멋진 라이브러리라고!
Gleam이라는 언어로 Mendix Pluggable Widget을 만들 수 있게 해주는 거야!

**JSX 같은 거 없이도 순수하게 Gleam만으로 Mendix 위젯을 만들 수 있어! 완전 신기하지 않아?!**

React는 [redraw](https://github.com/ghivert/redraw)/[redraw_dom](https://github.com/ghivert/redraw)이 담당하고, TEA 패턴은 [lustre](https://github.com/lustre-labs/lustre)가 담당해! glendix는 Mendix 관련된 것만 집중하는 거야!

## v3.0에서 뭐가 달라졌냐면요!

v3.0은 진짜 엄청나게 바뀌었어! `glendix/react` 레이어를 통째로 날려버렸어! (파일 14개나!) React 바인딩은 이제 **redraw**랑 **redraw_dom**한테 맡기는 거야! 그리고 **Lustre 브릿지**도 새로 만들어서 TEA 패턴을 Mendix 위젯 안에서 쓸 수 있게 됐어!

### 이런 게 바뀌었어!

- **React 바인딩 삭제됐어**: `glendix/react`, `glendix/react/attribute`, `glendix/react/hook`, `glendix/react/html`, `glendix/react/event`, `glendix/react/svg`, `glendix/react/svg_attribute`, `glendix/react/ref` — 전부 없어졌어! 대신 `redraw`랑 `redraw_dom` 직접 쓰면 돼!
- **새로운 `glendix/interop`**: 외부 JS React 컴포넌트(`widget`이랑 `binding`에서 가져온 거)를 `redraw.Element`로 연결해주는 거야!
- **새로운 `glendix/lustre`**: Lustre TEA 브릿지야! — `use_tea`랑 `use_simple` 훅으로 순수 Lustre `update`/`view` 함수 쓰고 React 엘리먼트로 렌더링할 수 있어!
- **`JsProps` 이사갔어**: `glendix/react.{type JsProps}` 대신 `glendix/mendix.{type JsProps}`로 바뀌었어!
- **`ReactElement` → `Element`**: 반환 타입이 이제 `redraw.{type Element}`야!

### 마이그레이션 치트시트!

| 전 (v2) | 후 (v3) |
|---|---|
| `import glendix/react.{type ReactElement}` | `import redraw.{type Element}` |
| `import glendix/react.{type JsProps}` | `import glendix/mendix.{type JsProps}` |
| `import glendix/react/html` | `import redraw/dom/html` |
| `import glendix/react/attribute` | `import redraw/dom/attribute` |
| `import glendix/react/event` | `import redraw/dom/events` |
| `import glendix/react/hook` | `import redraw` (훅이 메인 모듈에 있어!) |
| `import glendix/react/svg` | `import redraw/dom/svg` |
| `import glendix/react/ref` | `import redraw/ref` |
| `react.text("hi")` | `html.text("hi")` |
| `react.none()` | `html.none()` |
| `react.fragment(children)` | `redraw.fragment(children)` |
| `react.define_component(name, render)` | `redraw.component_(name, render)` |
| `react.memo(component)` | `redraw.memoize_(component)` |
| `hook.use_state(0)` | `redraw.use_state(0)` |
| `hook.use_effect(fn, deps)` | `redraw.use_effect(fn, deps)` |
| `react.component_el(comp, attrs, children)` | `interop.component_el(comp, attrs, children)` |
| `react.when(cond, fn)` | `case cond { True -> fn() False -> html.none() }` |

## 설치하는 방법!

`gleam.toml`에 이거 넣으면 돼! 진짜 간단하지?

```toml
# gleam.toml
[dependencies]
glendix = ">= 3.0.0 and < 4.0.0"
```

### 같이 필요한 것들

위젯 프로젝트의 `package.json`에 이것도 넣어줘야 해:

```json
{
  "dependencies": {
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "big.js": "^6.0.0"
  }
}
```

## 자 이제 시작해보자!

봐봐, 위젯 하나 만드는 게 이렇게 짧아! 대박이지?

```gleam
import glendix/mendix.{type JsProps}
import redraw.{type Element}
import redraw/dom/attribute
import redraw/dom/html

pub fn widget(props: JsProps) -> Element {
  let name = mendix.get_string_prop(props, "sampleText")
  html.div([attribute.class("my-widget")], [
    html.text("Hello " <> name),
  ])
}
```

`fn(JsProps) -> Element` — Mendix Pluggable Widget에 필요한 건 딱 이게 끝이야! 완전 쉽지?!

### Lustre TEA 패턴 쓰기!

The Elm Architecture가 좋다면 Lustre 브릿지를 쓰면 돼! `update`랑 `view` 함수가 100% 표준 Lustre야:

```gleam
import glendix/lustre as gl
import glendix/mendix.{type JsProps}
import lustre/effect
import lustre/element/html
import lustre/event
import redraw.{type Element}

type Model { Model(count: Int) }
type Msg { Increment }

fn update(model, msg) {
  case msg {
    Increment -> #(Model(model.count + 1), effect.none())
  }
}

fn view(model: Model) {
  html.div([], [
    html.button([event.on_click(Increment)], [
      html.text("Count: " <> int.to_string(model.count)),
    ]),
  ])
}

pub fn widget(_props: JsProps) -> Element {
  gl.use_tea(#(Model(0), effect.none()), update, view)
}
```

## 모듈 소개!

### React & 렌더링 (redraw 쪽!)

| 모듈 | 뭐 하는 건지! |
|---|---|
| `redraw` | 컴포넌트, 훅, fragment, context — Gleam으로 쓰는 React API 풀세트! |
| `redraw/dom/html` | HTML 태그들! — `div`, `span`, `input`, `text`, `none`, 엄청 많아! |
| `redraw/dom/attribute` | Attribute 타입 + HTML 속성 함수들! — `class`, `id`, `style` 등등! |
| `redraw/dom/events` | 이벤트 핸들러! — `on_click`, `on_change`, `on_input`, 캡처 버전까지! |
| `redraw/dom/svg` | SVG 요소들! — `svg`, `path`, `circle`, 필터 프리미티브 등등! |
| `redraw/dom` | DOM 유틸리티! — `create_portal`, `flush_sync`, 리소스 힌트! |

### glendix 브릿지!

| 모듈 | 뭐 하는 건지! |
|---|---|
| `glendix/interop` | 외부 JS React 컴포넌트(`widget`/`binding`에서 가져온 거)를 `redraw.Element`로 렌더링! |
| `glendix/lustre` | Lustre TEA 브릿지! — `use_tea`, `use_simple`, `render`, `embed` |
| `glendix/binding` | 다른 사람이 만든 React 컴포넌트 쓰는 거! — `bindings.json`만 쓰면 되고 `.mjs` 안 만들어도 돼! |
| `glendix/widget` | `.mpk` 위젯을 `widgets/` 폴더에서 쓰는 거! — `component`, `prop`, `editable_prop`, `action_prop` |
| `glendix/classic` | 옛날 Classic (Dojo) 위젯 래퍼 — `classic.render(widget_id, properties)` 패턴 |
| `glendix/marketplace` | Mendix Marketplace에서 위젯 검색하고 다운받는 거! |
| `glendix/define` | 위젯 프로퍼티 정의 TUI 에디터! |

### Mendix 쪽!

| 모듈 | 뭐 하는 건지! |
|---|---|
| `glendix/mendix` | Mendix 핵심 타입들 (`ValueStatus`, `ObjectItem`, `JsProps`) + props에서 값 꺼내기 |
| `glendix/mendix/editable_value` | 값 바꿀 수 있는 것들! — `value`, `set_value`, `set_text_value`, `display_value` |
| `glendix/mendix/action` | 액션 실행하기! — `can_execute`, `execute`, `execute_if_can` |
| `glendix/mendix/dynamic_value` | 읽기만 되는 동적 값 (표현식 속성 같은 거) |
| `glendix/mendix/list_value` | 리스트 데이터! — `items`, `set_filter`, `set_sort_order`, `reload` |
| `glendix/mendix/list_attribute` | 리스트 아이템별로 접근하는 타입들 — `ListAttributeValue`, `ListActionValue`, `ListWidgetValue` |
| `glendix/mendix/selection` | 하나 고르기, 여러 개 고르기! |
| `glendix/mendix/reference` | 하나랑 연결 (ReferenceValue) — 친구 한 명 가리키는 것 같은 거! |
| `glendix/mendix/reference_set` | 여러 개랑 연결 (ReferenceSetValue) — 친구 여러 명 가리키는 거! |
| `glendix/mendix/date` | JS Date 래퍼 (월이 Gleam에서는 1부터, JS에서는 0부터인데 알아서 바꿔줘! 똑똑하지?) |
| `glendix/mendix/big` | Big.js 래퍼야! 엄청 정확한 숫자 쓸 때 필요해! |
| `glendix/mendix/file` | `FileValue`, `WebImage` |
| `glendix/mendix/icon` | `WebIcon` — Glyph, Image, IconFont |
| `glendix/mendix/formatter` | `ValueFormatter` — `format`이랑 `parse` |
| `glendix/mendix/filter` | FilterCondition 빌더! |
| `glendix/editor_config` | Editor Configuration 도우미! (Jint이랑 호환돼!) |

### JS Interop 쪽!

| 모듈 | 뭐 하는 건지! |
|---|---|
| `glendix/js/array` | Gleam List ↔ JS Array 변환! |
| `glendix/js/object` | 객체 만들기, 속성 읽기/쓰기/삭제, 메서드 호출, `new`로 인스턴스 생성! |
| `glendix/js/json` | `stringify`랑 `parse`! (parse는 `Result`로 돌려줘서 안전해!) |
| `glendix/js/promise` | Promise 체이닝 (`then_`, `map`, `catch_`), `all`, `race`, `resolve`, `reject` |
| `glendix/js/dom` | DOM 조작! — `focus`, `blur`, `click`, `scroll_into_view`, `query_selector` |
| `glendix/js/timer` | `set_timeout`, `set_interval`, `clear_timeout`, `clear_interval` |

## 예제 모음!

### Attribute 리스트

버튼 만들 때 이렇게 속성을 리스트로 쭉 쓰면 돼! 장보기 목록 같지 않아?

```gleam
import redraw/dom/attribute
import redraw/dom/events
import redraw/dom/html

html.button(
  [
    attribute.class("btn btn-primary"),
    attribute.type_("submit"),
    attribute.disabled(False),
    events.on_click(fn(_event) { Nil }),
  ],
  [html.text("Submit")],
)
```

### useState + useEffect

카운터야! 버튼 누르면 숫자가 하나씩 올라가! 마법 같지?!

```gleam
import gleam/int
import redraw
import redraw/dom/attribute
import redraw/dom/events
import redraw/dom/html

pub fn counter(_props) -> redraw.Element {
  let #(count, set_count) = redraw.use_state(0)

  redraw.use_effect(fn() { Nil }, Nil)

  html.div([], [
    html.button(
      [events.on_click(fn(_) { set_count(count + 1) })],
      [html.text("Count: " <> int.to_string(count))],
    ),
  ])
}
```

### Mendix 값 읽고 쓰기!

Mendix에서 값 꺼내서 쓰는 방법이야:

```gleam
import gleam/option.{None, Some}
import glendix/mendix.{type JsProps}
import glendix/mendix/editable_value as ev
import redraw.{type Element}
import redraw/dom/html

pub fn render_input(props: JsProps) -> Element {
  case mendix.get_prop(props, "myAttribute") {
    Some(attr) -> {
      let display = ev.display_value(attr)
      let editable = ev.is_editable(attr)
      // ...
    }
    None -> html.none()
  }
}
```

### 다른 사람의 React 컴포넌트 쓰기 (바인딩)

npm에 있는 React 라이브러리를 `.mjs` 파일 없이 바로 쓸 수 있어! 완전 신기하지?!

**1. `bindings.json` 파일 만들기:**

```json
{
  "recharts": {
    "components": ["PieChart", "Pie", "Cell", "Tooltip", "Legend"]
  }
}
```

**2. 패키지 설치하기:**

```bash
npm install recharts
```

**3. `gleam run -m glendix/install` 실행!**

**4. Gleam 래퍼 모듈 쓰기:**

```gleam
// src/chart/recharts.gleam
import glendix/binding
import glendix/interop
import redraw.{type Element}
import redraw/dom/attribute.{type Attribute}

fn m() { binding.module("recharts") }

pub fn pie_chart(attrs: List(Attribute), children: List(Element)) -> Element {
  interop.component_el(binding.resolve(m(), "PieChart"), attrs, children)
}

pub fn pie(attrs: List(Attribute), children: List(Element)) -> Element {
  interop.component_el(binding.resolve(m(), "Pie"), attrs, children)
}
```

**5. 위젯에서 이렇게 쓰면 끝!:**

```gleam
import chart/recharts
import redraw/dom/attribute

pub fn my_chart(data) -> redraw.Element {
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

### .mpk 위젯 쓰기!

`.mpk` 파일을 `widgets/` 폴더에 넣으면 React 컴포넌트처럼 쓸 수 있어! 완전 쩔지 않아?!

**1. `.mpk` 파일을 `widgets/` 폴더에 넣기!**

**2. `gleam run -m glendix/install` 실행!** (바인딩 다 알아서 해줘!)

**3. 자동으로 만들어진 `src/widgets/*.gleam` 파일을 확인해봐:**

```gleam
// src/widgets/switch.gleam (자동으로 만들어진 거야!)
import glendix/mendix.{type JsProps}
import glendix/interop
import glendix/widget
import redraw.{type Element}
import redraw/dom/attribute

pub fn render(props: JsProps) -> Element {
  let boolean_attribute = mendix.get_prop_required(props, "booleanAttribute")
  let action = mendix.get_prop_required(props, "action")

  let comp = widget.component("Switch")
  interop.component_el(
    comp,
    [
      attribute.attribute("booleanAttribute", boolean_attribute),
      attribute.attribute("action", action),
    ],
    [],
  )
}
```

**4. 위젯에서 이렇게 쓰면 돼:**

Mendix에서 받은 prop은 그대로 전달하면 되고, 코드에서 직접 값을 만들 때는 위젯 prop 헬퍼를 쓰면 돼!

```gleam
// 코드에서 직접 값 만들기 (Lustre TEA 뷰 등)
import glendix/widget

widget.prop("caption", "제목")                                  // DynamicValue
widget.editable_prop("text", value, display, set_value)         // EditableValue
widget.action_prop("onClick", fn() { handle_click() })          // ActionValue
```

```gleam
import widgets/switch

switch.render(props)
```

### Marketplace에서 위젯 다운받기!

Mendix Marketplace에서 위젯을 검색하고 바로 다운받을 수 있어! 터미널에서 다 돼! 완전 편하다!

**1. `.env` 파일에 Mendix PAT 넣기:**

```
MENDIX_PAT=your_personal_access_token
```

> PAT는 [Mendix Developer Settings](https://user-settings.mendix.com/link/developersettings)에서 **Personal Access Tokens** 밑에 **New Token** 누르면 발급받을 수 있어! `mx:marketplace-content:read` 권한이 필요해!

**2. 이거 실행하면 돼:**

```bash
gleam run -m glendix/marketplace
```

**3. 귀여운 인터랙티브 메뉴가 나와!:**

```
  ── 페이지 1/5+ ──

  [0] Star Rating (54611) v3.2.2 — Mendix
  [1] Switch (50324) v4.0.0 — Mendix
  ...

  번호: 다운로드 | 검색어: 이름 검색 | n: 다음 | p: 이전 | r: 초기화 | q: 종료

> 0              ← 번호 누르면 다운받아!
> star           ← 이름으로 찾을 수도 있어!
> 0,1,3          ← 쉼표로 여러 개 한꺼번에!
```

## 빌드 스크립트!

| 명령어 | 뭐 하는 건지! |
|--------|-------------|
| `gleam run -m glendix/install` | 의존성 설치 + 바인딩 생성 + 위젯 파일 생성! |
| `gleam run -m glendix/marketplace` | Marketplace에서 위젯 검색하고 다운받기! |
| `gleam run -m glendix/define` | 위젯 프로퍼티 정의를 TUI로 편집! |
| `gleam run -m glendix/build` | 프로덕션 빌드! (.mpk 파일 만들어줘!) |
| `gleam run -m glendix/dev` | 개발 서버! (HMR이라서 고치면 바로 반영돼!) |
| `gleam run -m glendix/start` | Mendix 테스트 프로젝트 연결! |
| `gleam run -m glendix/lint` | ESLint로 코드 검사! |
| `gleam run -m glendix/lint_fix` | ESLint 문제 자동으로 고쳐줘! |
| `gleam run -m glendix/release` | 릴리즈 빌드! |

## 왜 이렇게 만들었냐면!

- **맡길 건 맡기고 중복은 안 해!** React 바인딩은 redraw 거, TEA 패턴은 lustre 거야! glendix는 Mendix 전용 — interop, 위젯, 바인딩, 빌드 도구만 담당해!
- **Opaque type으로 안전하게!** `JsProps`, `EditableValue` 같은 JS 값들을 Gleam 타입으로 꽁꽁 감싸서 실수로 이상하게 쓰면 컴파일할 때 잡아줘! 똑똑하지?
- **`undefined`가 `Option`으로 자동 변환!** JS에서 `undefined`나 `null`이 오면 Gleam에서는 `None`이 되고, 값이 있으면 `Some(value)`가 돼! 알아서 바꿔주니까 걱정 없어!
- **렌더링 방법이 두 가지야!** redraw로 직접 React 쓰거나 Lustre 브릿지로 TEA 패턴 쓰거나 — 둘 다 `redraw.Element`를 뱉으니까 자유롭게 조합할 수 있어!

## 고마운 분들!

glendix v3.0은 멋진 [redraw](https://github.com/ghivert/redraw)랑 [lustre](https://github.com/lustre-labs/lustre) 생태계 위에 만들어졌어! 두 프로젝트 모두 고마워!

## 라이선스

[Blue Oak Model License 1.0.0](LICENSE)
