# JSON Schema export

Convert typed models, type specs, validators, and field definitions into
[JSON Schema (Draft
2020-12)](https://json-schema.org/draft/2020-12/release-notes)
fragments. The result is an R list ready for
`jsonlite::toJSON(..., auto_unbox = TRUE)`.

Builtin validator factories ([`numeric_range()`](numeric_range.md),
[`string_length()`](string_length.md),
[`string_pattern()`](string_pattern.md),
[`vector_length()`](vector_length.md),
[`enum_validator()`](enum_validator.md)) attach a `constraint` attribute
that the exporter reads — so range and pattern constraints surface as
native `minimum` / `maxLength` / `pattern` keys rather than opaque
predicate stubs.

Constructs without a canonical JSON Schema representation (data frames,
factors, environments, custom predicate functions) are emitted with
`x-typethis-*` extension keys so they round-trip through typethis-aware
tooling without losing information.

## See also

Other JSON Schema: [`to_json_schema()`](to_json_schema.md)
