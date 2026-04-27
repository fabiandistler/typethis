# typethis: runtime type safety and validation for R

`typethis` brings type checks, validators, and typed data models to R.
Errors surface where they originate, with messages that name the
offending field or argument and what was expected.

## Function families

The exported API is grouped into the following families. The help page
for each function lists its family in the "See also" section, so once
you know one function you can navigate to its neighbours.

- Type checking:

  [`is_type()`](https://fabiandistler.github.io/typethis/reference/is_type.md),
  [`assert_type()`](https://fabiandistler.github.io/typethis/reference/assert_type.md),
  [`validate_type()`](https://fabiandistler.github.io/typethis/reference/validate_type.md),
  [`is_one_of()`](https://fabiandistler.github.io/typethis/reference/is_one_of.md),
  [`coerce_type()`](https://fabiandistler.github.io/typethis/reference/coerce_type.md)
  — the core runtime checks.

- Type specifications:

  [`t_union()`](https://fabiandistler.github.io/typethis/reference/t_union.md),
  [`t_nullable()`](https://fabiandistler.github.io/typethis/reference/t_nullable.md),
  [`t_list_of()`](https://fabiandistler.github.io/typethis/reference/t_list_of.md),
  [`t_vector_of()`](https://fabiandistler.github.io/typethis/reference/t_vector_of.md),
  [`t_enum()`](https://fabiandistler.github.io/typethis/reference/t_enum.md),
  [`t_model()`](https://fabiandistler.github.io/typethis/reference/t_model.md),
  [`t_predicate()`](https://fabiandistler.github.io/typethis/reference/t_predicate.md),
  [`is_type_spec()`](https://fabiandistler.github.io/typethis/reference/is_type_spec.md)
  — composable specs that work everywhere a type name does.

- Validators:

  [`numeric_range()`](https://fabiandistler.github.io/typethis/reference/numeric_range.md),
  [`string_length()`](https://fabiandistler.github.io/typethis/reference/string_length.md),
  [`string_pattern()`](https://fabiandistler.github.io/typethis/reference/string_pattern.md),
  [`vector_length()`](https://fabiandistler.github.io/typethis/reference/vector_length.md),
  [`dataframe_spec()`](https://fabiandistler.github.io/typethis/reference/dataframe_spec.md),
  [`enum_validator()`](https://fabiandistler.github.io/typethis/reference/enum_validator.md),
  [`list_of()`](https://fabiandistler.github.io/typethis/reference/list_of.md),
  [`nullable()`](https://fabiandistler.github.io/typethis/reference/nullable.md),
  [`combine_validators()`](https://fabiandistler.github.io/typethis/reference/combine_validators.md),
  [`validator_constraint()`](https://fabiandistler.github.io/typethis/reference/validator_constraint.md)
  — value-level rules attached to fields and arguments.

- Typed functions:

  [`typed_function()`](https://fabiandistler.github.io/typethis/reference/typed_function.md),
  [`signature()`](https://fabiandistler.github.io/typethis/reference/signature.md),
  [`with_signature()`](https://fabiandistler.github.io/typethis/reference/with_signature.md),
  [`is_typed()`](https://fabiandistler.github.io/typethis/reference/is_typed.md),
  [`get_signature()`](https://fabiandistler.github.io/typethis/reference/get_signature.md),
  [`typed_method()`](https://fabiandistler.github.io/typethis/reference/typed_method.md),
  [`validate_call()`](https://fabiandistler.github.io/typethis/reference/validate_call.md)
  — wrap a function so each call is validated.

- Typed models:

  [`define_model()`](https://fabiandistler.github.io/typethis/reference/define_model.md),
  [`field()`](https://fabiandistler.github.io/typethis/reference/field.md),
  [`is_model()`](https://fabiandistler.github.io/typethis/reference/is_model.md),
  [`get_schema()`](https://fabiandistler.github.io/typethis/reference/get_schema.md),
  [`validate_model()`](https://fabiandistler.github.io/typethis/reference/validate_model.md),
  [`update_model()`](https://fabiandistler.github.io/typethis/reference/update_model.md),
  [`model_to_list()`](https://fabiandistler.github.io/typethis/reference/model_to_list.md)
  — describe a record type with field-level validation, defaults, and
  nullability.

- JSON Schema export:

  [`to_json_schema()`](https://fabiandistler.github.io/typethis/reference/to_json_schema.md)
  — emit JSON Schema (Draft 2020-12) fragments from typed models, type
  specs, and validators.

- Data Contract bridge:

  [`to_datacontract()`](https://fabiandistler.github.io/typethis/reference/to_datacontract.md),
  [`write_datacontract()`](https://fabiandistler.github.io/typethis/reference/write_datacontract.md),
  [`read_datacontract()`](https://fabiandistler.github.io/typethis/reference/read_datacontract.md),
  [`from_datacontract()`](https://fabiandistler.github.io/typethis/reference/from_datacontract.md),
  [`datacontract_lint()`](https://fabiandistler.github.io/typethis/reference/datacontract_lint.md),
  [`datacontract_test()`](https://fabiandistler.github.io/typethis/reference/datacontract_test.md),
  [`datacontract_export()`](https://fabiandistler.github.io/typethis/reference/datacontract_export.md),
  [`datacontract_cli_available()`](https://fabiandistler.github.io/typethis/reference/datacontract_cli_available.md)
  — round-trip with the Open Data Contract Standard v3.

- OpenAPI 3.1 bridge:

  [`to_openapi()`](https://fabiandistler.github.io/typethis/reference/to_openapi.md),
  [`write_openapi()`](https://fabiandistler.github.io/typethis/reference/write_openapi.md),
  [`read_openapi()`](https://fabiandistler.github.io/typethis/reference/read_openapi.md),
  [`from_openapi()`](https://fabiandistler.github.io/typethis/reference/from_openapi.md)
  — round-trip typed models and functions with OpenAPI 3.1 documents.

## Where to start

- [`vignette("getting-started", package = "typethis")`](https://fabiandistler.github.io/typethis/articles/getting-started.md)
  — a 10-minute tour.

- [`vignette("validators-and-models", package = "typethis")`](https://fabiandistler.github.io/typethis/articles/validators-and-models.md)
  — built-in validators, nested models, strict mode, defaults.

- [`vignette("type-specs", package = "typethis")`](https://fabiandistler.github.io/typethis/articles/type-specs.md)
  — composable type specs.

- [`vignette("interop", package = "typethis")`](https://fabiandistler.github.io/typethis/articles/interop.md)
  — JSON Schema, ODCS, OpenAPI.

## Runtime only

`typethis` performs validation at runtime — when your code executes, not
when it is loaded. It does not replace static analysis tools such as
`lintr`. The benefit is that it works with any R code, no IDE plugin
required.

## See also

Useful links:

- <https://github.com/fabiandistler/typethis>

- Report bugs at <https://github.com/fabiandistler/typethis/issues>

## Author

**Maintainer**: TypeThis Team <dev@example.com>
