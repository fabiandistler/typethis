#' Define a typed data model
#'
#' @description
#' Defines a model class — a record type with named fields, types, optional
#' validators, defaults, and nullability — and creates two helpers in the
#' calling environment:
#'
#' - `new_<ClassName>()` — constructor. Validates each argument against
#'   the field spec and applies defaults.
#' - `update_<ClassName>(instance, …)` — returns a copy with the named
#'   fields replaced and revalidated.
#'
#' Define each field with [field()]; pass them as a named list to `fields`.
#' Fields can use any type accepted elsewhere in `typethis` (builtin
#' character names, predicate functions, registered model class names,
#' or composite [type_spec][type_spec] objects).
#'
#' @param ... The class name as the first positional argument (a single
#'   character scalar). Field definitions can also be passed here as
#'   `name = field(...)` arguments instead of via `fields`.
#' @param fields Named list of field definitions built with [field()] (or
#'   bare type names).
#' @param .validate If `FALSE`, validation is skipped on construction
#'   (useful for hot paths).
#' @param .strict If `TRUE`, the constructor rejects unknown fields.
#' @return Invisibly `NULL`. The constructor and updater are assigned in
#'   the calling environment.
#' @family typed models
#' @seealso [field()] for declaring a field; [validate_model()] /
#'   [model_to_list()] / [update_model()] / [get_schema()] for working
#'   with instances; [t_model()] for referencing a model from another
#'   field.
#' @export
#' @examples
#' define_model("User", fields = list(
#'   name  = field("character"),
#'   age   = field("integer", validator = numeric_range(0, 120),
#'                 default = 0L),
#'   email = field("character",
#'                 validator = string_pattern("^[^@]+@[^@]+$"))
#' ))
#'
#' u <- new_User(name = "Ada", email = "ada@example.com")
#' u$age   # default applied
#'
#' u2 <- update_User(u, age = 36L)
#' u2$age
#'
#' # Strict mode rejects unknown fields
#' define_model("StrictPoint", fields = list(
#'   x = field("numeric"),
#'   y = field("numeric")
#' ), .strict = TRUE)
#'
#' tryCatch(
#'   new_StrictPoint(x = 1, y = 2, z = 3),
#'   error = function(e) conditionMessage(e)
#' )
define_model <- function(
  ...,
  fields = NULL,
  .validate = TRUE,
  .strict = FALSE
) {
  args <- list(...)
  arg_names <- names(args)

  first_arg_unnamed <- is.null(arg_names) || arg_names[1] == ""

  if (
    length(args) >= 1 &&
      first_arg_unnamed &&
      is.character(args[[1]]) &&
      length(args[[1]]) == 1
  ) {
    class_name <- args[[1]]

    if (!is.null(fields)) {
      field_defs <- fields
    } else if (length(args) > 1) {
      field_defs <- args[-1]
    } else {
      stop(
        "define_model() requires either a `fields` argument",
        " or named field definitions"
      )
    }

    define_model_new_style(class_name, field_defs, .validate, .strict)
    return(invisible(NULL))
  }

  # Legacy: define_model(name = "type", ...) returning a constructor.
  # Kept for backward compatibility; not part of the documented API.
  field_names <- arg_names
  fields <- args

  if (is.null(field_names) || any(field_names == "")) {
    stop("All fields must be named")
  }

  constructor <- function(..., .validate_instance = .validate) {
    values <- list(...)
    value_names <- names(values)

    required_fields <- field_names
    missing <- setdiff(required_fields, value_names)

    for (fname in field_names) {
      if (!(fname %in% value_names)) {
        field_def <- fields[[fname]]
        if (is.list(field_def) && !is.null(field_def$default)) {
          values[[fname]] <- field_def$default
        }
      }
    }

    missing <- setdiff(required_fields, names(values))
    if (length(missing) > 0) {
      missing_no_default <- character(0)
      for (fname in missing) {
        field_def <- fields[[fname]]
        if (!is.list(field_def) || is.null(field_def$default)) {
          missing_no_default <- c(missing_no_default, fname)
        }
      }

      if (length(missing_no_default) > 0) {
        stop(
          sprintf(
            "Missing required fields: %s",
            paste(missing_no_default, collapse = ", ")
          ),
          call. = FALSE
        )
      }
    }

    if (.strict) {
      extra <- setdiff(value_names, field_names)
      if (length(extra) > 0) {
        stop(
          sprintf(
            "Extra fields not allowed: %s",
            paste(extra, collapse = ", ")
          ),
          call. = FALSE
        )
      }
    }

    if (.validate_instance) {
      for (fname in names(values)) {
        if (fname %in% field_names) {
          field_def <- fields[[fname]]
          value <- values[[fname]]

          if (is.list(field_def)) {
            field_type <- field_def$type
            validator <- field_def$validator
          } else {
            field_type <- field_def
            validator <- NULL
          }

          if (!is.null(field_type)) {
            assert_type(value, field_type, fname)
          }

          if (!is.null(validator) && is.function(validator)) {
            if (!validator(value)) {
              stop(
                sprintf(
                  "Validation failed for field '%s'",
                  fname
                ),
                call. = FALSE
              )
            }
          }
        }
      }
    }

    structure(
      values,
      class = c("typed_model", "list"),
      schema = fields,
      strict = .strict
    )
  }

  attr(constructor, "fields") <- fields
  attr(constructor, "strict") <- .strict
  attr(constructor, "model_class") <- TRUE

  constructor
}

