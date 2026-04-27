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

Other validators: [`combine_validators()`](combine_validators.md),
[`dataframe_spec()`](dataframe_spec.md),
[`enum_validator()`](enum_validator.md), [`list_of()`](list_of.md),
[`nullable()`](nullable.md), [`numeric_range()`](numeric_range.md),
[`string_pattern()`](string_pattern.md),
[`validator_constraint()`](validator_constraint.md),
[`vector_length()`](vector_length.md)

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
