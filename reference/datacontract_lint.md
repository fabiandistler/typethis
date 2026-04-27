# Run `datacontract lint` on a contract file

Thin wrapper around the upstream CLI. Requires the `datacontract` binary
on `PATH` — guard with
[`datacontract_cli_available()`](datacontract_cli_available.md).

## Usage

``` r
datacontract_lint(path, ...)
```

## Arguments

- path:

  Path to the contract YAML.

- ...:

  Additional CLI flags passed verbatim, e.g. `"--quiet"`.

## Value

List with `success` (logical), `status`, `stdout`, `stderr`. On a
non-zero CLI exit, an error is signalled.

## See also

Other Data Contract: [`datacontract`](datacontract.md),
[`datacontract_cli_available()`](datacontract_cli_available.md),
[`datacontract_export()`](datacontract_export.md),
[`datacontract_test()`](datacontract_test.md),
[`from_datacontract()`](from_datacontract.md),
[`read_datacontract()`](read_datacontract.md),
[`to_datacontract()`](to_datacontract.md),
[`write_datacontract()`](write_datacontract.md)

## Examples

``` r
if (datacontract_cli_available()) {
  datacontract_lint("orders.yaml")
}
```
