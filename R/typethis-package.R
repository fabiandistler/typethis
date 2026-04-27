#' typethis: runtime type safety and validation for R
#'
#' `typethis` brings type checks, validators, and typed data models to R.
#' Errors surface where they originate, with messages that name the offending
#' field or argument and what was expected.
#'
#' @section Function families:
#'
#' The exported API is grouped into the following families. The help page
#' for each function lists its family in the "See also" section, so once you
#' know one function you can navigate to its neighbours.
#'
#' \describe{
#'   \item{Type checking}{[is_type()], [assert_type()], [validate_type()],
#'     [is_one_of()], [coerce_type()] — the core runtime checks.}
#'   \item{Type specifications}{[t_union()], [t_nullable()], [t_list_of()],
#'     [t_vector_of()], [t_enum()], [t_model()], [t_predicate()],
#'     [is_type_spec()] — composable specs that work everywhere a type name
#'     does.}
#'   \item{Validators}{[numeric_range()], [string_length()],
#'     [string_pattern()], [vector_length()], [dataframe_spec()],
#'     [enum_validator()], [list_of()], [nullable()],
#'     [combine_validators()], [validator_constraint()] — value-level rules
#'     attached to fields and arguments.}
#'   \item{Typed functions}{[typed_function()], [signature()],
#'     [with_signature()], [is_typed()], [get_signature()], [typed_method()],
#'     [validate_call()] — wrap a function so each call is validated.}
#'   \item{Typed models}{[define_model()], [field()], [is_model()],
#'     [get_schema()], [validate_model()], [update_model()],
#'     [model_to_list()] — describe a record type with field-level
#'     validation, defaults, and nullability.}
#'   \item{JSON Schema export}{[to_json_schema()] — emit JSON Schema (Draft
#'     2020-12) fragments from typed models, type specs, and validators.}
#'   \item{Data Contract bridge}{[to_datacontract()],
#'     [write_datacontract()], [read_datacontract()], [from_datacontract()],
#'     [datacontract_lint()], [datacontract_test()], [datacontract_export()],
#'     [datacontract_cli_available()] — round-trip with the Open Data
#'     Contract Standard v3.}
#'   \item{OpenAPI 3.1 bridge}{[to_openapi()], [write_openapi()],
#'     [read_openapi()], [from_openapi()] — round-trip typed models and
#'     functions with OpenAPI 3.1 documents.}
#' }
#'
#' @section Where to start:
#'
#' \itemize{
#'   \item `vignette("getting-started", package = "typethis")` — a 10-minute
#'     tour.
#'   \item `vignette("validators-and-models", package = "typethis")` —
#'     built-in validators, nested models, strict mode, defaults.
#'   \item `vignette("type-specs", package = "typethis")` — composable type
#'     specs.
#'   \item `vignette("interop", package = "typethis")` — JSON Schema, ODCS,
#'     OpenAPI.
#' }
#'
#' @section Runtime only:
#'
#' `typethis` performs validation at runtime — when your code executes,
#' not when it is loaded. It does not replace static analysis tools such as
#' `lintr`. The benefit is that it works with any R code, no IDE plugin
#' required.
#'
#' @keywords internal
"_PACKAGE"
