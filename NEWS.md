# typethis (development version)

## typethis 0.6.0

### New Features

#### Retrofitting existing functions

- `as_typed()` is a convenience wrapper around `typed_function()` for
  adding type checks to a function you already have. Argument specs are
  passed via `...` instead of `arg_specs = list(...)`, and specs for
  arguments with literal atomic defaults (`1L`, `1.5`, `"a"`, `TRUE`)
  are inferred automatically. Pass `name = NULL` to opt a single
  argument out, or `.infer = FALSE` to disable inference entirely.
  `as_typed()` is idempotent — re-wrapping a typed function merges the
  new specs into the existing wrapper instead of stacking another
  layer.
- `infer_specs()` returns the inferred argument specs for a function
  as a named list, useful for inspection or for building a spec
  manually.

Possible follow-ups deferred for a later release: a bulk
`as_typed_env()` helper for retrofitting whole namespaces, and a
replacement-style `types(f) <-` form.

## typethis 0.5.0

### New Features

#### OpenAPI 3.1 Bridge

- `to_openapi()` (S3 generic) converts typed models, model
  constructors, instances, typed functions, and mixed lists into an
  OpenAPI 3.1 document fragment. Schemas land under
  `components.schemas`; `$ref` strings are rewritten from JSON
  Schema's `#/$defs/X` form to OpenAPI's `#/components/schemas/X`
  form. Typed functions become a `paths` entry with a JSON
  `requestBody` (each `arg_specs` entry as a property; arguments
  without defaults end up in `required`) and a `200` response derived
  from `return_spec`.
- `from_openapi()` reads an OpenAPI 3.x document (path, URL, or
  parsed list) and registers each entry under `components.schemas`
  as a typed model with generated `new_*()` / `update_*()`
  constructors. `$ref`s to `components.schemas` resolve to
  `t_model()` references; inline `object` properties are registered
  as their own typed models.
- `write_openapi()` / `read_openapi()` wrap file IO. Format is
  inferred from the file extension (`.yaml`/`.yml` → YAML via
  `yaml`, `.json` → JSON via `jsonlite`); pass `format = "yaml"` /
  `"json"` to override.

The bridge sits on top of `to_json_schema()` (v0.3) — composite
type specs and validator constraints flow through unchanged, with no
new mapping code needed.

### Dependencies

- `jsonlite` is now also used (in addition to JSON Schema export) for
  `write_openapi(format = "json")` / `read_openapi()` on `.json`
  paths. Still in `Suggests`.

## typethis 0.4.1

### Improvements

