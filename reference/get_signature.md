# Inspect the signature of a typed function

Returns the argument specs, return spec, and original formals attached
by
[`typed_function()`](https://fabiandistler.github.io/typethis/reference/typed_function.md).
Returns `NULL` for plain functions.

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

Other typed functions:
[`is_typed()`](https://fabiandistler.github.io/typethis/reference/is_typed.md),
[`signature`](https://fabiandistler.github.io/typethis/reference/signature.md),
[`typed_function()`](https://fabiandistler.github.io/typethis/reference/typed_function.md),
[`typed_method()`](https://fabiandistler.github.io/typethis/reference/typed_method.md),
[`validate_call()`](https://fabiandistler.github.io/typethis/reference/validate_call.md),
[`with_signature()`](https://fabiandistler.github.io/typethis/reference/with_signature.md)

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
