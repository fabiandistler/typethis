# typethis Roadmap

## v0.8 (current)

Whole-package type retrofit lands in v0.8 as three connected features:

1.  **[`enable_for_package()`](reference/enable_for_package.md)** runs
    [`as_typed()`](reference/as_typed.md) over every exported function
    in an installed package’s namespace, with optional per-function
    `.specs` and a `.filter` predicate.
2.  **[`as_typed_from_roxygen()`](reference/as_typed_from_roxygen.md)**
    lifts type specs out of installed `.Rd` files via an explicit
    `[type]` prefix or a vocabulary heuristic
    ([`default_type_vocabulary()`](reference/default_type_vocabulary.md)),
    and forwards the result through
    [`enable_for_package()`](reference/enable_for_package.md).
    [`parse_param_type()`](reference/parse_param_type.md) is the
    single-description preview helper.
3.  **[`enable_typed_namespace()`](reference/enable_typed_namespace.md)**
    /
    **[`disable_typed_namespace()`](reference/disable_typed_namespace.md)**
    register a `setHook(packageEvent(pkg, "onLoad"), ...)` handler that
    applies the retrofit on every load (and immediately if the namespace
    is already loaded), going through an unlock-modify-relock dance.
    [`as_typed_env()`](reference/as_typed_env.md) and
    [`enable_for_package()`](reference/enable_for_package.md) gained a
    matching `.unlock` parameter.

This pattern is for development and exploratory use, not CRAN-bound
code. See [`vignette("package-wide")`](articles/package-wide.md).

## v0.7

1.  **[`as_typed_env()`](reference/as_typed_env.md)** retrofits every
    function in an environment in one call, with `.specs` for
    per-function overrides and `.filter` to narrow the set.
2.  **`types(f)` / `types(f) <- value`** is a symmetric replacement-form
    accessor over [`as_typed()`](reference/as_typed.md).
    `types(g) <- types(f)` round-trips; `types(f) <- NULL` un-types `f`.

## v0.6

1.  **[`as_typed()`](reference/as_typed.md)** wraps an existing function
    with type checks via `...` argument specs. Specs for arguments with
    literal atomic defaults are inferred automatically;
    [`as_typed()`](reference/as_typed.md) is idempotent.
2.  **[`infer_specs()`](reference/infer_specs.md)** returns the inferred
    argument specs for a function as a named list.

## v0.5

A single feature lands in v0.5:

1.  **OpenAPI 3.1 bridge.** [`to_openapi()`](reference/to_openapi.md) /
    [`from_openapi()`](reference/from_openapi.md) lift typed models into
    `components.schemas` (with `$ref` rewriting from `#/$defs/X` to
    `#/components/schemas/X`) and turn typed functions into `paths`
    entries with a JSON `requestBody` and a `200` response.
    [`write_openapi()`](reference/write_openapi.md) /
    [`read_openapi()`](reference/read_openapi.md) are convenience
    wrappers around `yaml` and `jsonlite`; the format is inferred from
    the file extension. Composite type specs (`t_union`, `t_list_of`,
    `t_nullable`, `t_enum`) and [`field()`](reference/field.md)
    validator constraints (`numeric_range`, `string_pattern`, …) flow
    through unchanged via
    [`to_json_schema()`](reference/to_json_schema.md).

This sits alongside the v0.4 ODCS bridge: typethis models can now be
exported to either standard, and either standard can be loaded back into
typethis.

## v0.4

A single feature lands in v0.4:

1.  **Data Contract (ODCS v3) bridge.**
    [`to_datacontract()`](reference/to_datacontract.md) /
    [`from_datacontract()`](reference/from_datacontract.md) map typed
    models to and from the Open Data Contract Standard v3.x.
    [`write_datacontract()`](reference/write_datacontract.md) /
    [`read_datacontract()`](reference/read_datacontract.md) are
    convenience wrappers around `yaml`.
    [`datacontract_lint()`](reference/datacontract_lint.md) / `_test()`
    / `_export()` are thin shells over the upstream `datacontract` CLI.
    [`field()`](reference/field.md) gained ODCS metadata arguments
    (`primary_key`, `unique`, `pii`, `classification`, `tags`,
    `examples`, `references`, `quality`).

This closes the gap to Pydantic, which can be generated from a contract
via `datacontract export --format pydantic-model`. typethis works the
same way in both directions for R.

## v0.3

Two features land in v0.3, both rooted in the v0.2 foundation:

