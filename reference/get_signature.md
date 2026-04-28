# Inspect the signature of a typed function

Returns the argument specs, return spec, and original formals attached
by [`typed_function()`](typed_function.md). Returns `NULL` for plain
functions.

## Usage

``` r
get_signature(fn)
```

## Arguments

- fn:

  A typed function.

## Value

Named list with `args`, `return`, and `formals`, or `NULL`.

## See also

Other typed functions: [`as_typed()`](as_typed.md),
[`infer_specs()`](infer_specs.md), [`is_typed()`](is_typed.md),
[`signature`](signature.md), [`typed_function()`](typed_function.md),
[`typed_method()`](typed_method.md),
[`validate_call()`](validate_call.md),
[`with_signature()`](with_signature.md)

## Examples

``` r
f <- typed_function(
  function(x, y) x + y,
  arg_specs = c(x = "numeric", y = "numeric"),
  return_spec = "numeric"
)
get_signature(f)
#> $args
#>         x         y 
#> "numeric" "numeric" 
#> 
#> $return
#> [1] "numeric"
#> 
#> $formals
#> $formals$x
#> 
#> 
#> $formals$y
#> 
#> 
#> 
```
