[English](README.md) | [Korean](README.ko.md) | **Japanese**

# glendix

`glendix` は Gleam で Mendix Pluggable Widget を開発するための JavaScript
ターゲットのビルド・レンダリングブリッジです。

責務を明確に分離します。

- **glendix**: Pluggable Widgets Tools、ウィジェット定義編集、npm React
  バインディング、Lustre→React ブリッジ
- **mendraw**: Mendix クライアント値とインストール済み `.mpk` 資産の型付き
  バインディング
- **mxpak**: Marketplace 検索、ダウンロード、キャッシュ、ロック、重複排除
- **glendam**: 汎用ブラウザ自動化

Glendix は Marketplace やブラウザ自動化を実装しません。

## インストール

```toml
[dependencies]
glendix = ">= 5.1.0 and < 6.0.0"
```

Mendix クライアント値または MPK コンポーネントが必要な場合だけ `mendraw`、
パッケージ取得が必要な場合だけ `mxpak` を利用します。

## 外部 npm React コンポーネント

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

npm バインディングは Glendix 単体で動作します。

## ブラウザ環境とオブジェクト prop

`glendix/js/environment` を使うと、`window.matchMedia` を公開せずに
`prefers-color-scheme` を読み取れます。`color_scheme` は `Light`、`Dark`、
`System` を返し、`resolved_color_scheme` は `ResolvedLight`、`ResolvedDark`、
または `ResolutionUnavailable` を返します。設定変更の動的な購読は意図的に
対象外なので、アプリケーションによる再描画のタイミングで再照会します。

順序付きの型付きエントリから 1 つの素の JavaScript 設定オブジェクトを構築し、
Redraw の属性を通して外部コンポーネントに渡します。

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

`object.from_entries` は通常の文字列キーの順序を保持し、重複キーには最後の値を
採用し、特殊なキーもデータとして安全に格納します。

## Marketplace ウィジェットとの組み合わせ

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

各ステップは mxpak の資産取得、Mendraw の型付きバインディング生成、Glendix の
JavaScript 設定、最終 MPK ビルドを担当します。

## コマンド

| コマンド | 責務 |
| --- | --- |
| `gleam run -m glendix/install` | JS 依存関係と Glendix npm バインディング |
| `gleam run -m glendix/define` | property 定義編集 |
| `gleam run -m glendix/dev` | 開発ビルド/サーバー |
| `gleam run -m glendix/build` | production `.mpk` ビルド |
| `gleam run -m glendix/start` | Mendix テストプロジェクト接続 |
| `gleam run -m glendix/lint` | lint |
| `gleam run -m glendix/lint_fix` | lint 修正 |
| `gleam run -m glendix/release` | release ビルド |

## 開発

```sh
gleam deps download
gleam format --check
gleam check
gleam build --warnings-as-errors
gleam docs build
gleam test --runtime bun
```

## ライセンス

[MIT ライセンス](LICENSE)
