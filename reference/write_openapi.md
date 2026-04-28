# Write an OpenAPI document to disk

Convenience wrapper around [`to_openapi()`](to_openapi.md) + the
appropriate writer
([`yaml::write_yaml()`](https://yaml.r-lib.org/reference/write_yaml.html)
for YAML,
[`jsonlite::toJSON()`](https://jeroen.r-universe.dev/jsonlite/reference/fromJSON.html)
for JSON). The output format is inferred from the file extension and can
be overridden.

## Usage

``` r
write_openapi(x, path, info = NULL, paths = NULL, format = NULL, ...)
```

## Arguments

- x:

  See [`to_openapi()`](to_openapi.md).

- path:

  Destination file path. Use `.yaml`/`.yml` for YAML output or `.json`
  for JSON.

- info, paths, ...:

  Forwarded to [`to_openapi()`](to_openapi.md).

- format:

  Output format: `"yaml"` (default for `.yaml`/`.yml`) or `"json"`
  (default for `.json`). Defaults to YAML if the extension is ambiguous.

## Value

The OpenAPI document list, invisibly.

## See also

Other OpenAPI: [`from_openapi()`](from_openapi.md),
[`openapi`](openapi.md), [`read_openapi()`](read_openapi.md),
[`to_openapi()`](to_openapi.md)

## Examples

``` r
if (requireNamespace("yaml", quietly = TRUE)) {
  define_model("User", fields = list(
    id   = field("integer", primary_key = TRUE),
    name = field("character")
  ))
  tmp <- tempfile(fileext = ".yaml")
  write_openapi("User", tmp,
    info = list(title = "Users API", version = "1.0.0")
  )
  readLines(tmp, n = 5)
}
#> [1] "openapi: 3.1.0"     "info:"              "  title: Users API"
#> [4] "  version: 1.0.0"   "components:"       
```
