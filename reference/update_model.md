# Update fields on a typed model instance

Generic alternative to the class-specific `update_<ClassName>()`
produced by
[`define_model()`](https://fabiandistler.github.io/typethis/reference/define_model.md).
Returns a new instance with the named fields replaced and (by default)
revalidated.

## Usage

``` r
update_model(model, ..., .validate = TRUE)
```

## Arguments

- model:

  A model instance.

- ...:

  Fields to update, as `name = value`.

- .validate:

  If `FALSE`, skip revalidation.

## Value

Updated model instance.

## See also

The class-specific `update_<ClassName>()` constructor created by
[`define_model()`](https://fabiandistler.github.io/typethis/reference/define_model.md)
preserves the S3 class chain and is preferred when available.

Other typed models:
[`define_model()`](https://fabiandistler.github.io/typethis/reference/define_model.md),
[`field()`](https://fabiandistler.github.io/typethis/reference/field.md),
[`get_schema()`](https://fabiandistler.github.io/typethis/reference/get_schema.md),
[`is_model()`](https://fabiandistler.github.io/typethis/reference/is_model.md),
[`model_to_list()`](https://fabiandistler.github.io/typethis/reference/model_to_list.md),
[`print.typed_model()`](https://fabiandistler.github.io/typethis/reference/print.typed_model.md),
[`validate_model()`](https://fabiandistler.github.io/typethis/reference/validate_model.md)

## Examples

``` r
define_model("Person", fields = list(
  name = field("character"),
  age  = field("integer")
))
p <- new_Person(name = "Ada", age = 36L)
update_model(p, age = 37L)$age
#> [1] 37
```
