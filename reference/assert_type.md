# Assert that a value has an expected type

Throws an informative error if `value` does not match `type`. Use this
at function boundaries to fail fast with a useful message.

## Usage

``` r
assert_type(value, type, name = "value", nullable = FALSE)
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

`invisible(TRUE)` on success; an error otherwise.

## See also

[`is_type()`](https://fabiandistler.github.io/typethis/reference/is_type.md)
for a non-throwing check;
[`validate_type()`](https://fabiandistler.github.io/typethis/reference/validate_type.md)
to get the message back as data.

Other type checking:
[`coerce_type()`](https://fabiandistler.github.io/typethis/reference/coerce_type.md),
[`is_one_of()`](https://fabiandistler.github.io/typethis/reference/is_one_of.md),
[`is_type()`](https://fabiandistler.github.io/typethis/reference/is_type.md),
[`validate_type()`](https://fabiandistler.github.io/typethis/reference/validate_type.md)

## Examples

``` r
assert_type(5, "numeric", "x")

err <- tryCatch(
  assert_type("hello", "numeric", "x"),
  error = function(e) conditionMessage(e)
)
err
#> [1] "Type error: 'x' must be numeric, got character"
```
