# Test whether an object is a type spec

Returns `TRUE` if `x` was created by one of the `t_*()` constructors.

## Usage

``` r
is_type_spec(x)
```

## Arguments

- x:

  Object to test.

## Value

`TRUE` or `FALSE`.

## See also

Other type specifications: [`t_enum()`](t_enum.md),
[`t_list_of()`](t_list_of.md), [`t_model()`](t_model.md),
[`t_nullable()`](t_nullable.md), [`t_predicate()`](t_predicate.md),
[`t_union()`](t_union.md), [`t_vector_of()`](t_vector_of.md),
[`type_spec`](type_spec.md)

## Examples

``` r
is_type_spec(t_union("numeric", "character"))
#> [1] TRUE
is_type_spec("numeric")
#> [1] FALSE
```
