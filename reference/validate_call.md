# Validate a call to a typed function without executing it

Runs the same checks as a real call but returns the outcome as a list
instead of executing the body. Useful for validating user input before
performing side effects.

## Usage

``` r
validate_call(fn, ..., return_spec = NULL)
```

## Arguments

- fn:

  A typed function.

- ...:

  Arguments to validate against `fn`'s spec.

- return_spec:

  Reserved for API parity; currently unused.

## Value

Named list `list(valid, errors)`. `errors` is `NULL` on success.

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
[`with_signature()`](with_signature.md)

## Examples

``` r
f <- typed_function(
  function(x, y) x + y,
  arg_specs = c(x = "numeric", y = "numeric")
)
validate_call(f, x = 5, y = 3)
#> $valid
#> [1] TRUE
#> 
#> $errors
#> NULL
#> 
validate_call(f, x = "a", y = 3)
#> $valid
#> [1] FALSE
#> 
#> $errors
#> [1] "Type error: 'x' must be numeric, got character"
#> 
```
