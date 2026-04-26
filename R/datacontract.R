#' Data Contract Integration
#'
#' @description
#' Convert typed models to and from the Open Data Contract Standard
#' (ODCS v3.x) YAML format, and run the `datacontract` CLI from R.
#'
#' Pydantic has the same kind of bridge: `datacontract export
#' --format pydantic-model` generates Pydantic source code from a contract.
#' typethis closes the loop for R: typed models can be exported to ODCS
#' YAML, and existing ODCS contracts can be loaded back into the typethis
#' model registry at runtime.
#'
#' Constructs without a native ODCS representation (data frames, factors,
#' unions, custom predicate functions) are emitted with `x-typethis-*`
#' extension keys so the bridge round-trips through typethis-aware tooling.
#'
#' @name datacontract
NULL

odcs_api_version <- "v3.0.2"

# ---------------------------------------------------------------------------
# Public API: export
# ---------------------------------------------------------------------------

#' Convert typethis schemas to a Data Contract (ODCS v3) list
#'
#' @param x A typed model instance, a model constructor, a model class
#'   name (character scalar), or a character vector of class names. Use a
#'   vector to bundle multiple models into one contract.
#' @param info Optional named list with top-level metadata. Recognised
#'   keys: `id`, `name`, `version`, `status`, `description` (string or
#'   list with `purpose`, `usage`, `limitations`), `owner`, `tags`.
#' @param servers Optional named list of server definitions, passed
#'   through verbatim to ODCS. Example:
#'   `list(production = list(type = "bigquery", project = "p", dataset = "d"))`.
#' @param ... Reserved for method extension.
#' @return A named R list shaped as an ODCS v3 contract. Serialise via
#'   `yaml::write_yaml()` or [write_datacontract()].
#' @export
#' @examples
#' \dontrun{
#' define_model("Order", fields = list(
#'   order_id = field("character", primary_key = TRUE),
#'   amount   = field("numeric", validator = numeric_range(0, 1e6))
#' ))
#' contract <- to_datacontract("Order",
#'   info = list(name = "orders", version = "1.0.0"))
#' }
to_datacontract <- function(x, info = NULL, servers = NULL, ...) {
  UseMethod("to_datacontract")
}

#' @export
to_datacontract.default <- function(x, info = NULL, servers = NULL, ...) {
  if (is.character(x)) {
    return(build_contract(x, info = info, servers = servers))
  }
  if (is.function(x) && isTRUE(attr(x, "model_class"))) {
    cls <- attr(x, "class_name") %||% "Model"
    return(build_contract(cls, info = info, servers = servers))
  }
  stop(
    "to_datacontract(): expected a model class name, ",
    "constructor, or instance.",
    call. = FALSE
  )
}

#' @export
to_datacontract.typed_model <- function(x, info = NULL, servers = NULL, ...) {
  cls <- attr(x, "model_class_name") %||% "Model"
  build_contract(cls, info = info, servers = servers)
}

#' @export
to_datacontract.list <- function(x, info = NULL, servers = NULL, ...) {
  names_only <- vapply(x, function(e) {
    if (is.character(e) && length(e) == 1L) {
      e
    } else if (is_model(e)) {
      attr(e, "model_class_name") %||% NA_character_
    } else if (is.function(e) && isTRUE(attr(e, "model_class"))) {
      attr(e, "class_name") %||% NA_character_
    } else {
      NA_character_
    }
  }, character(1))
  if (any(is.na(names_only))) {
    stop("to_datacontract(): all list entries must resolve to a model name",
         call. = FALSE)
  }
  build_contract(names_only, info = info, servers = servers)
}

#' Write a typethis schema to a Data Contract YAML file
#'
#' @param x See [to_datacontract()].
#' @param path Destination file path.
#' @param info,servers See [to_datacontract()].
#' @param ... Forwarded to [to_datacontract()].
#' @return The contract list, invisibly.
#' @export
write_datacontract <- function(x, path, info = NULL, servers = NULL, ...) {
  ensure_yaml()
  contract <- to_datacontract(x, info = info, servers = servers, ...)
  yaml::write_yaml(contract, path)
  invisible(contract)
}

