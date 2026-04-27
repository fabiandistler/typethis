# Export typed models or typed functions to OpenAPI 3.1

Builds an OpenAPI 3.1 document fragment from typed models, typed
functions, or a mixed list. Schemas are produced via
[`to_json_schema()`](to_json_schema.md) and lifted into
`components.schemas`; `$ref` strings are rewritten from the JSON Schema
convention (`#/$defs/X`) to the OpenAPI convention
(`#/components/schemas/X`). Typed functions become a single `paths`
entry with a JSON `requestBody` carrying the arguments and a `200`
response carrying the return type.

## Usage

``` r
to_openapi(x, info = NULL, paths = NULL, ...)
```

## Arguments

- x:

  A model class name (character scalar), a model constructor or
  instance, a typed function, or a list mixing any of the above.

- info:

  Optional named list with OpenAPI `info` fields (`title`, `version`,
  `description`, ...). Sensible defaults are filled in.

- paths:

  Optional named list of additional `paths` entries to merge in (e.g.
  for typed functions added by name).

- ...:

  Forwarded to method dispatch.

## Value

A list ready for
[`yaml::write_yaml()`](https://yaml.r-lib.org/reference/write_yaml.html)
or
[`jsonlite::toJSON()`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html).

## Details

To control the path and operation ID for a typed function, set
`attr(fn, "openapi_op_id") <- "yourId"` before passing it in.

## See also

[`write_openapi()`](write_openapi.md) for the file-IO convenience
wrapper; [`from_openapi()`](from_openapi.md) for the reverse direction;
[`to_json_schema()`](to_json_schema.md) for the underlying schema
export.

Other OpenAPI: [`from_openapi()`](from_openapi.md),
[`openapi`](openapi.md), [`read_openapi()`](read_openapi.md),
[`write_openapi()`](write_openapi.md)

## Examples

``` r
define_model("User", fields = list(
  id   = field("integer", primary_key = TRUE),
  name = field("character")
))
doc <- to_openapi("User",
  info = list(title = "Users API", version = "1.0.0"))
names(doc)
#> [1] "openapi"    "info"       "components"
names(doc$components$schemas)
#> [1] "User"
```
