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
glendix = ">= 6.0.0 and < 7.0.0"
```

Mendix クライアント値または MPK コンポーネントが必要な場合だけ `mendraw`、
パッケージ取得が必要な場合だけ `mxpak` を利用します。

## Lustre ブリッジ

`glendix/lustre` は標準的な Lustre の `Model`・`update`・`view` を
Redraw/React element に変換し、`use_tea`、`use_simple`、`render`、`embed`、
`keyed_host` を提供します。

### Props による再マウント

型付き props から計算した revision が変わったときに Lustre application 全体を
再起動する必要がある場合は、`keyed_host` を使用します。

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

`props_revision` は application の型付き state から pure Gleam で導出します。
key が同じなら最新 props を callback に渡しながら application を維持し、key が
変われば再マウントします。評価済みの `use_tea` result に直接 key を付けるだけでは
hook を所有する React component boundary は作られず、`lustre/element/keyed` は
実行中の Lustre tree 内の child にしか影響しません。

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

## ブラウザーファイル capability

`glendix/js/file` は Gossamer ベースの宣言的ダウンロードリソースと、
Plinth ベースのモダンなファイル選択を提供します。対応状況、キャンセル、
メタデータ検証、ハンドルを開く処理、バイト読み取りの失敗をそれぞれ型で
返します。隠し入力のフォールバック、アプリケーション固有の解析やファイル名
方針は意図的に含みません。

API、検証順序、フォールバック方針、ecosystem/残存 FFI の対応表は
[browser file capability contract](BROWSER_FILE_CAPABILITIES.md) を参照してください。

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
