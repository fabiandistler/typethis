# Changelog

## typethis (development version)

### typethis 0.5.0

#### New Features

##### OpenAPI 3.1 Bridge

- [`to_openapi()`](https://fabiandistler.github.io/typethis/reference/to_openapi.md)
  (S3 generic) converts typed models, model constructors, instances,
  typed functions, and mixed lists into an OpenAPI 3.1 document
  fragment. Schemas land under `components.schemas`; `$ref` strings are
  rewritten from JSON Schema’s `#/$defs/X` form to OpenAPI’s
  `#/components/schemas/X` form. Typed functions become a `paths` entry
  with a JSON `requestBody` (each `arg_specs` entry as a property;
  arguments without defaults end up in `required`) and a `200` response
  derived from `return_spec`.
- [`from_openapi()`](https://fabiandistler.github.io/typethis/reference/from_openapi.md)
  reads an OpenAPI 3.x document (path, URL, or parsed list) and
  registers each entry under `components.schemas` as a typed model with
  generated `new_*()` / `update_*()` constructors. `$ref`s to
  `components.schemas` resolve to
  [`t_model()`](https://fabiandistler.github.io/typethis/reference/t_model.md)
  references; inline `object` properties are registered as their own
  typed models.
- [`write_openapi()`](https://fabiandistler.github.io/typethis/reference/write_openapi.md)
  /
  [`read_openapi()`](https://fabiandistler.github.io/typethis/reference/read_openapi.md)
  wrap file IO. Format is inferred from the file extension
  (`.yaml`/`.yml` → YAML via `yaml`, `.json` → JSON via `jsonlite`);
  pass `format = "yaml"` / `"json"` to override.

The bridge sits on top of
[`to_json_schema()`](https://fabiandistler.github.io/typethis/reference/to_json_schema.md)
(v0.3) — composite type specs and validator constraints flow through
unchanged, with no new mapping code needed.

#### Dependencies

- `jsonlite` is now also used (in addition to JSON Schema export) for
  `write_openapi(format = "json")` /
  [`read_openapi()`](https://fabiandistler.github.io/typethis/reference/read_openapi.md)
  on `.json` paths. Still in `Suggests`.

### typethis 0.4.1

#### Improvements

- [`coerce_type()`](https://fabiandistler.github.io/typethis/reference/coerce_type.md)
  now accepts a `type_spec` argument for the composable cases where
  coercion has a clear meaning:
  [`t_nullable()`](https://fabiandistler.github.io/typethis/reference/t_nullable.md)
  (NULL passes through, otherwise the inner spec drives the coercion),
  [`t_union()`](https://fabiandistler.github.io/typethis/reference/t_union.md)
  (each alternative is tried in order; the first that coerces and
  validates wins), and
  [`t_enum()`](https://fabiandistler.github.io/typethis/reference/t_enum.md)
  (the value is accepted directly if already in the allowed set, or
  coerced to the enum’s value type and re-checked). Other `type_spec`
  kinds
  ([`t_list_of()`](https://fabiandistler.github.io/typethis/reference/t_list_of.md),
  [`t_vector_of()`](https://fabiandistler.github.io/typethis/reference/t_vector_of.md),
  [`t_model()`](https://fabiandistler.github.io/typethis/reference/t_model.md),
  [`t_predicate()`](https://fabiandistler.github.io/typethis/reference/t_predicate.md))
  still error, but with a clearer message naming the unsupported kind.
- README and vignette updated to cover v0.3 (composable type specs, JSON
  Schema export) and v0.4 (Data Contract bridge).

#### Internal

- New test for nested-object registration in
  [`from_datacontract()`](https://fabiandistler.github.io/typethis/reference/from_datacontract.md)
  (covers the implicit `define_model_in()` side-effect for nested ODCS
  object properties).
- New `.github/workflows/R-CMD-check.yaml` runs `R CMD check` (errors on
  warnings) on macOS, Windows, and Ubuntu (release, devel, oldrel-1)
  plus a `lintr` job on every push and PR.

### typethis 0.4.0

#### New Features

##### Data Contract (ODCS v3) Bridge

- [`to_datacontract()`](https://fabiandistler.github.io/typethis/reference/to_datacontract.md)
  (S3 generic) converts typed models, model constructors, and instances
  into Open Data Contract Standard v3.x contracts as native R lists,
  ready for
  [`yaml::write_yaml()`](https://yaml.r-lib.org/reference/write_yaml.html).
- [`write_datacontract()`](https://fabiandistler.github.io/typethis/reference/write_datacontract.md)
  writes a contract directly to a `.yaml` file.
- [`from_datacontract()`](https://fabiandistler.github.io/typethis/reference/from_datacontract.md)
  reads a contract YAML (path, URL, or parsed list) and registers each
  `schema` entry as a typed model with generated `new_*()` /
  `update_*()` constructors.
- [`read_datacontract()`](https://fabiandistler.github.io/typethis/reference/read_datacontract.md)
  parses a contract YAML without registering anything.
- Thin wrappers around the `datacontract` CLI:
  [`datacontract_lint()`](https://fabiandistler.github.io/typethis/reference/datacontract_lint.md),
  [`datacontract_test()`](https://fabiandistler.github.io/typethis/reference/datacontract_test.md),
  [`datacontract_export()`](https://fabiandistler.github.io/typethis/reference/datacontract_export.md),
  plus
  [`datacontract_cli_available()`](https://fabiandistler.github.io/typethis/reference/datacontract_cli_available.md)
  for capability detection.
- [`field()`](https://fabiandistler.github.io/typethis/reference/field.md)
  gained ODCS metadata arguments: `primary_key`, `unique`, `pii`,
  `classification`, `tags`, `examples`, `references`, `quality`. They
  round-trip through the contract bridge and are introspectable, but
  have no effect on runtime validation.
- Validator constraints (`numeric_range`, `string_length`,
  `string_pattern`, `vector_length`, `enum_validator`, `dataframe_spec`)
  are emitted as native ODCS constraint fields (`minimum`, `maxLength`,
  `pattern`, `enum`, …).
- Constructs without a native ODCS mapping (data frames, factors,
  unions, custom predicate functions) emit `x-typethis-*` extension keys
  so the bridge round-trips through typethis-aware tooling.

#### Dependencies

- `yaml (>= 2.3.0)` added to `Suggests`. Required only for
  [`write_datacontract()`](https://fabiandistler.github.io/typethis/reference/write_datacontract.md),
  [`read_datacontract()`](https://fabiandistler.github.io/typethis/reference/read_datacontract.md),
  and
  [`from_datacontract()`](https://fabiandistler.github.io/typethis/reference/from_datacontract.md).

### typethis 0.3.0

#### New Features

##### Composite Type Specs

- New `type_spec` S3 class for structured, composable type
  specifications.
- New constructors:
  [`t_union()`](https://fabiandistler.github.io/typethis/reference/t_union.md),
  [`t_nullable()`](https://fabiandistler.github.io/typethis/reference/t_nullable.md),
  [`t_list_of()`](https://fabiandistler.github.io/typethis/reference/t_list_of.md),
  [`t_vector_of()`](https://fabiandistler.github.io/typethis/reference/t_vector_of.md),
  [`t_enum()`](https://fabiandistler.github.io/typethis/reference/t_enum.md),
  [`t_model()`](https://fabiandistler.github.io/typethis/reference/t_model.md),
  [`t_predicate()`](https://fabiandistler.github.io/typethis/reference/t_predicate.md).
  They compose: `t_list_of(t_union("integer", "character"))` is valid.
- All composite specs work with
  [`is_type()`](https://fabiandistler.github.io/typethis/reference/is_type.md),
  [`assert_type()`](https://fabiandistler.github.io/typethis/reference/assert_type.md),
  [`typed_function()`](https://fabiandistler.github.io/typethis/reference/typed_function.md)
  (`arg_specs`/`return_spec`), and
  [`field()`](https://fabiandistler.github.io/typethis/reference/field.md).
- Backward compatible: plain character builtin names and predicate
  functions continue to work everywhere they did before.
- Helper
  [`is_type_spec()`](https://fabiandistler.github.io/typethis/reference/is_type_spec.md)
  to detect composite specs.

##### JSON Schema Export

- New
  [`to_json_schema()`](https://fabiandistler.github.io/typethis/reference/to_json_schema.md)
  (S3 generic) serializes typed models, type specs, validator closures,
  and
  [`field()`](https://fabiandistler.github.io/typethis/reference/field.md)
  definitions into JSON Schema (Draft 2020-12) fragments suitable for
  [`jsonlite::toJSON()`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html).
- Methods: `to_json_schema.default()`, `to_json_schema.type_spec()`,
  `to_json_schema.typed_model()`.
- Builtin validator factories (`numeric_range`, `string_length`,
  `string_pattern`, `vector_length`, `enum_validator`, `list_of`,
  `dataframe_spec`, `nullable`, `combine_validators`) now attach a
  structured `constraint` attribute to their returned closure. Use
  [`validator_constraint()`](https://fabiandistler.github.io/typethis/reference/validator_constraint.md)
  to read it. The closure is otherwise unchanged and remains callable as
  before.
- Nested models become `$ref` entries with auto-populated `$defs`;
  cyclic references terminate via a stub-then-fill protocol.
- Constructs without a canonical JSON Schema mapping (data frames,
  factors, custom predicates) emit `x-typethis-*` extension keys.

#### Bug Fixes

- `define_model_new_style()` now correctly detects `type_spec` objects
  passed as field definitions (they are lists, but not field-definition
  lists). Previously a bare `t_union(...)` in a `fields = list(...)`
  argument would produce a confusing “must have a ‘type’ specification”
  error.

#### Dependencies

- `jsonlite (>= 1.8.0)` added to `Suggests` (needed only for serializing
  schemas produced by
  [`to_json_schema()`](https://fabiandistler.github.io/typethis/reference/to_json_schema.md)).

### typethis 0.2.0

#### New Features

##### Typed Functions (F1-F8)

- **[`typed_function()`](https://fabiandistler.github.io/typethis/reference/typed_function.md)**
  now correctly validates arguments regardless of calling convention:
  - Positional arguments: `add(1, 2)`
  - Named arguments: `add(x = 1, y = 2)`
  - Mixed calls: `add(1, y = 2)`
  - Reordered named arguments: `add(y = 2, x = 1)`
- Missing required argument detection with clear error messages
- `...` (ellipsis) passthrough support
- Return value validation against `return_spec`
- Metadata preservation (formals, body, attributes)
- [`get_signature()`](https://fabiandistler.github.io/typethis/reference/get_signature.md)
  exposes introspection data for tooling

##### Typed Models (M1-M5)

- New API: `define_model("ModelName", fields = list(...))` generates:
  - `new_ModelName()` constructor in calling environment
  - `update_ModelName()` for safe mutation with revalidation
- Nested model support: fields can reference other model classes
- Field defaults applied consistently including for nested fields
- Backward compatibility: old-style `define_model(name = "type", ...)`
  still works

##### Documentation (D1-D4)

- README now clarifies runtime-only scope
- README includes comparison table:
  [`typed_function()`](https://fabiandistler.github.io/typethis/reference/typed_function.md)
  vs
  [`define_model()`](https://fabiandistler.github.io/typethis/reference/define_model.md)
- Updated vignette with v0.2 examples

#### Bug Fixes

- Fixed formals assignment bug causing “argument missing” errors
- Fixed attribute preservation not copying original function metadata
- Fixed return value validation not executing

#### Improvements

- API parameter naming aligned: `arg_specs`/`return_spec` (new) with
  backward-compatible `arg_types`/`return_type`
- Improved error messages for type mismatches
- Code style aligned with tidyverse style guide

#### Dependencies

- Added `VignetteBuilder: knitr` to DESCRIPTION

------------------------------------------------------------------------

## typethis 0.1.0

- First release of typethis on CRAN.

#### Features

##### Core Type Checking

- [`is_type()`](https://fabiandistler.github.io/typethis/reference/is_type.md):
  Check if a value matches a type specification
- [`assert_type()`](https://fabiandistler.github.io/typethis/reference/assert_type.md):
  Assert type with automatic error throwing
- [`validate_type()`](https://fabiandistler.github.io/typethis/reference/validate_type.md):
  Validate type with detailed error messages
- [`is_one_of()`](https://fabiandistler.github.io/typethis/reference/is_one_of.md):
  Check if value matches one of multiple types
- [`coerce_type()`](https://fabiandistler.github.io/typethis/reference/coerce_type.md):
  Safe type coercion with validation

##### Typed Functions

- [`typed_function()`](https://fabiandistler.github.io/typethis/reference/typed_function.md):
  Create type-safe functions with input/output validation
- [`signature()`](https://fabiandistler.github.io/typethis/reference/signature.md):
  Define function signatures with types
- [`with_signature()`](https://fabiandistler.github.io/typethis/reference/with_signature.md):
  Apply type signatures to functions
- [`is_typed()`](https://fabiandistler.github.io/typethis/reference/is_typed.md):
  Check if a function is typed
- [`get_signature()`](https://fabiandistler.github.io/typethis/reference/get_signature.md):
  Retrieve function signature information
- [`validate_call()`](https://fabiandistler.github.io/typethis/reference/validate_call.md):
  Validate function calls without execution

##### Advanced Validators

- [`numeric_range()`](https://fabiandistler.github.io/typethis/reference/numeric_range.md):
  Validate numeric values within ranges
- [`string_length()`](https://fabiandistler.github.io/typethis/reference/string_length.md):
  Validate string length constraints
- [`string_pattern()`](https://fabiandistler.github.io/typethis/reference/string_pattern.md):
  Validate strings against regex patterns
- [`vector_length()`](https://fabiandistler.github.io/typethis/reference/vector_length.md):
  Validate vector/list lengths
- [`dataframe_spec()`](https://fabiandistler.github.io/typethis/reference/dataframe_spec.md):
  Validate data frame structure and columns
- [`enum_validator()`](https://fabiandistler.github.io/typethis/reference/enum_validator.md):
  Validate against allowed values
- [`list_of()`](https://fabiandistler.github.io/typethis/reference/list_of.md):
  Validate list element types
- [`nullable()`](https://fabiandistler.github.io/typethis/reference/nullable.md):
  Make validators accept NULL
- [`combine_validators()`](https://fabiandistler.github.io/typethis/reference/combine_validators.md):
  Combine multiple validators

##### Typed Models

- [`define_model()`](https://fabiandistler.github.io/typethis/reference/define_model.md):
  Create typed data models (similar to Pydantic)
- [`field()`](https://fabiandistler.github.io/typethis/reference/field.md):
  Define model fields with validation and defaults
- [`is_model()`](https://fabiandistler.github.io/typethis/reference/is_model.md):
  Check if object is a typed model
- [`get_schema()`](https://fabiandistler.github.io/typethis/reference/get_schema.md):
  Retrieve model schema
- [`validate_model()`](https://fabiandistler.github.io/typethis/reference/validate_model.md):
  Validate model instances
- [`update_model()`](https://fabiandistler.github.io/typethis/reference/update_model.md):
  Update model fields with validation
- [`model_to_list()`](https://fabiandistler.github.io/typethis/reference/model_to_list.md):
  Convert models to lists

#### Supported Types

Built-in support for common R types: - numeric, integer, double -
character, logical - list, data.frame, matrix - factor, Date, POSIXct -
function, environment

#### Documentation

- Comprehensive README with examples
- Detailed vignette covering all features
- Extensive test coverage
- Function documentation with examples

#### Comparison with Similar Tools

`typethis` is inspired by: - **pydantic** (Python): Runtime validation
and data models - **mypy** (Python): Type checking and annotations -
**typed** (R): Type system for R

Key advantages of `typethis`: - ✅ Comprehensive validation system - ✅
Pydantic-like models for R - ✅ Built-in validators for common
patterns - ✅ Function type checking - ✅ Easy integration with existing
code - ✅ No external dependencies (except testthat for testing)

#### Breaking Changes

None (initial release)

#### Bug Fixes

None (initial release)

#### Known Issues

- Static type checking is not supported (runtime only)
- Performance overhead for validation-heavy code
- No S4 class integration yet

#### Future Roadmap

Planned for future releases: - Integration with S4 classes - More
built-in validators - Performance optimizations - Type inference
capabilities - IDE integration (RStudio addins) - Schema serialization
(JSON Schema export) - OpenAPI integration - Static analysis tools

#### Contributors

- TypeThis Team

#### Acknowledgments

Inspired by: - pydantic (Python) - mypy (Python) - TypeScript - Rust’s
type system

#### License

MIT License

------------------------------------------------------------------------

For detailed usage and examples, see `vignette("typethis-guide")` or
visit the [GitHub
repository](https://github.com/fabiandistler/typethis).
