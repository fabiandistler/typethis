# typethis 0.1.0

## Initial Release

This is the first release of `typethis`, bringing comprehensive type safety and validation to R.

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
