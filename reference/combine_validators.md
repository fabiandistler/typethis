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

Other validators: [`dataframe_spec()`](dataframe_spec.md),
[`enum_validator()`](enum_validator.md), [`list_of()`](list_of.md),
[`nullable()`](nullable.md), [`numeric_range()`](numeric_range.md),
[`string_length()`](string_length.md),
[`string_pattern()`](string_pattern.md),
[`validator_constraint()`](validator_constraint.md),
[`vector_length()`](vector_length.md)

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
