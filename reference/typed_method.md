# Build a typed-method decorator

Returns a function that wraps an underlying method with type checks
suitable for S3 or R6 classes. The returned decorator is a thin shim
over
[`typed_function()`](https://fabiandistler.github.io/typethis/reference/typed_function.md)
that ignores `class_name` / `method_name` at runtime — they are kept as
documentation hooks.

## Usage

``` r
typed_method(class_name, method_name, arg_types = list(), return_type = NULL)
```

## Arguments

- class_name:

  Class name (informational).

- method_name:

  Method name (informational).

- arg_types:

  Named list of argument type specifications.

- return_type:

  Return-type specification.

## Value

A decorator: `function(fn) -> typed function`.

## See also

Other typed functions:
[`get_signature()`](https://fabiandistler.github.io/typethis/reference/get_signature.md),
[`is_typed()`](https://fabiandistler.github.io/typethis/reference/is_typed.md),
[`signature`](https://fabiandistler.github.io/typethis/reference/signature.md),
[`typed_function()`](https://fabiandistler.github.io/typethis/reference/typed_function.md),
[`validate_call()`](https://fabiandistler.github.io/typethis/reference/validate_call.md),
[`with_signature()`](https://fabiandistler.github.io/typethis/reference/with_signature.md)

## Examples

``` r
decorate <- typed_method(
  "Point", "translate",
  arg_types = list(dx = "numeric", dy = "numeric"),
  return_type = "list"
)
translate <- decorate(function(dx, dy) list(dx = dx, dy = dy))
translate(1, 2)
#> $dx
#> [1] 1
#> 
#> $dy
#> [1] 2
#> 
```
