# Validate a value against a fixed set of allowed values

Returns a validator closure that accepts values where every element is
in `allowed_values`. For an equivalent that doubles as a type
specification (usable with [`field()`](field.md) and
[`typed_function()`](typed_function.md)) see [`t_enum()`](t_enum.md).

## Usage

``` r
enum_validator(allowed_values)
```

## Arguments

- allowed_values:

  Atomic vector of allowed values.

## Value

A validator function `function(value) -> logical`.

## See also

[`t_enum()`](t_enum.md) for the composable type-spec form.

Other validators: [`combine_validators()`](combine_validators.md),
[`dataframe_spec()`](dataframe_spec.md), [`list_of()`](list_of.md),
[`nullable()`](nullable.md), [`numeric_range()`](numeric_range.md),
[`string_length()`](string_length.md),
[`string_pattern()`](string_pattern.md),
[`validator_constraint()`](validator_constraint.md),
[`vector_length()`](vector_length.md)

## Examples

``` r
status <- enum_validator(c("active", "inactive", "pending"))
status("active")
#> [1] TRUE
status("deleted")
#> [1] FALSE
status(c("active", "pending"))
#> [1] TRUE
```
