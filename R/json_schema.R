#' JSON Schema export
#'
#' @description
#' Convert typed models, type specs, validators, and field definitions
#' into [JSON Schema (Draft
#' 2020-12)](https://json-schema.org/draft/2020-12/release-notes) fragments.
#' The result is an R list ready for `jsonlite::toJSON(..., auto_unbox =
#' TRUE)`.
#'
#' Builtin validator factories ([numeric_range()], [string_length()],
#' [string_pattern()], [vector_length()], [enum_validator()]) attach a
#' `constraint` attribute that the exporter reads — so range and pattern
#' constraints surface as native `minimum` / `maxLength` / `pattern` keys
#' rather than opaque predicate stubs.
#'
#' Constructs without a canonical JSON Schema representation (data frames,
#' factors, environments, custom predicate functions) are emitted with
#' `x-typethis-*` extension keys so they round-trip through typethis-aware
#' tooling without losing information.
#'
#' @name json_schema
#' @family JSON Schema
NULL

json_schema_draft <- "https://json-schema.org/draft/2020-12/schema"

#' Export a typed model or spec to JSON Schema
#'
#' Returns a named R list shaped as a JSON Schema (Draft 2020-12) fragment,
#' ready to be serialized with `jsonlite::toJSON()`. Methods exist for
#' typed model instances, model class names, type specs, validators, and
#' [field()] definitions.
#'
#' @param x A typed model instance, a model constructor, a model class
#'   name (character scalar), a [type_spec][type_spec], a builtin type
#'   name, a validator closure, or a `field()` definition list.
#' @param ... Reserved for method extension.
#' @return A named R list shaped as a JSON Schema fragment.
#' @family JSON Schema
#' @seealso [to_datacontract()] and [to_openapi()] for related export
#'   bridges.
#' @export
#' @examples
#' define_model("Person", fields = list(
#'   name = field("character", nullable = FALSE),
#'   age  = field("integer", validator = numeric_range(0, 120))
#' ))
#' schema <- to_json_schema("Person")
#' str(schema, max.level = 2)
#'
#' if (requireNamespace("jsonlite", quietly = TRUE)) {
#'   cat(jsonlite::toJSON(schema, auto_unbox = TRUE, pretty = TRUE))
#' }
to_json_schema <- function(x, ...) {
  UseMethod("to_json_schema")
}

#' @export
to_json_schema.default <- function(x, ...) {
  if (is.character(x) && length(x) == 1L) {
    registry <- getOption("typethis_model_registry", list())
    if (x %in% names(registry)) {
      return(model_to_json_schema(x, defs = NULL))
    }
    return(builtin_to_json_schema(x))
  }
  if (is.function(x)) {
    constraint <- attr(x, "constraint")
    if (!is.null(constraint)) {
      return(constraint_to_json_schema(constraint))
    }
    return(list(
      `x-typethis-kind` = "predicate",
      description = "custom validator"
    ))
  }
  if (is.list(x) && !is.null(x$type) && !inherits(x, "type_spec")) {
    # field() definition
    return(field_to_json_schema(x, defs = NULL))
  }
  stop("to_json_schema(): unsupported input", call. = FALSE)
}

#' @export
to_json_schema.type_spec <- function(x, ..., defs = NULL) {
  defs <- defs %||% new_defs_env()
  schema <- type_spec_to_json_schema(x, defs)
  attach_defs(schema, defs)
}

#' @export
to_json_schema.typed_model <- function(x, ...) {
  class_name <- attr(x, "model_class_name")
  if (is.null(class_name)) {
    class_name <- "Model"
  }
  to_json_schema(class_name, ...)
}

# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------

#' @keywords internal
#' @noRd
new_defs_env <- function() {
  env <- new.env(parent = emptyenv())
  env$.defs <- list()
  env$.in_progress <- character(0)
  env
}