#' @noRd
define_model_new_style <- function(
  class_name,
  fields,
  .validate = TRUE,
  .strict = FALSE
) {
  field_names <- names(fields)

  if (is.null(field_names) || any(field_names == "")) {
    stop("All fields must be named")
  }

  for (fname in field_names) {
    field_def <- fields[[fname]]
    if (
      !is.list(field_def) ||
        inherits(field_def, "type_spec") ||
        is.function(field_def)
    ) {
      fields[[fname]] <- list(type = field_def, nullable = FALSE)
    } else if (is.null(field_def$type)) {
      stop(sprintf("Field '%s' must have a 'type' specification", fname))
    }
  }

  model_registry <- getOption("typethis_model_registry", list())
  model_registry[[class_name]] <- list(
    fields = fields,
    validate = .validate,
    strict = .strict
  )
  options(typethis_model_registry = model_registry)

  new_func_name <- paste0("new_", class_name)
  new_func <- function(...) {
    values <- list(...)
    value_names <- names(values)

    for (fname in field_names) {
      if (!(fname %in% value_names)) {
        field_def <- fields[[fname]]
        if (!is.null(field_def$default)) {
          values[[fname]] <- field_def$default
        }
      }
    }

    missing <- setdiff(field_names, names(values))
    if (length(missing) > 0) {
      missing_no_default <- character(0)
      for (fname in missing) {
        field_def <- fields[[fname]]
        if (is.null(field_def$default) && !isTRUE(field_def$nullable)) {
          missing_no_default <- c(missing_no_default, fname)
        }
      }

      if (length(missing_no_default) > 0) {
        stop(
          sprintf(
            "Missing required fields for %s: %s",
            class_name,
            paste(missing_no_default, collapse = ", ")
          ),
          call. = FALSE
        )
      }
    }

    if (.strict) {
      extra <- setdiff(value_names, field_names)
      if (length(extra) > 0) {
        stop(
          sprintf(
            "Extra fields not allowed for %s: %s",
            class_name,
            paste(extra, collapse = ", ")
          ),
          call. = FALSE
        )
      }
    }

    if (.validate) {
      for (fname in names(values)) {
        if (fname %in% field_names) {
          field_def <- fields[[fname]]
          value <- values[[fname]]

          validate_field_value(fname, value, field_def, class_name)
        }
      }
    }

    structure(
      values,
      class = c(class_name, "typed_model", "list"),
      schema = fields,
      strict = .strict,
      model_class_name = class_name
    )
  }

  attr(new_func, "fields") <- fields
  attr(new_func, "strict") <- .strict
  attr(new_func, "model_class") <- TRUE
  attr(new_func, "class_name") <- class_name

  update_func_name <- paste0("update_", class_name)
  update_func <- function(instance, ...) {
    if (!inherits(instance, class_name)) {
      stop(sprintf(
        "Expected %s instance, got %s",
        class_name,
        class(instance)[1]
      ))
    }

    updates <- list(...)

    for (fname in names(updates)) {
      if (fname %in% field_names) {
        instance[[fname]] <- updates[[fname]]
      } else if (.strict) {
        stop(sprintf("Field '%s' not in %s schema", fname, class_name))
      } else {
        instance[[fname]] <- updates[[fname]]
      }
    }

    if (.validate) {
      for (fname in names(updates)) {
        if (fname %in% field_names) {
          field_def <- fields[[fname]]
          value <- instance[[fname]]

          validate_field_value(fname, value, field_def, class_name)
        }
      }
    }

    instance
  }

  caller_env <- parent.frame(2)
  assign(new_func_name, new_func, envir = caller_env)
  assign(update_func_name, update_func, envir = caller_env)

  invisible(NULL)
}

