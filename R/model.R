#' Type-Safe Models
#'
#' @description
#' Create type-safe data models similar to Pydantic in Python.
#' Models validate data structure and types at creation time.

#' Define a typed model schema
#'
#' @description
#' Two API styles are supported:
#'
#' **New-style (v0.2+)**: `define_model("ClassName", fields = list(...))`
#' Creates `new_ClassName()` and `update_ClassName()` functions in the
#' calling environment.
#'
#' **Old-style**: `define_model(name = "type", ...)`
#' Returns a constructor function that creates model instances.
#'
#' @param ... For new-style: first argument is class name (character).
#'           For old-style: field definitions (name = type or name = field())
#' @param fields Named list of field definitions (new-style only)
#' @param .validate Enable validation on creation
#' @param .strict Strict mode - no extra fields allowed
#' @return For old-style: Model class constructor.
#'         For new-style: invisibly NULL (functions assigned to calling env)
#' @export
#' @examples
#' # New-style API (v0.2+)
#' define_model("Person",
#'   fields = list(
#'     name = field("character", nullable = FALSE),
#'     age = field("integer", nullable = FALSE, default = 0L)
#'   )
#' )
#' p <- new_Person(name = "Alice", age = 30L)
#' p2 <- update_Person(p, age = 31L)
#'
#' # Old-style API (backward compatible)
#' User <- define_model(
#'   name = "character",
#'   age = "numeric",
#'   email = "character",
#'   .validate = TRUE
#' )
#' user <- User(name = "John", age = 30, email = "john@example.com")
define_model <- function(..., fields = NULL, .validate = TRUE,
                         .strict = FALSE) {
  args <- list(...)
  arg_names <- names(args)

  # Detect new-style API:
  # - First argument is UNNAMED character string (class name)
  # - Old-style has all named arguments
  first_arg_unnamed <- is.null(arg_names) || arg_names[1] == ""

  if (length(args) >= 1 && first_arg_unnamed &&
        is.character(args[[1]]) && length(args[[1]]) == 1) {
    class_name <- args[[1]]

    # Get fields from explicit fields argument or from remaining ... args
    if (!is.null(fields)) {
      field_defs <- fields
    } else if (length(args) > 1) {
      # Remaining args after class name should be named field definitions
      field_defs <- args[-1]
    } else {
      stop(
        "New-style define_model() requires 'fields' argument",
        " or named field definitions"
      )
    }

    # Dispatch to new-style implementation
    define_model_new_style(class_name, field_defs, .validate, .strict)
    return(invisible(NULL))
  }

  # Old-style API: all args are field definitions (all named)
  field_names <- arg_names
  fields <- args # Use args instead of fields for old-style

  if (is.null(field_names) || any(field_names == "")) {
    stop("All fields must be named")
  }

  # Create model constructor (old-style)
  constructor <- function(..., .validate_instance = .validate) {
    values <- list(...)
    value_names <- names(values)

    # Check for missing required fields
    required_fields <- field_names
    missing <- setdiff(required_fields, value_names)

    # Handle default values
    for (fname in field_names) {
      if (!(fname %in% value_names)) {
        field_def <- fields[[fname]]
        if (is.list(field_def) && !is.null(field_def$default)) {
          values[[fname]] <- field_def$default
        }
      }
    }

    # Check again for missing required fields
    missing <- setdiff(required_fields, names(values))
    if (length(missing) > 0) {
      # Check if missing fields have defaults
      missing_no_default <- character(0)
      for (fname in missing) {
        field_def <- fields[[fname]]
        if (!is.list(field_def) || is.null(field_def$default)) {
          missing_no_default <- c(missing_no_default, fname)
        }
      }

      if (length(missing_no_default) > 0) {
        stop(sprintf(
          "Missing required fields: %s",
          paste(missing_no_default, collapse = ", ")
        ), call. = FALSE)
      }
    }

    # Check for extra fields in strict mode
    if (.strict) {
      extra <- setdiff(value_names, field_names)
      if (length(extra) > 0) {
        stop(sprintf(
          "Extra fields not allowed: %s",
          paste(extra, collapse = ", ")
        ), call. = FALSE)
      }
    }

    # Validate each field
    if (.validate_instance) {
      for (fname in names(values)) {
        if (fname %in% field_names) {
          field_def <- fields[[fname]]
          value <- values[[fname]]

          # Extract type and validator
          if (is.list(field_def)) {
            field_type <- field_def$type
            validator <- field_def$validator
          } else {
            field_type <- field_def
            validator <- NULL
          }

          # Type check
          if (!is.null(field_type)) {
            assert_type(value, field_type, fname)
          }

          # Custom validator
          if (!is.null(validator) && is.function(validator)) {
            if (!validator(value)) {
              stop(sprintf(
                "Validation failed for field '%s'",
                fname
              ), call. = FALSE)
            }
          }
        }
      }
    }

    # Create model instance
    instance <- structure(
      values,
      class = c("typed_model", "list"),
      schema = fields,
      strict = .strict
    )

    instance
  }

  # Add metadata
  attr(constructor, "fields") <- fields
  attr(constructor, "strict") <- .strict
  attr(constructor, "model_class") <- TRUE

  constructor
}