#' @keywords internal
#' @noRd
attach_defs <- function(schema, defs) {
  if (length(defs$.defs) > 0L) {
    schema$`$defs` <- defs$.defs
  }
  schema
}

#' @keywords internal
#' @noRd
`%||%` <- function(a, b) if (is.null(a)) b else a

#' @keywords internal
#' @noRd
builtin_to_json_schema <- function(name) {
  switch(name,
    "numeric" = list(type = "number"),
    "double" = list(type = "number"),
    "integer" = list(type = "integer"),
    "character" = list(type = "string"),
    "logical" = list(type = "boolean"),
    "list" = list(type = "array"),
    "data.frame" = list(
      type = "array",
      items = list(type = "object"),
      `x-typethis-kind` = "data.frame"
    ),
    "matrix" = list(
      type = "array",
      items = list(type = "array"),
      `x-typethis-kind` = "matrix"
    ),
    "factor" = list(type = "string", `x-typethis-kind` = "factor"),
    "date" = list(type = "string", format = "date"),
    "posixct" = list(type = "string", format = "date-time"),
    "function" = list(`x-typethis-kind` = "function"),
    "environment" = list(`x-typethis-kind` = "environment"),
    stop(
      sprintf("Unknown builtin type for JSON Schema: %s", name),
      call. = FALSE
    )
  )
}

#' @keywords internal
#' @noRd
type_spec_to_json_schema <- function(spec, defs) {
  switch(spec$kind,
    "builtin" = builtin_to_json_schema(spec$name),
    "predicate" = list(
      `x-typethis-kind` = "predicate",
      description = spec$description %||% "custom validator"
    ),
    "nullable" = nullable_to_json_schema(spec$inner, defs),
    "union" = list(
      oneOf = lapply(spec$alternatives, type_spec_to_json_schema, defs = defs)
    ),
    "enum" = enum_to_json_schema(spec),
    "model_ref" = model_ref_to_json_schema(spec$class_name, defs),
    "list_of" = list_of_to_json_schema(spec, defs),
    "vector_of" = list_of_to_json_schema(spec, defs),
    stop(sprintf("Unknown type_spec kind: %s", spec$kind), call. = FALSE)
  )
}

#' @keywords internal
#' @noRd
nullable_to_json_schema <- function(inner_spec, defs) {
  inner <- type_spec_to_json_schema(inner_spec, defs)
  if (
    is.character(inner$type) && length(inner$type) == 1L && length(inner) == 1L
  ) {
    inner$type <- c(inner$type, "null")
    return(inner)
  }
  list(oneOf = list(inner, list(type = "null")))
}

#' @keywords internal
#' @noRd
enum_to_json_schema <- function(spec) {
  type_str <- switch(spec$value_type,
    "character" = "string",
    "integer" = "integer",
    "numeric" = "number",
    "logical" = "boolean",
    "string"
  )
  list(type = type_str, enum = as.list(spec$values))
}

#' @keywords internal
#' @noRd
list_of_to_json_schema <- function(spec, defs) {
  out <- list(
    type = "array",
    items = type_spec_to_json_schema(spec$element, defs)
  )
  if (!is.null(spec$exact_length)) {
    out$minItems <- spec$exact_length
    out$maxItems <- spec$exact_length
  } else {
    if (!is.null(spec$min_length) && spec$min_length > 0) {
      out$minItems <- spec$min_length
    }
    if (!is.null(spec$max_length) && is.finite(spec$max_length)) {
      out$maxItems <- spec$max_length
    }
  }
  out
}

#' @keywords internal
#' @noRd
model_ref_to_json_schema <- function(class_name, defs) {
  if (!is.null(defs)) {
    register_model_def(class_name, defs)
  }
  list(`$ref` = sprintf("#/$defs/%s", class_name))
}

