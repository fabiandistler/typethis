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

Other type specifications:
[`is_type_spec()`](https://fabiandistler.github.io/typethis/reference/is_type_spec.md),
[`t_enum()`](https://fabiandistler.github.io/typethis/reference/t_enum.md),
[`t_list_of()`](https://fabiandistler.github.io/typethis/reference/t_list_of.md),
[`t_model()`](https://fabiandistler.github.io/typethis/reference/t_model.md),
[`t_predicate()`](https://fabiandistler.github.io/typethis/reference/t_predicate.md),
[`t_union()`](https://fabiandistler.github.io/typethis/reference/t_union.md),
[`t_vector_of()`](https://fabiandistler.github.io/typethis/reference/t_vector_of.md),
[`type_spec`](https://fabiandistler.github.io/typethis/reference/type_spec.md)

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
