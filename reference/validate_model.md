# Validate a model instance against its schema

Runs every field through type and validator checks and returns a list
`list(valid, errors)` rather than throwing.

## Usage

``` r
validate_model(instance)
```

## Arguments

- instance:

  A model instance.

## Value

Named list `list(valid, errors)`. `errors` is `NULL` on success.

## See also

Other typed models: [`define_model()`](define_model.md),
[`field()`](field.md), [`get_schema()`](get_schema.md),
[`is_model()`](is_model.md), [`model_to_list()`](model_to_list.md),
[`print.typed_model()`](print.typed_model.md),
[`update_model()`](update_model.md)

## Examples

``` r
define_model("Person", fields = list(
  name = field("character"),
  age  = field("integer", validator = numeric_range(0, 120))
))
p <- new_Person(name = "Ada", age = 36L)
validate_model(p)
#> $valid
#> [1] TRUE
#> 
#> $errors
#> NULL
#> 
```