1.  **Composite type specs.** A structured `type_spec` S3 class with
    constructors [`t_union()`](reference/t_union.md),
    [`t_nullable()`](reference/t_nullable.md),
    [`t_list_of()`](reference/t_list_of.md),
    [`t_vector_of()`](reference/t_vector_of.md),
    [`t_enum()`](reference/t_enum.md),
    [`t_model()`](reference/t_model.md),
    [`t_predicate()`](reference/t_predicate.md). Composes freely;
    backward compatible with character names and predicate functions.
2.  **JSON Schema export.**
    [`to_json_schema()`](reference/to_json_schema.md) produces JSON
    Schema (Draft 2020-12) fragments from typed models, composite specs,
    validators, and [`field()`](reference/field.md) definitions. Builtin
    validators expose a `constraint` attribute that the exporter reads
    to emit `minimum`/`maxLength`/`pattern`/`enum` etc.

These features are the foundation for follow-up work (OpenAPI export,
RStudio addins for signature display, type inference helpers).

# typethis v0.2 Roadmap

This roadmap reflects the most promising next step for `typethis`: make
**typed functions** reliable enough to be the core user-facing feature,
and keep **typed classes** lightweight and idiomatic for R.

## Guiding principle

`typethis` should feel like **runtime validation for real R code**, not
a promise of full static typing.

That means:

- typed functions should work with ordinary R calling conventions
- typed models should remain simple validated records
- documentation should clearly separate runtime checks from static
  analysis

## 1. Make typed functions the flagship feature

Typed functions are the most compelling part of the package and the best
place to invest in v0.2.

### Goals

- validate **positional and named arguments** consistently
- respect the function’s real formals, defaults, and `...`
- validate return values with the same rigor as inputs
- keep coercion explicit and predictable
- provide better error messages and introspection metadata

### Why this matters

This is the feature most likely to feel familiar to users coming from
Python type hints or mypy-adjacent workflows. If typed functions are
solid, the rest of the package becomes easier to trust.

### Suggested work items

1.  Bind arguments against the wrapped function’s signature instead of
    only looking at supplied names.
2.  Make [`validate_call()`](reference/validate_call.md) follow the same
    binding rules as [`typed_function()`](reference/typed_function.md).
3.  Preserve wrapper metadata without clobbering the type information
    stored on the wrapper.
4.  Add tests for positional calls, default arguments, missing
    arguments, and `...`.
5.  Improve type-spec support for common cases like optional values and
    nested containers.

## 2. Keep typed classes as validated records

The current [`define_model()`](reference/define_model.md) API is useful,
but it is closer to a **validated record** abstraction than a full class
system.

### Recommendation

For v0.2, keep typed classes on **S3** and treat them as list-backed
validated records.

### Why S3 is the right fit

- it matches how R users already work with records and lists
- it stays lightweight and dependency-free
- it fits the current package shape without introducing a heavier OO
  model
- it avoids committing to R6 mutability or S4 complexity before there is
  a real need

### Suggested work items

1.  Formalize the `typed_model` contract: construction, validation,
    printing, and conversion.
2.  Make safe mutation explicit through
    [`update_model()`](reference/update_model.md) and revalidation
    helpers.
3.  Support nested models and field defaults consistently.
4.  Honor field metadata such as `nullable` consistently.
5.  Defer S4/R6 unless a concrete use case appears.

## 3. Clarify the package’s promise in docs

The README and vignette should make the runtime-only scope explicit so
users do not expect a full static type checker.

### Suggested documentation updates

- state clearly that `typethis` is runtime validation, not a mypy
  replacement
- show examples that use positional arguments, defaults, and nested data
  structures
- document what type specifications are supported today
- explain when to use [`typed_function()`](reference/typed_function.md)
  versus [`define_model()`](reference/define_model.md)

## 4. Proposed v0.2 sequencing

### Phase 1: typed functions

Fix argument binding, validation parity, and introspection. This is the
highest-value work because it strengthens the feature users are most
likely to reach for first.

### Phase 2: typed models

Stabilize the validated-record contract, nested fields, defaults, and
mutation helpers.

### Phase 3: documentation and positioning

Update the README and vignette once the core behavior is stable so the
examples match actual package behavior.

## 5. Success criteria for v0.2

The release should be considered successful if:

- typed functions validate both named and positional calls correctly
- model instances stay valid after creation and update
- the package feels useful for practical runtime validation in R
- the docs make the runtime-only limitation explicit
- no API promises more than the implementation actually delivers
