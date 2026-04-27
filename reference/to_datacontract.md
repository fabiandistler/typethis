# Build an ODCS v3 contract from typed models

Returns the contract as a native R list, ready for
[`yaml::write_yaml()`](https://yaml.r-lib.org/reference/write_yaml.html)
or further programmatic manipulation. Methods exist for typed model
instances, model constructors, character class names, and lists of any
of these.

## Usage

``` r
to_datacontract(x, info = NULL, servers = NULL, ...)
```

## Arguments

- x:

  A typed model instance, a model constructor, a model class name
  (character scalar), or a character vector of class names. Use a vector
  to bundle multiple models into one contract.

- info:

  Optional named list with top-level metadata. Recognised keys: `id`,
  `name`, `version`, `status`, `description` (string or list with
  `purpose`, `usage`, `limitations`), `owner`, `tags`.

- servers:

  Optional named list of server definitions, passed through verbatim to
  ODCS. Example:
  `list(production = list(type = "bigquery", project = "p", dataset = "d"))`.

- ...:

  Reserved for method extension.

## Value

A named R list shaped as an ODCS v3 contract.

## See also

[`write_datacontract()`](https://fabiandistler.github.io/typethis/reference/write_datacontract.md)
to write directly to disk;
[`from_datacontract()`](https://fabiandistler.github.io/typethis/reference/from_datacontract.md)
for the reverse direction.

Other Data Contract:
[`datacontract`](https://fabiandistler.github.io/typethis/reference/datacontract.md),
[`datacontract_cli_available()`](https://fabiandistler.github.io/typethis/reference/datacontract_cli_available.md),
[`datacontract_export()`](https://fabiandistler.github.io/typethis/reference/datacontract_export.md),
[`datacontract_lint()`](https://fabiandistler.github.io/typethis/reference/datacontract_lint.md),
[`datacontract_test()`](https://fabiandistler.github.io/typethis/reference/datacontract_test.md),
[`from_datacontract()`](https://fabiandistler.github.io/typethis/reference/from_datacontract.md),
[`read_datacontract()`](https://fabiandistler.github.io/typethis/reference/read_datacontract.md),
[`write_datacontract()`](https://fabiandistler.github.io/typethis/reference/write_datacontract.md)

## Examples

``` r
define_model("Order", fields = list(
  order_id = field("character", primary_key = TRUE),
  amount   = field("numeric", validator = numeric_range(0, 1e6))
))

contract <- to_datacontract("Order",
  info = list(name = "orders", version = "1.0.0"))
str(contract, max.level = 2)
#> List of 7
#>  $ apiVersion: chr "v3.0.2"
#>  $ kind      : chr "DataContract"
#>  $ id        : chr "Order"
#>  $ status    : chr "draft"
#>  $ name      : chr "orders"
#>  $ version   : chr "1.0.0"
#>  $ schema    :List of 1
#>   ..$ :List of 3
```
