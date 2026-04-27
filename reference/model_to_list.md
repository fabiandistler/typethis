# Convert a typed model instance to a plain list

Convert a typed model instance to a plain list

## Usage

``` r
model_to_list(model)
```

## Arguments

- model:

  A model instance.

## Value

A plain list with the model's field values.

## See also

Other typed models:
[`define_model()`](https://fabiandistler.github.io/typethis/reference/define_model.md),
[`field()`](https://fabiandistler.github.io/typethis/reference/field.md),
[`get_schema()`](https://fabiandistler.github.io/typethis/reference/get_schema.md),
[`is_model()`](https://fabiandistler.github.io/typethis/reference/is_model.md),
[`print.typed_model()`](https://fabiandistler.github.io/typethis/reference/print.typed_model.md),
[`update_model()`](https://fabiandistler.github.io/typethis/reference/update_model.md),
[`validate_model()`](https://fabiandistler.github.io/typethis/reference/validate_model.md)

## Examples

``` r
define_model("Point", fields = list(
  x = field("numeric"),
  y = field("numeric")
))
p <- new_Point(x = 1, y = 2)
model_to_list(p)
#> <Typed Model: Point>
#> Fields:
#>   x: numeric = 1
#>   y: numeric = 2
```
