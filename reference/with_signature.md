# Apply a signature to a function

Equivalent to passing `sig$args` and `sig$return` to
[`typed_function()`](typed_function.md).

## Usage

``` r
with_signature(fn, sig)
```

## Arguments

- fn:

  Function to wrap.

- sig:

  A `type_signature` object from [`signature()`](signature.md).

## Value

A typed function.

## See also

Other typed functions: [`as_typed()`](as_typed.md),
[`as_typed_env()`](as_typed_env.md),
[`as_typed_from_roxygen()`](as_typed_from_roxygen.md),
[`default_type_vocabulary()`](default_type_vocabulary.md),
[`disable_typed_namespace()`](disable_typed_namespace.md),
[`enable_for_package()`](enable_for_package.md),
[`enable_typed_namespace()`](enable_typed_namespace.md),
[`get_signature()`](get_signature.md),
[`infer_specs()`](infer_specs.md), [`is_typed()`](is_typed.md),
[`parse_param_type()`](parse_param_type.md),
[`signature()`](signature.md), [`typed_function()`](typed_function.md),
[`typed_method()`](typed_method.md), [`types()`](types.md),
[`validate_call()`](validate_call.md)

## Examples

``` r
sig <- signature(x = "numeric", y = "numeric", .return = "numeric")
multiply <- with_signature(function(x, y) x * y, sig)
multiply(5, 3)
#> [1] 15
```
