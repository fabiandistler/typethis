# typethis v0.2 Roadmap

This roadmap reflects the most promising next step for `typethis`: make **typed functions** reliable enough to be the core user-facing feature, and keep **typed classes** lightweight and idiomatic for R.

## Guiding principle

`typethis` should feel like **runtime validation for real R code**, not a promise of full static typing.

That means:

- typed functions should work with ordinary R calling conventions
- typed models should remain simple validated records
- documentation should clearly separate runtime checks from static analysis

## 1. Make typed functions the flagship feature

Typed functions are the most compelling part of the package and the best place to invest in v0.2.

### Goals

- validate **positional and named arguments** consistently
- respect the function’s real formals, defaults, and `...`
- validate return values with the same rigor as inputs
- keep coercion explicit and predictable
- provide better error messages and introspection metadata

### Why this matters

This is the feature most likely to feel familiar to users coming from Python type hints or mypy-adjacent workflows. If typed functions are solid, the rest of the package becomes easier to trust.

### Suggested work items

1. Bind arguments against the wrapped function’s signature instead of only looking at supplied names.
2. Make `validate_call()` follow the same binding rules as `typed_function()`.
3. Preserve wrapper metadata without clobbering the type information stored on the wrapper.
4. Add tests for positional calls, default arguments, missing arguments, and `...`.
5. Improve type-spec support for common cases like optional values and nested containers.

## 2. Keep typed classes as validated records

The current `define_model()` API is useful, but it is closer to a **validated record** abstraction than a full class system.

### Recommendation

For v0.2, keep typed classes on **S3** and treat them as list-backed validated records.

### Why S3 is the right fit

- it matches how R users already work with records and lists
- it stays lightweight and dependency-free
- it fits the current package shape without introducing a heavier OO model
- it avoids committing to R6 mutability or S4 complexity before there is a real need

### Suggested work items

1. Formalize the `typed_model` contract: construction, validation, printing, and conversion.
2. Make safe mutation explicit through `update_model()` and revalidation helpers.
3. Support nested models and field defaults consistently.
4. Honor field metadata such as `nullable` consistently.
5. Defer S4/R6 unless a concrete use case appears.

## 3. Clarify the package’s promise in docs

The README and vignette should make the runtime-only scope explicit so users do not expect a full static type checker.

### Suggested documentation updates

- state clearly that `typethis` is runtime validation, not a mypy replacement
- show examples that use positional arguments, defaults, and nested data structures
- document what type specifications are supported today
- explain when to use `typed_function()` versus `define_model()`

## 4. Proposed v0.2 sequencing

### Phase 1: typed functions

Fix argument binding, validation parity, and introspection. This is the highest-value work because it strengthens the feature users are most likely to reach for first.

### Phase 2: typed models

Stabilize the validated-record contract, nested fields, defaults, and mutation helpers.

### Phase 3: documentation and positioning

Update the README and vignette once the core behavior is stable so the examples match actual package behavior.

## 5. Success criteria for v0.2

The release should be considered successful if:

- typed functions validate both named and positional calls correctly
- model instances stay valid after creation and update
- the package feels useful for practical runtime validation in R
- the docs make the runtime-only limitation explicit
- no API promises more than the implementation actually delivers
