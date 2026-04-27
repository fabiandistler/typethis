# Read an ODCS contract YAML into an R list

Pure parsing helper — does not register anything in the typethis model
registry. Use [`from_datacontract()`](from_datacontract.md) for the full
import pipeline.

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

Other Data Contract: [`datacontract`](datacontract.md),
[`datacontract_cli_available()`](datacontract_cli_available.md),
[`datacontract_export()`](datacontract_export.md),
[`datacontract_lint()`](datacontract_lint.md),
[`datacontract_test()`](datacontract_test.md),
[`from_datacontract()`](from_datacontract.md),
[`to_datacontract()`](to_datacontract.md),
[`write_datacontract()`](write_datacontract.md)
