# Define a typed data model

Defines a model class — a record type with named fields, types, optional
validators, defaults, and nullability — and creates two helpers in the
calling environment:

- `new_<ClassName>()` — constructor. Validates each argument against the
  field spec and applies defaults.

- `update_<ClassName>(instance, …)` — returns a copy with the named
  fields replaced and revalidated.

Define each field with
[`field()`](https://fabiandistler.github.io/typethis/reference/field.md);
pass them as a named list to `fields`. Fields can use any type accepted
elsewhere in `typethis` (builtin character names, predicate functions,
registered model class names, or composite
[type_spec](https://fabiandistler.github.io/typethis/reference/type_spec.md)
objects).

## Usage

``` r
define_model(..., fields = NULL, .validate = TRUE, .strict = FALSE)
```

## Arguments

- ...:

  The class name as the first positional argument (a single character
  scalar). Field definitions can also be passed here as
  `name = field(...)` arguments instead of via `fields`.

- fields:

  Named list of field definitions built with
  [`field()`](https://fabiandistler.github.io/typethis/reference/field.md)
  (or bare type names).

- .validate:

  If `FALSE`, validation is skipped on construction (useful for hot
  paths).

- .strict:

  If `TRUE`, the constructor rejects unknown fields.

## Value

Invisibly `NULL`. The constructor and updater are assigned in the
calling environment.

## See also

[`field()`](https://fabiandistler.github.io/typethis/reference/field.md)
for declaring a field;
[`validate_model()`](https://fabiandistler.github.io/typethis/reference/validate_model.md)
/
[`model_to_list()`](https://fabiandistler.github.io/typethis/reference/model_to_list.md)
/
[`update_model()`](https://fabiandistler.github.io/typethis/reference/update_model.md)
/
[`get_schema()`](https://fabiandistler.github.io/typethis/reference/get_schema.md)
for working with instances;
[`t_model()`](https://fabiandistler.github.io/typethis/reference/t_model.md)
for referencing a model from another field.

Other typed models:
[`field()`](https://fabiandistler.github.io/typethis/reference/field.md),
[`get_schema()`](https://fabiandistler.github.io/typethis/reference/get_schema.md),
[`is_model()`](https://fabiandistler.github.io/typethis/reference/is_model.md),
[`model_to_list()`](https://fabiandistler.github.io/typethis/reference/model_to_list.md),
[`print.typed_model()`](https://fabiandistler.github.io/typethis/reference/print.typed_model.md),
[`update_model()`](https://fabiandistler.github.io/typethis/reference/update_model.md),
[`validate_model()`](https://fabiandistler.github.io/typethis/reference/validate_model.md)

## Examples

``` r
define_model("User", fields = list(
  name  = field("character"),
  age   = field("integer", validator = numeric_range(0, 120),
                default = 0L),
  email = field("character",
                validator = string_pattern("^[^@]+@[^@]+$"))
))

u <- new_User(name = "Ada", email = "ada@example.com")
u$age   # default applied
#> [1] 0

u2 <- update_User(u, age = 36L)
u2$age
#> [1] 36

# Strict mode rejects unknown fields
define_model("StrictPoint", fields = list(
  x = field("numeric"),
  y = field("numeric")
), .strict = TRUE)

tryCatch(
  new_StrictPoint(x = 1, y = 2, z = 3),
  error = function(e) conditionMessage(e)
)
#> [1] "Extra fields not allowed for StrictPoint: z"
```