#' @keywords internal
#' @noRd
register_model_def <- function(class_name, defs) {
  if (class_name %in% names(defs$.defs)) {
    return(invisible())
  }
  if (class_name %in% defs$.in_progress) {
    # Cycle: leave a stub; the outer call will fill it in.
    return(invisible())
  }
  registry <- getOption("typethis_model_registry", list())
  if (!class_name %in% names(registry)) {
    defs$.defs[[class_name]] <- list(
      `x-typethis-kind` = "unresolved-model-ref",
      description = sprintf(
        "Model class '%s' not registered at export time",
        class_name
      )
    )
    return(invisible())
  }

  defs$.in_progress <- c(defs$.in_progress, class_name)
  defs$.defs[[class_name]] <- list() # stub before recursion
  defs$.defs[[class_name]] <- model_to_json_schema_body(class_name, defs)
  defs$.in_progress <- setdiff(defs$.in_progress, class_name)
  invisible()
}

#' @keywords internal
#' @noRd
constraint_to_json_schema <- function(constraint) {
  switch(constraint$kind,
    "numeric_range" = numeric_range_constraint(constraint),
    "string_length" = string_length_constraint(constraint),
    "string_pattern" = list(
      type = "string",
      pattern = constraint$pattern
    ),
    "vector_length" = vector_length_constraint(constraint),
    "enum" = list(enum = as.list(constraint$values)),
    "list_of" = list(
      type = "array",
      items = to_json_schema(constraint$element_type)
    ),
    "dataframe_spec" = list(
      type = "array",
      items = list(type = "object"),
      `x-typethis-dataframe` = list(
        requiredCols = as.list(constraint$required_cols %||% character(0)),
        minRows = constraint$min_rows,
        maxRows = if (is.finite(constraint$max_rows)) {
          constraint$max_rows
        } else {
          NULL
        }
      )
    ),
    "nullable" = nullable_constraint(constraint),
    "combine" = combine_constraint(constraint),
    list()
  )
}

#' @keywords internal
#' @noRd
numeric_range_constraint <- function(c) {
  out <- list(type = "number")
  if (is.finite(c$min)) {
    if (isTRUE(c$exclusive_min)) {
      out$exclusiveMinimum <- c$min
    } else {
      out$minimum <- c$min
    }
  }
  if (is.finite(c$max)) {
    if (isTRUE(c$exclusive_max)) {
      out$exclusiveMaximum <- c$max
    } else {
      out$maximum <- c$max
    }
  }
  out
}

#' @keywords internal
#' @noRd
string_length_constraint <- function(c) {
  out <- list(type = "string")
  if (!is.null(c$min_length) && c$min_length > 0) {
    out$minLength <- c$min_length
  }
  if (!is.null(c$max_length) && is.finite(c$max_length)) {
    out$maxLength <- c$max_length
  }
  out
}

#' @keywords internal
#' @noRd
vector_length_constraint <- function(c) {
  out <- list(type = "array")
  if (!is.null(c$exact_len)) {
    out$minItems <- c$exact_len
    out$maxItems <- c$exact_len
  } else {
    if (!is.null(c$min_len) && c$min_len > 0) {
      out$minItems <- c$min_len
    }
    if (!is.null(c$max_len) && is.finite(c$max_len)) {
      out$maxItems <- c$max_len
    }
  }
  out
}

#' @keywords internal
#' @noRd
nullable_constraint <- function(c) {
  inner <- if (!is.null(c$inner_constraint)) {
    constraint_to_json_schema(c$inner_constraint)
  } else {
    list()
  }
  if (is.character(inner$type) && length(inner$type) == 1L) {
    inner$type <- c(inner$type, "null")
    return(inner)
  }
  list(oneOf = list(inner, list(type = "null")))
}

#' @keywords internal
#' @noRd
combine_constraint <- function(c) {
  parts <- lapply(c$parts, function(p) {
    if (is.null(p)) {
      list(`x-typethis-kind` = "predicate")
    } else {
      constraint_to_json_schema(p)
    }
  })
  if (isTRUE(c$all_of)) {
    list(allOf = parts)
  } else {
    list(anyOf = parts)
  }
}

