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

Other type specifications:
[`is_type_spec()`](https://fabiandistler.github.io/typethis/reference/is_type_spec.md),
[`t_enum()`](https://fabiandistler.github.io/typethis/reference/t_enum.md),
[`t_list_of()`](https://fabiandistler.github.io/typethis/reference/t_list_of.md),
[`t_model()`](https://fabiandistler.github.io/typethis/reference/t_model.md),
[`t_nullable()`](https://fabiandistler.github.io/typethis/reference/t_nullable.md),
[`t_predicate()`](https://fabiandistler.github.io/typethis/reference/t_predicate.md),
[`t_vector_of()`](https://fabiandistler.github.io/typethis/reference/t_vector_of.md),
[`type_spec`](https://fabiandistler.github.io/typethis/reference/type_spec.md)

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
