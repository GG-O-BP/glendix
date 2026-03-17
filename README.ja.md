[English](README.md) | [한국어](README.ko.md) | **日本語**

# glendix

こんにちは！glendixだよ！すっごくかっこいいライブラリなんだ！
GleamっていうプログラミングげんごでReact 19とMendix Pluggable Widget APIがつかえるようになるよ！

**JSXとかいらないよ！ぜんぶGleamだけでMendix Pluggable Widgetがつくれちゃうんだ！すごくない？！**

## v2.0でなにがかわったの？

v2.0はね、ものすっごくよくなったんだよ！ [redraw](https://github.com/ghivert/redraw)っていうすてきなプロジェクトからいっぱいおべんきょうしたの。redrawはGleamでReactがつかえるすごいライブラリで、かた安全性とモジュールのつくりがとってもきれい！でもglendixはMendixウィジェットせんようだから、redrawのはんようSPAきのう（bootstrap/composeとかjsx-runtimeとか）はつかわないで、ほんとうにやくだつところだけもらったんだ！

### こういうところがかわったよ！

- **FFIモジュールがわかれたよ**: まえは`react_ffi.mjs`ひとつにぜんぶはいってたんだけど、ごちゃごちゃだったから`hook_ffi.mjs`と`event_ffi.mjs`と`attribute_ffi.mjs`にわけたの！ひとつずつひとつのおしごとだけするからすっきり！
- **Attributeリスト API**: むかしの`prop.gleam`パイプラインをやめて、`attribute.gleam`でリストでかくようにしたよ — `[attribute.class("x"), event.on_click(handler)]`ってかくだけ！かんたんでしょ？
- **Hookが39こもあるよ！**: `useLayoutEffect`、`useInsertionEffect`、`useImperativeHandle`、`useLazyState`、`useSyncExternalStore`、`useDebugValue`、`useOptimistic`（リデューサーバージョンもあるよ！）、`useAsyncTransition`、`useFormStatus`、おかたづけバージョンも！
- **イベントハンドラが154こいじょう！**: キャプチャフェーズ、コンポジション/メディア/UI/ロード/エラー/トランジションイベント + アクセサ82こいじょう + `persist`/`is_persistent`ユーティリティも！めっちゃいっぱい！
- **HTML属性が108こいじょう！**: `dangerously_set_inner_html`、`popover`、`fetch_priority`、`enter_key_hint`、マイクロデータ、Shadow DOMとかいっぱい！
- **HTMLタグも85こいじょう！**: `fieldset`、`details`、`dialog`、`video`、`ruby`、`kbd`、`search`、`hgroup`、`meta`、`script`、`object`とかとかとか！
- **SVGようそが58こ**: フィルタプリミティブだけで16こもあるよ（`fe_convolve_matrix`とか`fe_diffuse_lighting`とか）
- **SVG属性も97こいじょう！**: テキストレンダリング、マーカー、マスク/クリッピング、フィルタ属性 — おわりがないよ！
- **すごいコンポーネント**: `StrictMode`、`Suspense`、`Profiler`、`portal`、`forwardRef`、`memo_`、`startTransition`、`flushSync` — おとなのひとがつかうやつもぜんぶあるよ！

## インストールのしかた！

`gleam.toml`にこれをかくだけだよ！かんたんでしょ？

```toml
# gleam.toml
[dependencies]
glendix = { path = "../glendix" }
```

> まだHexにのせてないからローカルパスでつかってね！ごめんね～

### いっしょにひつようなもの

ウィジェットプロジェクトの`package.json`にこれもいれてね：

```json
{
  "dependencies": {
    "react": "^19.0.0",
    "big.js": "^6.0.0"
  }
}
```

## さっそくはじめよう！

みてみて、ウィジェットひとつつくるのってこんなにみじかいんだよ！びっくりでしょ？

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

`fn(JsProps) -> ReactElement` — Mendix Pluggable Widgetにひつようなのはこれだけ！ちょーかんたん！

## モジュールのしょうかい！

### Reactのところ！

| モジュール | なにをするの？ |
|---|---|
| `glendix/react` | いちばんだいじなところ！ `ReactElement`とか`JsProps`とか`Component`とか`Promise`のかた、それと`element`、`fragment`、`keyed`、`text`、`none`、`when`、`when_some`、Context API、`define_component`、`memo`（Gleamのこうぞうどうとうせいひかくっていうすっごくかしこいやつ！）、`flush_sync` |
| `glendix/react/attribute` | Attributeのかた + HTML属性かんすうが108こいじょう！ — `class`、`id`、`style`、`popover`、`fetch_priority`、`enter_key_hint`、マイクロデータ、Shadow DOMとか |
| `glendix/react/hook` | React Hookが40こも！！ — `use_state`、`use_effect`、`use_layout_effect`、`use_insertion_effect`、`use_memo`、`use_callback`、`use_ref`、`use_reducer`、`use_context`、`use_id`、`use_transition`、`use_async_transition`、`use_deferred_value`、`use_optimistic`/`use_optimistic_`、`use_imperative_handle`、`use_lazy_state`、`use_sync_external_store`、`use_debug_value`、`use_promise`（React.useだよ！）、`use_form_status` |
| `glendix/react/ref` | Refアクセサ — `current`と`assign`（hookモジュールとわけてきれいにしたよ！） |
| `glendix/react/event` | イベントのかたが16しゅるい + ハンドラが154こいじょう（キャプチャフェーズとかトランジションイベントもはいってるよ！）+ アクセサが82こいじょう |
| `glendix/react/html` | HTMLタグが85こいじょう！ — `div`、`span`、`input`、`details`、`dialog`、`video`、`ruby`、`kbd`、`search`、`meta`、`script`、`object`とか（じゅんすいGleam、FFIなし！） |
| `glendix/react/svg` | SVGようそが58こ！ — `svg`、`path`、`circle`、フィルタプリミティブ16こ、`discard`とか（じゅんすいGleam、FFIなし！） |
| `glendix/react/svg_attribute` | SVGせんよう属性かんすうが97こいじょう！ — `view_box`、`fill`、`stroke`、マーカー、フィルタ属性とか（じゅんすいGleam、FFIなし！） |
| `glendix/binding` | ほかのひとがつくったReactコンポーネントをつかうよ！ — `bindings.json`をかくだけで`.mjs`はいらない！ |
| `glendix/widget` | `.mpk`ウィジェットをReactコンポーネントみたいにつかえるよ！ — `widgets/`フォルダにいれるだけ！べんり！ |
| `glendix/classic` | むかしのClassic（Dojo）ウィジェットラッパー — `classic.render(widget_id, properties)`パターン |
| `glendix/marketplace` | Mendix Marketplaceでウィジェットをさがしてダウンロードできるよ！ — `gleam run -m glendix/marketplace` |
| `glendix/define` | ウィジェットプロパティていぎのTUIエディター！ — グループついか、かたせってい、列挙がたかんり、ぜんぶターミナルでできるよ！ |

### Mendixのところ！

| モジュール | なにをするの？ |
|---|---|
| `glendix/mendix` | Mendixのだいじなかた（`ValueStatus`、`ObjectItem`）+ JsPropsからあたいをとりだす（`get_prop`、`get_string_prop`） |
| `glendix/mendix/editable_value` | かえられるあたい！ — `value`、`set_value`、`set_text_value`、`display_value` |
| `glendix/mendix/action` | アクションをじっこう！ — `can_execute`、`execute`、`execute_if_can` |
| `glendix/mendix/dynamic_value` | よむだけのどうてきなあたい（しきぞくせいとかのこと） |
| `glendix/mendix/list_value` | リストデータ！ — `items`、`set_filter`、`set_sort_order`、`reload` |
| `glendix/mendix/list_attribute` | リストのアイテムごとにアクセスするかた — `ListAttributeValue`、`ListActionValue`、`ListWidgetValue` |
| `glendix/mendix/selection` | ひとつえらぶ、いっぱいえらぶ！ |
| `glendix/mendix/reference` | ひとつとつながる（ReferenceValue） — おともだちひとりをゆびさすかんじ！ |
| `glendix/mendix/reference_set` | いっぱいとつながる（ReferenceSetValue） — おともだちいっぱいゆびさすかんじ！ |
| `glendix/mendix/date` | JS Dateラッパー（つきがGleamでは1から、JSでは0からなんだけどじどうでかえてくれるよ！あたまいい！） |
| `glendix/mendix/big` | Big.jsラッパーだよ！すっごくせいかくなすうじがつかえるの（`compare`すると`gleam/order.Order`がかえってくるよ！） |
| `glendix/mendix/file` | `FileValue`、`WebImage` |
| `glendix/mendix/icon` | `WebIcon` — Glyph、Image、IconFont |
| `glendix/mendix/formatter` | `ValueFormatter` — `format`と`parse` |
| `glendix/mendix/filter` | FilterConditionビルダー！ — `and_`、`or_`、`equals`、`contains`、`attribute`、`literal` |
| `glendix/editor_config` | Editor Configurationおたすけ！ — ぞくせいをかくす、タブにする、じゅんばんをかえる（Jintとなかよし！） |

### JS Interopのところ！

| モジュール | なにをするの？ |
|---|---|
| `glendix/js/array` | Gleam List ↔ JS Arrayへんかん！（react_ffi.mjsをつかうからべつのFFIファイルいらない！） |
| `glendix/js/object` | オブジェクトつくる、ぞくせいよむ/かく/けす、メソッドよぶ、`new`でインスタンスつくる！ |
| `glendix/js/json` | `stringify`と`parse`！（parseは`Result`でかえしてくれるからあんぜん！） |
| `glendix/js/promise` | Promiseチェイニング（`then_`、`map`、`catch_`）、`all`、`race`、`resolve`、`reject` — `react.Promise(a)`のかたをそのままつかうよ！ |
| `glendix/js/dom` | DOMおたすけ！ — `focus`、`blur`、`click`、`scroll_into_view`、`query_selector`（`Option`でかえしてくれるよ！） |
| `glendix/js/timer` | `set_timeout`、`set_interval`、`clear_timeout`、`clear_interval` — `TimerId`はopaqueだからすうじでいたずらできないよ！ |

> SpreadJSとかのJSライブラリとちょくせつおはなしするときにつかうエスケープハッチだよ！ぜんぶ`Dynamic`かただからかたあんぜんせいはないけど、すっごくじゆう！`glendix/binding`でできることならそっちのほうがいいよ！

## れいをみてみよう！

### Attributeリスト

ボタンをつくるときはこうやってぞくせいをリストでならべるよ！おかいものリストみたいでしょ？

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

ぞくせいをいれたりいれなかったりしたいときは`attribute.none()`をつかうんだよ！「やっぱりいいや～」ってかんじ：

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

カウンターだよ！ボタンをおすとすうじがひとつずつふえるの！まほうみたい！

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
    // さいしょにあらわれたときいっかいだけうごくよ！
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

### useLayoutEffect（がめんをはかるやつ！）

これはがめんがかわったすぐあとにうごくんだけど、めにみえるまえにやるからすっごくはやいの！

```gleam
import glendix/react/hook

let ref = hook.use_ref(0.0)

hook.use_layout_effect_cleanup(
  fn() {
    // ここでがめんのおおきさとかをはかるよ！
    fn() { Nil }  // つかいおわったらおかたづけ！
  },
  [some_dep],
)
```

### Mendixのあたいをよんだりかいたり！

Mendixからあたいをもらってつかうほうほうだよ：

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

### みえたりかくれたり！（じょうけんつきレンダリング）

あるときだけみせたいなーってときはこうするよ！

```gleam
import glendix/react
import glendix/react/html

// Trueのときだけみせるよ！
react.when(is_visible, fn() {
  html.div_([react.text("じゃじゃーん！みえたよ！")])
})

// Someのあたいがあるときだけみせるよ！
react.when_some(maybe_user, fn(user) {
  html.span_([react.text(user.name)])
})
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

**3. `gleam run -m glendix/install`をじっこう！**（バインディングをじどうでつくってくれるよ！）

**4. Gleamラッパーモジュールをかく**（html.gleamとおなじパターンだよ）：

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

**5. ウィジェットでこうやってつかうよ：**

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

### .mpkウィジェットをつかう！

`.mpk`ファイルを`widgets/`フォルダにいれるとReactコンポーネントみたいにつかえるんだよ！めっちゃかっこよくない？！

**1. `.mpk`ファイルを`widgets/`フォルダにいれる！**

**2. `gleam run -m glendix/install`をじっこう！**（バインディングをぜんぶじどうでやってくれるよ！）

じどうで2つのことがおきるよ！べんりでしょ？：
- `.mpk`ファイルから`.mjs`と`.css`をぬきだして`widget_ffi.mjs`をつくってくれる
- `.mpk`のXMLにある`<property>`のていぎをよんで、`src/widgets/`にバインディング`.gleam`ファイルをじどうでつくってくれる（もうあるときはそのまま！）

**3. じどうでできた`src/widgets/*.gleam`ファイルをみてみよう：**

```gleam
// src/widgets/switch.gleam（じどうでできたよ！）
import glendix/mendix
import glendix/react.{type JsProps, type ReactElement}
import glendix/react/attribute
import glendix/widget

/// Switchウィジェットをかく — propsからぞくせいをよんでウィジェットにわたすよ！
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

ひっすなぞくせいとえらべるぞくせいをじどうでくべつしてくれるよ！できたファイルはすきにかえてもいいからね！

**4. ウィジェットでこうやってつかうよ：**

```gleam
import widgets/switch

// コンポーネントのなかで
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

ウィジェットをえらぶとバージョンのいちらんがでてきて、PluggableかClassicかもじどうでわかるよ！ダウンロードした`.mpk`は`widgets/`にほぞんされて、`src/widgets/`にバインディングコードもじどうでつくられるの！ぜんぶじどう！

> バージョンじょうほうはPlaywright（Chromium）でとってくるよ！さいしょのいっかいだけブラウザでログインがいるけど、そのあとは`.marketplace-cache/session.json`におぼえてるからだいじょうぶ！

## ビルドスクリプト！

glendixにはビルドスクリプトがぜんぶはいってるから、べつのファイルをつくらなくても`gleam run -m`だけでうごくよ！らくちん！

| コマンド | なにをするの？ |
|----------|-------------|
| `gleam run -m glendix/install` | いぞんかんけいインストール + バインディングせいせい + ウィジェットバインディングせいせい + ウィジェット`.gleam`ファイルせいせい（パッケージマネージャはじどうでみつけてくれる！） |
| `gleam run -m glendix/marketplace` | Marketplaceでウィジェットをさがしてダウンロード！（インタラクティブ！） |
| `gleam run -m glendix/define` | ウィジェットプロパティていぎをTUIでへんしゅう！（グループ、かた、列挙がた — ターミナルでぜんぶできるよ！） |
| `gleam run -m glendix/build` | プロダクションビルド！（.mpkファイルができるよ！） |
| `gleam run -m glendix/dev` | かいはつサーバー！（HMRだからポート3000でかえたらすぐはんえいされる！さいこう！） |
| `gleam run -m glendix/start` | Mendixテストプロジェクトとつなげる！ |
| `gleam run -m glendix/lint` | ESLintでコードをチェック！ |
| `gleam run -m glendix/lint_fix` | ESLintのもんだいをじどうでなおしてくれる！ |
| `gleam run -m glendix/release` | リリースビルド！ |

パッケージマネージャもじどうでみつけてくれるよ！：
- `pnpm-lock.yaml`がある？ pnpmをつかうね！
- `bun.lockb`か`bun.lock`がある？ bunをつかうね！
- なにもない？ じゃあnpmでいいね！かんたん！

## なかみをみてみよう！

ちゃんとせいりされてるでしょ？たんけんしてみてね！

```
glendix/
  react.gleam              ← いちばんだいじ！createElement、Context、keyed、コンポーネントていぎ、flushSync
  react_ffi.mjs            ← ようそをつくる、Fragment、Context、すごいコンポーネントアダプター、Gleamこうぞうどうとうせいmemo
  react/
    attribute.gleam         ← Attributeのかた + HTML属性かんすう108こいじょう！
    attribute_ffi.mjs       ← AttributeをReact propsにかえるやつ！
    hook.gleam              ← React Hook 40こ！（use_promiseとuse_form_statusもあるよ！）
    hook_ffi.mjs            ← Hook JSおたすけ！
    ref.gleam               ← Refアクセサ（currentとassign）
    event.gleam             ← イベントのかた16しゅるい + ハンドラ154こいじょう + アクセサ82こいじょう！
    event_ffi.mjs           ← イベントアクセサJSおたすけ！
    html.gleam              ← HTMLタグ85こいじょう！（じゅんすいGleam — JSなし！）
    svg.gleam               ← SVGようそ58こ！（じゅんすいGleam — JSなし！）
    svg_attribute.gleam     ← SVGせんよう属性97こいじょう！（じゅんすいGleam — JSなし！）
  js/
    array.gleam             ← Gleam List ↔ JS Array（FFIなし — react_ffi.mjsをつかうよ！）
    object.gleam            ← オブジェクトつくる、ぞくせいアクセス、メソッドよぶ！
    object_ffi.mjs          ← オブジェクトJSおたすけ！
    json.gleam              ← JSON stringify/parse！
    json_ffi.mjs            ← JSON JSおたすけ！
    promise.gleam           ← Promiseチェイニング、all、race！
    promise_ffi.mjs         ← Promise JSおたすけ！
    dom.gleam               ← DOM focus/blur/click/scroll/query！
    dom_ffi.mjs             ← DOM JSおたすけ！
    timer.gleam             ← setTimeout/setInterval！（opaqueなTimerId！）
    timer_ffi.mjs           ← タイマーJSおたすけ！
  mendix.gleam              ← Mendixのだいじなかた + Propsアクセサ
  mendix_ffi.mjs            ← MendixランタイムかたJSおたすけ
  mendix/
    editable_value.gleam    ← EditableValue
    action.gleam            ← ActionValue
    dynamic_value.gleam     ← DynamicValue
    list_value.gleam        ← ListValue + Sort + Filter
    list_attribute.gleam    ← リストれんけいかた
    selection.gleam         ← Selection
    reference.gleam         ← ReferenceValue（ひとつとつながる！）
    reference_set.gleam     ← ReferenceSetValue（いっぱいとつながる！）
    date.gleam              ← JS Dateラッパー
    big.gleam               ← Big.jsラッパー
    file.gleam              ← File / Image
    icon.gleam              ← Icon
    formatter.gleam         ← ValueFormatter
    filter.gleam            ← FilterConditionビルダー
  editor_config.gleam       ← Editor Configurationおたすけ（Jintとなかよし！Listはつかわない！）
  editor_config_ffi.mjs     ← @mendix/pluggable-widgets-toolsラッピング
  binding.gleam             ← がいぶReactコンポーネントバインディング API
  binding_ffi.mjs           ← バインディングJSおたすけ（installしたらあたらしくなるよ！）
  widget.gleam              ← .mpkウィジェットコンポーネントバインディング API
  widget_ffi.mjs            ← ウィジェットJSおたすけ（installしたらあたらしくなるよ！）
  classic.gleam             ← Classic（Dojo）ウィジェットラッパー
  classic_ffi.mjs           ← ClassicウィジェットJSおたすけ（installしたらあたらしくなるよ！）
  marketplace.gleam         ← Marketplaceウィジェットさがしてダウンロード！
  marketplace_ffi.mjs       ← Content API + Playwright + S3ダウンロードJSおたすけ
  define.gleam              ← ウィジェットプロパティていぎTUIエディター！
  define_ffi.mjs            ← ターミナルにゅうしゅつりょく + ファイルよみかきJSおたすけ
  define/
    types.gleam             ← Property、PropertyGroup、WidgetMetaのかたていぎ
    ui.gleam                ← TUIレンダリングおたすけ（にゅうりょくフィールド、レイアウト）
  cmd.gleam                 ← シェルコマンドじっこう + PMけんしゅつ + バインディングせいせい
  cmd_ffi.mjs               ← Node.js child_process + fs + ZIPパース + バインディングせいせい + ウィジェット.gleamファイルせいせい
  build.gleam               ← ビルドスクリプト
  dev.gleam                 ← かいはつサーバースクリプト
  start.gleam               ← Mendixれんけいスクリプト
  install.gleam             ← インストール + バインディングせいせいスクリプト
  release.gleam             ← リリースビルドスクリプト
  lint.gleam                ← ESLintスクリプト
  lint_fix.gleam            ← ESLintじどうしゅうせいスクリプト
```

## どうしてこうつくったの？

- **FFIはうすーいつなぎめだよ！** `.mjs`ファイルはJSのせかいとおはなしするだけ！ほんとのロジックはぜんぶGleamでかくよ！モジュールごとにひとつだけたんとう — `react_ffi.mjs`はようそつくり、`hook_ffi.mjs`はフック、`event_ffi.mjs`はイベントよみとり！
- **Opaqueかたであんぜん！** `ReactElement`とか`JsProps`とか`EditableValue`みたいなJSのあたいをGleamのかたでぎゅっとつつんでるから、まちがったつかいかたするとコンパイルのときにおしえてくれるよ！かしこい！
- **`undefined`が`Option`にじどうへんかん！** JSから`undefined`とか`null`がきたらGleamでは`None`になって、あたいがあったら`Some(value)`になるの！じどうでかわるからしんぱいいらない！
- **ぞくせいはリストでかくだけ！** `[attribute.class("x"), event.on_click(handler)]`ってかくんだよ！いれたくないときは`attribute.none()`！`attribute.class()`をなんかいもかいたらじどうでくっつけてくれるの！べんりすぎ！
- **Gleamタプル = JS配列！** `#(a, b)`はJSだと`[a, b]`なの！だから`useState`のもどりちとそのままつかえるんだよ！ふしぎ！

## ありがとう！

v2.0のReactバインディングをよくするとき、[redraw](https://github.com/ghivert/redraw)プロジェクトからいっぱいおべんきょうしたよ！FFIモジュールのわけかた、Hookのパターン、イベントシステムのつくりとか、いろいろさんこうにしたの！ありがとうredraw！

## ライセンス

[Blue Oak Model License 1.0.0](LICENSE)
