[English](README.md) | [한국어](README.ko.md) | **日本語**

# glendix

こんにちは！glendixだよ！すっごくかっこいいライブラリなんだ！
GleamっていうプログラミングげんごでMendix Pluggable Widgetがつくれるよ！

**JSXとかいらないよ！ぜんぶGleamだけでMendix Pluggable Widgetがつくれちゃうんだ！すごくない？！**

Reactのところは[redraw](https://github.com/ghivert/redraw)/[redraw_dom](https://github.com/ghivert/redraw)がやってくれて、TEAパターンは[lustre](https://github.com/lustre-labs/lustre)がやってくれて、glendixはMendixのところだけがんばるよ！

## v3.0でなにがかわったの？

v3.0はね、ものすっごくおおきくかわったんだよ！`glendix/react`っていうレイヤーをぜーんぶけしちゃったの（14こもファイルをけしたよ！）。Reactのバインディングはぜんぶ**redraw**と**redraw_dom**におまかせすることにしたの！それとあたらしく**Lustreブリッジ**もついかしたから、MendixウィジェットのなかでTEAパターンがつかえるようになったよ！

### こういうところがかわったよ！

- **Reactバインディングはぜんぶなくなったよ**: `glendix/react`、`glendix/react/attribute`、`glendix/react/hook`、`glendix/react/html`、`glendix/react/event`、`glendix/react/svg`、`glendix/react/svg_attribute`、`glendix/react/ref` — ぜーんぶなくなっちゃった！かわりに`redraw`と`redraw_dom`をちょくせつつかってね！
- **あたらしい`glendix/interop`**: そとのJS Reactコンポーネント（`widget`と`binding`からのやつ）を`redraw.Element`にするおはしわたしだよ！
- **あたらしい`glendix/lustre`**: Lustre TEAブリッジだよ！ — `use_tea`と`use_simple`っていうフックで、じゅんすいなLustreの`update`/`view`をかいて、Reactようそとしてレンダリングできるの！すごいでしょ？
- **`JsProps`がおひっこししたよ**: `glendix/react.{type JsProps}`じゃなくて`glendix/mendix.{type JsProps}`になったよ！
- **`ReactElement` → `Element`**: もどりちのかたが`redraw.{type Element}`になったよ！

### おひっこしチートシート！

| まえ (v2) | あと (v3) |
|---|---|
| `import glendix/react.{type ReactElement}` | `import redraw.{type Element}` |
| `import glendix/react.{type JsProps}` | `import glendix/mendix.{type JsProps}` |
| `import glendix/react/html` | `import redraw/dom/html` |
| `import glendix/react/attribute` | `import redraw/dom/attribute` |
| `import glendix/react/event` | `import redraw/dom/events` |
| `import glendix/react/hook` | `import redraw`（フックはメインモジュールにはいってるよ！） |
| `import glendix/react/svg` | `import redraw/dom/svg` |
| `import glendix/react/ref` | `import redraw/ref` |
| `react.text("hi")` | `html.text("hi")` |
| `react.none()` | `html.none()` |
| `react.fragment(children)` | `redraw.fragment(children)` |
| `react.define_component(name, render)` | `redraw.component_(name, render)` |
| `react.memo(component)` | `redraw.memoize_(component)` |
| `hook.use_state(0)` | `redraw.use_state(0)` |
| `hook.use_effect(fn, deps)` | `redraw.use_effect(fn, deps)` |
| `react.component_el(comp, attrs, children)` | `interop.component_el(comp, attrs, children)` |
| `react.when(cond, fn)` | `case cond { True -> fn() False -> html.none() }` |

## インストールのしかた！

`gleam.toml`にこれをかくだけだよ！かんたんでしょ？

```toml
# gleam.toml
[dependencies]
glendix = ">= 3.0.2 and < 4.0.0"
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

## さっそくはじめよう！

みてみて、ウィジェットひとつつくるのってこんなにみじかいんだよ！びっくりでしょ？

```gleam
import glendix/mendix.{type JsProps}
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
import glendix/mendix.{type JsProps}
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
| `glendix/interop` | そとのJS Reactコンポーネント（`widget`/`binding`からのやつ）を`redraw.Element`にするよ！ |
| `glendix/lustre` | Lustre TEAブリッジ！ — `use_tea`、`use_simple`、`render`、`embed` |
| `glendix/binding` | ほかのひとがつくったReactコンポーネントをつかうよ！ — `bindings.json`をかくだけでだいじょうぶ！ |
| `glendix/widget` | `.mpk`ウィジェットを`widgets/`フォルダからつかえるよ！ — `component`、`prop`、`editable_prop`、`action_prop` |
| `glendix/classic` | むかしのClassic（Dojo）ウィジェットラッパー — `classic.render(widget_id, properties)`パターン |
| `glendix/marketplace` | Mendix Marketplaceでウィジェットをさがしてダウンロードできるよ！ |
| `glendix/define` | ウィジェットプロパティていぎのTUIエディター！ターミナルでぜんぶできるよ！ |

### Mendixのところ！

| モジュール | なにをするの？ |
|---|---|
| `glendix/mendix` | Mendixのだいじなかた（`ValueStatus`、`ObjectItem`、`JsProps`）+ Propsアクセサ |
| `glendix/mendix/editable_value` | かえられるあたい！ — `value`、`set_value`、`set_text_value`、`display_value` |
| `glendix/mendix/action` | アクションをじっこう！ — `can_execute`、`execute`、`execute_if_can` |
| `glendix/mendix/dynamic_value` | よむだけのどうてきなあたい（しきぞくせいとかのこと） |
| `glendix/mendix/list_value` | リストデータ！ — `items`、`set_filter`、`set_sort_order`、`reload` |
| `glendix/mendix/list_attribute` | リストのアイテムごとにアクセスするかた — `ListAttributeValue`、`ListActionValue`、`ListWidgetValue` |
| `glendix/mendix/selection` | ひとつえらぶ、いっぱいえらぶ！ |
| `glendix/mendix/reference` | ひとつとつながる（ReferenceValue） — おともだちひとりをゆびさすかんじ！ |
| `glendix/mendix/reference_set` | いっぱいとつながる（ReferenceSetValue） — おともだちいっぱいゆびさすかんじ！ |
| `glendix/mendix/date` | JS Dateラッパー（つきがGleamでは1から、JSでは0からなんだけどじどうでかえてくれるよ！あたまいい！） |
| `glendix/mendix/big` | Big.jsラッパーだよ！すっごくせいかくなすうじがつかえるの |
| `glendix/mendix/file` | `FileValue`、`WebImage` |
| `glendix/mendix/icon` | `WebIcon` — Glyph、Image、IconFont |
| `glendix/mendix/formatter` | `ValueFormatter` — `format`と`parse` |
| `glendix/mendix/filter` | FilterConditionビルダー！ |
| `glendix/editor_config` | Editor Configurationおたすけ！（Jintとなかよし！） |

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
import glendix/mendix.{type JsProps}
import glendix/mendix/editable_value as ev
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

**1. `bindings.json`ファイルをつくるよ：**

```json
{
  "recharts": {
    "components": ["PieChart", "Pie", "Cell", "Tooltip", "Legend"]
  }
}
```

**2. パッケージをインストール** — `bindings.json`にかいたパッケージは`node_modules`にないとだめだよ：

```bash
npm install recharts
```

**3. `gleam run -m glendix/install`をじっこう！**

**4. Gleamラッパーモジュールをかく：**

```gleam
// src/chart/recharts.gleam
import glendix/binding
import glendix/interop
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

`.mpk`ファイルを`widgets/`フォルダにいれるとReactコンポーネントみたいにつかえるんだよ！めっちゃかっこよくない？！

**1. `.mpk`ファイルを`widgets/`フォルダにいれる！**

**2. `gleam run -m glendix/install`をじっこう！**（バインディングをぜんぶじどうでやってくれるよ！）

**3. じどうでできた`src/widgets/*.gleam`ファイルをみてみよう：**

```gleam
// src/widgets/switch.gleam（じどうでできたよ！）
import glendix/mendix.{type JsProps}
import glendix/interop
import glendix/widget
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
import glendix/widget

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
gleam run -m glendix/marketplace
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

## ビルドスクリプト！

| コマンド | なにをするの？ |
|----------|-------------|
| `gleam run -m glendix/install` | ぜんぶインストール + バインディングせいせい + ウィジェットファイルせいせい！ |
| `gleam run -m glendix/marketplace` | Marketplaceでウィジェットをさがしてダウンロード！ |
| `gleam run -m glendix/define` | ウィジェットプロパティていぎをTUIでへんしゅう！ |
| `gleam run -m glendix/build` | プロダクションビルド！（.mpkファイルができるよ！） |
| `gleam run -m glendix/dev` | かいはつサーバー！（HMRだからかえたらすぐはんえい！） |
| `gleam run -m glendix/start` | Mendixテストプロジェクトとつなげる！ |
| `gleam run -m glendix/lint` | ESLintでコードをチェック！ |
| `gleam run -m glendix/lint_fix` | ESLintのもんだいをじどうでなおしてくれる！ |
| `gleam run -m glendix/release` | リリースビルド！ |

## どうしてこうつくったの？

- **まかせるものはまかせるよ！じぶんでつくりなおさない！** Reactバインディングはredrawのもの。TEAはlustreのもの。glendixはMendixのことだけがんばるの — interop、ウィジェット、バインディング、ビルドツール！
- **Opaqueかたであんぜん！** `JsProps`とか`EditableValue`みたいなJSのあたいをGleamのかたでぎゅっとつつんでるから、まちがったつかいかたするとコンパイルのときにおしえてくれるよ！かしこい！
- **`undefined`が`Option`にじどうへんかん！** JSから`undefined`とか`null`がきたらGleamでは`None`になって、あたいがあったら`Some(value)`になるの！じどうでかわるからしんぱいいらない！
- **レンダリングのみちが2つあるよ！** redrawでちょくせつReactをつかうか、LustreブリッジでTEAをつかうか — どっちも`redraw.Element`をだすから、じゆうにくみあわせられるの！すごいでしょ？

## ありがとう！

glendix v3.0はすばらしい[redraw](https://github.com/ghivert/redraw)と[lustre](https://github.com/lustre-labs/lustre)のうえにのっかってるよ！りょうほうのプロジェクトにかんしゃ！

## ライセンス

[Blue Oak Model License 1.0.0](LICENSE)