- `coerce_type()` now accepts a `type_spec` argument for the
  composable cases where coercion has a clear meaning:
  `t_nullable()` (NULL passes through, otherwise the inner spec
  drives the coercion), `t_union()` (each alternative is tried in
  order; the first that coerces and validates wins), and `t_enum()`
  (the value is accepted directly if already in the allowed set, or
  coerced to the enum's value type and re-checked). Other
  `type_spec` kinds (`t_list_of()`, `t_vector_of()`, `t_model()`,
  `t_predicate()`) still error, but with a clearer message naming
  the unsupported kind.
- README and vignette updated to cover v0.3 (composable type specs,
  JSON Schema export) and v0.4 (Data Contract bridge).

### Internal

- New test for nested-object registration in `from_datacontract()`
  (covers the implicit `define_model_in()` side-effect for nested
  ODCS object properties).
- New `.github/workflows/R-CMD-check.yaml` runs `R CMD check`
  (errors on warnings) on macOS, Windows, and Ubuntu (release,
  devel, oldrel-1) plus a `lintr` job on every push and PR.

## typethis 0.4.0

### New Features

#### Data Contract (ODCS v3) Bridge

- `to_datacontract()` (S3 generic) converts typed models, model
  constructors, and instances into Open Data Contract Standard v3.x
  contracts as native R lists, ready for `yaml::write_yaml()`.
- `write_datacontract()` writes a contract directly to a `.yaml` file.
- `from_datacontract()` reads a contract YAML (path, URL, or parsed
  list) and registers each `schema` entry as a typed model with
  generated `new_*()` / `update_*()` constructors.
- `read_datacontract()` parses a contract YAML without registering
  anything.
- Thin wrappers around the `datacontract` CLI: `datacontract_lint()`,
  `datacontract_test()`, `datacontract_export()`, plus
  `datacontract_cli_available()` for capability detection.
- `field()` gained ODCS metadata arguments: `primary_key`, `unique`,
  `pii`, `classification`, `tags`, `examples`, `references`,
  `quality`. They round-trip through the contract bridge and are
  introspectable, but have no effect on runtime validation.
- Validator constraints (`numeric_range`, `string_length`,
  `string_pattern`, `vector_length`, `enum_validator`,
  `dataframe_spec`) are emitted as native ODCS constraint fields
  (`minimum`, `maxLength`, `pattern`, `enum`, ...).
- Constructs without a native ODCS mapping (data frames, factors,
  unions, custom predicate functions) emit `x-typethis-*` extension
  keys so the bridge round-trips through typethis-aware tooling.

### Dependencies

- `yaml (>= 2.3.0)` added to `Suggests`. Required only for
  `write_datacontract()`, `read_datacontract()`, and
  `from_datacontract()`.

## typethis 0.3.0

### New Features

#### Composite Type Specs

- New `type_spec` S3 class for structured, composable type specifications.
- New constructors: `t_union()`, `t_nullable()`, `t_list_of()`, `t_vector_of()`,
  `t_enum()`, `t_model()`, `t_predicate()`. They compose:
  `t_list_of(t_union("integer", "character"))` is valid.
- All composite specs work with `is_type()`, `assert_type()`,
  `typed_function()` (`arg_specs`/`return_spec`), and `field()`.
- Backward compatible: plain character builtin names and predicate
  functions continue to work everywhere they did before.
- Helper `is_type_spec()` to detect composite specs.

#### JSON Schema Export

- New `to_json_schema()` (S3 generic) serializes typed models, type specs,
  validator closures, and `field()` definitions into JSON Schema
  (Draft 2020-12) fragments suitable for `jsonlite::toJSON()`.
- Methods: `to_json_schema.default()`, `to_json_schema.type_spec()`,
  `to_json_schema.typed_model()`.
- Builtin validator factories (`numeric_range`, `string_length`,
  `string_pattern`, `vector_length`, `enum_validator`, `list_of`,
  `dataframe_spec`, `nullable`, `combine_validators`) now attach a
  structured `constraint` attribute to their returned closure. Use
  `validator_constraint()` to read it. The closure is otherwise
  unchanged and remains callable as before.
- Nested models become `$ref` entries with auto-populated `$defs`;
  cyclic references terminate via a stub-then-fill protocol.
- Constructs without a canonical JSON Schema mapping (data frames,
  factors, custom predicates) emit `x-typethis-*` extension keys.

### Bug Fixes

- `define_model_new_style()` now correctly detects `type_spec` objects
  passed as field definitions (they are lists, but not field-definition
  lists). Previously a bare `t_union(...)` in a `fields = list(...)`
  argument would produce a confusing "must have a 'type' specification"
  error.

### Dependencies

- `jsonlite (>= 1.8.0)` added to `Suggests` (needed only for
  serializing schemas produced by `to_json_schema()`).

## typethis 0.2.0

### New Features

#### Typed Functions (F1-F8)
- **`typed_function()`** now correctly validates arguments regardless of calling convention:
  - Positional arguments: `add(1, 2)`
  - Named arguments: `add(x = 1, y = 2)`
  - Mixed calls: `add(1, y = 2)`
  - Reordered named arguments: `add(y = 2, x = 1)`
- Missing required argument detection with clear error messages
- `...` (ellipsis) passthrough support
- Return value validation against `return_spec`
- Metadata preservation (formals, body, attributes)
- `get_signature()` exposes introspection data for tooling

#### Typed Models (M1-M5)
- New API: `define_model("ModelName", fields = list(...))` generates:
  - `new_ModelName()` constructor in calling environment
  - `update_ModelName()` for safe mutation with revalidation
- Nested model support: fields can reference other model classes
- Field defaults applied consistently including for nested fields
- Backward compatibility: old-style `define_model(name = "type", ...)` still works

#### Documentation (D1-D4)
- README now clarifies runtime-only scope
- README includes comparison table: `typed_function()` vs `define_model()`
- Updated vignette with v0.2 examples

### Bug Fixes

- Fixed formals assignment bug causing "argument missing" errors
- Fixed attribute preservation not copying original function metadata
- Fixed return value validation not executing

### Improvements

- API parameter naming aligned: `arg_specs`/`return_spec` (new) with backward-compatible `arg_types`/`return_type`
- Improved error messages for type mismatches
- Code style aligned with tidyverse style guide

### Dependencies

- Added `VignetteBuilder: knitr` to DESCRIPTION

---

# typethis 0.1.0

* First release of typethis on CRAN.

### Features

#### Core Type Checking
- `is_type()`: Check if a value matches a type specification
- `assert_type()`: Assert type with automatic error throwing
- `validate_type()`: Validate type with detailed error messages
- `is_one_of()`: Check if value matches one of multiple types
- `coerce_type()`: Safe type coercion with validation

#### Typed Functions
- `typed_function()`: Create type-safe functions with input/output validation
- `signature()`: Define function signatures with types
- `with_signature()`: Apply type signatures to functions
- `is_typed()`: Check if a function is typed
- `get_signature()`: Retrieve function signature information
- `validate_call()`: Validate function calls without execution

#### Advanced Validators
- `numeric_range()`: Validate numeric values within ranges
- `string_length()`: Validate string length constraints
- `string_pattern()`: Validate strings against regex patterns
- `vector_length()`: Validate vector/list lengths
- `dataframe_spec()`: Validate data frame structure and columns
- `enum_validator()`: Validate against allowed values
- `list_of()`: Validate list element types
- `nullable()`: Make validators accept NULL
- `combine_validators()`: Combine multiple validators

#### Typed Models
- `define_model()`: Create typed data models (similar to Pydantic)
- `field()`: Define model fields with validation and defaults
- `is_model()`: Check if object is a typed model
- `get_schema()`: Retrieve model schema
- `validate_model()`: Validate model instances
- `update_model()`: Update model fields with validation
- `model_to_list()`: Convert models to lists

### Supported Types

Built-in support for common R types:
- numeric, integer, double
- character, logical
- list, data.frame, matrix
- factor, Date, POSIXct
- function, environment

### Documentation

- Comprehensive README with examples
- Detailed vignette covering all features
- Extensive test coverage
- Function documentation with examples

### Comparison with Similar Tools

`typethis` is inspired by:
- **pydantic** (Python): Runtime validation and data models
- **mypy** (Python): Type checking and annotations
- **typed** (R): Type system for R

Key advantages of `typethis`:
- ✅ Comprehensive validation system
- ✅ Pydantic-like models for R
- ✅ Built-in validators for common patterns
- ✅ Function type checking
- ✅ Easy integration with existing code
- ✅ No external dependencies (except testthat for testing)

### Breaking Changes

None (initial release)

### Bug Fixes

None (initial release)

### Known Issues

- Static type checking is not supported (runtime only)
- Performance overhead for validation-heavy code
- No S4 class integration yet

### Future Roadmap

Planned for future releases:
- Integration with S4 classes
- More built-in validators
- Performance optimizations
- Type inference capabilities
- IDE integration (RStudio addins)
- Schema serialization (JSON Schema export)
- OpenAPI integration
- Static analysis tools

### Contributors

- TypeThis Team

### Acknowledgments

Inspired by:
- pydantic (Python)
- mypy (Python)
- TypeScript
- Rust's type system

### License

MIT License

---

For detailed usage and examples, see `vignette("typethis-guide")` or visit the [GitHub repository](https://github.com/fabiandistler/typethis).
