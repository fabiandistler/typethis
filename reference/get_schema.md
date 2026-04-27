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

Other typed models:
[`define_model()`](https://fabiandistler.github.io/typethis/reference/define_model.md),
[`field()`](https://fabiandistler.github.io/typethis/reference/field.md),
[`is_model()`](https://fabiandistler.github.io/typethis/reference/is_model.md),
[`model_to_list()`](https://fabiandistler.github.io/typethis/reference/model_to_list.md),
[`print.typed_model()`](https://fabiandistler.github.io/typethis/reference/print.typed_model.md),
[`update_model()`](https://fabiandistler.github.io/typethis/reference/update_model.md),
[`validate_model()`](https://fabiandistler.github.io/typethis/reference/validate_model.md)

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
