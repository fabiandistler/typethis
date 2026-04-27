#' OpenAPI 3.1 bridge
#'
#' @description
#' Convert typed models and typed functions to and from [OpenAPI 3.1
#' documents](https://spec.openapis.org/oas/v3.1.0). OpenAPI 3.1 is
#' JSON-Schema-Draft-2020-12-compatible, so the schema fragments produced
#' by [to_json_schema()] are lifted directly into `components.schemas`;
#' `$ref` strings are rewritten from `#/$defs/X` to
#' `#/components/schemas/X`. Typed functions become a single `paths` entry
#' whose `requestBody` carries the arguments as a JSON object and whose
#' `200` response carries the return type.
#'
#' Key entry points:
#'
#' - [to_openapi()] / [write_openapi()] — export.
#' - [read_openapi()] / [from_openapi()] — import.
#'
#' @name openapi
#' @family OpenAPI
NULL

openapi_version <- "3.1.0"

# ---------------------------------------------------------------------------
# Public API: export
# ---------------------------------------------------------------------------

#' Export typed models or typed functions to OpenAPI 3.1
#'
#' Builds an OpenAPI 3.1 document fragment from typed models, typed
#' functions, or a mixed list. Schemas are produced via [to_json_schema()]
#' and lifted into `components.schemas`; `$ref` strings are rewritten from
#' the JSON Schema convention (`#/$defs/X`) to the OpenAPI convention
#' (`#/components/schemas/X`). Typed functions become a single `paths`
#' entry with a JSON `requestBody` carrying the arguments and a `200`
#' response carrying the return type.
#'
#' To control the path and operation ID for a typed function, set
#' `attr(fn, "openapi_op_id") <- "yourId"` before passing it in.
#'
#' @param x A model class name (character scalar), a model constructor or
#'   instance, a typed function, or a list mixing any of the above.
#' @param info Optional named list with OpenAPI `info` fields (`title`,
#'   `version`, `description`, ...). Sensible defaults are filled in.
#' @param paths Optional named list of additional `paths` entries to merge
#'   in (e.g. for typed functions added by name).
#' @param ... Forwarded to method dispatch.
#' @return A list ready for `yaml::write_yaml()` or `jsonlite::toJSON()`.
#' @family OpenAPI
#' @seealso [write_openapi()] for the file-IO convenience wrapper;
#'   [from_openapi()] for the reverse direction; [to_json_schema()] for
#'   the underlying schema export.
#' @export
#' @examples
#' define_model("User", fields = list(
#'   id   = field("integer", primary_key = TRUE),
#'   name = field("character")
#' ))
#' doc <- to_openapi("User",
#'   info = list(title = "Users API", version = "1.0.0"))
#' names(doc)
#' names(doc$components$schemas)
to_openapi <- function(x, info = NULL, paths = NULL, ...) {
  UseMethod("to_openapi")
}

#' @export
to_openapi.default <- function(x, info = NULL, paths = NULL, ...) {
  if (is.character(x)) {
    return(build_openapi(x, info = info, paths = paths))
  }
  if (is.function(x)) {
    if (isTRUE(attr(x, "model_class"))) {
      cls <- attr(x, "class_name") %||% "Model"
      return(build_openapi(cls, info = info, paths = paths))
    }
    if (isTRUE(attr(x, "typed"))) {
      return(build_openapi_from_function(x, info = info, paths = paths, ...))
    }
  }
  stop(
    "to_openapi(): expected a model class name, constructor, instance, ",
    "or typed function.",
    call. = FALSE
  )
}

#' @export
to_openapi.typed_model <- function(x, info = NULL, paths = NULL, ...) {
  cls <- attr(x, "model_class_name") %||% "Model"
  build_openapi(cls, info = info, paths = paths)
}

#' @export
to_openapi.list <- function(x, info = NULL, paths = NULL, ...) {
  resolved <- lapply(x, resolve_openapi_entry)
  models <- character(0)
  fn_paths <- list()
  for (entry in resolved) {
    if (entry$kind == "model") {
      models <- c(models, entry$name)
    } else if (entry$kind == "function") {
      fn_paths <- c(fn_paths, list(entry))
    }
  }
  doc <- build_openapi(models, info = info, paths = paths)
  for (entry in fn_paths) {
    doc <- merge_function_into_openapi(doc, entry$fn,
                                       path = entry$path,
                                       op_id = entry$name)
  }
  doc
}