# ---------------------------------------------------------------------------
# Public API: import
# ---------------------------------------------------------------------------

#' Read a Data Contract YAML file into an R list
#'
#' Pure parsing helper; does not register anything in the typethis model
#' registry. Use [from_datacontract()] for the full import pipeline.
#'
#' @param path File path or URL.
#' @return Parsed ODCS list.
#' @export
read_datacontract <- function(path) {
  ensure_yaml()
  if (grepl("^https?://", path)) {
    tmp <- tempfile(fileext = ".yaml")
    on.exit(unlink(tmp), add = TRUE)
    utils::download.file(path, tmp, quiet = TRUE)
    return(yaml::read_yaml(tmp))
  }
  yaml::read_yaml(path)
}

#' Load a Data Contract into the typethis model registry
#'
#' Reads an ODCS v3 contract (file path, URL, or already-parsed list) and
#' calls [define_model()] for every schema entry. Nested object properties
#' are registered as their own typed models so that `t_model()` references
#' resolve correctly.
#'
#' @param x A path, URL, or parsed ODCS list.
#' @param register Logical. If `TRUE` (default) define the models; if
#'   `FALSE` only return the field definitions without touching the
#'   registry.
#' @param envir Environment in which `new_<Class>()`/`update_<Class>()`
#'   constructors are assigned. Defaults to the calling environment.
#' @return Character vector of registered model class names, invisibly.
#' @export
#' @examples
#' \dontrun{
#' from_datacontract("orders.yaml")
#' new_Order(order_id = "ORD-1", amount = 42)
#' }
from_datacontract <- function(x, register = TRUE, envir = parent.frame()) {
  contract <- if (is.list(x)) x else read_datacontract(x)

  if (is.null(contract$schema) || !is.list(contract$schema)) {
    stop("Data Contract has no `schema` section", call. = FALSE)
  }

  ctx <- list(envir = envir, register = isTRUE(register))
  registered <- character(0)
  collected_fields <- list()
  for (entry in contract$schema) {
    if (is.null(entry$name)) {
      stop("Schema entry missing `name`", call. = FALSE)
    }
    fields_list <- odcs_properties_to_fields(entry$properties %||% list(),
                                             ctx)
    collected_fields[[entry$name]] <- fields_list

    if (isTRUE(register)) {
      define_model_in(entry$name, fields_list, envir)
    }
    registered <- c(registered, entry$name)
  }

  if (!isTRUE(register)) {
    attr(registered, "fields") <- collected_fields
  }
  invisible(registered)
}

# ---------------------------------------------------------------------------
# Public API: CLI wrappers
# ---------------------------------------------------------------------------

#' Check whether the `datacontract` CLI is available on PATH
#'
#' @return `TRUE` if the binary is found, `FALSE` otherwise.
#' @export
datacontract_cli_available <- function() {
  nzchar(Sys.which("datacontract"))
}

#' Run `datacontract lint` on a contract file
#'
#' @param path Path to the contract YAML.
#' @param ... Additional CLI flags passed verbatim, e.g. `"--quiet"`.
#' @return List with `success` (logical), `status`, `stdout`, `stderr`.
#' @export
datacontract_lint <- function(path, ...) {
  result <- cli_run(c("lint", path, ...))
  if (!result$success) {
    stop(
      "datacontract lint failed (status ", result$status, "):\n",
      paste(c(result$stdout, result$stderr), collapse = "\n"),
      call. = FALSE
    )
  }
  result
}