#' @noRd
define_model_new_style <- function(class_name, fields,
                                   .validate = TRUE, .strict = FALSE) {
  field_names <- names(fields)

  if (is.null(field_names) || any(field_names == "")) {
    stop("All fields must be named")
  }

  # Validate each field definition
  for (fname in field_names) {
    field_def <- fields[[fname]]
    # type_spec IS a list — must be detected before the generic list branch
    if (!is.list(field_def) || inherits(field_def, "type_spec") ||
          is.function(field_def)) {
      # Convert simple type spec to field definition
      fields[[fname]] <- list(type = field_def, nullable = FALSE)
    } else if (is.null(field_def$type)) {
      stop(sprintf("Field '%s' must have a 'type' specification", fname))
    }
  }

  # Store model schema in a registry for nested model support
  model_registry <- getOption("typethis_model_registry", list())
  model_registry[[class_name]] <- list(
    fields = fields,
    validate = .validate,
    strict = .strict
  )
  options(typethis_model_registry = model_registry)

  # Create new_<ClassName>() constructor function
  new_func_name <- paste0("new_", class_name)
  new_func <- function(...) {
    # Capture arguments
    values <- list(...)
    value_names <- names(values)

    # Handle default values
    for (fname in field_names) {
      if (!(fname %in% value_names)) {
        field_def <- fields[[fname]]
        if (!is.null(field_def$default)) {
          values[[fname]] <- field_def$default
        }
      }
    }

    # Check for missing required fields
    missing <- setdiff(field_names, names(values))
    if (length(missing) > 0) {
      # Check if missing fields have defaults
      missing_no_default <- character(0)
      for (fname in missing) {
        field_def <- fields[[fname]]
        if (is.null(field_def$default) && !isTRUE(field_def$nullable)) {
          missing_no_default <- c(missing_no_default, fname)
        }
      }

      if (length(missing_no_default) > 0) {
        stop(sprintf(
          "Missing required fields for %s: %s",
          class_name,
          paste(missing_no_default, collapse = ", ")
        ), call. = FALSE)
      }
    }

    # Check for extra fields in strict mode
    if (.strict) {
      extra <- setdiff(value_names, field_names)
      if (length(extra) > 0) {
        stop(sprintf(
          "Extra fields not allowed for %s: %s",
          class_name,
          paste(extra, collapse = ", ")
        ), call. = FALSE)
      }
    }

    # Validate each field
    if (.validate) {
      for (fname in names(values)) {
        if (fname %in% field_names) {
          field_def <- fields[[fname]]
          value <- values[[fname]]

          validate_field_value(fname, value, field_def, class_name)
        }
      }
    }

    # Create model instance with class-specific S3 class
    instance <- structure(
      values,
      class = c(class_name, "typed_model", "list"),
      schema = fields,
      strict = .strict,
      model_class_name = class_name
    )

    instance
  }

  # Add metadata to constructor
  attr(new_func, "fields") <- fields
  attr(new_func, "strict") <- .strict
  attr(new_func, "model_class") <- TRUE
  attr(new_func, "class_name") <- class_name

  # Create update_<ClassName>() function
  update_func_name <- paste0("update_", class_name)
  update_func <- function(instance, ...) {
    if (!inherits(instance, class_name)) {
      stop(sprintf(
        "Expected %s instance, got %s",
        class_name, class(instance)[1]
      ))
    }

    updates <- list(...)

    # Merge updates onto instance fields
    for (fname in names(updates)) {
      if (fname %in% field_names) {
        instance[[fname]] <- updates[[fname]]
      } else if (.strict) {
        stop(sprintf("Field '%s' not in %s schema", fname, class_name))
      } else {
        instance[[fname]] <- updates[[fname]]
      }
    }

    # Revalidate all fields that were updated
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

  # Assign functions to calling environment
  caller_env <- parent.frame(2)
  assign(new_func_name, new_func, envir = caller_env)
  assign(update_func_name, update_func, envir = caller_env)

  invisible(NULL)
}

#' Validate a field value against its definition
#' @param fname Field name
#' @param value Field value
#' @param field_def Field definition list
#' @param class_name Model class name for error messages
#' @keywords internal
validate_field_value <- function(fname, value, field_def,
                                 class_name = "model") {
  field_type <- field_def$type
  nullable <- isTRUE(field_def$nullable)
  validator <- field_def$validator

  # Handle NULL values
  if (is.null(value)) {
    if (!nullable) {
      stop(sprintf(
        "Field '%s' in %s cannot be NULL (nullable = FALSE)",
        fname, class_name
      ), call. = FALSE)
    }
    return(invisible(TRUE))
  }

  # Composite type_spec: dispatch through assert_type directly
  if (inherits(field_type, "type_spec")) {
    assert_type(value, field_type, fname)
  } else if (is.character(field_type) && length(field_type) == 1L) {
    # Check if type refers to a registered model class (nested model support)
    model_registry <- getOption("typethis_model_registry", list())
    if (field_type %in% names(model_registry)) {
      # Validate as nested model
      if (!is_model(value)) {
        stop(sprintf(
          "Field '%s' in %s must be a typed model, got %s",
          fname, class_name, class(value)[1]
        ), call. = FALSE)
      }
      if (!inherits(value, field_type)) {
        stop(sprintf(
          "Field '%s' in %s must be of class '%s', got '%s'",
          fname, class_name, field_type, class(value)[1]
        ), call. = FALSE)
      }
    } else {
      assert_type(value, field_type, fname)
    }
  } else if (!is.null(field_type)) {
    # Function predicate or other — delegate to assert_type
    assert_type(value, field_type, fname)
  }

  # Custom validator
  if (!is.null(validator) && is.function(validator)) {
    if (!validator(value)) {
      stop(sprintf(
        "Validation failed for field '%s' in %s",
        fname, class_name
      ), call. = FALSE)
    }
  }

  invisible(TRUE)
}

#' Define a field with validation and defaults
#'
#' @param type Type specification. Accepts a character builtin name
#'   (`"numeric"`, `"character"`, ...), a registered model class name,
#'   a predicate function, or a composite spec built with `t_union()`,
#'   `t_list_of()`, `t_nullable()`, `t_enum()`, `t_model()`, etc.
#' @param default Default value.
#' @param validator Custom validator function.
#' @param nullable Allow NULL values.
#' @param description Field description.
#' @param primary_key Logical. Field is part of the primary key. ODCS metadata
#'   only — has no effect on runtime validation.
#' @param unique Logical. Values must be unique. ODCS metadata only.
#' @param pii Logical. Field contains personally identifiable information.
#'   ODCS metadata only.
#' @param classification Optional character scalar (e.g. `"public"`,
#'   `"internal"`, `"confidential"`). ODCS metadata only.
#' @param tags Optional character vector of free-form tags.
#' @param examples Optional list/vector of example values for documentation.
#' @param references Optional named list `list(model = "Order", field = "id")`
#'   describing a foreign-key style reference. ODCS metadata only.
#' @param quality Optional list of quality checks (each a named list with
#'   `type`, `description`, and engine-specific keys like `query`).
#' @return Field specification.
#' @export
#' @examples
#' field("numeric", default = 0, validator = function(x) x >= 0)
#' field(t_union("integer", "character"))
#' field(t_list_of("character"), default = list())
#' field(t_enum(c("admin", "user")))
#' field("character", primary_key = TRUE, pii = TRUE,
#'       classification = "confidential")
field <- function(type, default = NULL, validator = NULL,
                  nullable = FALSE, description = "",
                  primary_key = FALSE, unique = FALSE,
                  pii = FALSE, classification = NULL,
                  tags = NULL, examples = NULL,
                  references = NULL, quality = NULL) {
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

#' Check if object is a typed model
#'
#' @param x Object to check
#' @return logical
#' @export
is_model <- function(x) {
  inherits(x, "typed_model")
}

#' Get model schema
#'
#' @param model Model instance or constructor
#' @return Schema definition
#' @export
#' @examples
#' User <- define_model(name = "character", age = "numeric")
#' user <- User(name = "John", age = 30)
#' get_schema(user)
#' get_schema(User)
get_schema <- function(model) {
  if (is_model(model)) {
    attr(model, "schema")
  } else if (is.function(model) && isTRUE(attr(model, "model_class"))) {
    attr(model, "fields")
  } else {
    NULL
  }
}

#' Validate model instance
#'
#' @param instance Model instance
#' @return list with valid (logical) and errors (character vector)
#' @export
#' @examples
#' User <- define_model(name = "character", age = "numeric")
#' user <- User(name = "John", age = 30, .validate_instance = FALSE)
#' validate_model(user)
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

      # Extract type and validator
      if (is.list(field_def)) {
        field_type <- field_def$type
        validator <- field_def$validator
      } else {
        field_type <- field_def
        validator <- NULL
      }

      # Type validation
      if (!is.null(field_type)) {
        validation <- validate_type(value, field_type, fname)
        if (!validation$valid) {
          errors <- c(errors, validation$error)
        }
      }

      # Custom validator
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

#' Convert model to list
#'
#' @param model Model instance
#' @return list
#' @export
model_to_list <- function(model) {
  if (!is_model(model)) {
    stop("Not a typed model")
  }

  as.list(model)
}

#' Update model fields
#'
#' @param model Model instance
#' @param ... Fields to update
#' @param .validate Validate after update
#' @return Updated model instance
#' @export
#' @examples
#' User <- define_model(name = "character", age = "numeric")
#' user <- User(name = "John", age = 30)
#' user <- update_model(user, age = 31)
update_model <- function(model, ..., .validate = TRUE) {
  if (!is_model(model)) {
    stop("Not a typed model")
  }

  updates <- list(...)
  schema <- attr(model, "schema")

  # Update fields
  for (fname in names(updates)) {
    if (fname %in% names(schema)) {
      value <- updates[[fname]]

      # Validate if needed
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

#' Print method for typed models
#'
#' @param x Model instance
#' @param ... Additional arguments
#' @export
print.typed_model <- function(x, ...) {
  # Get class name if available (new-style models)
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
