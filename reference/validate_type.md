# Validate a value's type and return a structured result

Like
[`assert_type()`](https://fabiandistler.github.io/typethis/reference/assert_type.md)
but returns a list `list(valid, error)` instead of throwing. Use it when
you want to collect or inspect errors rather than stop execution.

## Usage

``` r
validate_type(value, type, name = "value", nullable = FALSE)
```

## Arguments

- value:

  Value to test.

- type:

  Expected type — character, function, or `type_spec`.

- name:

  Variable name used in the error message.

- nullable:

  If `TRUE`, `NULL` is accepted.

## Value

Named list with `valid` (logical) and `error` (character or `NULL`).

## See also

Other type checking:
[`assert_type()`](https://fabiandistler.github.io/typethis/reference/assert_type.md),
[`coerce_type()`](https://fabiandistler.github.io/typethis/reference/coerce_type.md),
[`is_one_of()`](https://fabiandistler.github.io/typethis/reference/is_one_of.md),
[`is_type()`](https://fabiandistler.github.io/typethis/reference/is_type.md)

## Examples

``` r
validate_type(5, "numeric", "x")
#> $valid
#> [1] TRUE
#> 
#> $error
#> NULL
#> 
validate_type("hello", "numeric", "x")
#> $valid
#> [1] FALSE
#> 
#> $error
#> [1] "Type error: 'x' must be numeric, got character"
#> 
```
