#' Type-Safe Models
#'
#' @description
#' Create type-safe data models similar to Pydantic in Python.
#' Models validate data structure and types at creation time.

#' Define a typed model schema
#'
#' @param ... Field definitions (name = type or name = field())
#' @param .validate Enable validation on creation
#' @param .strict Strict mode - no extra fields allowed
#' @return Model class constructor
#' @export
#' @examples
#' User <- define_model(
#'   name = "character",
#'   age = "numeric",
#'   email = "character",
#'   .validate = TRUE
#' )
#'
#' user <- User(name = "John", age = 30, email = "john@example.com")
define_model <- function(..., .validate = TRUE, .strict = FALSE) {
  fields <- list(...)
  field_names <- names(fields)

  if (is.null(field_names) || any(field_names == "")) {
    stop("All fields must be named")
  }

  # Create model constructor
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

#' Define a field with validation and defaults
#'
#' @param type Type specification
#' @param default Default value
#' @param validator Custom validator function
#' @param nullable Allow NULL values
#' @param description Field description
#' @return Field specification
#' @export
#' @examples
#' field("numeric", default = 0, validator = function(x) x >= 0)
field <- function(type, default = NULL, validator = NULL,
                 nullable = FALSE, description = "") {
  list(
    type = type,
    default = default,
    validator = validator,
    nullable = nullable,
    description = description
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
          errors <- c(errors, sprintf("Validation failed for field '%s'", fname))
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
  cat("<Typed Model>\n")
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
