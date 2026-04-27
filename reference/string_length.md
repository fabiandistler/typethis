# Validate string length

Returns a validator closure that accepts character values whose every
element has length between `min_length` and `max_length` (inclusive).

## Usage

``` r
string_length(min_length = 0, max_length = Inf)
```

## Arguments

- min_length:

  Minimum number of characters.

- max_length:

  Maximum number of characters (defaults to `Inf`).

## Value

A validator function `function(value) -> logical`.

## See also

Other validators:
[`combine_validators()`](https://fabiandistler.github.io/typethis/reference/combine_validators.md),
[`dataframe_spec()`](https://fabiandistler.github.io/typethis/reference/dataframe_spec.md),
[`enum_validator()`](https://fabiandistler.github.io/typethis/reference/enum_validator.md),
[`list_of()`](https://fabiandistler.github.io/typethis/reference/list_of.md),
[`nullable()`](https://fabiandistler.github.io/typethis/reference/nullable.md),
[`numeric_range()`](https://fabiandistler.github.io/typethis/reference/numeric_range.md),
[`string_pattern()`](https://fabiandistler.github.io/typethis/reference/string_pattern.md),
[`validator_constraint()`](https://fabiandistler.github.io/typethis/reference/validator_constraint.md),
[`vector_length()`](https://fabiandistler.github.io/typethis/reference/vector_length.md)

## Examples

``` r
name <- string_length(min_length = 1, max_length = 50)
name("Ada Lovelace")
#> [1] TRUE
name("")
#> [1] FALSE
name(c("ok", "also ok"))
#> [1] TRUE
```
