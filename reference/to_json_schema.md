# Export a typed model or spec to JSON Schema

Returns a named R list shaped as a JSON Schema (Draft 2020-12) fragment,
ready to be serialized with
[`jsonlite::toJSON()`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html).
Methods exist for typed model instances, model class names, type specs,
validators, and [`field()`](field.md) definitions.

## Usage

``` r
to_json_schema(x, ...)
```

## Arguments

- x:

  A typed model instance, a model constructor, a model class name
  (character scalar), a [type_spec](type_spec.md), a builtin type name,
  a validator closure, or a [`field()`](field.md) definition list.

- ...:

  Reserved for method extension.

## Value

A named R list shaped as a JSON Schema fragment.

## See also

[`to_datacontract()`](to_datacontract.md) and
[`to_openapi()`](to_openapi.md) for related export bridges.

Other JSON Schema: [`json_schema`](json_schema.md)

## Examples

``` r
define_model("Person", fields = list(
  name = field("character", nullable = FALSE),
  age  = field("integer", validator = numeric_range(0, 120))
))
schema <- to_json_schema("Person")
str(schema, max.level = 2)
#> List of 6
#>  $ $schema             : chr "https://json-schema.org/draft/2020-12/schema"
#>  $ title               : chr "Person"
#>  $ type                : chr "object"
#>  $ properties          :List of 2
#>   ..$ name:List of 1
#>   ..$ age :List of 3
#>  $ additionalProperties: logi TRUE
#>  $ required            :List of 2
#>   ..$ : chr "name"
#>   ..$ : chr "age"

if (requireNamespace("jsonlite", quietly = TRUE)) {
  cat(jsonlite::toJSON(schema, auto_unbox = TRUE, pretty = TRUE))
}
#> {
#>   "$schema": "https://json-schema.org/draft/2020-12/schema",
#>   "title": "Person",
#>   "type": "object",
#>   "properties": {
#>     "name": {
#>       "type": "string"
#>     },
#>     "age": {
#>       "type": "integer",
#>       "minimum": 0,
#>       "maximum": 120
#>     }
#>   },
#>   "additionalProperties": true,
#>   "required": [
#>     "name",
#>     "age"
#>   ]
#> }
```
