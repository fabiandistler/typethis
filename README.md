# typethis: Type Safety and Validation for R

[![R-CMD-check](https://github.com/fabiandistler/typethis/workflows/R-CMD-check/badge.svg)](https://github.com/fabiandistler/typethis/actions)

`typethis` brings comprehensive type safety and validation to R, inspired by Python's `mypy` and `pydantic`. Write more robust R code with runtime type checking, typed functions, advanced validators, and typed data models.

## Features

- **Runtime Type Checking**: Validate types at runtime with `is_type()`, `assert_type()`, and `validate_type()`
- **Typed Functions**: Create type-safe functions with automatic input/output validation
- **Advanced Validators**: Built-in validators for common patterns (ranges, string patterns, data frames, etc.)
- **Typed Models**: Define data models with automatic validation (similar to Pydantic)
- **Type Coercion**: Safe type conversion with validation
- **Custom Validators**: Easy to create custom validation logic

## Installation

```r
# Install from GitHub
# install.packages("devtools")
devtools::install_github("fabiandistler/typethis")
```

## Quick Start

### Basic Type Checking

```r
library(typethis)

# Check types
is_type(5, "numeric")        # TRUE
is_type("hello", "numeric")  # FALSE

# Assert types (throws error on mismatch)
assert_type(5, "numeric", "my_variable")  # OK
assert_type("hello", "numeric", "my_variable")  # Error

# Validate with detailed error messages
result <- validate_type(5, "numeric", "x")
# result$valid = TRUE, result$error = NULL
```

### Typed Functions

```r
# Create a typed function
add_numbers <- typed_function(
  fn = function(x, y) x + y,
  arg_types = list(x = "numeric", y = "numeric"),
  return_type = "numeric"
)

add_numbers(5, 3)  # Returns 8
add_numbers("a", "b")  # Error: Type error

# Using signatures
sig <- signature(x = "numeric", y = "numeric", .return = "numeric")
multiply <- with_signature(function(x, y) x * y, sig)

multiply(5, 3)  # Returns 15
```

#### Calling Conventions

`typed_function()` supports all R calling conventions:

```r
add <- typed_function(
  fn = function(x, y) x + y,
  arg_specs = c(x = "numeric", y = "numeric")
)

# Positional arguments
add(1, 2)  # Returns 3

# Named arguments
add(x = 1, y = 2)  # Returns 3

# Reordered named arguments
add(y = 2, x = 1)  # Returns 3

# Mixed positional and named
add(1, y = 2)  # Returns 3

# Variadic functions with ... passthrough
sum_fn <- typed_function(
  fn = function(x, ...) sum(x, ...),
  arg_specs = c(x = "numeric")
)
sum_fn(c(1, NA, 3), na.rm = TRUE)  # Returns 4
```

#### Missing Argument Detection

```r
add <- typed_function(
  fn = function(x, y) x + y,
  arg_specs = c(x = "numeric", y = "numeric")
)

add(1)  # Error: missing required argument 'y' with no default

# Arguments with defaults are optional
add_with_default <- typed_function(
  fn = function(x, y = 1) x + y,
  arg_specs = c(x = "numeric", y = "numeric")
)
add_with_default(5)  # Returns 6
```

### Advanced Validators

```r
# Numeric range
age_validator <- numeric_range(min = 0, max = 120)
age_validator(25)   # TRUE
age_validator(150)  # FALSE

# String pattern (regex)
email_validator <- string_pattern(
  "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
)
email_validator("user@example.com")  # TRUE
email_validator("invalid-email")     # FALSE

# String length
name_validator <- string_length(min_length = 1, max_length = 50)

# Data frame validation
df_validator <- dataframe_spec(
  required_cols = c("id", "name", "age"),
  min_rows = 1
)

# Enum validator
status_validator <- enum_validator(c("active", "inactive", "pending"))

# Combine multiple validators
validator <- combine_validators(
  function(x) is.numeric(x),
  function(x) all(x > 0),
  all_of = TRUE
)
```

### Typed Models (like Pydantic)

```r
# v0.2+ New-style API: define_model("ClassName", fields = list(...))
define_model("User",
  fields = list(
    name = field("character", nullable = FALSE),
    age = field("numeric", nullable = FALSE),
    email = field("character", nullable = FALSE)
  )
)

# Creates new_User() and update_User() in your environment
user <- new_User(
  name = "John Doe",
  age = 30,
  email = "john@example.com"
)

# Access fields
user$name  # "John Doe"
user$age   # 30

# Type error is caught
new_User(name = "John", age = "thirty", email = "john@example.com")  # Error!

# Safe update with revalidation
user2 <- update_User(user, age = 31)

# Old-style API (still supported for backward compatibility)
Person <- define_model(
  name = "character",
  age = "numeric",
  email = "character",
  .validate = TRUE,
  .strict = TRUE
)
person <- Person(name = "Jane", age = 25, email = "jane@example.com")

# Advanced field definitions with defaults and validators
define_model("PersonWithDefaults",
  fields = list(
    name = field(
      type = "character",
      validator = string_length(min_length = 1, max_length = 100)
    ),
    age = field(
      type = "numeric",
      validator = numeric_range(min = 0, max = 120),
      default = 0
    ),
    email = field(
      type = "character",
      validator = string_pattern("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
    ),
    status = field(
      type = "character",
      validator = enum_validator(c("active", "inactive")),
      default = "active"
    )
  )
)

person <- new_PersonWithDefaults(
  name = "Jane Doe",
  email = "jane@example.com"
)
# age defaults to 0, status defaults to "active"

# Update model fields
person <- update_PersonWithDefaults(person, age = 25, status = "active")

# Validate model
result <- validate_model(person)
# result$valid = TRUE, result$errors = NULL

# Convert to list
model_to_list(person)
```

### Type Coercion

```r
# Safe type coercion
coerce_type("123", "numeric")     # 123
coerce_type(123, "character")     # "123"
coerce_type(c(1, 2), "integer")   # c(1L, 2L)

# Strict mode (fails on NA coercion)
coerce_type("abc", "numeric", strict = TRUE)  # Error
```

## Use Cases

### API Input Validation

```r
APIRequest <- define_model(
  endpoint = field("character", validator = string_pattern("^/api/")),
  method = field("character", validator = enum_validator(c("GET", "POST", "PUT", "DELETE"))),
  params = field("list", default = list()),
  .strict = TRUE
)

request <- APIRequest(
  endpoint = "/api/users",
  method = "GET",
  params = list(page = 1, limit = 10)
)
```

### Data Processing Pipelines

```r
process_data <- typed_function(
  fn = function(data, threshold) {
    data[data$value > threshold, ]
  },
  arg_types = list(
    data = dataframe_spec(required_cols = c("id", "value")),
    threshold = numeric_range(min = 0)
  ),
  return_type = "data.frame"
)
```

### Configuration Validation

```r
Config <- define_model(
  host = field("character", default = "localhost"),
  port = field("integer", validator = numeric_range(min = 1, max = 65535), default = 8080L),
  debug = field("logical", default = FALSE),
  database = define_model(
    name = "character",
    user = "character",
    password = "character"
  )
)
```

## Why typethis?

R is dynamically typed, which provides flexibility but can lead to runtime errors that are hard to debug. `typethis` helps you:

1. **Catch errors early**: Validate types at function boundaries
2. **Write clearer code**: Type annotations serve as documentation
3. **Build robust systems**: Ensure data conforms to expected schemas
4. **Validate inputs**: Comprehensive validation for user inputs, API responses, etc.
5. **Reduce bugs**: Prevent type-related bugs before they happen

## Runtime Only

**Important**: `typethis` provides **runtime validation only**, not static type checking.

- Type errors are caught when R code executes, not during development
- It does not replace static analysis tools like `mypy` for Python
- Benefits: works with any R code, no special IDE or tooling required
- Trade-off: errors are only caught at runtime

If you need static analysis for R, consider tools like `lintr` or IDE-based diagnostics.

## When to Use: `typed_function()` vs `define_model()`

| Use `typed_function()` when... | Use `define_model()` when... |
|--------------------------------|------------------------------|
| Wrapping existing functions | Creating structured data records |
| Validating function inputs/outputs | Building configuration objects |
| API boundary validation | Data transfer objects (DTOs) |
| Processing pipeline steps | Nested data structures |
| Need `...` passthrough | Need field-level validators |
| Function is the primary unit | Data is the primary unit |

### Quick Decision Guide

```r
# Use typed_function() for:
# - Functions that transform data
# - API endpoints
# - Data processing pipelines
process <- typed_function(
  fn = function(data, threshold) data[data$value > threshold, ],
  arg_specs = c(data = "data.frame", threshold = "numeric"),
  return_spec = "data.frame"
)

# Use define_model() for:
# - Configuration objects
# - API request/response schemas
# - Domain entities
Config <- define_model("Config",
  fields = list(
    host = field("character", default = "localhost"),
    port = field("integer", default = 8080L),
    debug = field("logical", default = FALSE)
  )
)
config <- new_Config(host = "api.example.com")
```

## Comparison with Python Tools

| Feature | typethis (R) | mypy (Python) | pydantic (Python) |
|---------|--------------|---------------|-------------------|
| Runtime type checking | ✅ | ❌ (static) | ✅ |
| Typed functions | ✅ | ✅ | ❌ |
| Data models | ✅ | ❌ | ✅ |
| Custom validators | ✅ | ❌ | ✅ |
| Type coercion | ✅ | ❌ | ✅ |
| Static analysis | ❌ | ✅ | ❌ |

## Documentation

See the package vignettes for detailed guides:

```r
# View the main guide
vignette("typethis-guide", package = "typethis")
```

## Roadmap

See [`ROADMAP.md`](ROADMAP.md) for the v0.2 plan. The short version: typed functions are the highest-priority feature, and typed classes should stay lightweight and S3-based until there is a clear reason to move to a heavier class system.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Related Projects

- [pydantic](https://pydantic-docs.helpmanual.io/) - Data validation for Python
- [mypy](http://mypy-lang.org/) - Static type checker for Python
- [typed](https://github.com/moodymudskipper/typed) - Another type checking package for R

## Examples

Check out more examples in the `vignettes/` directory:

- Basic type checking
- Creating typed functions
- Building data models
- Custom validators
- Integration with existing code

## Getting Help

- 📖 Read the [documentation](https://github.com/fabiandistler/typethis)
- 🐛 Report bugs at [GitHub Issues](https://github.com/fabiandistler/typethis/issues)
- 💬 Ask questions in [Discussions](https://github.com/fabiandistler/typethis/discussions)
