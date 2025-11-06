# typethis 0.1.0

## Initial MVP Release

### Features

* Static type checking for R code
* Type inference engine
* AST-based static analysis
* RStudio Addin integration
* data.table type support
* `reveal_type()` function for type inspection
* `typed()` decorator for runtime type checking
* `check_types()`, `check_file()`, `check_package()` functions
* Type assertion with `assert_type()`
* Comprehensive test suite
* Documentation and examples

### Type System

* Basic types: integer, numeric, double, character, logical, complex, raw
* Container types: list, vector, data.frame, data.table, tibble
* Special types: function, formula, S3, S4, R6, environment
* Custom type creation and validation

### RStudio Integration

* Check Types in Current File
* Reveal Type at Cursor
* Check Selection
* Insert Type Annotation

### Known Limitations

* Limited NSE (non-standard evaluation) support
* Some data.table operations may not be fully typed
* Type inference for complex S3/S4 dispatch is basic

### Planned Enhancements

* Type stubs for CRAN packages
* VS Code extension
* Pre-commit hooks
* CI/CD integration
* Configuration file support (.typethis.toml)
* Enhanced NSE handling
