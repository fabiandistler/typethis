# Run `datacontract test` on a contract file

Thin wrapper around the upstream CLI. Requires the `datacontract` binary
on `PATH` — guard with
[`datacontract_cli_available()`](https://fabiandistler.github.io/typethis/reference/datacontract_cli_available.md).

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

Other Data Contract:
[`datacontract`](https://fabiandistler.github.io/typethis/reference/datacontract.md),
[`datacontract_cli_available()`](https://fabiandistler.github.io/typethis/reference/datacontract_cli_available.md),
[`datacontract_export()`](https://fabiandistler.github.io/typethis/reference/datacontract_export.md),
[`datacontract_lint()`](https://fabiandistler.github.io/typethis/reference/datacontract_lint.md),
[`from_datacontract()`](https://fabiandistler.github.io/typethis/reference/from_datacontract.md),
[`read_datacontract()`](https://fabiandistler.github.io/typethis/reference/read_datacontract.md),
[`to_datacontract()`](https://fabiandistler.github.io/typethis/reference/to_datacontract.md),
[`write_datacontract()`](https://fabiandistler.github.io/typethis/reference/write_datacontract.md)

## Examples

``` r
if (datacontract_cli_available()) {
  datacontract_test("orders.yaml", server = "production")
}
```
