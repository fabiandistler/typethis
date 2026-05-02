# Package index

## Type Definitions

Functions for defining and checking type specifications.

- [`types()`](types.md) [`` `types<-`() ``](types.md) : Get or set the
  type specs of a function

- [`type_spec`](type_spec.md) : Composable type specifications

- [`is_type_spec()`](is_type_spec.md) : Test whether an object is a type
  spec

- [`is_type()`](is_type.md) : Test whether a value matches a type

- [`t_enum()`](t_enum.md) : Enumerated set of allowed values

- [`t_list_of()`](t_list_of.md) : List of elements of a given type

- [`t_model()`](t_model.md) : Reference to a registered model class

- [`t_nullable()`](t_nullable.md) :

  Allow `NULL` in addition to an inner type

- [`t_predicate()`](t_predicate.md) : Wrap a predicate function as a
  type spec

- [`t_union()`](t_union.md) : Union of type specifications

- [`t_vector_of()`](t_vector_of.md) : Atomic vector of a given builtin
  type

## Typed Functions and Methods

Tools for creating and managing functions with type safety.

- [`typed_function()`](typed_function.md) : Wrap a function with
  input/output type checks

- [`typed_method()`](typed_method.md) : Build a typed-method decorator

- [`as_typed()`](as_typed.md) : Retrofit type stability onto an existing
  function

- [`as_typed_env()`](as_typed_env.md) : Bulk-retrofit every function in
  an environment

- [`as_typed_from_roxygen()`](as_typed_from_roxygen.md) : Retrofit a
  package using its roxygen / Rd documentation

- [`default_type_vocabulary()`](default_type_vocabulary.md) :

  Default prose-to-spec vocabulary for
  [`as_typed_from_roxygen()`](../reference/as_typed_from_roxygen.md)

- [`enable_for_package()`](enable_for_package.md) : Enable type checking
  for an entire package

- [`enable_typed_namespace()`](enable_typed_namespace.md) : Enable type
  checking for an installed package, without editing it

- [`disable_typed_namespace()`](disable_typed_namespace.md) : Remove a
  typethis hook and revert the typed wrappers

- [`validate_call()`](validate_call.md) : Validate a call to a typed
  function without executing it

- [`is_typed()`](is_typed.md) :

  Test whether a function was wrapped by
  [`typed_function()`](../reference/typed_function.md)

- [`signature()`](signature.md) : Build a function signature object

- [`get_signature()`](get_signature.md) : Inspect the signature of a
  typed function

- [`with_signature()`](with_signature.md) : Apply a signature to a
  function

- [`parse_param_type()`](parse_param_type.md) : Map a single prose
  description to a type spec

## Models

Define and work with structured data models.

- [`define_model()`](define_model.md) : Define a typed data model
- [`validate_model()`](validate_model.md) : Validate a model instance
  against its schema
- [`field()`](field.md) : Define a model field
- [`update_model()`](update_model.md) : Update fields on a typed model
  instance
- [`is_model()`](is_model.md) : Test whether an object is a typed model
  instance
- [`model_to_list()`](model_to_list.md) : Convert a typed model instance
  to a plain list
- [`print(`*`<typed_model>`*`)`](print.typed_model.md) : Print method
  for typed model instances

## Validation and Constraints

Manual type checking and value-level constraints.

- [`validate_type()`](validate_type.md) : Validate a value's type and
  return a structured result

- [`assert_type()`](assert_type.md) : Assert that a value has an
  expected type

- [`coerce_type()`](coerce_type.md) : Coerce a value to a target type

- [`numeric_range()`](numeric_range.md) : Validate a numeric range

- [`string_pattern()`](string_pattern.md) : Validate strings against a
  regular expression

- [`string_length()`](string_length.md) : Validate string length

- [`vector_length()`](vector_length.md) : Validate vector or list length

- [`enum_validator()`](enum_validator.md) : Validate a value against a
  fixed set of allowed values

- [`combine_validators()`](combine_validators.md) : Combine multiple
  validators

- [`validator_constraint()`](validator_constraint.md) : Read the
  constraint descriptor attached to a validator

- [`is_one_of()`](is_one_of.md) : Test whether a value matches any of
  several types

- [`nullable()`](nullable.md) :

  Make a validator accept `NULL`

- [`list_of()`](list_of.md) : Validate a list whose elements share a
  type

## Interoperability - Data Contracts

Integration with Frictionless Data Contracts.

- [`datacontract`](datacontract.md) : Open Data Contract Standard (ODCS
  v3) bridge

- [`read_datacontract()`](read_datacontract.md) : Read an ODCS contract
  YAML into an R list

- [`write_datacontract()`](write_datacontract.md) : Write an ODCS v3
  contract to a YAML file

- [`from_datacontract()`](from_datacontract.md) : Import an ODCS
  contract into the typethis model registry

- [`to_datacontract()`](to_datacontract.md) : Build an ODCS v3 contract
  from typed models

- [`datacontract_cli_available()`](datacontract_cli_available.md) :

  Check whether the `datacontract` CLI is available on PATH

- [`datacontract_export()`](datacontract_export.md) :

  Run `datacontract export` and capture or write the result

- [`datacontract_lint()`](datacontract_lint.md) :

  Run `datacontract lint` on a contract file

- [`datacontract_test()`](datacontract_test.md) :

  Run `datacontract test` on a contract file

## Interoperability - OpenAPI

Integration with OpenAPI specifications.

- [`openapi`](openapi.md) : OpenAPI 3.1 bridge
- [`read_openapi()`](read_openapi.md) : Read an OpenAPI document into an
  R list
- [`write_openapi()`](write_openapi.md) : Write an OpenAPI document to
  disk
- [`from_openapi()`](from_openapi.md) : Import OpenAPI components into
  the typethis model registry
- [`to_openapi()`](to_openapi.md) : Export typed models or typed
  functions to OpenAPI 3.1

## Interoperability - JSON Schema

Working with JSON Schema.

- [`json_schema`](json_schema.md) : JSON Schema export
- [`to_json_schema()`](to_json_schema.md) : Export a typed model or spec
  to JSON Schema
- [`get_schema()`](get_schema.md) : Retrieve a model's schema

## Utilities

- [`infer_specs()`](infer_specs.md) : Infer argument specs from a
  function's default values
- [`dataframe_spec()`](dataframe_spec.md) : Validate a data frame's
  structure
