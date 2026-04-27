# Test whether an object is a typed model instance

Test whether an object is a typed model instance

## Usage

``` r
is_model(x)
```

## Arguments

- x:

  Object to test.

## Value

`TRUE` or `FALSE`.

## See also

Other typed models:
[`define_model()`](https://fabiandistler.github.io/typethis/reference/define_model.md),
[`field()`](https://fabiandistler.github.io/typethis/reference/field.md),
[`get_schema()`](https://fabiandistler.github.io/typethis/reference/get_schema.md),
[`model_to_list()`](https://fabiandistler.github.io/typethis/reference/model_to_list.md),
[`print.typed_model()`](https://fabiandistler.github.io/typethis/reference/print.typed_model.md),
[`update_model()`](https://fabiandistler.github.io/typethis/reference/update_model.md),
[`validate_model()`](https://fabiandistler.github.io/typethis/reference/validate_model.md)

## Examples

``` r
define_model("Tag", fields = list(name = field("character")))
is_model(new_Tag(name = "alpha"))
#> [1] TRUE
is_model(list(name = "alpha"))
#> [1] FALSE
```
