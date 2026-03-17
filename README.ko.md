[English](README.md) | **한국어** | [日本語](README.ja.md)

# glendix

안녕! 여기는 glendix야! 진짜진짜 멋진 라이브러리라고!
Gleam이라는 언어로 React 19이랑 Mendix Pluggable Widget API를 쓸 수 있게 해주는 거야!

**JSX 같은 거 없이도 순수하게 Gleam만으로 Mendix 위젯을 만들 수 있어! 완전 신기하지 않아?!**

## v2.0에서 뭐가 달라졌냐면요!

v2.0은 진짜 엄청 좋아졌어! [redraw](https://github.com/ghivert/redraw)라는 멋진 프로젝트를 보고 많이 배웠거든. redraw는 Gleam으로 React를 쓸 수 있게 해주는 진짜 잘 만든 라이브러리인데, 타입 안전성이랑 모듈 구조가 완전 깔끔해! 근데 glendix는 Mendix 위젯 전용이니까 redraw의 범용 SPA 기능(bootstrap/compose, jsx-runtime 같은 거)은 안 가져왔고, 진짜 도움 되는 것만 쏙쏙 골라서 개선했어!

### 이런 게 바뀌었어!

- **FFI 모듈이 나눠졌어**: 원래 `react_ffi.mjs` 하나에 다 들어있었는데 너무 복잡했거든! 그래서 `hook_ffi.mjs`, `event_ffi.mjs`, `attribute_ffi.mjs`로 쪼갰어 — 하나씩 하나의 일만 하니까 훨씬 깔끔해!
- **Attribute 리스트 API**: 예전에 쓰던 `prop.gleam` 파이프라인을 버리고 `attribute.gleam`에서 리스트로 쓰는 걸로 바꿨어 — `[attribute.class("x"), event.on_click(handler)]` 이렇게 하면 돼! 쉽지?
- **Hook이 39개나 돼!**: `useLayoutEffect`, `useInsertionEffect`, `useImperativeHandle`, `useLazyState`, `useSyncExternalStore`, `useDebugValue`, `useOptimistic` (리듀서 버전도 있어!), `useAsyncTransition`, `useFormStatus`, cleanup 버전까지!
- **이벤트 핸들러가 154개 넘어!**: 캡처 단계, 컴포지션/미디어/UI/로드/에러/트랜지션 이벤트 + 접근자 82개 넘게 + `persist`/`is_persistent` 유틸리티까지 — 완전 많다!
- **HTML 속성이 108개 넘게!**: `dangerously_set_inner_html`, `popover`, `fetch_priority`, `enter_key_hint`, 마이크로데이터, Shadow DOM 등등등
- **HTML 태그도 85개 넘게!**: `fieldset`, `details`, `dialog`, `video`, `ruby`, `kbd`, `search`, `hgroup`, `meta`, `script`, `object` 등등 엄청 많아!
- **SVG 요소 58개**: 필터 프리미티브만 16개야 (`fe_convolve_matrix`, `fe_diffuse_lighting` 같은 거)
- **SVG 속성도 97개 넘게!**: 텍스트 렌더링, 마커, 마스크/클리핑, 필터 속성 — 끝이 없어!
- **고급 컴포넌트**: `StrictMode`, `Suspense`, `Profiler`, `portal`, `forwardRef`, `memo_`, `startTransition`, `flushSync` — 어른들이 쓰는 것도 다 있어!

## 설치하는 방법!

`gleam.toml`에 이거 넣으면 돼! 진짜 간단하지?

```toml
# gleam.toml
[dependencies]
glendix = { path = "../glendix" }
```

> 아직 Hex에 안 올라가서 로컬 경로로 써야 해! 미안~

### 같이 필요한 것들

위젯 프로젝트의 `package.json`에 이것도 넣어줘야 해:

```json
{
  "dependencies": {
    "react": "^19.0.0",
    "big.js": "^6.0.0"
  }
}
```

## 자 이제 시작해보자!

봐봐, 위젯 하나 만드는 게 이렇게 짧아! 대박이지?

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

`fn(JsProps) -> ReactElement` — Mendix Pluggable Widget에 필요한 건 딱 이게 끝이야! 완전 쉽지?!

## 모듈 소개!

### React 쪽!

| 모듈 | 뭐 하는 건지! |
|---|---|
| `glendix/react` | 제일 중요한 핵심! `ReactElement`, `JsProps`, `Component`, `Promise` 타입이랑 `element`, `fragment`, `keyed`, `text`, `none`, `when`, `when_some`, Context API, `define_component`, `memo` (Gleam 구조 동등성 비교라는 건데 완전 똑똑해!), `flush_sync` |
| `glendix/react/attribute` | Attribute 타입 + HTML 속성 함수 108개 넘게! — `class`, `id`, `style`, `popover`, `fetch_priority`, `enter_key_hint`, 마이크로데이터, Shadow DOM 등등 |
| `glendix/react/hook` | React Hook이 40개나!! — `use_state`, `use_effect`, `use_layout_effect`, `use_insertion_effect`, `use_memo`, `use_callback`, `use_ref`, `use_reducer`, `use_context`, `use_id`, `use_transition`, `use_async_transition`, `use_deferred_value`, `use_optimistic`/`use_optimistic_`, `use_imperative_handle`, `use_lazy_state`, `use_sync_external_store`, `use_debug_value`, `use_promise` (React.use야!), `use_form_status` |
| `glendix/react/ref` | Ref 접근자 — `current`이랑 `assign` (hook 모듈이랑 따로 분리해서 깔끔해!) |
| `glendix/react/event` | 이벤트 타입 16개 + 핸들러 154개 넘게 (캡처 단계, 트랜지션 이벤트 포함!) + 접근자 82개 넘게 |
| `glendix/react/html` | HTML 태그 85개 넘게! — `div`, `span`, `input`, `details`, `dialog`, `video`, `ruby`, `kbd`, `search`, `meta`, `script`, `object` 등등 (순수 Gleam이라 FFI 없어!) |
| `glendix/react/svg` | SVG 요소 58개! — `svg`, `path`, `circle`, 필터 프리미티브 16개, `discard` 등등 (순수 Gleam, FFI 없어!) |
| `glendix/react/svg_attribute` | SVG 전용 속성 함수 97개 넘게! — `view_box`, `fill`, `stroke`, 마커, 필터 속성 등등 (순수 Gleam, FFI 없어!) |
| `glendix/binding` | 다른 사람이 만든 React 컴포넌트 쓰는 거! — `bindings.json`만 쓰면 되고 `.mjs` 안 만들어도 돼! |
| `glendix/widget` | `.mpk` 위젯을 React 컴포넌트로 쓰는 거! — `widgets/` 폴더에 넣으면 끝! 완전 편해! |
| `glendix/classic` | 옛날 Classic (Dojo) 위젯 래퍼 — `classic.render(widget_id, properties)` 패턴 |
| `glendix/marketplace` | Mendix Marketplace에서 위젯 검색하고 다운받는 거! — `gleam run -m glendix/marketplace` |
| `glendix/define` | 위젯 프로퍼티 정의 TUI 에디터! — 그룹 추가, 타입 설정, 열거형 관리까지 터미널에서 다 돼! |

### Mendix 쪽!

| 모듈 | 뭐 하는 건지! |
|---|---|
| `glendix/mendix` | Mendix 핵심 타입들 (`ValueStatus`, `ObjectItem`) + JsProps에서 값 꺼내기 (`get_prop`, `get_string_prop`) |
| `glendix/mendix/editable_value` | 값 바꿀 수 있는 것들! — `value`, `set_value`, `set_text_value`, `display_value` |
| `glendix/mendix/action` | 액션 실행하기! — `can_execute`, `execute`, `execute_if_can` |
| `glendix/mendix/dynamic_value` | 읽기만 되는 동적 값 (표현식 속성 같은 거) |
| `glendix/mendix/list_value` | 리스트 데이터! — `items`, `set_filter`, `set_sort_order`, `reload` |
| `glendix/mendix/list_attribute` | 리스트 아이템별로 접근하는 타입들 — `ListAttributeValue`, `ListActionValue`, `ListWidgetValue` |
| `glendix/mendix/selection` | 하나 고르기, 여러 개 고르기! |
| `glendix/mendix/reference` | 하나랑 연결 (ReferenceValue) — 친구 한 명 가리키는 것 같은 거! |
| `glendix/mendix/reference_set` | 여러 개랑 연결 (ReferenceSetValue) — 친구 여러 명 가리키는 거! |
| `glendix/mendix/date` | JS Date 래퍼 (월이 Gleam에서는 1부터, JS에서는 0부터인데 알아서 바꿔줘! 똑똑하지?) |
| `glendix/mendix/big` | Big.js 래퍼야! 엄청 정확한 숫자 쓸 때 필요해 (`compare`하면 `gleam/order.Order`가 나와!) |
| `glendix/mendix/file` | `FileValue`, `WebImage` |
| `glendix/mendix/icon` | `WebIcon` — Glyph, Image, IconFont |
| `glendix/mendix/formatter` | `ValueFormatter` — `format`이랑 `parse` |
| `glendix/mendix/filter` | FilterCondition 빌더! — `and_`, `or_`, `equals`, `contains`, `attribute`, `literal` |
| `glendix/editor_config` | Editor Configuration 도우미! — 속성 숨기기, 탭 만들기, 순서 바꾸기 (Jint이랑 호환돼!) |

### JS Interop 쪽!

| 모듈 | 뭐 하는 건지! |
|---|---|
| `glendix/js/array` | Gleam List ↔ JS Array 변환! (react_ffi.mjs 재사용이라 FFI 파일도 필요 없어!) |
| `glendix/js/object` | 객체 만들기, 속성 읽기/쓰기/삭제, 메서드 호출, `new`로 인스턴스 생성! |
| `glendix/js/json` | `stringify`랑 `parse`! (parse는 `Result`로 돌려줘서 안전해!) |
| `glendix/js/promise` | Promise 체이닝 (`then_`, `map`, `catch_`), `all`, `race`, `resolve`, `reject` — `react.Promise(a)` 타입 그대로 써! |
| `glendix/js/dom` | DOM 조작! — `focus`, `blur`, `click`, `scroll_into_view`, `query_selector` (`Option`으로 돌려줘!) |
| `glendix/js/timer` | `set_timeout`, `set_interval`, `clear_timeout`, `clear_interval` — `TimerId`가 opaque라서 숫자로 장난 못 쳐! |

> SpreadJS 같은 외부 JS 라이브러리랑 직접 얘기해야 할 때 쓰는 escape hatch야! 전부 `Dynamic` 타입이라 타입 안전성은 없지만 엄청 유연해! `glendix/binding`으로 되는 거면 그쪽이 더 좋아!

## 예제 모음!

### Attribute 리스트

버튼 만들 때 이렇게 속성을 리스트로 쭉 쓰면 돼! 장보기 목록 같지 않아?

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

어떤 속성을 넣을지 말지 고민될 때는 `attribute.none()`을 쓰면 돼! "아 역시 됐어~" 하는 거랑 비슷해:

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

카운터야! 버튼 누르면 숫자가 하나씩 올라가! 마법 같지?!

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
    // 처음 나타날 때 딱 한 번 실행돼!
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

### useLayoutEffect (화면 재는 거!)

이건 화면이 바뀐 직후에 실행되는데 눈에 보이기 전에 동작해! 엄청 빨라!

```gleam
import glendix/react/hook

let ref = hook.use_ref(0.0)

hook.use_layout_effect_cleanup(
  fn() {
    // 여기서 화면 크기 재고 그런 거 해!
    fn() { Nil }  // 다 쓰면 치우기!
  },
  [some_dep],
)
```

### Mendix 값 읽고 쓰기!

Mendix에서 값 꺼내서 쓰는 방법이야:

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

### 보였다 안 보였다! (조건부 렌더링)

어떨 때만 보여주고 싶을 때 이렇게 하면 돼!

```gleam
import glendix/react
import glendix/react/html

// True일 때만 보여줘!
react.when(is_visible, fn() {
  html.div_([react.text("짜잔! 보인다!")])
})

// Some 값이 있을 때만 보여줘!
react.when_some(maybe_user, fn(user) {
  html.span_([react.text(user.name)])
})
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

**2. 패키지 설치하기** — `bindings.json`에 쓴 패키지는 `node_modules`에 있어야 해:

```bash
npm install recharts
```

**3. `gleam run -m glendix/install` 실행!** (바인딩을 알아서 만들어줘!)

**4. Gleam 래퍼 모듈 쓰기** (html.gleam이랑 똑같은 패턴이야):

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

**5. 위젯에서 이렇게 쓰면 끝!:**

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

### .mpk 위젯 쓰기!

`.mpk` 파일을 `widgets/` 폴더에 넣으면 React 컴포넌트처럼 쓸 수 있어! 완전 쩔지 않아?!

**1. `.mpk` 파일을 `widgets/` 폴더에 넣기!**

**2. `gleam run -m glendix/install` 실행!** (바인딩 다 알아서 해줘!)

자동으로 두 가지가 일어나! 편하지?:
- `.mpk` 파일에서 `.mjs`랑 `.css`를 뽑아내고 `widget_ffi.mjs`를 만들어줘
- `.mpk` XML에 있는 `<property>` 정의를 읽어서 `src/widgets/`에 바인딩 `.gleam` 파일을 자동으로 만들어줘 (이미 있으면 안 건드려!)

**3. 자동으로 만들어진 `src/widgets/*.gleam` 파일을 확인해봐:**

```gleam
// src/widgets/switch.gleam (자동으로 만들어진 거야!)
import glendix/mendix
import glendix/react.{type JsProps, type ReactElement}
import glendix/react/attribute
import glendix/widget

/// Switch 위젯 그리기 - props에서 속성 읽어서 위젯한테 넘겨줘!
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

필수인 거랑 선택인 거를 알아서 구분해줘! 만들어진 파일은 마음대로 고쳐도 돼!

**4. 위젯에서 이렇게 쓰면 돼:**

```gleam
import widgets/switch

// 컴포넌트 안에서
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

위젯 고르면 버전 목록이 나오고, Pluggable인지 Classic인지도 알아서 구분해줘! 다운받은 `.mpk`는 `widgets/`에 저장되고, `src/widgets/`에 바인딩 코드도 자동으로 만들어져! 전부 다 자동이야!

> 버전 정보는 Playwright(Chromium)로 가져와! 처음에 한 번 로그인해야 하는데, 그 다음부터는 `.marketplace-cache/session.json`에 저장되니까 안 해도 돼!

## 빌드 스크립트!

glendix에 빌드 스크립트가 다 들어있어! 따로 파일 만들 필요 없이 `gleam run -m`만 치면 돼! 완전 간편하지?!

| 명령어 | 뭐 하는 건지! |
|--------|-------------|
| `gleam run -m glendix/install` | 의존성 설치 + 바인딩 생성 + 위젯 바인딩 생성 + 위젯 `.gleam` 파일 생성 (패키지 매니저 알아서 찾아줘!) |
| `gleam run -m glendix/marketplace` | Marketplace에서 위젯 검색하고 다운받기! (인터랙티브!) |
| `gleam run -m glendix/define` | 위젯 프로퍼티 정의를 TUI로 편집! (그룹, 타입, 열거형 — 터미널에서 다 돼!) |
| `gleam run -m glendix/build` | 프로덕션 빌드! (.mpk 파일 만들어줘!) |
| `gleam run -m glendix/dev` | 개발 서버! (HMR이라서 port 3000에서 고치면 바로 반영돼! 짱이지?) |
| `gleam run -m glendix/start` | Mendix 테스트 프로젝트 연결! |
| `gleam run -m glendix/lint` | ESLint로 코드 검사! |
| `gleam run -m glendix/lint_fix` | ESLint 문제 자동으로 고쳐줘! |
| `gleam run -m glendix/release` | 릴리즈 빌드! |

패키지 매니저도 알아서 찾아줘!:
- `pnpm-lock.yaml` 있으면? pnpm 쓸게!
- `bun.lockb`나 `bun.lock` 있으면? bun 쓸게!
- 아무것도 없으면? 그냥 npm 쓰면 되지! 간단!

## 안에 뭐가 들었나 봐봐!

정리가 되게 잘 돼있지? 한번 구경해봐!

```
glendix/
  react.gleam              ← 제일 중요한 핵심! createElement, Context, keyed, 컴포넌트 정의, flushSync
  react_ffi.mjs            ← 요소 만들기, Fragment, Context, 고급 컴포넌트 어댑터, Gleam 구조 동등성 memo
  react/
    attribute.gleam         ← Attribute 타입 + HTML 속성 함수 108개 넘게!
    attribute_ffi.mjs       ← Attribute를 React props로 바꿔주는 거!
    hook.gleam              ← React Hook 40개! (use_promise, use_form_status도 있어!)
    hook_ffi.mjs            ← Hook JS 도우미!
    ref.gleam               ← Ref 접근자 (current, assign)
    event.gleam             ← 이벤트 타입 16개 + 핸들러 154개 넘게 + 접근자 82개 넘게!
    event_ffi.mjs           ← 이벤트 접근자 JS 도우미!
    html.gleam              ← HTML 태그 85개 넘게! (순수 Gleam — JS 없어!)
    svg.gleam               ← SVG 요소 58개! (순수 Gleam — JS 없어!)
    svg_attribute.gleam     ← SVG 전용 속성 97개 넘게! (순수 Gleam — JS 없어!)
  js/
    array.gleam             ← Gleam List ↔ JS Array (FFI 없어 — react_ffi.mjs 재사용!)
    object.gleam            ← 객체 만들기, 속성 접근, 메서드 호출!
    object_ffi.mjs          ← 객체 JS 도우미!
    json.gleam              ← JSON stringify/parse!
    json_ffi.mjs            ← JSON JS 도우미!
    promise.gleam           ← Promise 체이닝, all, race!
    promise_ffi.mjs         ← Promise JS 도우미!
    dom.gleam               ← DOM focus/blur/click/scroll/query!
    dom_ffi.mjs             ← DOM JS 도우미!
    timer.gleam             ← setTimeout/setInterval! (opaque TimerId!)
    timer_ffi.mjs           ← 타이머 JS 도우미!
  mendix.gleam              ← Mendix 핵심 타입 + Props 접근자
  mendix_ffi.mjs            ← Mendix 런타임 타입 JS 도우미
  mendix/
    editable_value.gleam    ← EditableValue
    action.gleam            ← ActionValue
    dynamic_value.gleam     ← DynamicValue
    list_value.gleam        ← ListValue + Sort + Filter
    list_attribute.gleam    ← List 연결 타입들
    selection.gleam         ← Selection
    reference.gleam         ← ReferenceValue (하나랑 연결!)
    reference_set.gleam     ← ReferenceSetValue (여러 개랑 연결!)
    date.gleam              ← JS Date 래퍼
    big.gleam               ← Big.js 래퍼
    file.gleam              ← File / Image
    icon.gleam              ← Icon
    formatter.gleam         ← ValueFormatter
    filter.gleam            ← FilterCondition 빌더
  editor_config.gleam       ← Editor Configuration 도우미 (Jint 호환! List 안 써!)
  editor_config_ffi.mjs     ← @mendix/pluggable-widgets-tools 래핑
  binding.gleam             ← 외부 React 컴포넌트 바인딩 API
  binding_ffi.mjs           ← 바인딩 JS 도우미 (install하면 새로 만들어져!)
  widget.gleam              ← .mpk 위젯 컴포넌트 바인딩 API
  widget_ffi.mjs            ← 위젯 JS 도우미 (install하면 새로 만들어져!)
  classic.gleam             ← Classic (Dojo) 위젯 래퍼
  classic_ffi.mjs           ← Classic 위젯 JS 도우미 (install하면 새로 만들어져!)
  marketplace.gleam         ← Marketplace 위젯 검색하고 다운받기!
  marketplace_ffi.mjs       ← Content API + Playwright + S3 다운로드 JS 도우미
  define.gleam              ← 위젯 프로퍼티 정의 TUI 에디터!
  define_ffi.mjs            ← 터미널 입출력 + 파일 읽기/쓰기 JS 도우미
  define/
    types.gleam             ← Property, PropertyGroup, WidgetMeta 타입 정의
    ui.gleam                ← TUI 렌더링 도우미 (입력 필드, 레이아웃)
  cmd.gleam                 ← 쉘 명령어 실행 + PM 감지 + 바인딩 생성
  cmd_ffi.mjs               ← Node.js child_process + fs + ZIP 파싱 + 바인딩 생성 + 위젯 .gleam 파일 생성
  build.gleam               ← 빌드 스크립트
  dev.gleam                 ← 개발 서버 스크립트
  start.gleam               ← Mendix 연동 스크립트
  install.gleam             ← 설치 + 바인딩 생성 스크립트
  release.gleam             ← 릴리즈 빌드 스크립트
  lint.gleam                ← ESLint 스크립트
  lint_fix.gleam            ← ESLint 자동 수정 스크립트
```

## 왜 이렇게 만들었냐면!

- **FFI는 진짜 얇은 연결고리야!** `.mjs` 파일은 JS 세계랑 말 섞는 것만 하고, 진짜 로직은 전부 Gleam으로 써! 모듈마다 하나씩만 담당해 — `react_ffi.mjs`는 요소 만들기, `hook_ffi.mjs`는 훅, `event_ffi.mjs`는 이벤트 읽기!
- **Opaque type으로 안전하게!** `ReactElement`, `JsProps`, `EditableValue` 같은 JS 값들을 Gleam 타입으로 꽁꽁 감싸서 실수로 이상하게 쓰면 컴파일할 때 잡아줘! 똑똑하지?
- **`undefined`가 `Option`으로 자동 변환!** JS에서 `undefined`나 `null`이 오면 Gleam에서는 `None`이 되고, 값이 있으면 `Some(value)`가 돼! 알아서 바꿔주니까 걱정 없어!
- **속성은 리스트로 쓰면 돼!** `[attribute.class("x"), event.on_click(handler)]` 이렇게! 넣고 싶지 않을 때는 `attribute.none()` 쓰면 되고, `attribute.class()`를 여러 번 쓰면 알아서 합쳐줘! 완전 편해!
- **Gleam 튜플이 곧 JS 배열!** `#(a, b)`가 JS에서는 `[a, b]`야! 그래서 `useState` 반환값이랑 바로 호환돼! 신기방기!

## 고마운 분들!

v2.0에서 React 바인딩 개선할 때 [redraw](https://github.com/ghivert/redraw) 프로젝트를 많이 참고했어! FFI 모듈 나누기, Hook 패턴, 이벤트 시스템 구조 같은 걸 배웠어! 고마워요 redraw!

## 라이선스

[Blue Oak Model License 1.0.0](LICENSE)
