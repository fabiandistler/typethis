# Build a function signature object

Bundles argument types and an optional return type into a single object
that can be applied to one or more functions via
[`with_signature()`](https://fabiandistler.github.io/typethis/reference/with_signature.md).
Useful when several functions share the same shape.

## Usage

``` r
signature(..., .return = NULL)
```

## Arguments

- ...:

  Named type specifications (one per argument).

- .return:

  Return-type specification, or `NULL`.

## Value

A `type_signature` object.

## See also

Other typed functions:
[`get_signature()`](https://fabiandistler.github.io/typethis/reference/get_signature.md),
[`is_typed()`](https://fabiandistler.github.io/typethis/reference/is_typed.md),
[`typed_function()`](https://fabiandistler.github.io/typethis/reference/typed_function.md),
[`typed_method()`](https://fabiandistler.github.io/typethis/reference/typed_method.md),
[`validate_call()`](https://fabiandistler.github.io/typethis/reference/validate_call.md),
[`with_signature()`](https://fabiandistler.github.io/typethis/reference/with_signature.md)

## Examples

``` r
sig <- signature(x = "numeric", y = "numeric", .return = "numeric")
add <- with_signature(function(x, y) x + y, sig)
add(2, 3)
#> [1] 5
```
