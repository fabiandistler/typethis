# Wrap a predicate function as a type spec

Equivalent to passing a bare predicate function as a type, but lets you
attach a description that surfaces in error messages and JSON Schema
output.

## Usage

``` r
t_predicate(fn, description = NULL)
```

## Arguments

- fn:

  Predicate function — `function(value) -> logical`.

- description:

  Optional description string (used in error messages).

## Value

A `type_spec` of kind `"predicate"`.

## See also

Other type specifications: [`is_type_spec()`](is_type_spec.md),
[`t_enum()`](t_enum.md), [`t_list_of()`](t_list_of.md),
[`t_model()`](t_model.md), [`t_nullable()`](t_nullable.md),
[`t_union()`](t_union.md), [`t_vector_of()`](t_vector_of.md),
[`type_spec`](type_spec.md)

## Examples

``` r
positive <- t_predicate(
  function(x) is.numeric(x) && all(x > 0),
  description = "positive number"
)
is_type(5, positive)
#> [1] TRUE
is_type(-1, positive)
#> [1] FALSE
```
