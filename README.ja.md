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

## 型付き JSON ヘルパー

`glendix/js/json` はシリアライズとパースを `gleam_json` に委譲します。
シリアライズ API は以前のまま利用できます。

```gleam
import gleam/json
import glendix/js/json as glendix_json

glendix_json.stringify(value: json.int(42))
```

Glendix 6 以降、パース時には期待する結果型の decoder を指定します。

```gleam
import gleam/dynamic/decode
import glendix/js/json as glendix_json

glendix_json.parse(
  from: "{\"name\":\"glendix\"}",
  using: {
    use name <- decode.field("name", decode.string)
    decode.success(name)
  },
)
```

6 より前の `parse(from: source)` 呼び出しは
`parse(from: source, using: decoder)` に移行してください。構文エラーは
`InvalidSyntax`、有効な JSON が decoder と一致しない場合は
`DecoderMismatch` を返します。どちらも決定的で、JavaScript engine 固有の
例外メッセージを公開しません。

## 実験的ネイティブパッケージマネージャー

Glendix はプロジェクトのパッケージマネージャー・JavaScript runtime と
Mendix Pluggable Widgets Tools の npm 前提を次のように分離できます。

```toml
[javascript]
runtime = "bun"

[tools.glendix]
pm = "bun"
compatibility = "experimental-native"
```

| `pm` | Gleam runtime | dependency install |
| --- | --- | --- |
| `npm` | `node` | `npm install` |
| `yarn` | `node` | `yarn install` |
| `pnpm` | `node` | `pnpm install` |
| `bun` | `bun` | `bun install` |
| `deno` | `deno` | 必要な lifecycle script だけを許可した hoisted/manual `deno install` |

このモードでは、インストール済み Pluggable Widgets Tools CLI を選択した
runtime で直接実行します。一時的な `node`・`npm`・`npx` 互換 shim はその
子プロセスの `PATH` だけに追加され、ツールの強制 Node/npm check を満たし、
対応する install/run/exec を選択したパッケージマネージャーへ転送します。
コマンド終了時に shim を削除し、global binary・lockfile・パッケージマネージャー
設定は変更しません。対話的な npm lockfile migration も無効にするため、選択した
マネージャーの lockfile が正となります。

これは完全な npm emulator ではなく明示的な実験モードです。npm と Bun は
Mendix toolchain が必要とする lifecycle script を許可・信頼し、Yarn は
`node-modules` linker、pnpm も同じ native build script の許可が必要です。
Deno は Gleam command の permission と install 時の script 許可が必要です。
dependency module は `gleam run -m glendix/build --runtime bun` または
`--runtime deno` のように一致する runtime を明示し、npm/Yarn/pnpm では
`--runtime node` を使用します。

## Lustre ブリッジ

`glendix/lustre` は標準的な Lustre の `Model`・`update`・`view` を
Redraw/React element に変換します。`use_tea`、`use_simple`、`render`、
`embed`、`keyed_host` を提供します。

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
key が同じなら既存 application instance を維持しながら render callback に最新の
props を渡し、key が変われば以前の host を破棄して再マウントします。

`keyed_host` は Redraw の React key support を利用しつつ、Lustre hook を所有する
component boundary も提供します。評価済みの `use_tea` result を
`redraw.keyed` で囲むだけでは、この boundary は作られません。
`lustre/element/keyed` は実行中の Lustre virtual DOM 内の child だけを制御するため、
外側の React host を再マウントできません。

## 外部 npm React コンポーネント

```toml
[tools.glendix.bindings]
recharts = ["PieChart", "Pie"]
```

Glendix はこの設定を標準 TOML として解析します。パッケージマネージャー、
互換モード、モジュール名、コンポーネント名は引用符付き TOML 文字列にし、
各バインディング値は 1 個の文字列または文字列配列にする必要があります。
不正な TOML、重複キー、引用符のない文字列風の値は部分的に解釈せずエラーに
なります。`gleam.toml` または Glendix テーブルがない場合は、従来どおり
override とバインディングが未設定として扱われます。

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

`glendix/js/environment` は `window.matchMedia` を型付き境界の内側に隠し、ウィ
ジェットがアプリケーションローカルの FFI から直接呼び出さずにブラウザのカラー
スキーム設定を読み取れるようにします。`color_scheme` は OS の設定を `Light`、
`Dark`、`System` として返し、`resolved_color_scheme` は実際に適用される値を
`ResolvedLight`、`ResolvedDark`、または `matchMedia` を照会できない場合の
`ResolutionUnavailable` として解決します。設定変更の動的な購読
(`MediaQueryList` の `change` イベント) は意図的に対象外です。props やリビジョン
による再描画のタイミングで再照会してください。

`glendix/js/object` は順序付きの型付きエントリから素の JavaScript オブジェクトを
構築し、エントリ順を保持し、キーが重複した場合は最後の値を採用します。生成した
オブジェクトは Redraw の属性を通して、アプリケーションローカルの React FFI なし
で外部 React コンポーネントへ 1 つの prop として渡せます。

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

## WebAssembly 依存関係

Glendix は、ブラウザ toolchain が使用する次の標準的な静的 URL 形式の
WebAssembly module を自動的に package 化します。

```javascript
new URL("./engine_bg.wasm", import.meta.url)
```

生成された Rollup 設定は、各 binary を決定的な content hash 名で widget の
`assets/` directory にコピーします。AMD と ES module の出力には、それぞれ
正しい Mendix runtime path を使用し、query string と fragment を保持します。
同じ binary を繰り返し参照しても、asset は一度だけ生成されます。

自動処理の対象は静的な相対 `.wasm` 参照だけです。参照先が存在しない場合は、
module と解決済み path を含む error で build が失敗します。Glendix が生成する
`rollup.config.mjs` を置き換える project は、custom 設定で同等の asset 処理を
構成する必要があります。

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

## 6.0.0 の破壊的変更

`glendix/js/array` は変換を `gleam/javascript/array` に委譲するようになり、手書き
の JavaScript アダプターを同梱しなくなりました。`from_list` と `to_list` は関数
名・ラベル・要素順序の挙動を維持するため、一般的な
`list |> array.from_list |> array.to_list` の利用方法は変わりません。従来の
opaque 型 `glendix/js/array.JsArray(element)` は削除されたので、値の型は
`gleam/javascript/array.Array(element)` で注釈してください。

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