#' @keywords internal
#' @noRd
field_to_json_schema <- function(field_def, defs = NULL) {
  defs <- defs %||% new_defs_env()
  type_part <- if (!is.null(field_def$type)) {
    if (inherits(field_def$type, "type_spec")) {
      type_spec_to_json_schema(field_def$type, defs)
    } else if (is.character(field_def$type) && length(field_def$type) == 1L) {
      registry <- getOption("typethis_model_registry", list())
      if (field_def$type %in% names(registry)) {
        model_ref_to_json_schema(field_def$type, defs)
      } else {
        builtin_to_json_schema(field_def$type)
      }
    } else if (is.function(field_def$type)) {
      to_json_schema.default(field_def$type)
    } else {
      list()
    }
  } else {
    list()
  }

  # Validator constraint refines the type fragment
  if (!is.null(field_def$validator) && is.function(field_def$validator)) {
    constraint <- attr(field_def$validator, "constraint")
    if (!is.null(constraint)) {
      type_part <- merge_schema_fragments(
        type_part,
        constraint_to_json_schema(constraint)
      )
    } else {
      type_part$`x-typethis-kind` <- "predicate"
      if (is.null(type_part$description)) {
        type_part$description <- "custom validator"
      }
    }
  }

  if (isTRUE(field_def$nullable)) {
    type_part <- wrap_nullable_fragment(type_part)
  }

  if (!is.null(field_def$default)) {
    type_part$default <- field_def$default
  }

  if (!is.null(field_def$description) && nzchar(field_def$description)) {
    type_part$description <- field_def$description
  }

  type_part
}

#' @keywords internal
#' @noRd
wrap_nullable_fragment <- function(fragment) {
  if (is.character(fragment$type) && length(fragment$type) == 1L) {
    fragment$type <- c(fragment$type, "null")
    return(fragment)
  }
  list(oneOf = list(fragment, list(type = "null")))
}

#' @keywords internal
#' @noRd
merge_schema_fragments <- function(base, refinement) {
  if (length(refinement) == 0L) {
    return(base)
  }
  if (length(base) == 0L) {
    return(refinement)
  }
  out <- base
  for (key in names(refinement)) {
    if (identical(key, "type")) {
      # If both specify type, prefer base (more specific from spec)
      if (is.null(out$type)) out$type <- refinement$type
    } else {
      out[[key]] <- refinement[[key]]
    }
  }
  out
}

#' @keywords internal
#' @noRd
model_to_json_schema <- function(class_name, defs = NULL) {
  defs <- defs %||% new_defs_env()
  body <- model_to_json_schema_body(class_name, defs)
  schema <- c(
    list(
      `$schema` = json_schema_draft,
      title = class_name
    ),
    body
  )
  # Top-level: drop the self-entry from $defs (it's the main schema).
  defs$.defs[[class_name]] <- NULL
  attach_defs(schema, defs)
}

#' @keywords internal
#' @noRd
model_to_json_schema_body <- function(class_name, defs) {
  registry <- getOption("typethis_model_registry", list())
  entry <- registry[[class_name]]
  if (is.null(entry)) {
    stop(sprintf("Unknown model class: %s", class_name), call. = FALSE)
  }
  fields <- entry$fields
  strict <- isTRUE(entry$strict)

  properties <- list()
  required <- character(0)

  for (fname in names(fields)) {
    field_def <- fields[[fname]]
    properties[[fname]] <- field_to_json_schema(field_def, defs)
    if (is_required(field_def)) {
      required <- c(required, fname)
    }
  }

  out <- list(
    type = "object",
    properties = properties,
    additionalProperties = !strict
  )
  if (length(required) > 0L) {
    out$required <- as.list(required)
  }
  out
}

#' @keywords internal
#' @noRd
is_required <- function(field_def) {
  !isTRUE(field_def$nullable) && is.null(field_def$default)
}
