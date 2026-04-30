# typethis

> Runtime type safety and validation for R — inspired by Python's `pydantic` and `mypy`.

 <!-- badges: start -->
  [![R-CMD-check](https://github.com/fabiandistler/typethis/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/fabiandistler/typethis/actions/workflows/R-CMD-check.yaml)
  <!-- badges: end -->


`typethis` lets you describe what your data and your functions expect, and
checks it at runtime — clearly, with helpful error messages, and without
leaving plain R.

```r
define_model("User", fields = list(
  name  = field("character"),
  age   = field("integer", validator = numeric_range(0, 120)),
  email = field("character",
                validator = string_pattern("^[^@]+@[^@]+\\.[^@]+$"))
))

new_User(name = "Ada", age = 36L, email = "ada@example.com")
#> <Typed Model: User>
#> Fields:
#>   name: character = Ada
#>   age: integer = 36
#>   email: character = ada@example.com

new_User(name = "Ada", age = 200L, email = "ada@example.com")
#> Error: Validation failed for field 'age' in User
```

## Installation

```r
# install.packages("devtools")
devtools::install_github("fabiandistler/typethis")
```

## What you can do with it

- **Check types at runtime.** `is_type()`, `assert_type()`, `validate_type()`,
  `coerce_type()` for the everyday cases.
- **Wrap functions with type checks.** `typed_function()` validates arguments
  on every call and the return value on every exit.
- **Describe data with typed models.** `define_model("Class", fields = list(…))`
  generates `new_Class()` and `update_Class()` constructors with field-level
  validation, defaults, and nullability.
- **Compose richer types.** `t_union()`, `t_nullable()`, `t_list_of()`,
  `t_vector_of()`, `t_enum()`, `t_model()`, `t_predicate()` build up specs
  that work everywhere a type name does.
- **Reach out to other ecosystems.** Export and import [JSON
  Schema](https://json-schema.org/) (Draft 2020-12), [Open Data Contract
  Standard v3](https://bitol-io.github.io/open-data-contract-standard/),
  and [OpenAPI 3.1](https://spec.openapis.org/oas/v3.1.0) without leaving R.
- **Retrofit a whole package.** `enable_for_package()`,
  `as_typed_from_roxygen()`, and `enable_typed_namespace()` add type
  checks across an existing package without rewriting its functions.

## A 30-second tour

```r
library(typethis)

# 1. Type checks
is_type(1:3, "integer")            # TRUE
assert_type(42, "character", "x")  # Error: 'x' must be character, got integer

# 2. Typed functions
greet <- typed_function(
  function(name, times = 1L) paste(rep(name, times), collapse = " "),
  arg_specs = list(name = "character", times = "integer"),
  return_spec = "character"
)
greet("hi", times = 3L)            # "hi hi hi"
greet("hi", times = "3")           # Error: 'times' must be integer, got character

# 3. Typed models
define_model("Point", fields = list(
  x = field("numeric"),
  y = field("numeric")
))
p <- new_Point(x = 1, y = 2)
update_Point(p, x = 5)$x           # 5

# 4. Composable specs
status <- t_enum(c("new", "paid", "shipped"))
is_type("paid", status)            # TRUE
is_type("done", status)            # FALSE
```

## Documentation

The reference is shipped as vignettes — start with **Getting Started** and
follow the topic that matches what you want to do.

| Vignette | What it covers |
| --- | --- |
| [`vignette("getting-started")`](vignettes/getting-started.Rmd) | A 10-minute tour: type checks, typed functions, typed models. |
| [`vignette("validators-and-models")`](vignettes/validators-and-models.Rmd) | All built-in validators and how to combine them; nested and strict models; field metadata. |
| [`vignette("type-specs")`](vignettes/type-specs.Rmd) | Composable type specifications with the `t_*()` family. |
| [`vignette("interop")`](vignettes/interop.Rmd) | JSON Schema, Open Data Contract Standard, and OpenAPI 3.1 export and import. |
| [`vignette("package-wide")`](vignettes/package-wide.Rmd) | Retrofit type checks across an existing package without rewriting its functions. |

For the full function reference see `?typethis` (a topic-grouped index of
every exported function) or the individual help pages. Function help is
organised into families — `?typed_function` for example links to all other
functions in the "Typed functions" family via `seealso`.

## When should I use which tool?

| Use… | …when you want to… |
| --- | --- |
| `is_type()` / `assert_type()` | Add ad-hoc type checks at function boundaries. |
| `typed_function()` | Wrap a function so every call is validated automatically. |
| `define_model()` | Describe a record type — config, request body, domain entity — with field-level validation and constructors. |
| `numeric_range()`, `string_pattern()`, `enum_validator()`, … | Add value-level rules on top of types. |
| `t_union()`, `t_nullable()`, `t_list_of()`, `t_enum()`, … | Build a richer type spec inline (e.g. `t_list_of(t_union("integer", "character"))`). |
| `to_json_schema()` / `to_datacontract()` / `to_openapi()` | Hand the same definitions to non-R systems. |
| `enable_for_package()` / `as_typed_from_roxygen()` / `enable_typed_namespace()` | Retrofit type checks across an existing package without rewriting its functions. |

## Runtime only

`typethis` is a **runtime** validator. Errors surface when your code runs,
not when you save the file. That's the trade-off for working with any R
code, no IDE plugin, no compile step. For static analysis use `lintr` or
your IDE's diagnostics.

## Contributing

Contributions and bug reports are welcome — please open an
[issue](https://github.com/fabiandistler/typethis/issues) or pull request.

## License

MIT — see [`LICENSE`](LICENSE).

## Related projects

- [pydantic](https://docs.pydantic.dev/) — data validation for Python
- [mypy](https://mypy-lang.org/) — static type checker for Python
- [typed](https://github.com/moodymudskipper/typed) — another type system for R
