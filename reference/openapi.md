# OpenAPI 3.1 bridge

Convert typed models and typed functions to and from [OpenAPI 3.1
documents](https://spec.openapis.org/oas/v3.1.0). OpenAPI 3.1 is
JSON-Schema-Draft-2020-12-compatible, so the schema fragments produced
by [`to_json_schema()`](to_json_schema.md) are lifted directly into
`components.schemas`; `$ref` strings are rewritten from `#/$defs/X` to
`#/components/schemas/X`. Typed functions become a single `paths` entry
whose `requestBody` carries the arguments as a JSON object and whose
`200` response carries the return type.

Key entry points:

- [`to_openapi()`](to_openapi.md) /
  [`write_openapi()`](write_openapi.md) — export.

- [`read_openapi()`](read_openapi.md) /
  [`from_openapi()`](from_openapi.md) — import.

## See also

Other OpenAPI: [`from_openapi()`](from_openapi.md),
[`read_openapi()`](read_openapi.md), [`to_openapi()`](to_openapi.md),
[`write_openapi()`](write_openapi.md)
