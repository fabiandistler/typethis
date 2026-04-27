# Write an ODCS v3 contract to a YAML file

Convenience wrapper around [`to_datacontract()`](to_datacontract.md) +
[`yaml::write_yaml()`](https://yaml.r-lib.org/reference/write_yaml.html).

## Usage

``` r
write_datacontract(x, path, info = NULL, servers = NULL, ...)
```

## Arguments

- x:

  See [`to_datacontract()`](to_datacontract.md).

- path:

  Destination file path.

- info, servers:

  See [`to_datacontract()`](to_datacontract.md).

- ...:

  Forwarded to [`to_datacontract()`](to_datacontract.md).

## Value

The contract list, invisibly.

## See also

Other Data Contract: [`datacontract`](datacontract.md),
[`datacontract_cli_available()`](datacontract_cli_available.md),
[`datacontract_export()`](datacontract_export.md),
[`datacontract_lint()`](datacontract_lint.md),
[`datacontract_test()`](datacontract_test.md),
[`from_datacontract()`](from_datacontract.md),
[`read_datacontract()`](read_datacontract.md),
[`to_datacontract()`](to_datacontract.md)

## Examples

``` r
if (requireNamespace("yaml", quietly = TRUE)) {
  define_model("Customer", fields = list(
    customer_id = field("integer", primary_key = TRUE),
    name        = field("character")
  ))
  tmp <- tempfile(fileext = ".yaml")
  write_datacontract("Customer", tmp,
    info = list(name = "customers", version = "1.0.0"))
  readLines(tmp, n = 5)
}
#> [1] "apiVersion: v3.0.2" "kind: DataContract" "id: Customer"      
#> [4] "status: draft"      "name: customers"   
```
