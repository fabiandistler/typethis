# Test whether a function was wrapped by `typed_function()`

Test whether a function was wrapped by
[`typed_function()`](typed_function.md)

## Usage

``` r
is_typed(fn)
```

## Arguments

- fn:

  Function to test.

## Value

`TRUE` if `fn` carries the typed-function metadata.

## See also

Other typed functions: [`as_typed()`](as_typed.md),
[`as_typed_env()`](as_typed_env.md),
[`as_typed_from_roxygen()`](as_typed_from_roxygen.md),
[`default_type_vocabulary()`](default_type_vocabulary.md),
[`disable_typed_namespace()`](disable_typed_namespace.md),
[`enable_for_package()`](enable_for_package.md),
[`enable_typed_namespace()`](enable_typed_namespace.md),
[`get_signature()`](get_signature.md),
[`infer_specs()`](infer_specs.md),
[`parse_param_type()`](parse_param_type.md),
[`signature()`](signature.md), [`typed_function()`](typed_function.md),
[`typed_method()`](typed_method.md), [`types()`](types.md),
[`validate_call()`](validate_call.md),
[`with_signature()`](with_signature.md)

## Examples

``` r
f <- function(x) x + 1
g <- typed_function(f, arg_specs = c(x = "numeric"))
is_typed(f)
#> [1] FALSE
is_typed(g)
#> [1] TRUE
```
