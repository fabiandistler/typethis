# List of elements of a given type

Matches a list whose every element matches `type`. Optional length
constraints follow the semantics of
[`vector_length()`](https://fabiandistler.github.io/typethis/reference/vector_length.md).

## Usage

``` r
t_list_of(type, min_length = 0, max_length = Inf, exact_length = NULL)
```

## Arguments

- type:

  Element type specification.

- min_length:

  Minimum number of elements.

- max_length:

  Maximum number of elements (defaults to `Inf`).

- exact_length:

  If non-`NULL`, the list must have exactly this length.

## Value

A `type_spec` of kind `"list_of"`.

## See also

Other type specifications:
[`is_type_spec()`](https://fabiandistler.github.io/typethis/reference/is_type_spec.md),
[`t_enum()`](https://fabiandistler.github.io/typethis/reference/t_enum.md),
[`t_model()`](https://fabiandistler.github.io/typethis/reference/t_model.md),
[`t_nullable()`](https://fabiandistler.github.io/typethis/reference/t_nullable.md),
[`t_predicate()`](https://fabiandistler.github.io/typethis/reference/t_predicate.md),
[`t_union()`](https://fabiandistler.github.io/typethis/reference/t_union.md),
[`t_vector_of()`](https://fabiandistler.github.io/typethis/reference/t_vector_of.md),
[`type_spec`](https://fabiandistler.github.io/typethis/reference/type_spec.md)

## Examples

``` r
tags <- t_list_of("character", min_length = 1L)
is_type(list("alpha", "beta"), tags)
#> [1] TRUE
is_type(list(), tags)
#> [1] FALSE

# Mixed-type list
mixed <- t_list_of(t_union("integer", "character"))
is_type(list(1L, "two", 3L), mixed)
#> [1] TRUE
```