#' Validate a single field value against its definition
#'
#' Internal helper used by [define_model()] and the generated `update_*()`
#' functions. Exported for advanced use cases (custom model machinery).
#'
#' @param fname Field name (used only for error messages).
#' @param value Value to validate.
#' @param field_def Field definition list, as produced by [field()].
#' @param class_name Owning model class name (used only for error messages).
#' @return `invisible(TRUE)` on success; an error otherwise.
#' @keywords internal
validate_field_value <- function(
  fname,
  value,
  field_def,
  class_name = "model"
) {
  field_type <- field_def$type
  nullable <- isTRUE(field_def$nullable)
  validator <- field_def$validator

  if (is.null(value)) {
    if (!nullable) {
      stop(
        sprintf(
          "Field '%s' in %s cannot be NULL (nullable = FALSE)",
          fname,
          class_name
        ),
        call. = FALSE
      )
    }
    return(invisible(TRUE))
  }

  if (inherits(field_type, "type_spec")) {
    assert_type(value, field_type, fname)
  } else if (is.character(field_type) && length(field_type) == 1L) {
    model_registry <- getOption("typethis_model_registry", list())
    if (field_type %in% names(model_registry)) {
      if (!is_model(value)) {
        stop(
          sprintf(
            "Field '%s' in %s must be a typed model, got %s",
            fname,
            class_name,
            class(value)[1]
          ),
          call. = FALSE
        )
      }
      if (!inherits(value, field_type)) {
        stop(
          sprintf(
            "Field '%s' in %s must be of class '%s', got '%s'",
            fname,
            class_name,
            field_type,
            class(value)[1]
          ),
          call. = FALSE
        )
      }
    } else {
      assert_type(value, field_type, fname)
    }
  } else if (!is.null(field_type)) {
    assert_type(value, field_type, fname)
  }

  if (!is.null(validator) && is.function(validator)) {
    if (!validator(value)) {
      stop(
        sprintf(
          "Validation failed for field '%s' in %s",
          fname,
          class_name
        ),
        call. = FALSE
      )
    }
  }

  invisible(TRUE)
}

