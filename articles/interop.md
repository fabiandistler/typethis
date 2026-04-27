# Interop: JSON Schema, ODCS, and OpenAPI

``` r
library(typethis)
#> 
#> Attaching package: 'typethis'
#> The following object is masked from 'package:methods':
#> 
#>     signature
```

`typethis` ships three bridges so the same type definitions can travel
out to non-R systems and (for ODCS and OpenAPI) come back in:

- **JSON Schema** (Draft 2020-12) via
  \[[`to_json_schema()`](https://fabiandistler.github.io/typethis/reference/to_json_schema.md)\].
- **Open Data Contract Standard v3** via
  \[[`to_datacontract()`](https://fabiandistler.github.io/typethis/reference/to_datacontract.md)\]
  and
  \[[`from_datacontract()`](https://fabiandistler.github.io/typethis/reference/from_datacontract.md)\].
- **OpenAPI 3.1** via
  \[[`to_openapi()`](https://fabiandistler.github.io/typethis/reference/to_openapi.md)\]
  and
  \[[`from_openapi()`](https://fabiandistler.github.io/typethis/reference/from_openapi.md)\].

All three share the same machinery — JSON Schema is the canonical
representation, and the ODCS and OpenAPI exporters lift its fragments
into the appropriate envelope.

The optional dependencies (`jsonlite`, `yaml`) live in `Suggests`. The
examples below guard their use with
[`requireNamespace()`](https://rdrr.io/r/base/ns-load.html).

## JSON Schema

[`to_json_schema()`](https://fabiandistler.github.io/typethis/reference/to_json_schema.md)
turns typed models, type specs, validators, and
\[[`field()`](https://fabiandistler.github.io/typethis/reference/field.md)\]
definitions into a Draft 2020-12 JSON Schema fragment as a plain R list.

``` r
define_model("Person", fields = list(
  name = field("character", nullable = FALSE),
  age  = field("integer", validator = numeric_range(0, 120)),
  role = field(t_enum(c("admin", "user")), default = "user")
))

schema <- to_json_schema("Person")
str(schema, max.level = 2)
#> List of 6
#>  $ $schema             : chr "https://json-schema.org/draft/2020-12/schema"
#>  $ title               : chr "Person"
#>  $ type                : chr "object"
#>  $ properties          :List of 3
#>   ..$ name:List of 1
#>   ..$ age :List of 3
#>   ..$ role:List of 3
#>  $ additionalProperties: logi TRUE
#>  $ required            :List of 2
#>   ..$ : chr "name"
#>   ..$ : chr "age"
```

``` r
cat(jsonlite::toJSON(schema, auto_unbox = TRUE, pretty = TRUE))
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
#>     },
#>     "role": {
#>       "type": "string",
#>       "enum": [
#>         "admin",
#>         "user"
#>       ],
#>       "default": "user"
#>     }
#>   },
#>   "additionalProperties": true,
#>   "required": [
#>     "name",
#>     "age"
#>   ]
#> }
```

Key behaviours:

- Built-in validator constraints (`numeric_range`, `string_length`,
  `string_pattern`, `vector_length`, `enum_validator`) become native
  JSON Schema keywords (`minimum`, `maxLength`, `pattern`, `minItems`,
  `enum`).
- Nested models become `$ref` entries in `$defs`. Cyclic references are
  handled via a stub-then-fill protocol.
- Constructs without a canonical mapping (data frames, factors, custom
  predicate functions) emit `x-typethis-*` extension keys so they
  round-trip through typethis-aware tooling.

Other accepted inputs include type specs
(`to_json_schema(t_union(...))`), validator closures
(`to_json_schema(numeric_range(0, 10))`), and
[`field()`](https://fabiandistler.github.io/typethis/reference/field.md)
definitions.

## Open Data Contract Standard

The [Open Data Contract Standard
v3](https://bitol-io.github.io/open-data-contract-standard/) (ODCS) is
an industry format for describing data products. typethis goes both
ways: typed models export to ODCS YAML and existing ODCS contracts
import back into the model registry.

### Export

``` r
define_model("Order", fields = list(
  order_id = field("character",
                   primary_key = TRUE,
                   validator   = string_pattern("^ORD-[0-9]+$")),
  amount   = field("numeric",
                   validator = numeric_range(0, 1e6),
                   pii       = FALSE),
  status   = field(t_enum(c("new", "paid", "shipped")),
                   default = "new"),
  customer = field("character",
                   classification = "confidential",
                   pii            = TRUE)
))

contract <- to_datacontract("Order",
  info = list(name = "orders",
              version = "1.0.0",
              description = "Order records"))

str(contract, max.level = 2)
#> List of 8
#>  $ apiVersion : chr "v3.0.2"
#>  $ kind       : chr "DataContract"
#>  $ id         : chr "Order"
#>  $ status     : chr "draft"
#>  $ name       : chr "orders"
#>  $ version    : chr "1.0.0"
#>  $ description:List of 1
#>   ..$ purpose: chr "Order records"
#>  $ schema     :List of 1
#>   ..$ :List of 3
```

[`write_datacontract()`](https://fabiandistler.github.io/typethis/reference/write_datacontract.md)
is the file-IO convenience wrapper:

``` r
tmp <- tempfile(fileext = ".yaml")
write_datacontract("Order", tmp,
  info = list(name = "orders", version = "1.0.0"))
readLines(tmp, n = 6)
#> [1] "apiVersion: v3.0.2" "kind: DataContract" "id: Order"         
#> [4] "status: draft"      "name: orders"       "version: 1.0.0"
```

### Import

[`from_datacontract()`](https://fabiandistler.github.io/typethis/reference/from_datacontract.md)
reads a contract back, calls
[`define_model()`](https://fabiandistler.github.io/typethis/reference/define_model.md)
for every entry, and assigns generated `new_*()` and `update_*()`
constructors to `envir`.

``` r
env <- new.env()
from_datacontract(tmp, envir = env)
ls(env)
#> [1] "new_Order"    "update_Order"

env$new_Order(order_id = "ORD-1", amount = 42, customer = "Ada")
#> <Typed Model: Order>
#> Fields:
#>   order_id: character = ORD-1
#>   amount: numeric = 42
#>   customer: character = Ada
#>   status: character = new
```

### Field metadata

[`field()`](https://fabiandistler.github.io/typethis/reference/field.md)
accepts ODCS-specific metadata that round-trips through the contract but
has no effect on runtime validation:

| Argument         | Used for                                                                 |
|------------------|--------------------------------------------------------------------------|
| `primary_key`    | Marks the field as part of the primary key.                              |
| `unique`         | Indicates uniqueness.                                                    |
| `pii`            | Personally identifiable information flag.                                |
| `classification` | `"public"`, `"internal"`, `"confidential"`, …                            |
| `tags`           | Free-form character vector of tags.                                      |
| `examples`       | Example values (also surfaces in JSON Schema).                           |
| `references`     | Foreign-key style reference, e.g. `list(model = "Order", field = "id")`. |
| `quality`        | List of engine-specific quality checks.                                  |

### CLI

If the upstream [`datacontract` CLI](https://cli.datacontract.com/) is
installed and on `PATH`, three thin wrappers run it directly from R:

``` r
if (datacontract_cli_available()) {
  datacontract_lint(tmp)
  datacontract_test(tmp, server = "production")
  datacontract_export(tmp, format = "jsonschema")
}
```

## OpenAPI 3.1

OpenAPI 3.1 is JSON-Schema-Draft-2020-12-compatible, so the JSON Schema
machinery powers the OpenAPI bridge as well. Models become entries under
`components.schemas`; `$ref` strings are rewritten from `#/$defs/X` to
`#/components/schemas/X`. Typed functions become a `paths` entry whose
`requestBody` carries the arguments and whose `200` response carries the
return type.

### Models

``` r
define_model("Address2", fields = list(
  street = field("character"),
  city   = field("character")
))
define_model("PersonDoc", fields = list(
  id      = field("integer", primary_key = TRUE,
                  validator = numeric_range(min = 1L)),
  name    = field("character"),
  address = field("Address2")
))

doc <- to_openapi(list("PersonDoc", "Address2"),
  info = list(title = "People API", version = "1.0.0"))
names(doc$components$schemas)
#> [1] "PersonDoc" "Address2"
```

### Typed functions

``` r
greet <- typed_function(
  function(name, greeting = "Hi") paste(greeting, name),
  arg_specs   = list(name = "character", greeting = "character"),
  return_spec = "character"
)
attr(greet, "openapi_op_id") <- "greet"

doc <- to_openapi(list("PersonDoc", greet),
  info = list(title = "People API", version = "1.0.0"))
names(doc$paths)
#> [1] "/greet"
```

### Round-trip via disk

``` r
tmp <- tempfile(fileext = ".yaml")
write_openapi("PersonDoc", tmp,
  info = list(title = "People API", version = "1.0.0"))

env <- new.env()
from_openapi(tmp, envir = env)
ls(env)
#> [1] "new_Address2"     "new_PersonDoc"    "update_Address2"  "update_PersonDoc"
```

[`write_openapi()`](https://fabiandistler.github.io/typethis/reference/write_openapi.md)
infers the format from the file extension. Pass `format = "json"` (or
use a `.json` path) for JSON output.

## Choosing a bridge

| If you want to…                             | Use                                                                                              |
|---------------------------------------------|--------------------------------------------------------------------------------------------------|
| Hand a schema to any JSON-Schema-aware tool | [`to_json_schema()`](https://fabiandistler.github.io/typethis/reference/to_json_schema.md)       |
| Publish a data product description          | [`to_datacontract()`](https://fabiandistler.github.io/typethis/reference/to_datacontract.md)     |
| Document a JSON HTTP API                    | [`to_openapi()`](https://fabiandistler.github.io/typethis/reference/to_openapi.md)               |
| Bring an existing data contract into R      | [`from_datacontract()`](https://fabiandistler.github.io/typethis/reference/from_datacontract.md) |
| Bring an existing OpenAPI document into R   | [`from_openapi()`](https://fabiandistler.github.io/typethis/reference/from_openapi.md)           |