#' Run `datacontract test` on a contract file
#'
#' @param path Path to the contract YAML.
#' @param server Optional server name (ODCS `servers` key).
#' @param ... Additional CLI flags.
#' @return List with `success`, `status`, `stdout`, `stderr`.
#' @export
datacontract_test <- function(path, server = NULL, ...) {
  args <- c("test", path)
  if (!is.null(server)) args <- c(args, "--server", server)
  args <- c(args, ...)
  result <- cli_run(args)
  if (!result$success) {
    stop(
      "datacontract test failed (status ", result$status, "):\n",
      paste(c(result$stdout, result$stderr), collapse = "\n"),
      call. = FALSE
    )
  }
  result
}

#' Run `datacontract export` and capture or write the result
#'
#' Thin wrapper around the CLI's `export` subcommand. Handy for converting
#' an ODCS contract to other formats (JSON Schema, SQL, Avro, dbt, etc.).
#'
#' @param path Path to the contract YAML.
#' @param format Target format string, e.g. `"jsonschema"`, `"sql"`,
#'   `"pydantic-model"`, `"avro"`.
#' @param output Optional output file path. If `NULL` (default) the export
#'   is captured and returned as a character scalar.
#' @param ... Additional CLI flags (e.g. `"--server", "production"`).
#' @return If `output` is `NULL`, the export as a single character string;
#'   otherwise the path, invisibly.
#' @export
datacontract_export <- function(path, format, output = NULL, ...) {
  args <- c("export", path, "--format", format, ...)
  if (!is.null(output)) args <- c(args, "--output", output)
  result <- cli_run(args)
  if (!result$success) {
    stop(
      "datacontract export failed (status ", result$status, "):\n",
      paste(c(result$stdout, result$stderr), collapse = "\n"),
      call. = FALSE
    )
  }
  if (is.null(output)) {
    return(paste(result$stdout, collapse = "\n"))
  }
  invisible(output)
}

# ---------------------------------------------------------------------------
# Internals: export
# ---------------------------------------------------------------------------

#' @keywords internal
#' @noRd
build_contract <- function(class_names, info = NULL, servers = NULL) {
  registry <- getOption("typethis_model_registry", list())
  unknown <- setdiff(class_names, names(registry))
  if (length(unknown) > 0L) {
    stop(sprintf("Unknown model class(es): %s",
                 paste(unknown, collapse = ", ")), call. = FALSE)
  }

  primary <- class_names[[1L]]
  defs <- new.env(parent = emptyenv())
  defs$.entries <- list()
  defs$.in_progress <- character(0)

  schema_entries <- lapply(class_names, function(cn) {
    model_to_odcs_schema(cn, defs)
  })

  # Pull in any nested model classes that were registered along the way
  extra_names <- setdiff(names(defs$.entries), class_names)
  for (cn in extra_names) {
    schema_entries <- c(schema_entries, list(defs$.entries[[cn]]))
  }

  contract <- list(
    apiVersion = odcs_api_version,
    kind = "DataContract",
    id = info$id %||% primary,
    status = info$status %||% "draft",
    name = info$name %||% primary,
    version = info$version %||% "0.1.0"
  )

  desc <- info$description
  if (!is.null(desc)) {
    contract$description <- if (is.list(desc)) desc else list(purpose = desc)
  }
  if (!is.null(info$owner)) contract$owner <- info$owner
  if (!is.null(info$tags)) contract$tags <- as.list(info$tags)
  if (!is.null(servers)) contract$servers <- servers

  contract$schema <- schema_entries
  contract
}

#' @keywords internal
#' @noRd
model_to_odcs_schema <- function(class_name, defs) {
  registry <- getOption("typethis_model_registry", list())
  entry <- registry[[class_name]]
  if (is.null(entry)) {
    stop(sprintf("Unknown model class: %s", class_name), call. = FALSE)
  }
  if (class_name %in% defs$.in_progress) {
    return(list(name = class_name, logicalType = "object"))
  }
  defs$.in_progress <- c(defs$.in_progress, class_name)
  on.exit(defs$.in_progress <- setdiff(defs$.in_progress, class_name),
          add = TRUE)

  fields <- entry$fields
  props <- lapply(names(fields), function(fname) {
    prop <- field_to_odcs_property(fields[[fname]], defs)
    prop$name <- fname
    # Move name to first position for nicer YAML
    prop[c("name", setdiff(names(prop), "name"))]
  })

  out <- list(
    name = class_name,
    logicalType = "object",
    properties = props
  )
  defs$.entries[[class_name]] <- out
  out
}

