# Import an ODCS contract into the typethis model registry

Reads an ODCS v3 contract (file path, URL, or already-parsed list) and
calls [`define_model()`](define_model.md) for every `schema` entry.
Nested object properties are registered as their own typed models so
that [`t_model()`](t_model.md) references resolve correctly. After
import, the generated `new_*()` and `update_*()` constructors are
available in `envir`.

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

Other Data Contract: [`datacontract`](datacontract.md),
[`datacontract_cli_available()`](datacontract_cli_available.md),
[`datacontract_export()`](datacontract_export.md),
[`datacontract_lint()`](datacontract_lint.md),
[`datacontract_test()`](datacontract_test.md),
[`read_datacontract()`](read_datacontract.md),
[`to_datacontract()`](to_datacontract.md),
[`write_datacontract()`](write_datacontract.md)

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
