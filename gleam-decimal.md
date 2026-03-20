# Gleam decimal library development

## Goal

Replace the `big.js` npm dependency with a pure Gleam arbitrary-precision decimal library, targeting the JavaScript runtime.

## Current state

`glendix/mendix/big` is an opaque FFI wrapper around Big.js:

```
big.gleam (pub type Big, 13 functions) → big_ffi.mjs → import Big from "big.js"
```

API: `from_string`, `from_int`, `from_float`, `to_string`, `to_float`, `to_int`, `to_fixed`, `add`, `subtract`, `multiply`, `divide`, `absolute`, `negate`, `compare`, `equal`

The widget project must declare `"big.js"` in `package.json` dependencies.

## Architecture

### Internal representation

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

Alternative: string-based representation (simpler but slower arithmetic).

Recommended: digit-list + exponent. This is the standard approach used by most decimal libraries (Python's `decimal`, Erlang's `:decimal`, Java's `BigDecimal`).

### Mendix boundary conversion

Mendix runtime passes `Big.js` objects via `EditableValue<Big>`. This boundary cannot be eliminated — Mendix owns the type.

```
Mendix (Big.js object) ←→ glendix boundary ←→ Gleam Decimal
```

The conversion layer in glendix:

```gleam
// glendix/mendix/big.gleam — updated to use Gleam Decimal internally

/// Convert Mendix Big.js object to Gleam Decimal
@external(javascript, "./big_ffi.mjs", "big_to_decimal")
pub fn to_decimal(b: BigJs) -> Decimal

/// Convert Gleam Decimal to Mendix Big.js object
@external(javascript, "./big_ffi.mjs", "decimal_to_big")
pub fn from_decimal(d: Decimal) -> BigJs
```

FFI implementation (string-based bridge — simplest and safest):

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

This means:
- `big.js` stays in glendix's FFI boundary layer (2 functions only)
- Widget projects no longer need `big.js` in their `package.json`
- All arithmetic operations are pure Gleam — no FFI

### Scope: the Gleam decimal package

A standalone Gleam package (e.g., `gleam_decimal` or `decimal`) targeting JavaScript:

```
gleam_decimal/
├── gleam.toml          # target = "javascript"
├── src/
│   └── decimal.gleam   # Core module
└── test/
    └── decimal_test.gleam
```

No FFI files. Pure Gleam.

## Minimum API

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

This maps 1:1 to the current `glendix/mendix/big` API, making migration seamless.

## Implementation notes

### Key algorithms

1. **Addition/Subtraction**: Align exponents, then add/subtract digit lists with carry/borrow
2. **Multiplication**: Schoolbook or Karatsuba algorithm on digit lists, sum exponents
3. **Division**: Long division with configurable precision (default 20 significant digits, matching Big.js)
4. **Parsing**: Split on `.`, build digit list, calculate exponent from decimal point position

### JavaScript target considerations

- Gleam `Int` on JS target uses JavaScript `Number` (not BigInt) for small values — digit-per-element list avoids overflow
- `List(Int)` is a linked list in Gleam — consider performance for very large numbers
- For typical Mendix use cases (currency, measurements), numbers rarely exceed 20-30 digits — linked list performance is acceptable

### Precision and rounding

- Big.js defaults: 20 decimal places, ROUND_HALF_UP
- The Gleam library should support configurable precision and rounding modes
- Default behavior should match Big.js for drop-in compatibility

## Migration plan

### Phase 1: Gleam decimal package

1. Create `gleam_decimal` package with core arithmetic
2. Test against Big.js outputs for equivalence
3. Publish to Hex

### Phase 2: glendix integration

1. Add `gleam_decimal` to glendix dependencies
2. Rename current `Big` type to `BigJs` (Mendix boundary type)
3. Add `to_decimal` / `from_decimal` conversion pair
4. Deprecate direct arithmetic functions on `BigJs` (`big.add`, etc.)
5. Update `glendix_guide.md` with new patterns

### Phase 3: widget project cleanup

1. Remove `"big.js"` from widget project `package.json`
2. Widget code uses `decimal.add` instead of `big.add`
3. Conversion at Mendix boundary only:

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

## Open questions

- Package name: `gleam_decimal`, `decimal`, or `bigi_decimal` (extending the existing `bigi` ecosystem)?
- Should the library also target Erlang (wrapping `:decimal`)? Or JavaScript-only for now?
- Performance threshold: at what digit count does the linked-list representation become a concern?
