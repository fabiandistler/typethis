# typethis: runtime type safety and validation for R

`typethis` brings type checks, validators, and typed data models to R.
Errors surface where they originate, with messages that name the
offending field or argument and what was expected.

## Function families

The exported API is grouped into the following families. The help page
for each function lists its family in the "See also" section, so once
you know one function you can navigate to its neighbours.

- Type checking:

  [`is_type()`](is_type.md), [`assert_type()`](assert_type.md),
  [`validate_type()`](validate_type.md), [`is_one_of()`](is_one_of.md),
  [`coerce_type()`](coerce_type.md) — the core runtime checks.

- Type specifications:

  [`t_union()`](t_union.md), [`t_nullable()`](t_nullable.md),
  [`t_list_of()`](t_list_of.md), [`t_vector_of()`](t_vector_of.md),
  [`t_enum()`](t_enum.md), [`t_model()`](t_model.md),
  [`t_predicate()`](t_predicate.md), [`is_type_spec()`](is_type_spec.md)
  — composable specs that work everywhere a type name does.

- Validators:

  [`numeric_range()`](numeric_range.md),
  [`string_length()`](string_length.md),
  [`string_pattern()`](string_pattern.md),
  [`vector_length()`](vector_length.md),
  [`dataframe_spec()`](dataframe_spec.md),
  [`enum_validator()`](enum_validator.md), [`list_of()`](list_of.md),
  [`nullable()`](nullable.md),
  [`combine_validators()`](combine_validators.md),
  [`validator_constraint()`](validator_constraint.md) — value-level
  rules attached to fields and arguments.

- Typed functions:

  [`typed_function()`](typed_function.md),
  [`signature()`](signature.md),
  [`with_signature()`](with_signature.md), [`is_typed()`](is_typed.md),
  [`get_signature()`](get_signature.md),
  [`typed_method()`](typed_method.md),
  [`validate_call()`](validate_call.md) — wrap a function so each call
  is validated.

- Typed models:

  [`define_model()`](define_model.md), [`field()`](field.md),
  [`is_model()`](is_model.md), [`get_schema()`](get_schema.md),
  [`validate_model()`](validate_model.md),
  [`update_model()`](update_model.md),
  [`model_to_list()`](model_to_list.md) — describe a record type with
  field-level validation, defaults, and nullability.

- JSON Schema export:

  [`to_json_schema()`](to_json_schema.md) — emit JSON Schema (Draft
  2020-12) fragments from typed models, type specs, and validators.

- Data Contract bridge:

  [`to_datacontract()`](to_datacontract.md),
  [`write_datacontract()`](write_datacontract.md),
  [`read_datacontract()`](read_datacontract.md),
  [`from_datacontract()`](from_datacontract.md),
  [`datacontract_lint()`](datacontract_lint.md),
  [`datacontract_test()`](datacontract_test.md),
  [`datacontract_export()`](datacontract_export.md),
  [`datacontract_cli_available()`](datacontract_cli_available.md) —
  round-trip with the Open Data Contract Standard v3.

- OpenAPI 3.1 bridge:

  [`to_openapi()`](to_openapi.md),
  [`write_openapi()`](write_openapi.md),
  [`read_openapi()`](read_openapi.md),
  [`from_openapi()`](from_openapi.md) — round-trip typed models and
  functions with OpenAPI 3.1 documents.

## Where to start

- [`vignette("getting-started", package = "typethis")`](../articles/getting-started.md)
  — a 10-minute tour.

- [`vignette("validators-and-models", package = "typethis")`](../articles/validators-and-models.md)
  — built-in validators, nested models, strict mode, defaults.

- [`vignette("type-specs", package = "typethis")`](../articles/type-specs.md)
  — composable type specs.

- [`vignette("interop", package = "typethis")`](../articles/interop.md)
  — JSON Schema, ODCS, OpenAPI.

## Runtime only

`typethis` performs validation at runtime — when your code executes, not
when it is loaded. It does not replace static analysis tools such as
`lintr`. The benefit is that it works with any R code, no IDE plugin
required.

## See also

Useful links:

- <https://fabiandistler.github.io/typethis/>

- <https://github.com/fabiandistler/typethis>

- Report bugs at <https://github.com/fabiandistler/typethis/issues>

## Author

**Maintainer**: Fabian Distler <dev@example.com>
