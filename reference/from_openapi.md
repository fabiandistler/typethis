# Import OpenAPI components into the typethis model registry

Reads an OpenAPI 3.x document (file path, URL, or already-parsed list)
and calls [`define_model()`](define_model.md) for every entry under
`components.schemas`. Nested `object` properties with their own
`properties` block are registered as their own typed models so that
[`t_model()`](t_model.md) references resolve correctly. After import,
the generated `new_*()` and `update_*()` constructors are available in
`envir`.

## Usage

``` r
from_openapi(x, register = TRUE, envir = parent.frame())
```

## Arguments

- x:

  Path, URL, or parsed list.

- register:

  If `TRUE` (default), define the models; if `FALSE`, only parse and
  return the resolved field definitions on the result attribute.

- envir:

  Environment in which `new_<Class>()` / `update_<Class>()` constructors
  are assigned. Defaults to the calling environment.

## Value

Character vector of registered model class names, invisibly.

## See also

Other OpenAPI: [`openapi`](openapi.md),
[`read_openapi()`](read_openapi.md), [`to_openapi()`](to_openapi.md),
[`write_openapi()`](write_openapi.md)

## Examples

``` r
if (requireNamespace("yaml", quietly = TRUE)) {
  define_model("User", fields = list(
    id   = field("integer", primary_key = TRUE),
    name = field("character")
  ))
  tmp <- tempfile(fileext = ".yaml")
  write_openapi("User", tmp,
    info = list(title = "Users API", version = "1.0.0"))

  env <- new.env()
  from_openapi(tmp, envir = env)
  ls(env)  # new_User, update_User
}
#> [1] "new_User"    "update_User"
```
