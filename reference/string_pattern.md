# Validate strings against a regular expression

Returns a validator closure that accepts character values where every
element matches `pattern` (a POSIX extended regex). Set `ignore_case`
for case-insensitive matching.

## Usage

``` r
string_pattern(pattern, ignore_case = FALSE)
```

## Arguments

- pattern:

  Regular expression pattern.

- ignore_case:

  If `TRUE`, matching is case-insensitive.

## Value

A validator function `function(value) -> logical`.

## See also

Other validators: [`combine_validators()`](combine_validators.md),
[`dataframe_spec()`](dataframe_spec.md),
[`enum_validator()`](enum_validator.md), [`list_of()`](list_of.md),
[`nullable()`](nullable.md), [`numeric_range()`](numeric_range.md),
[`string_length()`](string_length.md),
[`validator_constraint()`](validator_constraint.md),
[`vector_length()`](vector_length.md)

## Examples

``` r
email <- string_pattern("^[^@]+@[^@]+\\.[^@]+$")
email("user@example.com")
#> [1] TRUE
email("not-an-email")
#> [1] FALSE

phone <- string_pattern("^[0-9 +()-]+$")
phone("+49 (0)30 1234 5678")
#> [1] TRUE
```
