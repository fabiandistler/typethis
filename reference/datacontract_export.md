# Run `datacontract export` and capture or write the result

Thin wrapper around the CLI's `export` subcommand. Handy for converting
an ODCS contract to other formats (JSON Schema, SQL, Avro, dbt, ...).
Requires the `datacontract` binary on `PATH` — guard with
[`datacontract_cli_available()`](https://fabiandistler.github.io/typethis/reference/datacontract_cli_available.md).

## Usage

``` r
datacontract_export(path, format, output = NULL, ...)
```

## Arguments

- path:

  Path to the contract YAML.

- format:

  Target format string, e.g. `"jsonschema"`, `"sql"`,
  `"pydantic-model"`, `"avro"`.

- output:

  Optional output file path. If `NULL` (default) the export is captured
  and returned as a character scalar.

- ...:

  Additional CLI flags (e.g. `"--server", "production"`).

## Value

If `output` is `NULL`, the export as a single character string;
otherwise the path, invisibly.

## See also

Other Data Contract:
[`datacontract`](https://fabiandistler.github.io/typethis/reference/datacontract.md),
[`datacontract_cli_available()`](https://fabiandistler.github.io/typethis/reference/datacontract_cli_available.md),
[`datacontract_lint()`](https://fabiandistler.github.io/typethis/reference/datacontract_lint.md),
[`datacontract_test()`](https://fabiandistler.github.io/typethis/reference/datacontract_test.md),
[`from_datacontract()`](https://fabiandistler.github.io/typethis/reference/from_datacontract.md),
[`read_datacontract()`](https://fabiandistler.github.io/typethis/reference/read_datacontract.md),
[`to_datacontract()`](https://fabiandistler.github.io/typethis/reference/to_datacontract.md),
[`write_datacontract()`](https://fabiandistler.github.io/typethis/reference/write_datacontract.md)

## Examples

``` r
if (datacontract_cli_available()) {
  datacontract_export("orders.yaml", format = "jsonschema")
}
```
