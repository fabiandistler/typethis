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

Other typed models: [`define_model()`](define_model.md),
[`field()`](field.md), [`get_schema()`](get_schema.md),
[`model_to_list()`](model_to_list.md),
[`print.typed_model()`](print.typed_model.md),
[`update_model()`](update_model.md),
[`validate_model()`](validate_model.md)

## Examples

``` r
define_model("Tag", fields = list(name = field("character")))
is_model(new_Tag(name = "alpha"))
#> [1] TRUE
is_model(list(name = "alpha"))
#> [1] FALSE
```
