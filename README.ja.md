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
