# Enumerated set of allowed values

Matches when every element of the value is in the allowed set.

## Usage

``` r
t_enum(values)
```

## Arguments

- values:

  Atomic vector of allowed values.

## Value

A `type_spec` of kind `"enum"`.

## See also

[`enum_validator()`](enum_validator.md) for a validator-only form.

Other type specifications: [`is_type_spec()`](is_type_spec.md),
[`t_list_of()`](t_list_of.md), [`t_model()`](t_model.md),
[`t_nullable()`](t_nullable.md), [`t_predicate()`](t_predicate.md),
[`t_union()`](t_union.md), [`t_vector_of()`](t_vector_of.md),
[`type_spec`](type_spec.md)

## Examples

``` r
role <- t_enum(c("admin", "user", "guest"))
is_type("admin", role)
#> [1] TRUE
is_type("root", role)
#> [1] FALSE
```
