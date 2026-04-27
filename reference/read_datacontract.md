# Read an ODCS contract YAML into an R list

Pure parsing helper — does not register anything in the typethis model
registry. Use
[`from_datacontract()`](https://fabiandistler.github.io/typethis/reference/from_datacontract.md)
for the full import pipeline.

## Usage

``` r
read_datacontract(path)
```

## Arguments

- path:

  File path or URL.

## Value

Parsed ODCS list.

## See also

Other Data Contract:
[`datacontract`](https://fabiandistler.github.io/typethis/reference/datacontract.md),
[`datacontract_cli_available()`](https://fabiandistler.github.io/typethis/reference/datacontract_cli_available.md),
[`datacontract_export()`](https://fabiandistler.github.io/typethis/reference/datacontract_export.md),
[`datacontract_lint()`](https://fabiandistler.github.io/typethis/reference/datacontract_lint.md),
[`datacontract_test()`](https://fabiandistler.github.io/typethis/reference/datacontract_test.md),
[`from_datacontract()`](https://fabiandistler.github.io/typethis/reference/from_datacontract.md),
[`to_datacontract()`](https://fabiandistler.github.io/typethis/reference/to_datacontract.md),
[`write_datacontract()`](https://fabiandistler.github.io/typethis/reference/write_datacontract.md)
