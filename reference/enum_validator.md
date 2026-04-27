# Validate a value against a fixed set of allowed values

Returns a validator closure that accepts values where every element is
in `allowed_values`. For an equivalent that doubles as a type
specification (usable with
[`field()`](https://fabiandistler.github.io/typethis/reference/field.md)
and
[`typed_function()`](https://fabiandistler.github.io/typethis/reference/typed_function.md))
see
[`t_enum()`](https://fabiandistler.github.io/typethis/reference/t_enum.md).

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

[`t_enum()`](https://fabiandistler.github.io/typethis/reference/t_enum.md)
for the composable type-spec form.

Other validators:
[`combine_validators()`](https://fabiandistler.github.io/typethis/reference/combine_validators.md),
[`dataframe_spec()`](https://fabiandistler.github.io/typethis/reference/dataframe_spec.md),
[`list_of()`](https://fabiandistler.github.io/typethis/reference/list_of.md),
[`nullable()`](https://fabiandistler.github.io/typethis/reference/nullable.md),
[`numeric_range()`](https://fabiandistler.github.io/typethis/reference/numeric_range.md),
[`string_length()`](https://fabiandistler.github.io/typethis/reference/string_length.md),
[`string_pattern()`](https://fabiandistler.github.io/typethis/reference/string_pattern.md),
[`validator_constraint()`](https://fabiandistler.github.io/typethis/reference/validator_constraint.md),
[`vector_length()`](https://fabiandistler.github.io/typethis/reference/vector_length.md)

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