#' Define a model field
#'
#' Builds a field definition for use inside [define_model()]. A field
#' carries a type, optional default, optional validator, and optional
#' nullability — plus a number of metadata slots (`primary_key`, `pii`,
#' `tags`, ...) that travel through the [to_datacontract()] /
#' [to_openapi()] / [to_json_schema()] bridges but have no effect on
#' runtime validation.
#'
#' `type` accepts:
#'
#' - A character builtin name (`"numeric"`, `"character"`, `"integer"`, ...).
#' - A predicate function `function(value) -> logical`.
#' - A registered model class name (string).
#' - Any [type_spec][type_spec] built with `t_*()`.
#'
#' @param type Type specification.
#' @param default Default value when the field is omitted at construction.
#' @param validator Optional value-level validator function.
#' @param nullable If `TRUE`, the field accepts `NULL`.
#' @param description Free-text description; surfaces in JSON Schema and
#'   ODCS export.
#' @param primary_key Logical. ODCS metadata only.
#' @param unique Logical. ODCS metadata only.
#' @param pii Logical. ODCS metadata only.
#' @param classification Optional classification label
#'   (`"public"`, `"internal"`, `"confidential"`, ...). ODCS metadata only.
#' @param tags Optional character vector of free-form tags.
#' @param examples Optional list/vector of example values.
#' @param references Optional named list `list(model = "Order", field = "id")`
#'   describing a foreign-key style reference. ODCS metadata only.
#' @param quality Optional list of quality checks (each a named list with
#'   `type`, `description`, and engine-specific keys like `query`).
#' @return A field definition (named list).
#' @family typed models
#' @export
#' @examples
#' field("numeric", default = 0)
#' field("integer", validator = numeric_range(0, 120))
#' field(t_union("integer", "character"))
#' field(t_list_of("character"), default = list())
#' field(t_enum(c("admin", "user")))
#' field("character", primary_key = TRUE, pii = TRUE,
#'       classification = "confidential")
field <- function(
  type,
  default = NULL,
  validator = NULL,
  nullable = FALSE,
  description = "",
  primary_key = FALSE,
  unique = FALSE,
  pii = FALSE,
  classification = NULL,
  tags = NULL,
  examples = NULL,
  references = NULL,
  quality = NULL
) {
  list(
    type = type,
    default = default,
    validator = validator,
    nullable = nullable,
    description = description,
    primary_key = isTRUE(primary_key),
    unique = isTRUE(unique),
    pii = isTRUE(pii),
    classification = classification,
    tags = tags,
    examples = examples,
    references = references,
    quality = quality
  )
}

#' Test whether an object is a typed model instance
#'
#' @param x Object to test.
#' @return `TRUE` or `FALSE`.
#' @family typed models
#' @export
#' @examples
#' define_model("Tag", fields = list(name = field("character")))
#' is_model(new_Tag(name = "alpha"))
#' is_model(list(name = "alpha"))
is_model <- function(x) {
  inherits(x, "typed_model")
}

#' Retrieve a model's schema
#'
#' Returns the named list of field definitions for a model instance or
#' constructor. `NULL` for objects that aren't models.
#'
#' @param model Model instance or constructor.
#' @return Named list of field definitions, or `NULL`.
#' @family typed models
#' @export
#' @examples
#' define_model("Person", fields = list(
#'   name = field("character"),
#'   age  = field("integer")
#' ))
#' p <- new_Person(name = "Ada", age = 36L)
#' names(get_schema(p))
get_schema <- function(model) {
  if (is_model(model)) {
    attr(model, "schema")
  } else if (is.function(model) && isTRUE(attr(model, "model_class"))) {
    attr(model, "fields")
  } else {
    NULL
  }
}

#' Validate a model instance against its schema
#'
#' Runs every field through type and validator checks and returns a list
#' `list(valid, errors)` rather than throwing.
#'
#' @param instance A model instance.
#' @return Named list `list(valid, errors)`. `errors` is `NULL` on success.
#' @family typed models
#' @export
#' @examples
#' define_model("Person", fields = list(
#'   name = field("character"),
#'   age  = field("integer", validator = numeric_range(0, 120))
#' ))
#' p <- new_Person(name = "Ada", age = 36L)
#' validate_model(p)
validate_model <- function(instance) {
  if (!is_model(instance)) {
    return(list(valid = FALSE, errors = "Not a typed model"))
  }

  schema <- attr(instance, "schema")
  errors <- character(0)

  for (fname in names(schema)) {
    if (fname %in% names(instance)) {
      field_def <- schema[[fname]]
      value <- instance[[fname]]

      if (is.list(field_def)) {
        field_type <- field_def$type
        validator <- field_def$validator
      } else {
        field_type <- field_def
        validator <- NULL
      }

      if (!is.null(field_type)) {
        validation <- validate_type(value, field_type, fname)
        if (!validation$valid) {
          errors <- c(errors, validation$error)
        }
      }

      if (!is.null(validator) && is.function(validator)) {
        if (!validator(value)) {
          errors <- c(
            errors,
            sprintf("Validation failed for field '%s'", fname)
          )
        }
      }
    }
  }

  list(
    valid = length(errors) == 0,
    errors = if (length(errors) > 0) errors else NULL
  )
}

