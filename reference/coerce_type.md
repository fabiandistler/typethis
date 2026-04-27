# Coerce a value to a target type

Attempts to convert `value` to `type` using the standard `as.*()`
coercions. With `strict = TRUE`, coercion that introduces `NA` (e.g.
`as.numeric("abc")`) raises an error instead of returning silently.

## Usage

``` r
coerce_type(value, type, strict = FALSE)
```

## Arguments

- value:

  Value to coerce.

- type:

  Target type — character builtin, or a supported `type_spec`.

- strict:

  If `TRUE`, fail when coercion introduces `NA`.

## Value

The coerced value.

## Details

Composite type specs are supported for the kinds where coercion has a
clear meaning: [`t_nullable()`](t_nullable.md) (NULL passes through,
otherwise the inner spec drives coercion), [`t_union()`](t_union.md)
(each alternative is tried in order), and [`t_enum()`](t_enum.md)
(values already in the allowed set pass through; otherwise the value is
coerced to the enum's value type and re-checked).

## See also

Other type checking: [`assert_type()`](assert_type.md),
[`is_one_of()`](is_one_of.md), [`is_type()`](is_type.md),
[`validate_type()`](validate_type.md)

## Examples

``` r
coerce_type("123", "numeric")
#> [1] 123
coerce_type(c(1, 2, 3), "character")
#> [1] "1" "2" "3"
coerce_type("yes", "logical")
#> [1] NA

err <- tryCatch(
  coerce_type("abc", "numeric", strict = TRUE),
  error = function(e) conditionMessage(e)
)
#> Warning: NAs introduced by coercion
err
#> [1] "Failed to coerce to numeric: Coercion to numeric resulted in NA values"
```
