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
glendix = ">= 5.1.0 and < 6.0.0"
```

Mendix 클라이언트 값이나 MPK 컴포넌트가 필요할 때만 `mendraw`를 추가하고,
패키지 설치가 필요할 때만 `mxpak`을 사용한다.

## 실험적 네이티브 패키지 매니저

Glendix는 프로젝트의 패키지 매니저·JavaScript 런타임과 Mendix Pluggable
Widgets Tools의 npm 전제를 다음처럼 격리할 수 있다.

```toml
[javascript]
runtime = "bun"

[tools.glendix]
pm = "bun"
compatibility = "experimental-native"
```

| `pm` | Gleam 런타임 | 의존성 설치 |
| --- | --- | --- |
| `npm` | `node` | `npm install` |
| `yarn` | `node` | `yarn install` |
| `pnpm` | `node` | `pnpm install` |
| `bun` | `bun` | `bun install` |
| `deno` | `deno` | 필수 lifecycle script만 허용한 hoisted/manual `deno install` |

이 모드에서 Glendix는 설치된 Pluggable Widgets Tools CLI를 선택한 런타임으로
직접 실행한다. 임시 `node`·`npm`·`npx` 호환 shim은 그 자식 프로세스의
`PATH`에만 추가되어 도구의 강제 Node/npm 검사를 만족시키고, 지원하는
install/run/exec 호출을 선택한 패키지 매니저로 전달한다. 명령 종료 시 shim을
제거하며 전역 바이너리·락파일·패키지 매니저 설정은 바꾸지 않는다. 대화형 npm
락파일 migration도 끄므로 선택한 매니저의 락파일이 기준이다.

이는 완전한 npm 에뮬레이터가 아닌 명시적 실험 모드다. npm과 Bun은 Mendix 도구
체인에 필요한 lifecycle script를 허용·신뢰하고, Yarn은 `node-modules` linker를
사용하며, pnpm도 같은 native build script를 허용해야 한다. Deno 프로젝트는
Gleam 명령에 필요한 권한과 설치 시 해당 script 허용이 필요하다. 의존 패키지
모듈은 `gleam run -m glendix/build --runtime bun` 또는
`--runtime deno`처럼 일치하는 런타임을 명시하고, npm/Yarn/pnpm은
`--runtime node`를 사용한다.

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

## 브라우저 환경과 객체 prop

`glendix/js/environment`는 `window.matchMedia`를 타입 경계 뒤에 숨겨, 위젯이
애플리케이션 로컬 FFI에서 직접 호출하지 않고 브라우저 컬러 스킴 설정을 읽게 한다.
`color_scheme`은 OS 설정을 `Light`, `Dark`, `System`으로 보고하고,
`resolved_color_scheme`은 실제 적용되는 값을 `ResolvedLight`, `ResolvedDark`,
또는 `matchMedia`를 조회할 수 없을 때의 `ResolutionUnavailable`로 확정한다.
설정 변경의 동적 구독(`MediaQueryList`의 `change` 이벤트)은 의도적으로 범위
밖이며, props나 revision 기반 재렌더링 시점에 다시 조회한다.

`glendix/js/object`는 순서 있는 typed 항목으로 일반 JavaScript 객체를 만들며,
항목 순서를 보존하고 중복 키는 마지막 값을 적용한다. 만들어진 객체는 Redraw 속성을
통해 애플리케이션 로컬 React FFI 없이 외부 React 컴포넌트에 하나의 prop으로 전달할
수 있다.

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

## WebAssembly 의존성

Glendix는 브라우저 도구가 사용하는 다음 표준 정적 URL 형식의 WebAssembly
모듈을 자동으로 패키징한다.

```javascript
new URL("./engine_bg.wasm", import.meta.url)
```

생성된 Rollup 설정은 각 바이너리를 결정적인 콘텐츠 해시 이름으로 위젯의
`assets/` 디렉터리에 복사한다. AMD와 ES module 출력에는 각각 올바른 Mendix
런타임 경로를 사용하며 query string과 fragment를 보존한다. 같은 바이너리를
반복해서 참조해도 자산은 한 번만 생성된다.

정적인 상대 `.wasm` 참조만 자동 처리한다. 참조 파일이 없으면 module과 해석된
경로를 포함한 오류로 빌드가 실패한다. Glendix가 생성한 `rollup.config.mjs`를
교체하는 프로젝트는 custom 설정에서 동등한 자산 처리를 구성해야 한다.

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