#' Write an OpenAPI document to disk
#'
#' Convenience wrapper around [to_openapi()] + the appropriate writer
#' (`yaml::write_yaml()` for YAML, `jsonlite::toJSON()` for JSON). The
#' output format is inferred from the file extension and can be overridden.
#'
#' @param x See [to_openapi()].
#' @param path Destination file path. Use `.yaml`/`.yml` for YAML output
#'   or `.json` for JSON.
#' @param info,paths,... Forwarded to [to_openapi()].
#' @param format Output format: `"yaml"` (default for `.yaml`/`.yml`) or
#'   `"json"` (default for `.json`). Defaults to YAML if the extension is
#'   ambiguous.
#' @return The OpenAPI document list, invisibly.
#' @family OpenAPI
#' @export
#' @examples
#' if (requireNamespace("yaml", quietly = TRUE)) {
#'   define_model("User", fields = list(
#'     id   = field("integer", primary_key = TRUE),
#'     name = field("character")
#'   ))
#'   tmp <- tempfile(fileext = ".yaml")
#'   write_openapi("User", tmp,
#'     info = list(title = "Users API", version = "1.0.0"))
#'   readLines(tmp, n = 5)
#' }
write_openapi <- function(x, path, info = NULL, paths = NULL,
                          format = NULL, ...) {
  doc <- to_openapi(x, info = info, paths = paths, ...)
  fmt <- format %||% openapi_format_from_path(path)
  if (identical(fmt, "json")) {
    ensure_jsonlite()
    writeLines(
      jsonlite::toJSON(doc, auto_unbox = TRUE, pretty = TRUE, null = "null"),
      path
    )
  } else {
    ensure_yaml()
    yaml::write_yaml(doc, path)
  }
  invisible(doc)
}

# ---------------------------------------------------------------------------
# Public API: import
# ---------------------------------------------------------------------------

#' Read an OpenAPI document into an R list
#'
#' Pure parsing helper — does not register anything. Use [from_openapi()]
#' for the full import pipeline.
#'
#' @param path File path or URL.
#' @return Parsed OpenAPI list.
#' @family OpenAPI
#' @export
read_openapi <- function(path) {
  fmt <- openapi_format_from_path(path)
  if (grepl("^https?://", path)) {
    tmp <- tempfile(fileext = paste0(".", fmt))
    on.exit(unlink(tmp), add = TRUE)
    utils::download.file(path, tmp, quiet = TRUE)
    path <- tmp
  }
  if (identical(fmt, "json")) {
    ensure_jsonlite()
    jsonlite::fromJSON(path, simplifyVector = FALSE)
  } else {
    ensure_yaml()
    yaml::read_yaml(path)
  }
}

#' Import OpenAPI components into the typethis model registry
#'
#' Reads an OpenAPI 3.x document (file path, URL, or already-parsed list)
#' and calls [define_model()] for every entry under `components.schemas`.
#' Nested `object` properties with their own `properties` block are
#' registered as their own typed models so that [t_model()] references
#' resolve correctly. After import, the generated `new_*()` and
#' `update_*()` constructors are available in `envir`.
#'
#' @param x Path, URL, or parsed list.
#' @param register If `TRUE` (default), define the models; if `FALSE`,
#'   only parse and return the resolved field definitions on the result
#'   attribute.
#' @param envir Environment in which `new_<Class>()` / `update_<Class>()`
#'   constructors are assigned. Defaults to the calling environment.
#' @return Character vector of registered model class names, invisibly.
#' @family OpenAPI
#' @export
#' @examples
#' if (requireNamespace("yaml", quietly = TRUE)) {
#'   define_model("User", fields = list(
#'     id   = field("integer", primary_key = TRUE),
#'     name = field("character")
#'   ))
#'   tmp <- tempfile(fileext = ".yaml")
#'   write_openapi("User", tmp,
#'     info = list(title = "Users API", version = "1.0.0"))
#'
#'   env <- new.env()
#'   from_openapi(tmp, envir = env)
#'   ls(env)  # new_User, update_User
#' }
from_openapi <- function(x, register = TRUE, envir = parent.frame()) {
  doc <- if (is.list(x)) x else read_openapi(x)

  schemas <- doc$components$schemas
  if (is.null(schemas) || !is.list(schemas) || length(schemas) == 0L) {
    stop("OpenAPI document has no `components.schemas` section",
         call. = FALSE)
  }

  ctx <- list(envir = envir, register = isTRUE(register))
  registered <- character(0)
  collected_fields <- list()

  for (class_name in names(schemas)) {
    schema <- schemas[[class_name]]
    fields_list <- openapi_schema_to_fields(schema, ctx)
    collected_fields[[class_name]] <- fields_list
    if (isTRUE(register)) {
      define_model_in(class_name, fields_list, envir)
    }
    registered <- c(registered, class_name)
  }

  if (!isTRUE(register)) {
    attr(registered, "fields") <- collected_fields
  }
  invisible(registered)
}

# ---------------------------------------------------------------------------
# Internals: build the OpenAPI document
# ---------------------------------------------------------------------------

