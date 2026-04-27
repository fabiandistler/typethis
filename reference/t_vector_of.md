# Atomic vector of a given builtin type

Like
[`t_list_of()`](https://fabiandistler.github.io/typethis/reference/t_list_of.md)
but for atomic vectors. The element type must be a builtin scalar type
name (`"numeric"`, `"integer"`, `"character"`, ...).

## Usage

``` r
t_vector_of(type, min_length = 0, max_length = Inf, exact_length = NULL)
```

## Arguments

- type:

  Builtin element type name.

- min_length:

  Minimum length.

- max_length:

  Maximum length (defaults to `Inf`).

- exact_length:

  If non-`NULL`, vector must have exactly this length.

## Value

A `type_spec` of kind `"vector_of"`.

## See also

Other type specifications:
[`is_type_spec()`](https://fabiandistler.github.io/typethis/reference/is_type_spec.md),
[`t_enum()`](https://fabiandistler.github.io/typethis/reference/t_enum.md),
[`t_list_of()`](https://fabiandistler.github.io/typethis/reference/t_list_of.md),
[`t_model()`](https://fabiandistler.github.io/typethis/reference/t_model.md),
[`t_nullable()`](https://fabiandistler.github.io/typethis/reference/t_nullable.md),
[`t_predicate()`](https://fabiandistler.github.io/typethis/reference/t_predicate.md),
[`t_union()`](https://fabiandistler.github.io/typethis/reference/t_union.md),
[`type_spec`](https://fabiandistler.github.io/typethis/reference/type_spec.md)

## Examples

``` r
triple <- t_vector_of("integer", exact_length = 3L)
is_type(1:3, triple)
#> [1] TRUE
is_type(1:5, triple)
#> [1] FALSE
```
