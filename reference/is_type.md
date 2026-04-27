# Test whether a value matches a type

Returns `TRUE` if `value` matches `type`, `FALSE` otherwise. `type` may
be a builtin name (`"numeric"`, `"character"`, ...), a registered model
class, a predicate function, or a
[type_spec](https://fabiandistler.github.io/typethis/reference/type_spec.md)
built with the `t_*()` constructors.

## Usage

``` r
is_type(value, type, nullable = FALSE)
```

## Arguments

- value:

  Value to test.

- type:

  Expected type — character, function, or `type_spec`.

- nullable:

  If `TRUE`, `NULL` matches as well.

## Value

`TRUE` or `FALSE`.

## See also

Other type checking:
[`assert_type()`](https://fabiandistler.github.io/typethis/reference/assert_type.md),
[`coerce_type()`](https://fabiandistler.github.io/typethis/reference/coerce_type.md),
[`is_one_of()`](https://fabiandistler.github.io/typethis/reference/is_one_of.md),
[`validate_type()`](https://fabiandistler.github.io/typethis/reference/validate_type.md)

## Examples

``` r
is_type(5, "numeric")
#> [1] TRUE
is_type("hello", "character")
#> [1] TRUE
is_type(NULL, "numeric")
#> [1] FALSE
is_type(NULL, "numeric", nullable = TRUE)
#> [1] TRUE
is_type(1L, t_union("integer", "character"))
#> [1] TRUE
```
