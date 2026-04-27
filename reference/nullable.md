# Make a validator accept `NULL`

Wraps `validator` so that `NULL` is also accepted. Useful for optional
fields. For a composable type-spec equivalent, see
[`t_nullable()`](t_nullable.md).

## Usage

``` r
nullable(validator)
```

## Arguments

- validator:

  Underlying validator function.

## Value

A validator function `function(value) -> logical`.

## See also

[`t_nullable()`](t_nullable.md) for the composable type-spec form.

Other validators: [`combine_validators()`](combine_validators.md),
[`dataframe_spec()`](dataframe_spec.md),
[`enum_validator()`](enum_validator.md), [`list_of()`](list_of.md),
[`numeric_range()`](numeric_range.md),
[`string_length()`](string_length.md),
[`string_pattern()`](string_pattern.md),
[`validator_constraint()`](validator_constraint.md),
[`vector_length()`](vector_length.md)

## Examples

``` r
optional_num <- nullable(function(x) is.numeric(x))
optional_num(5)
#> [1] TRUE
optional_num(NULL)
#> [1] TRUE
optional_num("hi")
#> [1] FALSE
```
