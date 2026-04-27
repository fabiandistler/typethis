# Retrieve a model's schema

Returns the named list of field definitions for a model instance or
constructor. `NULL` for objects that aren't models.

## Usage

``` r
get_schema(model)
```

## Arguments

- model:

  Model instance or constructor.

## Value

Named list of field definitions, or `NULL`.

## See also

Other typed models: [`define_model()`](define_model.md),
[`field()`](field.md), [`is_model()`](is_model.md),
[`model_to_list()`](model_to_list.md),
[`print.typed_model()`](print.typed_model.md),
[`update_model()`](update_model.md),
[`validate_model()`](validate_model.md)

## Examples

``` r
define_model("Person", fields = list(
  name = field("character"),
  age  = field("integer")
))
p <- new_Person(name = "Ada", age = 36L)
names(get_schema(p))
#> [1] "name" "age" 
```
