# Run `datacontract test` on a contract file

Thin wrapper around the upstream CLI. Requires the `datacontract` binary
on `PATH` — guard with
[`datacontract_cli_available()`](datacontract_cli_available.md).

## Usage

``` r
datacontract_test(path, server = NULL, ...)
```

## Arguments

- path:

  Path to the contract YAML.

- server:

  Optional server name (ODCS `servers` key).

- ...:

  Additional CLI flags.

## Value

List with `success`, `status`, `stdout`, `stderr`.

## See also

Other Data Contract: [`datacontract`](datacontract.md),
[`datacontract_cli_available()`](datacontract_cli_available.md),
[`datacontract_export()`](datacontract_export.md),
[`datacontract_lint()`](datacontract_lint.md),
[`from_datacontract()`](from_datacontract.md),
[`read_datacontract()`](read_datacontract.md),
[`to_datacontract()`](to_datacontract.md),
[`write_datacontract()`](write_datacontract.md)

## Examples

``` r
if (datacontract_cli_available()) {
  datacontract_test("orders.yaml", server = "production")
}
```
