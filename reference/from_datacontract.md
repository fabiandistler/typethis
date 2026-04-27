# Import an ODCS contract into the typethis model registry

Reads an ODCS v3 contract (file path, URL, or already-parsed list) and
calls
[`define_model()`](https://fabiandistler.github.io/typethis/reference/define_model.md)
for every `schema` entry. Nested object properties are registered as
their own typed models so that
[`t_model()`](https://fabiandistler.github.io/typethis/reference/t_model.md)
references resolve correctly. After import, the generated `new_*()` and
`update_*()` constructors are available in `envir`.

## Usage

``` r
from_datacontract(x, register = TRUE, envir = parent.frame())
```

## Arguments

- x:

  A path, URL, or parsed ODCS list.

- register:

  Logical. If `TRUE` (default), define the models; if `FALSE`, only
  return the field definitions without touching the registry.

- envir:

  Environment in which `new_<Class>()` / `update_<Class>()` constructors
  are assigned. Defaults to the calling environment.

## Value

Character vector of registered model class names, invisibly.

## See also

Other Data Contract:
[`datacontract`](https://fabiandistler.github.io/typethis/reference/datacontract.md),
[`datacontract_cli_available()`](https://fabiandistler.github.io/typethis/reference/datacontract_cli_available.md),
[`datacontract_export()`](https://fabiandistler.github.io/typethis/reference/datacontract_export.md),
[`datacontract_lint()`](https://fabiandistler.github.io/typethis/reference/datacontract_lint.md),
[`datacontract_test()`](https://fabiandistler.github.io/typethis/reference/datacontract_test.md),
[`read_datacontract()`](https://fabiandistler.github.io/typethis/reference/read_datacontract.md),
[`to_datacontract()`](https://fabiandistler.github.io/typethis/reference/to_datacontract.md),
[`write_datacontract()`](https://fabiandistler.github.io/typethis/reference/write_datacontract.md)

## Examples

``` r
if (requireNamespace("yaml", quietly = TRUE)) {
  define_model("Order", fields = list(
    order_id = field("character", primary_key = TRUE),
    amount   = field("numeric")
  ))

  tmp <- tempfile(fileext = ".yaml")
  write_datacontract("Order", tmp,
    info = list(name = "orders", version = "1.0.0"))

  env <- new.env()
  from_datacontract(tmp, envir = env)
  ls(env)  # new_Order, update_Order
}
#> [1] "new_Order"    "update_Order"
```
