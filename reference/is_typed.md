# Test whether a function was wrapped by `typed_function()`

Test whether a function was wrapped by
[`typed_function()`](https://fabiandistler.github.io/typethis/reference/typed_function.md)

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

Other typed functions:
[`get_signature()`](https://fabiandistler.github.io/typethis/reference/get_signature.md),
[`signature`](https://fabiandistler.github.io/typethis/reference/signature.md),
[`typed_function()`](https://fabiandistler.github.io/typethis/reference/typed_function.md),
[`typed_method()`](https://fabiandistler.github.io/typethis/reference/typed_method.md),
[`validate_call()`](https://fabiandistler.github.io/typethis/reference/validate_call.md),
[`with_signature()`](https://fabiandistler.github.io/typethis/reference/with_signature.md)

## Examples

``` r
f <- function(x) x + 1
g <- typed_function(f, arg_specs = c(x = "numeric"))
is_typed(f)
#> [1] FALSE
is_typed(g)
#> [1] TRUE
```