#' Convert a typed model instance to a plain list
#'
#' @param model A model instance.
#' @return A plain list with the model's field values.
#' @family typed models
#' @export
#' @examples
#' define_model("Point", fields = list(
#'   x = field("numeric"),
#'   y = field("numeric")
#' ))
#' p <- new_Point(x = 1, y = 2)
#' model_to_list(p)
model_to_list <- function(model) {
  if (!is_model(model)) {
    stop("Not a typed model")
  }

  as.list(model)
}

#' Update fields on a typed model instance
#'
#' Generic alternative to the class-specific `update_<ClassName>()` produced
#' by [define_model()]. Returns a new instance with the named fields
#' replaced and (by default) revalidated.
#'
#' @param model A model instance.
#' @param ... Fields to update, as `name = value`.
#' @param .validate If `FALSE`, skip revalidation.
#' @return Updated model instance.
#' @family typed models
#' @seealso The class-specific `update_<ClassName>()` constructor created by
#'   [define_model()] preserves the S3 class chain and is preferred when
#'   available.
#' @export
#' @examples
#' define_model("Person", fields = list(
#'   name = field("character"),
#'   age  = field("integer")
#' ))
#' p <- new_Person(name = "Ada", age = 36L)
#' update_model(p, age = 37L)$age
update_model <- function(model, ..., .validate = TRUE) {
  if (!is_model(model)) {
    stop("Not a typed model")
  }

  updates <- list(...)
  schema <- attr(model, "schema")

  for (fname in names(updates)) {
    if (fname %in% names(schema)) {
      value <- updates[[fname]]

      if (.validate) {
        field_def <- schema[[fname]]

        if (is.list(field_def)) {
          field_type <- field_def$type
          validator <- field_def$validator
        } else {
          field_type <- field_def
          validator <- NULL
        }

        if (!is.null(field_type)) {
          assert_type(value, field_type, fname)
        }

        if (!is.null(validator) && is.function(validator)) {
          if (!validator(value)) {
            stop(sprintf("Validation failed for field '%s'", fname))
          }
        }
      }

      model[[fname]] <- value
    } else if (attr(model, "strict")) {
      stop(sprintf("Field '%s' not in schema", fname))
    } else {
      model[[fname]] <- updates[[fname]]
    }
  }

  model
}

#' Print method for typed model instances
#'
#' @param x Model instance.
#' @param ... Unused.
#' @return Invisibly `x`.
#' @family typed models
#' @export
#' @examples
#' define_model("Point", fields = list(
#'   x = field("numeric"),
#'   y = field("numeric")
#' ))
#' new_Point(x = 1, y = 2)
print.typed_model <- function(x, ...) {
  class_name <- attr(x, "model_class_name")
  if (!is.null(class_name)) {
    cat(sprintf("<Typed Model: %s>\n", class_name))
  } else {
    cat("<Typed Model>\n")
  }
  cat("Fields:\n")

  for (name in names(x)) {
    value <- x[[name]]
    type <- class(value)[1]
    cat(sprintf("  %s: %s = ", name, type))

    if (is.atomic(value) && length(value) <= 3) {
      cat(paste(value, collapse = ", "))
    } else {
      cat(sprintf("<%s of length %d>", type, length(value)))
    }
    cat("\n")
  }

  invisible(x)
}
