# Combine multiple validators

Returns a single validator that delegates to each of `...`. With
`all_of = TRUE` (the default) every validator must pass; with
`all_of = FALSE` any one of them is enough.

## Usage

``` r
combine_validators(..., all_of = TRUE)
```

## Arguments

- ...:

  Validator functions.

- all_of:

  If `TRUE`, all must pass; if `FALSE`, any one suffices.

## Value

A validator function `function(value) -> logical`.

## See also

Other validators:
[`dataframe_spec()`](https://fabiandistler.github.io/typethis/reference/dataframe_spec.md),
[`enum_validator()`](https://fabiandistler.github.io/typethis/reference/enum_validator.md),
[`list_of()`](https://fabiandistler.github.io/typethis/reference/list_of.md),
[`nullable()`](https://fabiandistler.github.io/typethis/reference/nullable.md),
[`numeric_range()`](https://fabiandistler.github.io/typethis/reference/numeric_range.md),
[`string_length()`](https://fabiandistler.github.io/typethis/reference/string_length.md),
[`string_pattern()`](https://fabiandistler.github.io/typethis/reference/string_pattern.md),
[`validator_constraint()`](https://fabiandistler.github.io/typethis/reference/validator_constraint.md),
[`vector_length()`](https://fabiandistler.github.io/typethis/reference/vector_length.md)

## Examples

``` r
positive_num <- combine_validators(
  function(x) is.numeric(x),
  function(x) all(x > 0)
)
positive_num(5)
#> [1] TRUE
positive_num(-5)
#> [1] FALSE

num_or_str <- combine_validators(
  function(x) is.numeric(x),
  function(x) is.character(x),
  all_of = FALSE
)
num_or_str(5)
#> [1] TRUE
num_or_str("hi")
#> [1] TRUE
num_or_str(TRUE)
#> [1] FALSE
```
