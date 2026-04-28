# Build a typed-method decorator

Returns a function that wraps an underlying method with type checks
suitable for S3 or R6 classes. The returned decorator is a thin shim
over [`typed_function()`](typed_function.md) that ignores `class_name` /
`method_name` at runtime — they are kept as documentation hooks.

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

Other typed functions: [`as_typed()`](as_typed.md),
[`as_typed_env()`](as_typed_env.md),
[`get_signature()`](get_signature.md),
[`infer_specs()`](infer_specs.md), [`is_typed()`](is_typed.md),
[`signature`](signature.md), [`typed_function()`](typed_function.md),
[`types()`](types.md), [`validate_call()`](validate_call.md),
[`with_signature()`](with_signature.md)

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