#' @keywords internal
#' @noRd
build_openapi <- function(class_names, info = NULL, paths = NULL) {
  fallback <- class_names[1] %||% "typethis API"
  info <- normalise_openapi_info(info, fallback_title = fallback)

  components_schemas <- list()
  for (name in unique(class_names)) {
    schema <- to_json_schema(name)
    pieces <- split_top_level_schema(schema)
    components_schemas[[name]] <- pieces$body
    for (def_name in names(pieces$defs)) {
      if (is.null(components_schemas[[def_name]])) {
        components_schemas[[def_name]] <- pieces$defs[[def_name]]
      }
    }
  }
  components_schemas <- lapply(components_schemas, rewrite_refs_to_components)

  doc <- list(
    openapi = openapi_version,
    info = info,
    components = list(schemas = components_schemas)
  )
  if (!is.null(paths) && length(paths) > 0L) {
    doc$paths <- paths
  }
  doc
}

#' @keywords internal
#' @noRd
build_openapi_from_function <- function(fn, info = NULL, paths = NULL,
                                        path = NULL, op_id = NULL,
                                        method = "post", ...) {
  info <- normalise_openapi_info(info, fallback_title = "typethis function")
  doc <- build_openapi(character(0), info = info)
  merge_function_into_openapi(doc, fn, path = path, op_id = op_id,
                              method = method)
}

#' @keywords internal
#' @noRd
merge_function_into_openapi <- function(doc, fn, path = NULL, op_id = NULL,
                                        method = "post") {
  sig <- get_signature(fn)
  if (is.null(sig)) {
    stop("merge_function_into_openapi(): not a typed function", call. = FALSE)
  }
  op_id <- op_id %||% "operation"
  path <- path %||% paste0("/", op_id)
  method <- tolower(method)

  defs_env <- new_defs_env()
  request_props <- list()
  required <- character(0)
  for (arg_name in names(sig$args)) {
    spec <- sig$args[[arg_name]]
    request_props[[arg_name]] <- spec_to_inline_schema(spec, defs_env)
    formal_val <- as.list(sig$formals)[[arg_name]]
    has_no_default <- tryCatch(
      is.symbol(formal_val) && as.character(formal_val) == "",
      error = function(e) TRUE
    )
    if (isTRUE(has_no_default)) required <- c(required, arg_name)
  }
  request_schema <- list(
    type = "object",
    properties = request_props
  )
  if (length(required) > 0L) request_schema$required <- as.list(required)

  response_schema <- if (!is.null(sig$return)) {
    spec_to_inline_schema(sig$return, defs_env)
  } else {
    list(description = "No declared return type")
  }

  # Lift any def references discovered while inlining into components.schemas
  schemas <- doc$components$schemas %||% list()
  for (def_name in names(defs_env$.defs)) {
    if (is.null(schemas[[def_name]])) {
      schemas[[def_name]] <- rewrite_refs_to_components(
        defs_env$.defs[[def_name]]
      )
    }
  }
  doc$components$schemas <- schemas

  request_schema <- rewrite_refs_to_components(request_schema)
  response_schema <- rewrite_refs_to_components(response_schema)

  operation <- list(
    operationId = op_id,
    requestBody = list(
      required = TRUE,
      content = list(
        `application/json` = list(schema = request_schema)
      )
    ),
    responses = list(
      `200` = list(
        description = "Successful response",
        content = list(
          `application/json` = list(schema = response_schema)
        )
      )
    )
  )

  doc$paths <- doc$paths %||% list()
  doc$paths[[path]] <- doc$paths[[path]] %||% list()
  doc$paths[[path]][[method]] <- operation
  doc
}

#' @keywords internal
#' @noRd
spec_to_inline_schema <- function(spec, defs_env) {
  if (is.null(spec)) return(list())
  if (inherits(spec, "type_spec")) {
    return(type_spec_to_json_schema(spec, defs_env))
  }
  if (is.character(spec) && length(spec) == 1L) {
    registry <- getOption("typethis_model_registry", list())
    if (spec %in% names(registry)) {
      return(model_ref_to_json_schema(spec, defs_env))
    }
    return(builtin_to_json_schema(spec))
  }
  if (is.function(spec)) {
    constraint <- attr(spec, "constraint")
    if (!is.null(constraint)) return(constraint_to_json_schema(constraint))
    return(list(`x-typethis-kind` = "predicate"))
  }
  list()
}

#' @keywords internal
#' @noRd
split_top_level_schema <- function(schema) {
  defs <- schema$`$defs` %||% list()
  schema$`$defs` <- NULL
  schema$`$schema` <- NULL
  list(body = schema, defs = defs)
}

