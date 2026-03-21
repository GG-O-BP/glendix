[English](README.md) | **한국어** | [日本語](README.ja.md)

# glendix

안녕! 여기는 glendix야! 진짜진짜 멋진 라이브러리라고!
Gleam이라는 언어로 Mendix Pluggable Widget을 만들 수 있게 해주는 거야!

**JSX 같은 거 없이도 순수하게 Gleam만으로 Mendix 위젯을 만들 수 있어! 완전 신기하지 않아?!**

React는 [redraw](https://github.com/ghivert/redraw)/[redraw_dom](https://github.com/ghivert/redraw)이 담당하고, TEA 패턴은 [lustre](https://github.com/lustre-labs/lustre)가 담당해! Mendix 타입·위젯·마켓플레이스는 [mendraw](https://github.com/GG-O-BP/mendraw)한테 맡기고, glendix는 빌드 도구랑 바인딩에 집중하는 거야!

## v4.0에서 뭐가 달라졌냐면요!

v4.0에서는 Mendix API 타입, 위젯 바인딩(.mpk), Classic 위젯, 마켓플레이스를 전부 **mendraw**한테 맡기게 됐어! glendix는 이제 빌드 도구, 외부 React 컴포넌트 바인딩, Lustre 브릿지에만 집중해!

### 이런 게 바뀌었어!

- **Mendix 타입이 mendraw로 이사갔어**: `import glendix/mendix` → `import mendraw/mendix`, 하위 모듈(`editable_value`, `action`, `list_value` 등)도 전부 `mendraw/mendix/*`로!
- **interop이 mendraw로 이사갔어**: `import glendix/interop` → `import mendraw/interop`
- **widget이 mendraw로 이사갔어**: `import glendix/widget` → `import mendraw/widget`, TOML 설정도 `[tools.glendix.widgets.*]` → `[tools.mendraw.widgets.*]`
- **classic이 mendraw로 이사갔어**: `import glendix/classic` → `import mendraw/classic`
- **마켓플레이스가 mendraw로 이사갔어**: `gleam run -m glendix/marketplace` → `gleam run -m mendraw/marketplace`
- **glendix/binding은 그대로야!**: 외부 React 컴포넌트 바인딩은 glendix에 남아!
- **glendix/lustre도 그대로야!**: Lustre TEA 브릿지도 glendix에 남아!

### 마이그레이션 치트시트! (v3 → v4)

| 전 (v3) | 후 (v4) |
|---|---|
| `import glendix/mendix.{type JsProps}` | `import mendraw/mendix.{type JsProps}` |
| `import glendix/mendix/editable_value` | `import mendraw/mendix/editable_value` |
| `import glendix/mendix/action` | `import mendraw/mendix/action` |
| `import glendix/interop` | `import mendraw/interop` |
| `import glendix/widget` | `import mendraw/widget` |
| `import glendix/classic` | `import mendraw/classic` |
| `gleam run -m glendix/marketplace` | `gleam run -m mendraw/marketplace` |
| `[tools.glendix.widgets.X]` | `[tools.mendraw.widgets.X]` |

## 설치하는 방법!

`gleam.toml`에 이거 넣으면 돼! 진짜 간단하지?

```toml
# gleam.toml
[dependencies]
glendix = ">= 4.0.1 and < 5.0.0"
mendraw = ">= 1.1.9 and < 2.0.0"
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

> `big.js`는 Decimal 속성을 쓰는 위젯만 필요해! 안 쓰면 빼도 돼!

## 자 이제 시작해보자!

봐봐, 위젯 하나 만드는 게 이렇게 짧아! 대박이지?

```gleam
import mendraw/mendix.{type JsProps}
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
import mendraw/mendix.{type JsProps}
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
| `glendix/lustre` | Lustre TEA 브릿지! — `use_tea`, `use_simple`, `render`, `embed` |
| `glendix/binding` | 다른 사람이 만든 React 컴포넌트 쓰는 거! — `gleam.toml [tools.glendix.bindings]`에 설정하면 `.mjs` 안 만들어도 돼! |
| `glendix/define` | 위젯 프로퍼티 정의 TUI 에디터! |
| `glendix/editor_config` | Editor Configuration 도우미! (Jint이랑 호환돼!) |

### mendraw (Mendix API & 위젯)!

| 모듈 | 뭐 하는 건지! |
|---|---|
| `mendraw/mendix` | Mendix 핵심 타입들 (`ValueStatus`, `ObjectItem`, `JsProps`) + props에서 값 꺼내기 |
| `mendraw/interop` | 외부 JS React 컴포넌트를 `redraw.Element`로 렌더링! |
| `mendraw/widget` | `.mpk` 위젯 쓰는 거! — `gleam.toml`로 자동 다운로드! |
| `mendraw/classic` | 옛날 Classic (Dojo) 위젯 래퍼! |
| `mendraw/marketplace` | Mendix Marketplace에서 위젯 검색하고 다운받는 거! |

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
import mendraw/mendix.{type JsProps}
import mendraw/mendix/editable_value as ev
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

**1. `gleam.toml`에 바인딩 추가하기:**

```toml
[tools.glendix.bindings]
recharts = ["PieChart", "Pie", "Cell", "Tooltip", "Legend"]
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
import mendraw/interop
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

Marketplace 위젯을 React 컴포넌트처럼 쓸 수 있어! `gleam.toml`에 등록하고 자동 다운로드하면 돼!

`gleam.toml`에 위젯 설정하고 `gleam run -m glendix/install` 하면 끝!

```toml
[tools.mendraw.widgets.Charts]
version = "3.0.0"
# s3_id = "com/..."   ← 이거 있으면 인증 없이 바로 다운받아!
```

`build/widgets/`에 캐시하고 바인딩도 다 만들어줘!

**자동으로 만들어진 `src/widgets/*.gleam` 파일을 확인해봐:**

```gleam
// src/widgets/switch.gleam (자동으로 만들어진 거야!)
import mendraw/mendix.{type JsProps}
import mendraw/interop
import mendraw/widget
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
import mendraw/widget

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
gleam run -m mendraw/marketplace
```

**3. 귀여운 인터랙티브 메뉴가 나와!:**

```
  ── 페이지 1/5+ ──

  [0] Star Rating (54611) v3.2.2 — Mendix
  [1] Switch (50324) v4.0.1 — Mendix
  ...

  번호: 다운로드 | 검색어: 이름 검색 | n: 다음 | p: 이전 | r: 초기화 | q: 종료

> 0              ← 번호 누르면 다운받아!
> star           ← 이름으로 찾을 수도 있어!
> 0,1,3          ← 쉼표로 여러 개 한꺼번에!
```

다운받은 위젯은 `build/widgets/`에 캐시되고 `gleam.toml`에 자동으로 추가돼! `.mpk` 파일을 소스에 커밋 안 해도 돼서 완전 깔끔해!

## 빌드 스크립트!

| 명령어 | 뭐 하는 건지! |
|--------|-------------|
| `gleam run -m glendix/install` | 의존성 설치 + TOML 위젯 다운로드 + 바인딩 생성 + 위젯 파일 생성! |
| `gleam run -m mendraw/marketplace` | Marketplace에서 위젯 검색하고 다운받기! |
| `gleam run -m glendix/define` | 위젯 프로퍼티 정의를 TUI로 편집! |
| `gleam run -m glendix/build` | 프로덕션 빌드! (.mpk 파일 만들어줘!) |
| `gleam run -m glendix/dev` | 개발 서버! (HMR이라서 고치면 바로 반영돼!) |
| `gleam run -m glendix/start` | Mendix 테스트 프로젝트 연결! |
| `gleam run -m glendix/lint` | ESLint로 코드 검사! |
| `gleam run -m glendix/lint_fix` | ESLint 문제 자동으로 고쳐줘! |
| `gleam run -m glendix/release` | 릴리즈 빌드! |

## 왜 이렇게 만들었냐면!

- **맡길 건 맡기고 중복은 안 해!** React 바인딩은 redraw 거, TEA 패턴은 lustre 거, Mendix 타입·위젯은 mendraw 거야! glendix는 빌드 도구, 외부 바인딩, Lustre 브릿지만 담당해!
- **Opaque type으로 안전하게!** `JsProps`, `EditableValue` 같은 JS 값들을 Gleam 타입으로 꽁꽁 감싸서 실수로 이상하게 쓰면 컴파일할 때 잡아줘! 똑똑하지?
- **`undefined`가 `Option`으로 자동 변환!** JS에서 `undefined`나 `null`이 오면 Gleam에서는 `None`이 되고, 값이 있으면 `Some(value)`가 돼! 알아서 바꿔주니까 걱정 없어!
- **렌더링 방법이 두 가지야!** redraw로 직접 React 쓰거나 Lustre 브릿지로 TEA 패턴 쓰거나 — 둘 다 `redraw.Element`를 뱉으니까 자유롭게 조합할 수 있어!

## 고마운 분들!

glendix v4.0은 멋진 [redraw](https://github.com/ghivert/redraw), [lustre](https://github.com/lustre-labs/lustre), [mendraw](https://github.com/GG-O-BP/mendraw) 생태계 위에 만들어졌어! 세 프로젝트 모두 고마워!

## 라이선스

[Blue Oak Model License 1.0.0](LICENSE)
