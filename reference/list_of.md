# Validate a list whose elements share a type

Returns a validator closure that accepts a list whose every element
matches `element_type` and whose length is within
`[min_length, max_length]`. For an equivalent that doubles as a type
specification, see [`t_list_of()`](t_list_of.md).

## Usage

``` r
list_of(element_type, min_length = 0, max_length = Inf)
```

## Arguments

- element_type:

  Type of list elements (character builtin name, predicate function, or
  `type_spec`).

- min_length:

  Minimum number of elements.

- max_length:

  Maximum number of elements (defaults to `Inf`).

## Value

A validator function `function(value) -> logical`.

## See also

[`t_list_of()`](t_list_of.md) for the composable type-spec form.

Other validators: [`combine_validators()`](combine_validators.md),
[`dataframe_spec()`](dataframe_spec.md),
[`enum_validator()`](enum_validator.md), [`nullable()`](nullable.md),
[`numeric_range()`](numeric_range.md),
[`string_length()`](string_length.md),
[`string_pattern()`](string_pattern.md),
[`validator_constraint()`](validator_constraint.md),
[`vector_length()`](vector_length.md)

## Examples

``` r
nums <- list_of("numeric", min_length = 1)
nums(list(1, 2, 3))
#> [1] TRUE
nums(list("a", "b"))
#> [1] FALSE
nums(list())
#> [1] FALSE
```
