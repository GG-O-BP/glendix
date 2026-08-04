[English](gleam-decimal.md) | [Korean](gleam-decimal.ko.md) | **Japanese**

# Gleam 10 進数ライブラリの開発

> [!NOTE]
> これは現在の Glendix API ではなく、過去の設計提案です。Decimal 値の境界は
> 現在 `mendraw/mendix/decimal` が所有し、以下の pure Gleam 演算 API は将来案です。

## 目標

`big.js` npm 依存関係を、JavaScript ランタイムをターゲットとした純粋な Gleam 任意精度 10 進数ライブラリに置き換えます。

## 現在の状態

この提案を書いた時点では、`glendix/mendix/big` は Big.js の不透明な FFI
ラッパーでした。

```
big.gleam (pub type Big, 13 functions) → big_ffi.mjs → import Big from "big.js"
```

API: `from_string`、`from_int`、`from_float`、`to_string`、`to_float`、`to_int`、`to_fixed`、`add`、 `subtract`、`multiply`、`divide`、`absolute`、`negate`、`compare`、`equal`

ウィジェット プロジェクトは、`package.json` 依存関係で `"big.js"` を宣言する必要があります。

## アーキテクチャ

### 内部表現

```gleam
/// Arbitrary-precision decimal: sign + coefficient (List(Int) of digits) + exponent
/// Example: -123.456 → Decimal(Negative, [1,2,3,4,5,6], -3)
pub opaque type Decimal {
  Decimal(sign: Sign, digits: List(Int), exponent: Int)
}

pub type Sign {
  Positive
  Negative
}
```

代替: 文字列ベースの表現 (単純ですが、演算は遅くなります)。

推奨: 数字リスト + 指数。これは、ほとんどの 10 進数ライブラリ (Python の `decimal`、Erlang の `:decimal`、Java の `BigDecimal`) で使用される標準的なアプローチです。

### Mendix 境界変換

Mendix ランタイムは、`Big.js` オブジェクトを `EditableValue<Big>` 経由で渡します。この境界は削除できません。Mendix がその型を所有しています。

```
Mendix (Big.js object) ←→ glendix boundary ←→ Gleam Decimal
```

glendix の変換レイヤー:

```gleam
// glendix/mendix/big.gleam — updated to use Gleam Decimal internally

/// Convert Mendix Big.js object to Gleam Decimal
@external(javascript, "./big_ffi.mjs", "big_to_decimal")
pub fn to_decimal(b: BigJs) -> Decimal

/// Convert Gleam Decimal to Mendix Big.js object
@external(javascript, "./big_ffi.mjs", "decimal_to_big")
pub fn from_decimal(d: Decimal) -> BigJs
```

FFI 実装 (文字列ベースのブリッジ - 最も単純かつ安全):

```js
// big_ffi.mjs
import Big from "big.js";
import { from_string } from "gleam_decimal"; // Gleam decimal package

export function big_to_decimal(bigJs) {
  return from_string(bigJs.toString());
}

export function decimal_to_big(decimal) {
  return new Big(to_string(decimal));
}
```

これは次のことを意味します。
- `big.js` は glendix の FFI 境界層に残ります (2 つの機能のみ)
- ウィジェット プロジェクトは、`package.json` に `big.js` を必要としなくなりました。
- すべての算術演算は純粋な Gleam であり、FFI はありません

### スコープ: Gleam 10 進数パッケージ

JavaScript をターゲットとするスタンドアロン Gleam パッケージ (`gleam_decimal` または `decimal` など):

```
gleam_decimal/
├── gleam.toml          # target = "javascript"
├── src/
│   └── decimal.gleam   # Core module
└── test/
    └── decimal_test.gleam
```

FFI ファイルはありません。ピュアグリム。

## 最小 API