#' @keywords internal
#' @noRd
field_to_odcs_property <- function(field_def, defs) {
  type_part <- type_to_odcs(field_def$type, defs)
  prop <- type_part

  if (!is.null(field_def$validator) && is.function(field_def$validator)) {
    constraint <- attr(field_def$validator, "constraint")
    if (!is.null(constraint)) {
      prop <- merge_odcs(prop, constraint_to_odcs(constraint))
    } else {
      prop[["x-typethis-kind"]] <- "predicate"
    }
  }

  prop$required <- !isTRUE(field_def$nullable) && is.null(field_def$default)

  if (!is.null(field_def$default)) prop$default <- field_def$default
  if (!is.null(field_def$description) && nzchar(field_def$description)) {
    prop$description <- field_def$description
  }
  if (isTRUE(field_def$primary_key)) prop$primaryKey <- TRUE
  if (isTRUE(field_def$unique)) prop$unique <- TRUE
  if (isTRUE(field_def$pii)) prop$pii <- TRUE
  if (!is.null(field_def$classification)) {
    prop$classification <- field_def$classification
  }
  if (!is.null(field_def$tags)) prop$tags <- as.list(field_def$tags)
  if (!is.null(field_def$examples)) prop$examples <- as.list(field_def$examples)
  if (!is.null(field_def$references)) prop$references <- field_def$references
  if (!is.null(field_def$quality)) prop$quality <- field_def$quality

  prop
}

#' @keywords internal
#' @noRd
type_to_odcs <- function(type, defs) {
  if (inherits(type, "type_spec")) {
    return(type_spec_to_odcs(type, defs))
  }
  if (is.character(type) && length(type) == 1L) {
    registry <- getOption("typethis_model_registry", list())
    if (type %in% names(registry)) {
      # Nested model: register it and emit a $ref
      if (!(type %in% names(defs$.entries))) {
        model_to_odcs_schema(type, defs)
      }
      return(list(
        logicalType = "object",
        `$ref` = sprintf("#/schema/%s", type)
      ))
    }
    return(builtin_to_odcs(type))
  }
  if (is.function(type)) {
    return(list(
      logicalType = "string",
      `x-typethis-kind` = "predicate"
    ))
  }
  list(logicalType = "string")
}

#' @keywords internal
#' @noRd
builtin_to_odcs <- function(name) {
  switch(name,
    "numeric"     = list(logicalType = "number"),
    "double"      = list(logicalType = "number"),
    "integer"     = list(logicalType = "integer"),
    "character"   = list(logicalType = "string"),
    "logical"     = list(logicalType = "boolean"),
    "list"        = list(logicalType = "array"),
    "data.frame"  = list(
      logicalType = "array",
      items = list(logicalType = "object"),
      `x-typethis-kind` = "data.frame"
    ),
    "matrix"      = list(
      logicalType = "array",
      items = list(logicalType = "array"),
      `x-typethis-kind` = "matrix"
    ),
    "factor"      = list(
      logicalType = "string",
      `x-typethis-kind` = "factor"
    ),
    "date"        = list(logicalType = "date"),
    "posixct"     = list(
      logicalType = "date",
      physicalType = "timestamp"
    ),
    "function"    = list(
      logicalType = "string",
      `x-typethis-kind` = "function"
    ),
    "environment" = list(
      logicalType = "string",
      `x-typethis-kind` = "environment"
    ),
    stop(sprintf("Unknown builtin type for ODCS: %s", name), call. = FALSE)
  )
}

