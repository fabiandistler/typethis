# Union of type specifications

Matches if the value matches any of the given alternatives.

## Usage

``` r
t_union(...)
```

## Arguments

- ...:

  Type specifications — character builtin names, predicate functions, or
  other `type_spec` objects.

## Value

A `type_spec` of kind `"union"`.

## See also

Other type specifications: [`is_type_spec()`](is_type_spec.md),
[`t_enum()`](t_enum.md), [`t_list_of()`](t_list_of.md),
[`t_model()`](t_model.md), [`t_nullable()`](t_nullable.md),
[`t_predicate()`](t_predicate.md), [`t_vector_of()`](t_vector_of.md),
[`type_spec`](type_spec.md)

## Examples

``` r
id <- t_union("integer", "character")
is_type(1L, id)
#> [1] TRUE
is_type("u-42", id)
#> [1] TRUE
is_type(1.5, id)
#> [1] FALSE
```
