# typethis Roadmap

## v0.4 (current)

A single feature lands in v0.4:

1. **Data Contract (ODCS v3) bridge.** `to_datacontract()` /
   `from_datacontract()` map typed models to and from the Open Data
   Contract Standard v3.x. `write_datacontract()` /
   `read_datacontract()` are convenience wrappers around `yaml`.
   `datacontract_lint()` / `_test()` / `_export()` are thin shells
   over the upstream `datacontract` CLI. `field()` gained ODCS
   metadata arguments (`primary_key`, `unique`, `pii`,
   `classification`, `tags`, `examples`, `references`, `quality`).

This closes the gap to Pydantic, which can be generated from a contract
via `datacontract export --format pydantic-model`. typethis works the
same way in both directions for R.

## v0.3

Two features land in v0.3, both rooted in the v0.2 foundation:

1. **Composite type specs.** A structured `type_spec` S3 class with
   constructors `t_union()`, `t_nullable()`, `t_list_of()`,
   `t_vector_of()`, `t_enum()`, `t_model()`, `t_predicate()`. Composes
   freely; backward compatible with character names and predicate
   functions.
2. **JSON Schema export.** `to_json_schema()` produces JSON Schema
   (Draft 2020-12) fragments from typed models, composite specs,
   validators, and `field()` definitions. Builtin validators expose a
   `constraint` attribute that the exporter reads to emit
   `minimum`/`maxLength`/`pattern`/`enum` etc.

These features are the foundation for follow-up work (OpenAPI export,
RStudio addins for signature display, type inference helpers).

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
