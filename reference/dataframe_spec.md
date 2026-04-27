# Validate a data frame's structure

Returns a validator closure that accepts data frames containing every
column listed in `required_cols` and whose row count is within
`[min_rows, max_rows]`.

## Usage

``` r
dataframe_spec(required_cols = NULL, min_rows = 0, max_rows = Inf)
```

## Arguments

- required_cols:

  Character vector of required column names.

- min_rows:

  Minimum number of rows.

- max_rows:

  Maximum number of rows (defaults to `Inf`).

## Value

A validator function `function(value) -> logical`.

## See also

Other validators: [`combine_validators()`](combine_validators.md),
[`enum_validator()`](enum_validator.md), [`list_of()`](list_of.md),
[`nullable()`](nullable.md), [`numeric_range()`](numeric_range.md),
[`string_length()`](string_length.md),
[`string_pattern()`](string_pattern.md),
[`validator_constraint()`](validator_constraint.md),
[`vector_length()`](vector_length.md)

## Examples

``` r
is_orders <- dataframe_spec(
  required_cols = c("id", "amount"),
  min_rows = 1
)
is_orders(data.frame(id = 1:3, amount = c(10, 20, 30)))
#> [1] TRUE
is_orders(data.frame(id = integer()))
#> [1] FALSE
is_orders(data.frame(name = "Ada"))
#> [1] FALSE
```
