# Validate vector or list length

Returns a validator closure that accepts values whose
[`length()`](https://rdrr.io/r/base/length.html) matches the requested
constraint. Pass either `min_len` / `max_len`, or a single `exact_len`
(which overrides the bounds).

## Usage

``` r
vector_length(min_len = 0, max_len = Inf, exact_len = NULL)
```

## Arguments

- min_len:

  Minimum length (inclusive).

- max_len:

  Maximum length (inclusive, defaults to `Inf`).

- exact_len:

  If non-`NULL`, the value must have exactly this length.

## Value

A validator function `function(value) -> logical`.

## See also

Other validators: [`combine_validators()`](combine_validators.md),
[`dataframe_spec()`](dataframe_spec.md),
[`enum_validator()`](enum_validator.md), [`list_of()`](list_of.md),
[`nullable()`](nullable.md), [`numeric_range()`](numeric_range.md),
[`string_length()`](string_length.md),
[`string_pattern()`](string_pattern.md),
[`validator_constraint()`](validator_constraint.md)

## Examples

``` r
pair <- vector_length(exact_len = 2)
pair(c(1, 2))
#> [1] TRUE
pair(c(1, 2, 3))
#> [1] FALSE

nonempty <- vector_length(min_len = 1)
nonempty(integer())
#> [1] FALSE
nonempty(1:5)
#> [1] TRUE
```
