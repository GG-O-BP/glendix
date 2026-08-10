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
glendix = ">= 5.0.0 and < 6.0.0"
```

Mendix 클라이언트 값이나 MPK 컴포넌트가 필요할 때만 `mendraw`를 추가하고,
패키지 설치가 필요할 때만 `mxpak`을 사용한다.

## Lustre 브리지

`glendix/lustre`는 표준 Lustre `Model`/`update`/`view`를 Redraw/React element로
변환한다. `use_tea`, `use_simple`, `render`, `embed`를 제공한다.

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

[Blue Oak Model License 1.0.0](LICENSE)
