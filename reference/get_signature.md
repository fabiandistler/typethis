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
[`as_typed_env()`](as_typed_env.md),
[`as_typed_from_roxygen()`](as_typed_from_roxygen.md),
[`default_type_vocabulary()`](default_type_vocabulary.md),
[`disable_typed_namespace()`](disable_typed_namespace.md),
[`enable_for_package()`](enable_for_package.md),
[`enable_typed_namespace()`](enable_typed_namespace.md),
[`infer_specs()`](infer_specs.md), [`is_typed()`](is_typed.md),
[`parse_param_type()`](parse_param_type.md),
[`signature`](signature.md), [`typed_function()`](typed_function.md),
[`typed_method()`](typed_method.md), [`types()`](types.md),
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
