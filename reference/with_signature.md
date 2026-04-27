# Apply a signature to a function

Equivalent to passing `sig$args` and `sig$return` to
[`typed_function()`](https://fabiandistler.github.io/typethis/reference/typed_function.md).

## Usage

``` r
with_signature(fn, sig)
```

## Arguments

- fn:

  Function to wrap.

- sig:

  A `type_signature` object from
  [`signature()`](https://fabiandistler.github.io/typethis/reference/signature.md).

## Value

A typed function.

## See also

Other typed functions:
[`get_signature()`](https://fabiandistler.github.io/typethis/reference/get_signature.md),
[`is_typed()`](https://fabiandistler.github.io/typethis/reference/is_typed.md),
[`signature`](https://fabiandistler.github.io/typethis/reference/signature.md),
[`typed_function()`](https://fabiandistler.github.io/typethis/reference/typed_function.md),
[`typed_method()`](https://fabiandistler.github.io/typethis/reference/typed_method.md),
[`validate_call()`](https://fabiandistler.github.io/typethis/reference/validate_call.md)

## Examples

``` r
sig <- signature(x = "numeric", y = "numeric", .return = "numeric")
multiply <- with_signature(function(x, y) x * y, sig)
multiply(5, 3)
#> [1] 15
```
