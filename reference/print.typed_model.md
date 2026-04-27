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

Other typed models: [`define_model()`](define_model.md),
[`field()`](field.md), [`get_schema()`](get_schema.md),
[`is_model()`](is_model.md), [`model_to_list()`](model_to_list.md),
[`update_model()`](update_model.md),
[`validate_model()`](validate_model.md)

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
