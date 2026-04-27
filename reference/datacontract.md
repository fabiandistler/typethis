# Open Data Contract Standard (ODCS v3) bridge

Convert typed models to and from the [Open Data Contract Standard (ODCS)
v3](https://bitol-io.github.io/open-data-contract-standard/) YAML
format, and run the `datacontract` CLI from R.

Pydantic has the same kind of bridge:
`datacontract export --format pydantic-model` generates Pydantic source
code from a contract. typethis closes the loop for R: typed models can
be exported to ODCS YAML, and existing ODCS contracts can be loaded back
into the model registry at runtime as `new_*()` / `update_*()`
constructors.

Constructs without a native ODCS representation (data frames, factors,
unions, custom predicate functions) are emitted with `x-typethis-*`
extension keys so the bridge round-trips through typethis-aware tooling.

Key entry points:

- [`to_datacontract()`](https://fabiandistler.github.io/typethis/reference/to_datacontract.md)
  /
  [`write_datacontract()`](https://fabiandistler.github.io/typethis/reference/write_datacontract.md)
  — export.

- [`read_datacontract()`](https://fabiandistler.github.io/typethis/reference/read_datacontract.md)
  /
  [`from_datacontract()`](https://fabiandistler.github.io/typethis/reference/from_datacontract.md)
  — import.

- [`datacontract_lint()`](https://fabiandistler.github.io/typethis/reference/datacontract_lint.md)
  /
  [`datacontract_test()`](https://fabiandistler.github.io/typethis/reference/datacontract_test.md)
  /
  [`datacontract_export()`](https://fabiandistler.github.io/typethis/reference/datacontract_export.md)
  — thin wrappers around the upstream CLI.

## See also

Other Data Contract:
[`datacontract_cli_available()`](https://fabiandistler.github.io/typethis/reference/datacontract_cli_available.md),
[`datacontract_export()`](https://fabiandistler.github.io/typethis/reference/datacontract_export.md),
[`datacontract_lint()`](https://fabiandistler.github.io/typethis/reference/datacontract_lint.md),
[`datacontract_test()`](https://fabiandistler.github.io/typethis/reference/datacontract_test.md),
[`from_datacontract()`](https://fabiandistler.github.io/typethis/reference/from_datacontract.md),
[`read_datacontract()`](https://fabiandistler.github.io/typethis/reference/read_datacontract.md),
[`to_datacontract()`](https://fabiandistler.github.io/typethis/reference/to_datacontract.md),
[`write_datacontract()`](https://fabiandistler.github.io/typethis/reference/write_datacontract.md)
