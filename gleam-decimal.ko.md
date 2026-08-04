[English](gleam-decimal.md) | **Korean** | [Japanese](gleam-decimal.ja.md)

# 글림 십진 라이브러리 개발

> [!NOTE]
> 이 문서는 현재 Glendix API가 아닌 과거 설계 제안이다. Decimal 값 경계는 현재
> `mendraw/mendix/decimal`이 담당하며, 아래 pure Gleam 연산 API는 향후 제안이다.

## 목표

`big.js` npm 종속성을 JavaScript 런타임을 대상으로 하는 순수 Gleam 임의 정밀도 십진 라이브러리로 대체합니다.

## 현재 상태

이 제안을 작성할 당시 `glendix/mendix/big`는 Big.js를 감싼 opaque FFI
래퍼였다.

```
big.gleam (pub type Big, 13 functions) → big_ffi.mjs → import Big from "big.js"
```

API: `from_string`, `from_int`, `from_float`, `to_string`, `to_float`, `to_int`, `to_fixed`, `add`, `subtract`, `multiply`, `divide`, `absolute`, `negate`, `compare`, `equal`

위젯 프로젝트는 `package.json` 종속성에서 `"big.js"`를 선언해야 합니다.

## 아키텍처

### 내부 표현

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

대안: 문자열 기반 표현(더 간단하지만 느린 산술).

권장 사항: 숫자 목록 + 지수. 이는 대부분의 십진 라이브러리(Python의 `decimal`, Erlang의 `:decimal`, Java의 `BigDecimal`)에서 사용되는 표준 접근 방식입니다.

### Mendix 경계 변환

Mendix 런타임은 `EditableValue<Big>`를 통해 `Big.js` 개체를 전달합니다. 이 경계는 제거될 수 없습니다. Mendix가 이 유형을 소유하고 있습니다.

```
Mendix (Big.js object) ←→ glendix boundary ←→ Gleam Decimal
```

glendix의 변환 레이어:

```gleam
// glendix/mendix/big.gleam — updated to use Gleam Decimal internally

/// Convert Mendix Big.js object to Gleam Decimal
@external(javascript, "./big_ffi.mjs", "big_to_decimal")
pub fn to_decimal(b: BigJs) -> Decimal

/// Convert Gleam Decimal to Mendix Big.js object
@external(javascript, "./big_ffi.mjs", "decimal_to_big")
pub fn from_decimal(d: Decimal) -> BigJs
```

FFI 구현(문자열 기반 브리지 — 가장 간단하고 안전함):

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

이는 다음을 의미합니다.
- `big.js`는 glendix의 FFI 경계층에 유지됩니다(2개 기능만 해당).
- 위젯 프로젝트의 `package.json`에는 더 이상 `big.js`가 필요하지 않습니다.
- 모든 산술 연산은 순수 Gleam입니다. FFI가 없습니다.

### 범위: Gleam 소수 패키지

JavaScript를 대상으로 하는 독립형 Gleam 패키지(예: `gleam_decimal` 또는 `decimal`):

```
gleam_decimal/
├── gleam.toml          # target = "javascript"
├── src/
│   └── decimal.gleam   # Core module
└── test/
    └── decimal_test.gleam
```

FFI 파일이 없습니다. 퓨어 글림.

## 최소 API

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

이는 현재 `glendix/mendix/big` API에 1:1로 매핑되므로 마이그레이션이 원활해집니다.

## 구현 참고사항

### 주요 알고리즘

1. **덧셈/뺄셈**: 지수를 정렬한 다음 캐리/빌림을 사용하여 숫자 목록을 더하거나 뺍니다.
2. **곱셈**: 숫자 목록의 Schoolbook 또는 Karatsuba 알고리즘, 합계 지수
3. **나누기**: 구성 가능한 정밀도가 있는 긴 나눗셈(기본적으로 유효 숫자 20자리, Big.js와 일치)
4. **파싱**: `.`로 분할, 숫자 목록 작성, 소수점 위치에서 지수 계산

### JavaScript 대상 고려 사항

- JS 대상의 Gleam `Int`는 작은 값에 JavaScript `Number`(BigInt 아님)를 사용합니다. 요소당 자릿수 목록이 오버플로를 방지합니다.
- `List(Int)`는 Gleam의 연결 목록입니다. 매우 큰 숫자에 대한 성능을 고려하세요.
- 일반적인 Mendix 사용 사례(통화, 측정)의 경우 숫자는 20~30자리를 거의 초과하지 않습니다. 연결 목록 성능은 허용 가능합니다.

### 정밀도 및 반올림

- Big.js 기본값: 소수점 이하 20자리, ROUND_HALF_UP
- Gleam 라이브러리는 구성 가능한 정밀도 및 반올림 모드를 지원해야 합니다.
- 드롭인 호환성을 위해 기본 동작은 Big.js와 일치해야 합니다.

## 마이그레이션 계획

### 1단계: Gleam Decimal 패키지

1. 핵심 연산을 사용하여 `gleam_decimal` 패키지 생성
2. Big.js 출력에 대해 동등성을 테스트합니다.
3. Hex에 게시

### 2단계: glendix 통합

1. glendix 종속성에 `gleam_decimal` 추가
2. 현재 `Big` 유형의 이름을 `BigJs`(Mendix 경계 유형)로 바꿉니다.
3. `to_decimal` / `from_decimal` 변환 쌍 추가
4. `BigJs`(`big.add` 등)에서 직접 산술 함수를 더 이상 사용하지 않습니다.
5. 새로운 패턴으로 `glendix_guide.md` 업데이트

### 3단계: 위젯 프로젝트 정리

1. 위젯 프로젝트 `package.json`에서 `"big.js"`를 제거합니다.
2. 위젯 코드는 `big.add` 대신 `decimal.add`를 사용합니다.
3. Mendix 경계에서만 변환:

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

## 공개 질문

- 패키지 이름: `gleam_decimal`, `decimal`, 아니면 `bigi_decimal`(기존 `bigi` 생태계 확장)?
- 라이브러리는 Erlang(`:decimal` 래핑)도 대상으로 해야 합니까? 아니면 지금은 JavaScript만 사용하고 있나요?
- 성능 임계값: 연결된 목록 표현이 문제가 되는 자릿수는 몇 자릿수입니까?
