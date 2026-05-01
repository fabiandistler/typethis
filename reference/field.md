# Define a model field

Builds a field definition for use inside
[`define_model()`](define_model.md). A field carries a type, optional
default, optional validator, and optional nullability — plus a number of
metadata slots (`primary_key`, `pii`, `tags`, ...) that travel through
the [`to_datacontract()`](to_datacontract.md) /
[`to_openapi()`](to_openapi.md) /
[`to_json_schema()`](to_json_schema.md) bridges but have no effect on
runtime validation.

## Usage

``` r
field(
  type,
  default = NULL,
  validator = NULL,
  nullable = FALSE,
  description = "",
  primary_key = FALSE,
  unique = FALSE,
  pii = FALSE,
  classification = NULL,
  tags = NULL,
  examples = NULL,
  references = NULL,
  quality = NULL
)
```

## Arguments

- type:

  Type specification.

- default:

  Default value when the field is omitted at construction.

- validator:

  Optional value-level validator function.

- nullable:

  If `TRUE`, the field accepts `NULL`.

- description:

  Free-text description; surfaces in JSON Schema and ODCS export.

- primary_key:

  Logical. ODCS metadata only.

- unique:

  Logical. ODCS metadata only.

- pii:

  Logical. ODCS metadata only.

- classification:

  Optional classification label (`"public"`, `"internal"`,
  `"confidential"`, ...). ODCS metadata only.

- tags:

  Optional character vector of free-form tags.

- examples:

  Optional list/vector of example values.

- references:

  Optional named list `list(model = "Order", field = "id")` describing a
  foreign-key style reference. ODCS metadata only.

- quality:

  Optional list of quality checks (each a named list with `type`,
  `description`, and engine-specific keys like `query`).

## Value

A field definition (named list).

## Details

`type` accepts:

- A character builtin name (`"numeric"`, `"character"`, `"integer"`,
  ...).

- A predicate function `function(value) -> logical`.

- A registered model class name (string).

- Any [type_spec](type_spec.md) built with `t_*()`.

## See also

Other typed models: [`define_model()`](define_model.md),
[`get_schema()`](get_schema.md), [`is_model()`](is_model.md),
[`model_to_list()`](model_to_list.md),
[`print.typed_model()`](print.typed_model.md),
[`update_model()`](update_model.md),
[`validate_model()`](validate_model.md)

## Examples

``` r
field("numeric", default = 0)
#> $type
#> [1] "numeric"
#> 
#> $default
#> [1] 0
#> 
#> $validator
#> NULL
#> 
#> $nullable
#> [1] FALSE
#> 
#> $description
#> [1] ""
#> 
#> $primary_key
#> [1] FALSE
#> 
#> $unique
#> [1] FALSE
#> 
#> $pii
#> [1] FALSE
#> 
#> $classification
#> NULL
#> 
#> $tags
#> NULL
#> 
#> $examples
#> NULL
#> 
#> $references
#> NULL
#> 
#> $quality
#> NULL
#> 
field("integer", validator = numeric_range(0, 120))
#> $type
#> [1] "integer"
#> 
#> $default
#> NULL
#> 
#> $validator
#> function (value) 
#> {
#>     if (!is.numeric(value)) {
#>         return(FALSE)
#>     }
#>     min_ok <- if (exclusive_min) 
#>         all(value > min)
#>     else all(value >= min)
#>     max_ok <- if (exclusive_max) 
#>         all(value < max)
#>     else all(value <= max)
#>     min_ok && max_ok
#> }
#> <bytecode: 0x55a5fa5155e0>
#> <environment: 0x55a602e91950>
#> attr(,"constraint")
#> attr(,"constraint")$kind
#> [1] "numeric_range"
#> 
#> attr(,"constraint")$min
#> [1] 0
#> 
#> attr(,"constraint")$max
#> [1] 120
#> 
#> attr(,"constraint")$exclusive_min
#> [1] FALSE
#> 
#> attr(,"constraint")$exclusive_max
#> [1] FALSE
#> 
#> 
#> $nullable
#> [1] FALSE
#> 
#> $description
#> [1] ""
#> 
#> $primary_key
#> [1] FALSE
#> 
#> $unique
#> [1] FALSE
#> 
#> $pii
#> [1] FALSE
#> 
#> $classification
#> NULL
#> 
#> $tags
#> NULL
#> 
#> $examples
#> NULL
#> 
#> $references
#> NULL
#> 
#> $quality
#> NULL
#> 
field(t_union("integer", "character"))
#> $type
#> <type_spec: union<integer, character>>
#> 
#> $default
#> NULL
#> 
#> $validator
#> NULL
#> 
#> $nullable
#> [1] FALSE
#> 
#> $description
#> [1] ""
#> 
#> $primary_key
#> [1] FALSE
#> 
#> $unique
#> [1] FALSE
#> 
#> $pii
#> [1] FALSE
#> 
#> $classification
#> NULL
#> 
#> $tags
#> NULL
#> 
#> $examples
#> NULL
#> 
#> $references
#> NULL
#> 
#> $quality
#> NULL
#> 
field(t_list_of("character"), default = list())
#> $type
#> <type_spec: list_of<character>>
#> 
#> $default
#> list()
#> 
#> $validator
#> NULL
#> 
#> $nullable
#> [1] FALSE
#> 
#> $description
#> [1] ""
#> 
#> $primary_key
#> [1] FALSE
#> 
#> $unique
#> [1] FALSE
#> 
#> $pii
#> [1] FALSE
#> 
#> $classification
#> NULL
#> 
#> $tags
#> NULL
#> 
#> $examples
#> NULL
#> 
#> $references
#> NULL
#> 
#> $quality
#> NULL
#> 
field(t_enum(c("admin", "user")))
#> $type
#> <type_spec: enum<admin, user>>
#> 
#> $default
#> NULL
#> 
#> $validator
#> NULL
#> 
#> $nullable
#> [1] FALSE
#> 
#> $description
#> [1] ""
#> 
#> $primary_key
#> [1] FALSE
#> 
#> $unique
#> [1] FALSE
#> 
#> $pii
#> [1] FALSE
#> 
#> $classification
#> NULL
#> 
#> $tags
#> NULL
#> 
#> $examples
#> NULL
#> 
#> $references
#> NULL
#> 
#> $quality
#> NULL
#> 
field("character",
  primary_key = TRUE, pii = TRUE,
  classification = "confidential"
)
#> $type
#> [1] "character"
#> 
#> $default
#> NULL
#> 
#> $validator
#> NULL
#> 
#> $nullable
#> [1] FALSE
#> 
#> $description
#> [1] ""
#> 
#> $primary_key
#> [1] TRUE
#> 
#> $unique
#> [1] FALSE
#> 
#> $pii
#> [1] TRUE
#> 
#> $classification
#> [1] "confidential"
#> 
#> $tags
#> NULL
#> 
#> $examples
#> NULL
#> 
#> $references
#> NULL
#> 
#> $quality
#> NULL
#> 
```