```gleam
// === Creation ===
pub fn from_string(s: String) -> Result(Decimal, Nil)
pub fn from_int(n: Int) -> Decimal
pub fn from_float(f: Float) -> Decimal   // inherits IEEE 754 imprecision

// === Conversion ===
pub fn to_string(d: Decimal) -> String
pub fn to_float(d: Decimal) -> Float
pub fn to_int(d: Decimal) -> Int         // truncates fractional part
pub fn to_fixed(d: Decimal, dp: Int) -> String

// === Arithmetic ===
pub fn add(a: Decimal, b: Decimal) -> Decimal
pub fn subtract(a: Decimal, b: Decimal) -> Decimal
pub fn multiply(a: Decimal, b: Decimal) -> Decimal
pub fn divide(a: Decimal, b: Decimal) -> Result(Decimal, Nil)  // division by zero
pub fn absolute(d: Decimal) -> Decimal
pub fn negate(d: Decimal) -> Decimal

// === Comparison ===
pub fn compare(a: Decimal, b: Decimal) -> Order
pub fn equal(a: Decimal, b: Decimal) -> Bool
```

これにより、現在の `glendix/mendix/big` API に 1:1 がマッピングされ、移行がシームレスになります。

## 実装メモ

### 主要なアルゴリズム

1. **加算/減算**: 指数を整列させ、桁上げ/借用を使用して桁リストを加算/減算します。
2. **乗算**: 桁リスト、合計指数に関する教科書またはカラツバ アルゴリズム
3. **除算**: 精度を設定可能な長い除算 (デフォルトは有効数字 20 桁、Big.js と一致)
4. **解析**: `.` で分割し、桁リストを作成し、小数点位置から指数を計算します

### JavaScript ターゲットの考慮事項

- JS ターゲットの Gleam `Int` は、小さい値に対して JavaScript `Number` (BigInt ではない) を使用します — 要素ごとの桁リストによりオーバーフローが回避されます
- `List(Int)` は Gleam のリンク リストです - 非常に大きな数値のパフォーマンスを考慮してください
- 典型的な Mendix の使用例 (通貨、測定値) では、数値が 20 ～ 30 桁を超えることはほとんどありません。リンクされたリストのパフォーマンスは許容範囲内です。

### 精度と丸め

- Big.js のデフォルト: 小数点以下 20 桁、ROUND_HALF_UP
- Gleam ライブラリは、構成可能な精度と丸めモードをサポートする必要があります
- ドロップイン互換性のために、デフォルトの動作は Big.js と一致する必要があります

## 移行計画

### フェーズ 1: Gleam 10 進数パッケージ

1. コア演算を含む `gleam_decimal` パッケージを作成します
2. Big.js 出力に対して同等性をテストする
3. Hex にパブリッシュ

### フェーズ 2: glendix の統合

1. `gleam_decimal` を glendix の依存関係に追加します
2. 現在の `Big` タイプの名前を `BigJs` (Mendix 境界タイプ) に変更します。
3. `to_decimal` / `from_decimal` 変換ペアを追加します
4. `BigJs` (`big.add` など) の直接算術関数を非推奨にする
5. `glendix_guide.md` を新しいパターンで更新します

### フェーズ 3: ウィジェット プロジェクトのクリーンアップ

1. ウィジェットプロジェクト `package.json` から `"big.js"` を削除します
2. ウィジェット コードは、`big.add` ではなく `decimal.add` を使用します。
3. Mendix 境界のみでの変換:

```gleam
// Before (big.js throughout)
let value = mendix.get_big_prop(props, "amount")
let result = big.add(value, big.from_string("10"))

// After (Gleam Decimal for logic, Big.js at boundary only)
let value = mendix.get_big_prop(props, "amount") |> big.to_decimal
let result = decimal.add(value, decimal.from_string("10"))
// When passing back to Mendix:
big.from_decimal(result)
```

## 未解決の質問

- パッケージ名: `gleam_decimal`、`decimal`、または `bigi_decimal` (既存の `bigi` エコシステムを拡張)?
- ライブラリは Erlang (`:decimal` のラッピング) もターゲットにする必要がありますか?それとも現時点では JavaScript のみですか?
- パフォーマンスのしきい値: リンク リスト表現が問題になる桁数は何ですか?
