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

Other typed functions:
[`get_signature()`](https://fabiandistler.github.io/typethis/reference/get_signature.md),
[`is_typed()`](https://fabiandistler.github.io/typethis/reference/is_typed.md),
[`signature`](https://fabiandistler.github.io/typethis/reference/signature.md),
[`typed_function()`](https://fabiandistler.github.io/typethis/reference/typed_function.md),
[`typed_method()`](https://fabiandistler.github.io/typethis/reference/typed_method.md),
[`with_signature()`](https://fabiandistler.github.io/typethis/reference/with_signature.md)

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