#' @keywords internal
#' @noRd
rewrite_refs_to_components <- function(x) {
  if (is.list(x)) {
    if (!is.null(x[["$ref"]]) && is.character(x[["$ref"]])) {
      x[["$ref"]] <- sub("^#/\\$defs/", "#/components/schemas/", x[["$ref"]])
    }
    x[] <- lapply(x, rewrite_refs_to_components)
  }
  x
}

#' @keywords internal
#' @noRd
normalise_openapi_info <- function(info, fallback_title) {
  info <- info %||% list()
  if (is.null(info$title))   info$title   <- fallback_title
  if (is.null(info$version)) info$version <- "0.1.0"
  info
}

#' @keywords internal
#' @noRd
resolve_openapi_entry <- function(entry) {
  if (is.character(entry) && length(entry) == 1L) {
    return(list(kind = "model", name = entry))
  }
  if (is_model(entry)) {
    return(list(kind = "model",
                name = attr(entry, "model_class_name") %||% "Model"))
  }
  if (is.function(entry)) {
    if (isTRUE(attr(entry, "model_class"))) {
      return(list(kind = "model",
                  name = attr(entry, "class_name") %||% "Model"))
    }
    if (isTRUE(attr(entry, "typed"))) {
      op_id <- attr(entry, "openapi_op_id") %||% "operation"
      path <- attr(entry, "openapi_path") %||% paste0("/", op_id)
      return(list(kind = "function", fn = entry, name = op_id, path = path))
    }
  }
  stop("to_openapi(): unsupported list entry", call. = FALSE)
}

# ---------------------------------------------------------------------------
# Internals: import (OpenAPI schema -> typethis fields)
# ---------------------------------------------------------------------------

#' @keywords internal
#' @noRd
openapi_schema_to_fields <- function(schema, ctx) {
  if (!identical(schema$type, "object") || is.null(schema$properties)) {
    return(list())
  }
  required <- as.character(schema$required %||% character(0))
  fields <- list()
  for (prop_name in names(schema$properties)) {
    prop <- schema$properties[[prop_name]]
    fields[[prop_name]] <- openapi_property_to_field(
      prop_name, prop,
      required = prop_name %in% required,
      ctx = ctx
    )
  }
  fields
}

#' @keywords internal
#' @noRd
openapi_property_to_field <- function(prop_name, prop, required, ctx) {
  type_arg <- openapi_to_type_spec_or_name(prop_name, prop, ctx)
  validator <- openapi_to_validator(prop)
  nullable <- !isTRUE(required) && is.null(prop$default)

  field(
    type = type_arg,
    default = prop$default,
    validator = validator,
    nullable = nullable,
    description = prop$description %||% "",
    examples = prop$examples
  )
}

#' @keywords internal
#' @noRd
openapi_to_type_spec_or_name <- function(prop_name, prop, ctx) {
  if (!is.null(prop[["$ref"]])) {
    ref <- prop[["$ref"]]
    name <- sub("^#/components/schemas/", "", ref)
    return(t_model(name))
  }

  type <- prop$type %||% "string"

  if (identical(type, "object") && !is.null(prop$properties)) {
    fallback <- paste0("Anon", as.integer(Sys.time()))
    nested_name <- prop$title %||% prop_name %||% fallback
    nested_fields <- openapi_schema_to_fields(prop, ctx)
    if (isTRUE(ctx$register)) {
      define_model_in(nested_name, nested_fields, ctx$envir)
    }
    return(t_model(nested_name))
  }

  if (identical(type, "array")) {
    inner <- if (!is.null(prop$items)) {
      openapi_to_type_spec_or_name(prop_name, prop$items, ctx)
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

  builtin_from_openapi_type(type, prop$format)
}

#' @keywords internal
#' @noRd
builtin_from_openapi_type <- function(type, format = NULL) {
  if (identical(type, "string")) {
    if (identical(format, "date")) return("date")
    if (identical(format, "date-time")) return("posixct")
    return("character")
  }
  switch(type,
    "integer" = "integer",
    "number"  = "numeric",
    "boolean" = "logical",
    "array"   = "list",
    "object"  = "list",
    "character"
  )
}

#' @keywords internal
#' @noRd
openapi_to_validator <- function(prop) {
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

# ---------------------------------------------------------------------------
# Internals: misc
# ---------------------------------------------------------------------------

#' @keywords internal
#' @noRd
openapi_format_from_path <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext %in% c("yaml", "yml")) return("yaml")
  if (ext == "json") return("json")
  "yaml"
}

#' @keywords internal
#' @noRd
ensure_jsonlite <- function() {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop(
      "The 'jsonlite' package is required for OpenAPI JSON support. ",
      "Install via install.packages('jsonlite').",
      call. = FALSE
    )
  }
}
