# Validate a numeric range

Returns a validator closure that accepts numeric values inside the
`[min, max]` interval. Endpoints can be excluded with `exclusive_min` or
`exclusive_max`.

## Usage

``` r
numeric_range(
  min = -Inf,
  max = Inf,
  exclusive_min = FALSE,
  exclusive_max = FALSE
)
```

## Arguments

- min:

  Lower bound (inclusive unless `exclusive_min = TRUE`).

- max:

  Upper bound (inclusive unless `exclusive_max = TRUE`).

- exclusive_min:

  If `TRUE`, the lower bound is excluded.

- exclusive_max:

  If `TRUE`, the upper bound is excluded.

## Value

A validator function `function(value) -> logical`.

## See also

Other validators:
[`combine_validators()`](https://fabiandistler.github.io/typethis/reference/combine_validators.md),
[`dataframe_spec()`](https://fabiandistler.github.io/typethis/reference/dataframe_spec.md),
[`enum_validator()`](https://fabiandistler.github.io/typethis/reference/enum_validator.md),
[`list_of()`](https://fabiandistler.github.io/typethis/reference/list_of.md),
[`nullable()`](https://fabiandistler.github.io/typethis/reference/nullable.md),
[`string_length()`](https://fabiandistler.github.io/typethis/reference/string_length.md),
[`string_pattern()`](https://fabiandistler.github.io/typethis/reference/string_pattern.md),
[`validator_constraint()`](https://fabiandistler.github.io/typethis/reference/validator_constraint.md),
[`vector_length()`](https://fabiandistler.github.io/typethis/reference/vector_length.md)

## Examples

``` r
age <- numeric_range(0, 120)
age(25)
#> [1] TRUE
age(150)
#> [1] FALSE

# Probability in (0, 1) — both endpoints excluded
p <- numeric_range(0, 1, exclusive_min = TRUE, exclusive_max = TRUE)
p(0.5)
#> [1] TRUE
p(0)
#> [1] FALSE
```
