# Run `datacontract lint` on a contract file

Thin wrapper around the upstream CLI. Requires the `datacontract` binary
on `PATH` — guard with
[`datacontract_cli_available()`](https://fabiandistler.github.io/typethis/reference/datacontract_cli_available.md).

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

Other Data Contract:
[`datacontract`](https://fabiandistler.github.io/typethis/reference/datacontract.md),
[`datacontract_cli_available()`](https://fabiandistler.github.io/typethis/reference/datacontract_cli_available.md),
[`datacontract_export()`](https://fabiandistler.github.io/typethis/reference/datacontract_export.md),
[`datacontract_test()`](https://fabiandistler.github.io/typethis/reference/datacontract_test.md),
[`from_datacontract()`](https://fabiandistler.github.io/typethis/reference/from_datacontract.md),
[`read_datacontract()`](https://fabiandistler.github.io/typethis/reference/read_datacontract.md),
[`to_datacontract()`](https://fabiandistler.github.io/typethis/reference/to_datacontract.md),
[`write_datacontract()`](https://fabiandistler.github.io/typethis/reference/write_datacontract.md)

## Examples

``` r
if (datacontract_cli_available()) {
  datacontract_lint("orders.yaml")
}
```