#' @keywords internal
#' @noRd
type_spec_to_odcs <- function(spec, defs) {
  switch(spec$kind,
    "builtin"   = builtin_to_odcs(spec$name),
    "predicate" = list(
      logicalType = "string",
      `x-typethis-kind` = "predicate",
      description = spec$description %||% "custom validator"
    ),
    "nullable"  = type_spec_to_odcs(spec$inner, defs),
    "union"     = union_to_odcs(spec, defs),
    "enum"      = enum_spec_to_odcs(spec),
    "model_ref" = model_ref_to_odcs(spec$class_name, defs),
    "list_of"   = list_of_to_odcs(spec, defs),
    "vector_of" = list_of_to_odcs(spec, defs),
    stop(sprintf("Unknown type_spec kind: %s", spec$kind), call. = FALSE)
  )
}

#' @keywords internal
#' @noRd
union_to_odcs <- function(spec, defs) {
  alts <- lapply(spec$alternatives, type_spec_to_odcs, defs = defs)
  out <- alts[[1L]]
  out[["x-typethis-union"]] <- alts
  out
}

#' @keywords internal
#' @noRd
enum_spec_to_odcs <- function(spec) {
  type_str <- switch(spec$value_type,
    "character" = "string",
    "integer"   = "integer",
    "numeric"   = "number",
    "logical"   = "boolean",
    "string"
  )
  list(logicalType = type_str, enum = as.list(spec$values))
}

#' @keywords internal
#' @noRd
model_ref_to_odcs <- function(class_name, defs) {
  registry <- getOption("typethis_model_registry", list())
  if (class_name %in% names(registry) &&
        !(class_name %in% names(defs$.entries))) {
    model_to_odcs_schema(class_name, defs)
  }
  list(
    logicalType = "object",
    `$ref` = sprintf("#/schema/%s", class_name)
  )
}

