# Print method for typed model instances

Print method for typed model instances

## Usage

``` r
# S3 method for class 'typed_model'
print(x, ...)
```

## Arguments

- x:

  Model instance.

- ...:

  Unused.

## Value

Invisibly `x`.

## See also

Other typed models:
[`define_model()`](https://fabiandistler.github.io/typethis/reference/define_model.md),
[`field()`](https://fabiandistler.github.io/typethis/reference/field.md),
[`get_schema()`](https://fabiandistler.github.io/typethis/reference/get_schema.md),
[`is_model()`](https://fabiandistler.github.io/typethis/reference/is_model.md),
[`model_to_list()`](https://fabiandistler.github.io/typethis/reference/model_to_list.md),
[`update_model()`](https://fabiandistler.github.io/typethis/reference/update_model.md),
[`validate_model()`](https://fabiandistler.github.io/typethis/reference/validate_model.md)

## Examples

``` r
define_model("Point", fields = list(
  x = field("numeric"),
  y = field("numeric")
))
new_Point(x = 1, y = 2)
#> <Typed Model: Point>
#> Fields:
#>   x: numeric = 1
#>   y: numeric = 2
```
