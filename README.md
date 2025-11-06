# typethis

**Static Type Checking for R** - Inspired by mypy for Python

`typethis` brings gradual static type checking to R, allowing you to catch type errors before runtime without sacrificing R's dynamic nature.

## Features

### ✅ MVP Features (Current)

- **Static Analysis Core**: Analyzes R code without execution using AST parsing
- **Type Inference**: Automatically infers types from literals, function calls, and assignments
- **Gradual Typing**: Add types incrementally to existing code
- **RStudio Integration**: Addins for type checking in your IDE
- **data.table Support**: Special handling for data.table types and operations
- **reveal_type()**: Inspect inferred types like mypy
- **Runtime Type Checking**: Optional runtime validation with `typed()` decorator

## Installation

```r
# Install from GitHub
devtools::install_github("yourusername/typethis")
```

## Quick Start

### Basic Usage

```r
library(typethis)

# Infer types automatically
x <- 5L
reveal_type(x)  # Type of 'x': integer

# Check types in code
code <- "
x <- 5L
y <- 'hello'
z <- x + y  # Type inconsistency!
"

result <- check_types(code)
print(result)
```

### Type Annotations with `typed()`

```r
# Add runtime type checking to functions
add <- typed(x = "integer", y = "integer", .return = "integer")(
  function(x, y) {
    x + y
  }
)

add(5L, 3L)        # OK
add("a", "b")      # Error: Type mismatch!
```

### data.table Support

```r
library(data.table)

# Define typed data.table
dt <- data.table(
  id = 1:5,
  name = letters[1:5],
  value = rnorm(5)
)

# Infer column types
reveal_type(dt)
# Type of 'dt': data.table
#   Columns:
#     id: integer
#     name: character
#     value: double
```

### RStudio Addins

After installing the package, you'll find new addins in RStudio:

1. **Check Types in Current File**: Run type checking on your R file
2. **Reveal Type at Cursor**: Show type of variable under cursor
3. **Check Selection**: Check types in selected code
4. **Insert Type Annotation**: Insert type annotation template

## Usage Examples

### Check an R File

```r
# Check types in a file
result <- check_file("my_script.R")

# Check all files in a package
results <- check_package("path/to/package")
```

### Type Inference

```r
# Infer types from code
code <- "
x <- 5L
y <- 3.14
z <- 'hello'
df <- data.frame(a = 1:3, b = letters[1:3])
"

types <- infer_types_from_code(code)
print(types)
#   variable      type line
# 1        x   integer    2
# 2        y   numeric    3
# 3        z character    4
# 4       df data.frame    5
```

### Reveal All Types

```r
code <- "
x <- 5L
y <- x * 2
z <- as.character(y)
"

reveal_all_types(code)
# Types found in code:
# ===================
# Line 2: x :: integer
# Line 3: y :: numeric
# Line 4: z :: character
```

### Type Assertions

```r
# Runtime type assertions
x <- 5L
assert_type(x, "integer")  # OK
assert_type(x, "character")  # Error!

# With variable name for better error messages
assert_type(x, "integer", var_name = "x")
```

## Type System

### Basic Types

- `integer`, `numeric`, `double`
- `character`, `logical`
- `complex`, `raw`
- `NULL`, `any`, `unknown`

### Container Types

- `list`, `vector`
- `data.frame`, `data.table`, `tibble`

### Special Types

- `function` (with argument and return types)
- `formula`
- `S3`, `S4`, `R6` (class-based types)
- `environment`

### Creating Custom Types

```r
# data.table with column types
dt_type <- data_table_type(
  id = "integer",
  name = "character",
  value = "numeric"
)

# Function with signature
fn_type <- function_type(
  args = list(x = "integer", y = "numeric"),
  return_type = "numeric"
)
```

## How It Works

1. **Parse**: Code is parsed into an AST using `getParseData()`
2. **Infer**: Types are inferred from literals, function calls, and context
3. **Check**: Type consistency is verified across assignments and function calls
4. **Report**: Errors and warnings are collected and displayed

## Comparison with Other Tools

### vs typeChecker

- ✅ More comprehensive type system
- ✅ data.table support
- ✅ RStudio integration
- ✅ Active development

### vs Static Analysis Tools

- ✅ Focused specifically on types
- ✅ Gradual typing (not all-or-nothing)
- ✅ IDE integration

## Limitations

### Current Limitations

- NSE (non-standard evaluation) is complex to analyze fully
- Some data.table operations may not be fully typed
- Type inference for complex S3/S4 dispatch is limited
- No support for type stubs yet

### Future Enhancements

- [ ] Type stubs for CRAN packages
- [ ] VS Code extension
- [ ] Pre-commit hooks
- [ ] CI/CD integration
- [ ] Configuration via `.typethis.toml`
- [ ] Enhanced NSE handling
- [ ] More sophisticated inference

## Development

```r
# Install development version
devtools::install_github("yourusername/typethis")

# Run tests
devtools::test()

# Build package
devtools::build()
```

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - see LICENSE file for details

## Acknowledgments

- Inspired by [mypy](https://mypy-lang.org/) for Python
- Built on R's excellent parsing capabilities
- Thanks to the R community for feedback and support

## Examples

See the `examples/` directory for more detailed usage examples:

- `basic_usage.R`: Getting started with typethis
- `data_table_examples.R`: Working with data.table
- `function_typing.R`: Type checking functions
- `rstudio_workflow.R`: Using RStudio addins

## Get Help

- Report issues: [GitHub Issues](https://github.com/yourusername/typethis/issues)
- Ask questions: [GitHub Discussions](https://github.com/yourusername/typethis/discussions)

---

**Note**: This is an MVP (Minimum Viable Product). The type system will continue to evolve based on community feedback and real-world usage.
