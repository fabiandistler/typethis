# Test whether a value matches any of several types

Convenience wrapper around [`is_type()`](is_type.md) for checking
against a vector of alternatives. For a structured spec that you can
also use with [`typed_function()`](typed_function.md) and
[`field()`](field.md), see [`t_union()`](t_union.md).

## Usage

``` r
is_one_of(value, types)
```

## Arguments

- value:

  Value to test.

- types:

  Character vector of types (or list of type specs).

## Value

`TRUE` if `value` matches at least one entry in `types`.

## See also

[`t_union()`](t_union.md) for a composable equivalent that works as a
type specification.

Other type checking: [`assert_type()`](assert_type.md),
[`coerce_type()`](coerce_type.md), [`is_type()`](is_type.md),
[`validate_type()`](validate_type.md)

## Examples

``` r
is_one_of(5, c("numeric", "character"))
#> [1] TRUE
is_one_of("hello", c("numeric", "character"))
#> [1] TRUE
is_one_of(TRUE, c("numeric", "character"))
#> [1] FALSE
```
