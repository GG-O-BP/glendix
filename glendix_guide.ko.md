[English](README.md) | **Korean** | [Japanese](README.ja.md)

# glendix

`glendix`는 Gleam으로 Mendix Pluggable Widget을 개발하기 위한 JavaScript 타깃
빌드·렌더링 브리지다.

패키지 책임은 명확히 분리한다.

- **glendix**: Pluggable Widgets Tools 실행, 위젯 정의 편집, npm React 바인딩,
  Lustre→React 브리지
- **mendraw**: Mendix 클라이언트 값과 설치된 `.mpk` 자산의 타입 바인딩
- **mxpak**: Marketplace 검색·다운로드·캐시·락파일·중복 제거
- **glendam**: 범용 브라우저 자동화

Glendix는 Marketplace나 브라우저 자동화를 구현하지 않는다.

## 설치

```toml
[dependencies]
glendix = ">= 6.0.0 and < 7.0.0"
```

Mendix 클라이언트 값이나 MPK 컴포넌트가 필요할 때만 `mendraw`를 추가하고,
패키지 설치가 필요할 때만 `mxpak`을 사용한다.

## Lustre 브리지

`glendix/lustre`는 표준 Lustre `Model`/`update`/`view`를 Redraw/React element로
변환한다. `use_tea`, `use_simple`, `render`, `embed`, `keyed_host`를 제공한다.

### Props 기반 재마운트

typed props에서 계산한 revision이 바뀔 때 Lustre 애플리케이션 전체를 다시
시작해야 한다면 `keyed_host`를 사용한다.

```gleam
pub fn component(props: Props) -> redraw.Element {
  glendix_lustre.keyed_host(
    key: props_revision(props),
    props: props,
    render: fn(current_props) {
      glendix_lustre.use_tea(
        init(current_props),
        update,
        view,
      )
    },
  )
}
```

`props_revision`은 애플리케이션의 typed 상태로부터 순수 Gleam으로 계산한다. 키가
같으면 최신 props를 callback에 전달하면서 애플리케이션을 유지하고, 키가 바뀌면
재마운트한다. 평가가 끝난 `use_tea` 결과에 직접 key를 붙이는 것만으로는 hook을
소유하는 React component 경계를 만들 수 없으며, `lustre/element/keyed`는 실행 중인
Lustre tree 내부 자식에만 영향을 준다.

## 외부 npm React 컴포넌트

```toml
[tools.glendix.bindings]
recharts = ["PieChart", "Pie"]
```

```gleam
import gleam/result
import glendix/binding
import redraw
import redraw/dom/attribute

pub fn pie_chart(
  attributes attributes: List(attribute.Attribute),
  children children: List(redraw.Element),
) -> Result(redraw.Element, binding.BindingError) {
  use module <- result.try(binding.module("recharts"))
  use component <- result.try(binding.resolve(module, "PieChart"))
  Ok(binding.element(component, attributes, children))
}
```

npm 바인딩은 Glendix만으로 동작한다. `binding.element_`와
`binding.void_element`도 제공한다.

## 브라우저 환경과 객체 prop

`glendix/js/environment`를 사용하면 `window.matchMedia`를 노출하지 않고
`prefers-color-scheme`을 읽을 수 있다. `color_scheme`은 `Light`, `Dark`,
`System`을 반환하고, `resolved_color_scheme`은 `ResolvedLight`,
`ResolvedDark`, 또는 `ResolutionUnavailable`을 반환한다. 설정 변경의 동적
구독은 의도적으로 범위 밖이므로 애플리케이션이 재렌더링할 때 다시 조회한다.

순서 있는 typed 항목으로 하나의 일반 JavaScript 설정 객체를 만들고 Redraw 속성을
통해 외부 컴포넌트에 전달한다.

```gleam
import glendix/binding
import glendix/js/environment
import glendix/js/object
import redraw
import redraw/dom/attribute

pub fn themed_component(
  component component: binding.JsComponent,
) -> redraw.Element {
  let theme = case environment.resolved_color_scheme() {
    environment.ResolvedDark -> "dark"
    environment.ResolvedLight -> "light"
    environment.ResolutionUnavailable -> "light"
  }
  let configuration =
    object.from_entries([#("theme", object.string(theme))])
  binding.element(
    component,
    [attribute.attribute("config", object.from_object(configuration))],
    [],
  )
}
```

`object.from_entries`는 일반 문자열 키 순서를 보존하고, 중복 키에는 마지막 값을
적용하며, 특수 키도 데이터로 안전하게 저장한다.

## Marketplace 위젯과 조합

```toml
[tools.mxpak]
mode = "extract"

[tools.mxpak.widgets.Charts]
version = "3.0.0"
```

```sh
mxp install
gleam run -m mendraw/install
gleam run -m glendix/install
gleam run -m glendix/build
```

각 단계는 순서대로 mxpak의 패키지 설치, Mendraw의 타입 바인딩 생성, Glendix의
JavaScript 설정, 최종 MPK 빌드를 담당한다. Marketplace 위젯을 쓰지 않는 프로젝트는
앞의 두 단계를 생략한다.

## 명령

| 명령 | 책임 |
| --- | --- |
| `gleam run -m glendix/install` | JS 의존성 설치와 Glendix npm 바인딩 생성 |
| `gleam run -m glendix/define` | 위젯 property 정의 편집 |
| `gleam run -m glendix/dev` | 개발 빌드/서버 |
| `gleam run -m glendix/build` | production `.mpk` 빌드 |
| `gleam run -m glendix/start` | Mendix 테스트 프로젝트 연결 |
| `gleam run -m glendix/lint` | lint 검사 |
| `gleam run -m glendix/lint_fix` | lint 수정 |
| `gleam run -m glendix/release` | release 빌드 |

## 개발

```sh
gleam deps download
gleam format --check
gleam check
gleam build --warnings-as-errors
gleam docs build
gleam test --runtime bun
```

## 라이선스

[MIT 라이선스](LICENSE)
