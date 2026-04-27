# Make a validator accept `NULL`

Wraps `validator` so that `NULL` is also accepted. Useful for optional
fields. For a composable type-spec equivalent, see
[`t_nullable()`](https://fabiandistler.github.io/typethis/reference/t_nullable.md).

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

[`t_nullable()`](https://fabiandistler.github.io/typethis/reference/t_nullable.md)
for the composable type-spec form.

Other validators:
[`combine_validators()`](https://fabiandistler.github.io/typethis/reference/combine_validators.md),
[`dataframe_spec()`](https://fabiandistler.github.io/typethis/reference/dataframe_spec.md),
[`enum_validator()`](https://fabiandistler.github.io/typethis/reference/enum_validator.md),
[`list_of()`](https://fabiandistler.github.io/typethis/reference/list_of.md),
[`numeric_range()`](https://fabiandistler.github.io/typethis/reference/numeric_range.md),
[`string_length()`](https://fabiandistler.github.io/typethis/reference/string_length.md),
[`string_pattern()`](https://fabiandistler.github.io/typethis/reference/string_pattern.md),
[`validator_constraint()`](https://fabiandistler.github.io/typethis/reference/validator_constraint.md),
[`vector_length()`](https://fabiandistler.github.io/typethis/reference/vector_length.md)

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
