# typethis (development version)

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
