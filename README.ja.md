[English](README.md) | [한국어](README.ko.md) | **日本語**

# glendix

こんにちは！glendixだよ！すっごくかっこいいライブラリなんだ！
GleamっていうプログラミングげんごでMendix Pluggable Widgetがつくれるよ！

**JSXとかいらないよ！ぜんぶGleamだけでMendix Pluggable Widgetがつくれちゃうんだ！すごくない？！**

Reactのところは[redraw](https://github.com/ghivert/redraw)/[redraw_dom](https://github.com/ghivert/redraw)がやってくれて、TEAパターンは[lustre](https://github.com/lustre-labs/lustre)がやってくれて、Mendixのかた・ウィジェット・マーケットプレイスは[mendraw](https://github.com/GG-O-BP/mendraw)におまかせ！glendixはビルドツールとバインディングにしゅうちゅうするよ！

## v4.0でなにがかわったの？

v4.0ではね、MendixのAPIかた、ウィジェットバインディング（.mpk）、Classicウィジェット、マーケットプレイスをぜーんぶ**mendraw**におまかせすることにしたの！glendixはこれからビルドツール、そとのReactコンポーネントバインディング、Lustreブリッジだけがんばるよ！

### こういうところがかわったよ！

- **Mendixのかたがmendrawにおひっこし**: `import glendix/mendix` → `import mendraw/mendix`、したのモジュール（`editable_value`、`action`、`list_value`とか）もぜんぶ `mendraw/mendix/*` に！
- **interopがmendrawにおひっこし**: `import glendix/interop` → `import mendraw/interop`
- **widgetがmendrawにおひっこし**: `import glendix/widget` → `import mendraw/widget`、TOMLのせってい `[tools.glendix.widgets.*]` → `[tools.mendraw.widgets.*]`
- **classicがmendrawにおひっこし**: `import glendix/classic` → `import mendraw/classic`
- **マーケットプレイスがmendrawにおひっこし**: `gleam run -m glendix/marketplace` → `gleam run -m mendraw/marketplace`
- **glendix/bindingはそのまま！**: そとのReactコンポーネントバインディングはglendixにのこるよ！
- **glendix/lustreもそのまま！**: Lustre TEAブリッジもglendixにのこるよ！

### おひっこしチートシート！（v3 → v4）

| まえ (v3) | あと (v4) |
|---|---|
| `import glendix/mendix.{type JsProps}` | `import mendraw/mendix.{type JsProps}` |
| `import glendix/mendix/editable_value` | `import mendraw/mendix/editable_value` |
| `import glendix/mendix/action` | `import mendraw/mendix/action` |
| `import glendix/interop` | `import mendraw/interop` |
| `import glendix/widget` | `import mendraw/widget` |
| `import glendix/classic` | `import mendraw/classic` |
| `gleam run -m glendix/marketplace` | `gleam run -m mendraw/marketplace` |
| `[tools.glendix.widgets.X]` | `[tools.mendraw.widgets.X]` |

## インストールのしかた！

`gleam.toml`にこれをかくだけだよ！かんたんでしょ？

```toml
# gleam.toml
[dependencies]
glendix = ">= 4.0.0 and < 5.0.0"
mendraw = ">= 1.0.0 and < 2.0.0"
```

### いっしょにひつようなもの

ウィジェットプロジェクトの`package.json`にこれもいれてね：

```json
{
  "dependencies": {
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "big.js": "^6.0.0"
  }
}
```

> `big.js`はDecimalぞくせいをつかうウィジェットだけひつようだよ！つかわないならいれなくてもだいじょうぶ！

## さっそくはじめよう！

みてみて、ウィジェットひとつつくるのってこんなにみじかいんだよ！びっくりでしょ？

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

`fn(JsProps) -> Element` — Mendix Pluggable Widgetにひつようなのはこれだけ！ちょーかんたん！

### Lustre TEAパターンをつかってみよう！

The Elm Architectureがすきなひとは、Lustreブリッジをつかってね！`update`と`view`のかんすうはぜんぶふつうのLustreだよ！

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

## モジュールのしょうかい！

### Reactとレンダリングのところ！（redrawがやってくれるよ！）

| モジュール | なにをするの？ |
|---|---|
| `redraw` | コンポーネント、フック、フラグメント、コンテキスト — GleamでつかえるReact APIぜんぶ！ |
| `redraw/dom/html` | HTMLタグ！ — `div`、`span`、`input`、`text`、`none`、ほかにもいーっぱい！ |
| `redraw/dom/attribute` | Attributeのかた + HTML属性かんすう！ — `class`、`id`、`style`とかとか！ |
| `redraw/dom/events` | イベントハンドラ！ — `on_click`、`on_change`、`on_input`、キャプチャバージョンもあるよ！ |
| `redraw/dom/svg` | SVGようそ！ — `svg`、`path`、`circle`、フィルタプリミティブとかいっぱい！ |
| `redraw/dom` | DOMユーティリティ！ — `create_portal`、`flush_sync`、リソースヒント！ |

### glendixのブリッジ！

| モジュール | なにをするの？ |
|---|---|
| `glendix/lustre` | Lustre TEAブリッジ！ — `use_tea`、`use_simple`、`render`、`embed` |
| `glendix/binding` | ほかのひとがつくったReactコンポーネントをつかうよ！ — `gleam.toml [tools.glendix.bindings]`にせっていするだけ！ |
| `glendix/define` | ウィジェットプロパティていぎのTUIエディター！ターミナルでぜんぶできるよ！ |
| `glendix/editor_config` | Editor Configurationおたすけ！（Jintとなかよし！） |

### mendraw（MendixのAPIとウィジェット！）

| モジュール | なにをするの？ |
|---|---|
| `mendraw/mendix` | Mendixのだいじなかた（`ValueStatus`、`ObjectItem`、`JsProps`）+ Propsアクセサ |
| `mendraw/interop` | そとのJS Reactコンポーネントを`redraw.Element`にするよ！ |
| `mendraw/widget` | `.mpk`ウィジェットをつかうよ！ — `gleam.toml`でじどうダウンロード！ |
| `mendraw/classic` | むかしのClassic（Dojo）ウィジェットラッパー！ |
| `mendraw/marketplace` | Mendix Marketplaceでウィジェットをさがしてダウンロード！ |

### JS Interopのところ！

| モジュール | なにをするの？ |
|---|---|
| `glendix/js/array` | Gleam List ↔ JS Arrayへんかん！ |
| `glendix/js/object` | オブジェクトつくる、ぞくせいよむ/かく/けす、メソッドよぶ、`new`でインスタンスつくる！ |
| `glendix/js/json` | `stringify`と`parse`！（parseは`Result`でかえしてくれるからあんぜん！） |
| `glendix/js/promise` | Promiseチェイニング（`then_`、`map`、`catch_`）、`all`、`race`、`resolve`、`reject` |
| `glendix/js/dom` | DOMおたすけ！ — `focus`、`blur`、`click`、`scroll_into_view`、`query_selector` |
| `glendix/js/timer` | `set_timeout`、`set_interval`、`clear_timeout`、`clear_interval` |

## れいをみてみよう！

### Attributeリスト

ボタンをつくるときはこうやってぞくせいをリストでならべるよ！おかいものリストみたいでしょ？

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

カウンターだよ！ボタンをおすとすうじがひとつずつふえるの！まほうみたい！

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

### Mendixのあたいをよんだりかいたり！

Mendixからあたいをもらってつかうほうほうだよ：

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

### ほかのひとのReactコンポーネントをつかう（バインディング）

npmにあるReactライブラリを`.mjs`ファイルなしでつかえちゃうんだよ！すごいでしょ？！

**1. `gleam.toml`にバインディングをついかするよ：**

```toml
[tools.glendix.bindings]
recharts = ["PieChart", "Pie", "Cell", "Tooltip", "Legend"]
```

**2. パッケージをインストール：**

```bash
npm install recharts
```

**3. `gleam run -m glendix/install`をじっこう！**

**4. Gleamラッパーモジュールをかく：**

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

**5. ウィジェットでこうやってつかうよ：**

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

### .mpkウィジェットをつかう！

Marketplaceのウィジェットをまるでreactコンポーネントみたいにつかえちゃうんだよ！`gleam.toml`にとうろくしてじどうダウンロードするよ！

`gleam.toml`にウィジェットをせっていして`gleam run -m glendix/install`するだけ！

```toml
[tools.mendraw.widgets.Charts]
version = "3.0.0"
# s3_id = "com/..."   ← これがあるとにんしょうなしでちょくせつダウンロード！
```

`build/widgets/`にキャッシュして、バインディングもぜんぶつくってくれるよ！

**じどうでできた`src/widgets/*.gleam`ファイルをみてみよう：**

```gleam
// src/widgets/switch.gleam（じどうでできたよ！）
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

**4. ウィジェットでこうやってつかうよ：**

Mendixからもらったpropはそのままわたせるよ！コードからじぶんであたいをつくるときはウィジェットpropヘルパーをつかってね！

```gleam
// コードからじぶんであたいをつくる（Lustre TEAビューとか）
import mendraw/widget

widget.prop("caption", "タイトル")                                // DynamicValue
widget.editable_prop("text", value, display, set_value)           // EditableValue
widget.action_prop("onClick", fn() { handle_click() })            // ActionValue
```

```gleam
import widgets/switch

switch.render(props)
```

### Marketplaceからウィジェットをダウンロード！

Mendix Marketplaceでウィジェットをさがしてそのままダウンロードできちゃうんだ！ターミナルだけでぜんぶできるよ！すっごくべんり！

**1. `.env`ファイルにMendix PATをかく：**

```
MENDIX_PAT=your_personal_access_token
```

> PATは[Mendix Developer Settings](https://user-settings.mendix.com/link/developersettings)の**Personal Access Tokens**のところで**New Token**をおすともらえるよ！`mx:marketplace-content:read`ってけんげんがいるよ！

**2. これをじっこうしてね：**

```bash
gleam run -m mendraw/marketplace
```

**3. かわいいインタラクティブメニューがでてくるよ！：**

```
  ── ページ 1/5+ ──

  [0] Star Rating (54611) v3.2.2 — Mendix
  [1] Switch (50324) v4.0.0 — Mendix
  ...

  番号: ダウンロード | 検索語: 名前検索 | n: 次へ | p: 前へ | r: リセット | q: 終了

> 0              ← ばんごうをいれるとダウンロード！
> star           ← なまえでさがせるよ！
> 0,1,3          ← カンマでいくつもいっぺんに！
```

ダウンロードしたウィジェットは`build/widgets/`にキャッシュされて、`gleam.toml`にじどうでついかされるよ！`.mpk`ファイルをソースにコミットしなくていいからすっきり！

## ビルドスクリプト！

| コマンド | なにをするの？ |
|----------|-------------|
| `gleam run -m glendix/install` | ぜんぶインストール + TOMLウィジェットダウンロード + バインディングせいせい + ウィジェットファイルせいせい！ |
| `gleam run -m mendraw/marketplace` | Marketplaceでウィジェットをさがしてダウンロード！ |
| `gleam run -m glendix/define` | ウィジェットプロパティていぎをTUIでへんしゅう！ |
| `gleam run -m glendix/build` | プロダクションビルド！（.mpkファイルができるよ！） |
| `gleam run -m glendix/dev` | かいはつサーバー！（HMRだからかえたらすぐはんえい！） |
| `gleam run -m glendix/start` | Mendixテストプロジェクトとつなげる！ |
| `gleam run -m glendix/lint` | ESLintでコードをチェック！ |
| `gleam run -m glendix/lint_fix` | ESLintのもんだいをじどうでなおしてくれる！ |
| `gleam run -m glendix/release` | リリースビルド！ |

## どうしてこうつくったの？

- **まかせるものはまかせるよ！じぶんでつくりなおさない！** Reactバインディングはredrawのもの。TEAはlustreのもの。Mendixのかたとウィジェットはmendrawのもの。glendixはビルドツールとバインディングにしゅうちゅうするの！
- **Opaqueかたであんぜん！** `JsProps`とか`EditableValue`みたいなJSのあたいをGleamのかたでぎゅっとつつんでるから、まちがったつかいかたするとコンパイルのときにおしえてくれるよ！かしこい！
- **`undefined`が`Option`にじどうへんかん！** JSから`undefined`とか`null`がきたらGleamでは`None`になって、あたいがあったら`Some(value)`になるの！じどうでかわるからしんぱいいらない！
- **レンダリングのみちが2つあるよ！** redrawでちょくせつReactをつかうか、LustreブリッジでTEAをつかうか — どっちも`redraw.Element`をだすから、じゆうにくみあわせられるの！すごいでしょ？

## ありがとう！

glendix v4.0はすばらしい[redraw](https://github.com/ghivert/redraw)と[lustre](https://github.com/lustre-labs/lustre)と[mendraw](https://github.com/GG-O-BP/mendraw)のうえにのっかってるよ！みっつのプロジェクトにかんしゃ！

## ライセンス

[Blue Oak Model License 1.0.0](LICENSE)