#' @keywords internal
#' @noRd
list_of_to_odcs <- function(spec, defs) {
  out <- list(
    logicalType = "array",
    items = type_spec_to_odcs(spec$element, defs)
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
constraint_to_odcs <- function(constraint) {
  switch(constraint$kind,
    "numeric_range"  = numeric_range_to_odcs(constraint),
    "string_length"  = string_length_to_odcs(constraint),
    "string_pattern" = list(
      logicalType = "string",
      pattern = constraint$pattern
    ),
    "vector_length"  = vector_length_to_odcs(constraint),
    "enum"           = list(enum = as.list(constraint$values)),
    "list_of"        = list(
      logicalType = "array",
      items = type_to_odcs(constraint$element_type,
                           new.env(parent = emptyenv()))
    ),
    "dataframe_spec" = list(
      logicalType = "array",
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
    "nullable"       = constraint_to_odcs(
      constraint$inner_constraint %||% list(kind = "predicate")
    ),
    "combine"        = combine_constraint_to_odcs(constraint),
    list()
  )
}

#' @keywords internal
#' @noRd
numeric_range_to_odcs <- function(c) {
  out <- list(logicalType = "number")
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
string_length_to_odcs <- function(c) {
  out <- list(logicalType = "string")
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
vector_length_to_odcs <- function(c) {
  out <- list(logicalType = "array")
  if (!is.null(c$exact_len)) {
    out$minItems <- c$exact_len
    out$maxItems <- c$exact_len
  } else {
    if (!is.null(c$min_len) && c$min_len > 0) out$minItems <- c$min_len
    if (!is.null(c$max_len) && is.finite(c$max_len)) {
      out$maxItems <- c$max_len
    }
  }
  out
}

#' @keywords internal
#' @noRd
combine_constraint_to_odcs <- function(c) {
  parts <- lapply(c$parts, function(p) {
    if (is.null(p)) {
      list(`x-typethis-kind` = "predicate")
    } else {
      constraint_to_odcs(p)
    }
  })
  Reduce(merge_odcs, parts, accumulate = FALSE)
}

#' @keywords internal
#' @noRd
merge_odcs <- function(base, refinement) {
  if (length(refinement) == 0L) return(base)
  if (length(base) == 0L) return(refinement)
  out <- base
  for (key in names(refinement)) {
    if (identical(key, "logicalType") && !is.null(out$logicalType)) next
    out[[key]] <- refinement[[key]]
  }
  out
}

# ---------------------------------------------------------------------------
# Internals: import
# ---------------------------------------------------------------------------

#' @keywords internal
#' @noRd
odcs_properties_to_fields <- function(properties, ctx) {
  if (length(properties) == 0L) return(list())

  fields <- list()
  for (prop in properties) {
    if (is.null(prop$name)) {
      stop("ODCS property is missing a `name`", call. = FALSE)
    }
    fields[[prop$name]] <- odcs_property_to_field(prop, ctx)
  }
  fields
}

#' @keywords internal
#' @noRd
odcs_property_to_field <- function(prop, ctx) {
  type_arg <- odcs_to_type_spec_or_name(prop, ctx)
  validator <- odcs_to_validator(prop)

  nullable <- isFALSE(prop$required) && is.null(prop$default) &&
    !isTRUE(prop$primaryKey)

  field(
    type = type_arg,
    default = prop$default,
    validator = validator,
    nullable = nullable,
    description = prop$description %||% "",
    primary_key = isTRUE(prop$primaryKey),
    unique = isTRUE(prop$unique),
    pii = isTRUE(prop$pii),
    classification = prop$classification,
    tags = if (!is.null(prop$tags)) unlist(prop$tags) else NULL,
    examples = prop$examples,
    references = prop$references,
    quality = prop$quality
  )
}

#' @keywords internal
#' @noRd
odcs_to_type_spec_or_name <- function(prop, ctx) {
  logical_type <- prop$logicalType %||% "string"

  if (!is.null(prop[["$ref"]])) {
    ref <- prop[["$ref"]]
    name <- sub("^#/schema/", "", ref)
    return(t_model(name))
  }

  if (logical_type == "object" && !is.null(prop$properties)) {
    nested_name <- prop$name %||% paste0("Anon", as.integer(Sys.time()))
    nested_fields <- odcs_properties_to_fields(prop$properties, ctx)
    if (isTRUE(ctx$register)) {
      define_model_in(nested_name, nested_fields, ctx$envir)
    }
    return(t_model(nested_name))
  }

  if (logical_type == "array") {
    inner <- if (!is.null(prop$items)) {
      odcs_to_type_spec_or_name(prop$items, ctx)
    } else {
      "character"
    }
    return(t_list_of(
      type = inner,
      min_length = prop$minItems %||% 0,
      max_length = prop$maxItems %||% Inf
    ))
  }

  if (!is.null(prop$enum)) {
    return(t_enum(unlist(prop$enum)))
  }

  builtin_from_logical(logical_type)
}

#' @keywords internal
#' @noRd
builtin_from_logical <- function(logical_type) {
  switch(logical_type,
    "string"    = "character",
    "text"      = "character",
    "integer"   = "integer",
    "long"      = "integer",
    "number"    = "numeric",
    "decimal"   = "numeric",
    "boolean"   = "logical",
    "date"      = "date",
    "timestamp" = "posixct",
    "object"    = "list",
    "array"     = "list",
    "character"
  )
}

#' @keywords internal
#' @noRd
odcs_to_validator <- function(prop) {
  validators <- list()

  if (!is.null(prop$minimum) || !is.null(prop$maximum) ||
        !is.null(prop$exclusiveMinimum) || !is.null(prop$exclusiveMaximum)) {
    validators <- c(validators, list(numeric_range(
      min = prop$exclusiveMinimum %||% prop$minimum %||% -Inf,
      max = prop$exclusiveMaximum %||% prop$maximum %||% Inf,
      exclusive_min = !is.null(prop$exclusiveMinimum),
      exclusive_max = !is.null(prop$exclusiveMaximum)
    )))
  }
  if (!is.null(prop$minLength) || !is.null(prop$maxLength)) {
    validators <- c(validators, list(string_length(
      min_length = prop$minLength %||% 0,
      max_length = prop$maxLength %||% Inf
    )))
  }
  if (!is.null(prop$pattern)) {
    validators <- c(validators, list(string_pattern(prop$pattern)))
  }

  if (length(validators) == 0L) return(NULL)
  if (length(validators) == 1L) return(validators[[1L]])
  do.call(combine_validators, c(validators, list(all_of = TRUE)))
}

#' @keywords internal
#' @noRd
define_model_in <- function(class_name, fields, envir) {
  # Stash fields under the registry directly, then build constructors in
  # the requested environment. This avoids relying on parent.frame() lookup
  # from inside an internal helper.
  registry <- getOption("typethis_model_registry", list())
  registry[[class_name]] <- list(
    fields = fields,
    validate = TRUE,
    strict = FALSE
  )
  options(typethis_model_registry = registry)

  field_names <- names(fields)
  new_func <- function(...) {
    values <- list(...)
    for (fname in field_names) {
      if (!(fname %in% names(values))) {
        fd <- fields[[fname]]
        if (!is.null(fd$default)) values[[fname]] <- fd$default
      }
    }
    missing_required <- character(0)
    for (fname in field_names) {
      fd <- fields[[fname]]
      if (!(fname %in% names(values)) &&
            is.null(fd$default) && !isTRUE(fd$nullable)) {
        missing_required <- c(missing_required, fname)
      }
    }
    if (length(missing_required) > 0L) {
      stop(sprintf("Missing required fields for %s: %s",
                   class_name,
                   paste(missing_required, collapse = ", ")),
           call. = FALSE)
    }
    for (fname in names(values)) {
      if (fname %in% field_names) {
        validate_field_value(fname, values[[fname]],
                             fields[[fname]], class_name)
      }
    }
    structure(
      values,
      class = c(class_name, "typed_model", "list"),
      schema = fields,
      strict = FALSE,
      model_class_name = class_name
    )
  }
  attr(new_func, "fields") <- fields
  attr(new_func, "model_class") <- TRUE
  attr(new_func, "class_name") <- class_name

  update_func <- function(instance, ...) {
    if (!inherits(instance, class_name)) {
      stop(sprintf("Expected %s instance, got %s",
                   class_name, class(instance)[1]), call. = FALSE)
    }
    updates <- list(...)
    for (fname in names(updates)) instance[[fname]] <- updates[[fname]]
    for (fname in names(updates)) {
      if (fname %in% field_names) {
        validate_field_value(fname, instance[[fname]],
                             fields[[fname]], class_name)
      }
    }
    instance
  }

  assign(paste0("new_", class_name), new_func, envir = envir)
  assign(paste0("update_", class_name), update_func, envir = envir)
  invisible(NULL)
}

# ---------------------------------------------------------------------------
# Internals: CLI
# ---------------------------------------------------------------------------

#' @keywords internal
#' @noRd
cli_run <- function(args, ...) {
  if (!datacontract_cli_available()) {
    stop(
      "datacontract CLI not found on PATH. Install via ",
      "`pip install datacontract-cli`.",
      call. = FALSE
    )
  }
  cli_invoke(args, ...)
}

#' @keywords internal
#' @noRd
cli_invoke <- function(args, ...) {
  out_file <- tempfile()
  err_file <- tempfile()
  on.exit({
    unlink(out_file)
    unlink(err_file)
  }, add = TRUE)

  status <- system2("datacontract", args = args,
                    stdout = out_file, stderr = err_file, ...)
  list(
    success = identical(as.integer(status), 0L),
    status = as.integer(status),
    stdout = readLines(out_file, warn = FALSE),
    stderr = readLines(err_file, warn = FALSE)
  )
}

#' @keywords internal
#' @noRd
ensure_yaml <- function() {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop(
      "The 'yaml' package is required for Data Contract YAML support. ",
      "Install via install.packages('yaml').",
      call. = FALSE
    )
  }
}
