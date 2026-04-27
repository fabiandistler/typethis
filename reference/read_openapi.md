# Read an OpenAPI document into an R list

Pure parsing helper — does not register anything. Use
[`from_openapi()`](from_openapi.md) for the full import pipeline.

## Usage

``` r
read_openapi(path)
```

## Arguments

- path:

  File path or URL.

## Value

Parsed OpenAPI list.

## See also

Other OpenAPI: [`from_openapi()`](from_openapi.md),
[`openapi`](openapi.md), [`to_openapi()`](to_openapi.md),
[`write_openapi()`](write_openapi.md)
