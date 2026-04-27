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

Other typed models: [`define_model()`](define_model.md),
[`field()`](field.md), [`get_schema()`](get_schema.md),
[`is_model()`](is_model.md),
[`print.typed_model()`](print.typed_model.md),
[`update_model()`](update_model.md),
[`validate_model()`](validate_model.md)

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
