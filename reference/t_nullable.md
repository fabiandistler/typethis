# Allow `NULL` in addition to an inner type

Allow `NULL` in addition to an inner type

## Usage

``` r
t_nullable(type)
```

## Arguments

- type:

  Inner type specification.

## Value

A `type_spec` of kind `"nullable"`.

## See also

Other type specifications: [`is_type_spec()`](is_type_spec.md),
[`t_enum()`](t_enum.md), [`t_list_of()`](t_list_of.md),
[`t_model()`](t_model.md), [`t_predicate()`](t_predicate.md),
[`t_union()`](t_union.md), [`t_vector_of()`](t_vector_of.md),
[`type_spec`](type_spec.md)

## Examples

``` r
maybe_int <- t_nullable("integer")
is_type(NULL, maybe_int)
#> [1] TRUE
is_type(1L, maybe_int)
#> [1] TRUE
is_type("hi", maybe_int)
#> [1] FALSE
```
