#' Test whether a value matches a type
#'
#' Returns `TRUE` if `value` matches `type`, `FALSE` otherwise. `type` may
#' be a builtin name (`"numeric"`, `"character"`, ...), a registered model
#' class, a predicate function, or a [type_spec][type_spec] built with the
#' `t_*()` constructors.
#'
#' @param value Value to test.
#' @param type Expected type — character, function, or `type_spec`.
#' @param nullable If `TRUE`, `NULL` matches as well.
#' @return `TRUE` or `FALSE`.
#' @family type checking
#' @export
#' @examples
#' is_type(5, "numeric")
#' is_type("hello", "character")
#' is_type(NULL, "numeric")
#' is_type(NULL, "numeric", nullable = TRUE)
#' is_type(1L, t_union("integer", "character"))
is_type <- function(value, type, nullable = FALSE) {
  if (inherits(type, "type_spec")) {
    if (is.null(value)) {
      return(nullable || identical(type$kind, "nullable") ||
               identical(type$kind, "union") &&
                 any(vapply(type$alternatives,
                            function(a) identical(a$kind, "nullable"),
                            logical(1))))
    }
    return(check_type_spec(value, type))
  }

  if (is.null(value)) {
    return(nullable)
  }

  if (is.function(type)) {
    return(type(value))
  }

  if (is.character(type)) {
    return(check_builtin_type(value, type))
  }

  stop("Type must be a character string, function, or type_spec")
}

#' @noRd
check_builtin_type <- function(value, type) {
  switch(type,
    "numeric" = is.numeric(value),
    "integer" = is.integer(value),
    "double" = is.double(value),
    "character" = is.character(value),
    "logical" = is.logical(value),
    "list" = is.list(value),
    "data.frame" = is.data.frame(value),
    "matrix" = is.matrix(value),
    "factor" = is.factor(value),
    "date" = inherits(value, "Date"),
    "posixct" = inherits(value, "POSIXct"),
    "function" = is.function(value),
    "environment" = is.environment(value),
    stop(sprintf("Unknown type: %s", type))
  )
}

#' Assert that a value has an expected type
#'
#' Throws an informative error if `value` does not match `type`. Use this
#' at function boundaries to fail fast with a useful message.
#'
#' @param value Value to test.
#' @param type Expected type — character, function, or `type_spec`.
#' @param name Variable name used in the error message.
#' @param nullable If `TRUE`, `NULL` is accepted.
#' @return `invisible(TRUE)` on success; an error otherwise.
#' @family type checking
#' @seealso [is_type()] for a non-throwing check; [validate_type()] to get
#'   the message back as data.
#' @export
#' @examples
#' assert_type(5, "numeric", "x")
#'
#' err <- tryCatch(
#'   assert_type("hello", "numeric", "x"),
#'   error = function(e) conditionMessage(e)
#' )
#' err
assert_type <- function(value, type, name = "value", nullable = FALSE) {
  if (!is_type(value, type, nullable)) {
    actual_type <- class(value)[1]
    expected_type <- format_type_label(type, substitute(type))
    stop(sprintf(
      "Type error: '%s' must be %s, got %s",
      name, expected_type, actual_type
    ), call. = FALSE)
  }
  invisible(TRUE)
}

#' @keywords internal
#' @noRd
format_type_label <- function(type, sub) {
  if (inherits(type, "type_spec")) {
    return(format(type))
  }
  if (is.function(type)) {
    return(deparse(sub))
  }
  as.character(type)
}

#' Validate a value's type and return a structured result
#'
#' Like [assert_type()] but returns a list `list(valid, error)` instead of
#' throwing. Use it when you want to collect or inspect errors rather than
#' stop execution.
#'
#' @param value Value to test.
#' @param type Expected type — character, function, or `type_spec`.
#' @param name Variable name used in the error message.
#' @param nullable If `TRUE`, `NULL` is accepted.
#' @return Named list with `valid` (logical) and `error` (character or `NULL`).
#' @family type checking
#' @export
#' @examples
#' validate_type(5, "numeric", "x")
#' validate_type("hello", "numeric", "x")
validate_type <- function(value, type, name = "value", nullable = FALSE) {
  if (is_type(value, type, nullable)) {
    return(list(valid = TRUE, error = NULL))
  }

  actual_type <- class(value)[1]
  expected_type <- format_type_label(type, substitute(type))
  error_msg <- sprintf(
    "Type error: '%s' must be %s, got %s",
    name, expected_type, actual_type
  )

  list(valid = FALSE, error = error_msg)
}

#' Test whether a value matches any of several types
#'
#' Convenience wrapper around [is_type()] for checking against a vector of
#' alternatives. For a structured spec that you can also use with
#' [typed_function()] and [field()], see [t_union()].
#'
#' @param value Value to test.
#' @param types Character vector of types (or list of type specs).
#' @return `TRUE` if `value` matches at least one entry in `types`.
#' @family type checking
#' @seealso [t_union()] for a composable equivalent that works as a type
#'   specification.
#' @export
#' @examples
#' is_one_of(5, c("numeric", "character"))
#' is_one_of("hello", c("numeric", "character"))
#' is_one_of(TRUE, c("numeric", "character"))
is_one_of <- function(value, types) {
  any(sapply(types, function(t) is_type(value, t)))
}

#' Coerce a value to a target type
#'
#' Attempts to convert `value` to `type` using the standard `as.*()`
#' coercions. With `strict = TRUE`, coercion that introduces `NA` (e.g.
#' `as.numeric("abc")`) raises an error instead of returning silently.
#'
#' Composite type specs are supported for the kinds where coercion has a
#' clear meaning: [t_nullable()] (NULL passes through, otherwise the inner
#' spec drives coercion), [t_union()] (each alternative is tried in order),
#' and [t_enum()] (values already in the allowed set pass through; otherwise
#' the value is coerced to the enum's value type and re-checked).
#'
#' @param value Value to coerce.
#' @param type Target type — character builtin, or a supported `type_spec`.
#' @param strict If `TRUE`, fail when coercion introduces `NA`.
#' @return The coerced value.
#' @family type checking
#' @export
#' @examples
#' coerce_type("123", "numeric")
#' coerce_type(c(1, 2, 3), "character")
#' coerce_type("yes", "logical")
#'
#' err <- tryCatch(
#'   coerce_type("abc", "numeric", strict = TRUE),
#'   error = function(e) conditionMessage(e)
#' )
#' err
coerce_type <- function(value, type, strict = FALSE) {
  if (inherits(type, "type_spec")) {
    return(coerce_type_spec(value, type, strict = strict))
  }

  if (is_type(value, type)) {
    return(value)
  }

  tryCatch(
    {
      result <- switch(type,
        "numeric" = as.numeric(value),
        "integer" = as.integer(value),
        "double" = as.double(value),
        "character" = as.character(value),
        "logical" = as.logical(value),
        "factor" = as.factor(value),
        "date" = as.Date(value),
        stop(sprintf("Cannot coerce to type: %s", type))
      )

      if (strict && any(is.na(result) & !is.na(value))) {
        stop(sprintf("Coercion to %s resulted in NA values", type))
      }

      result
    },
    error = function(e) {
      stop(sprintf(
        "Failed to coerce to %s: %s",
        type, e$message
      ), call. = FALSE)
    }
  )
}

#' Coerce a value to a `type_spec`
#'
#' Supports `t_nullable()` (NULL passes through, otherwise recurses on the
#' inner spec), `t_union()` (tries each alternative in order, returns the
#' first that coerces and validates), and `t_enum()` (accepts the value if
#' it is — possibly after coercion to the enum's value type — in the
#' allowed set). Other `type_spec` kinds (model_ref, list_of, vector_of,
#' predicate) are not supported and signal a clear error.
#'
#' @keywords internal
#' @noRd
coerce_type_spec <- function(value, spec, strict) {
  switch(spec$kind,
    "builtin" = coerce_type(value, spec$name, strict = strict),
    "nullable" = if (is.null(value)) {
      NULL
    } else {
      coerce_type_spec(value, spec$inner, strict = strict)
    },
    "union" = coerce_union(value, spec$alternatives, strict),
    "enum"  = coerce_enum(value, spec, strict),
    stop(sprintf(
      "coerce_type() does not support type_spec kind '%s'", spec$kind
    ), call. = FALSE)
  )
}

#' @keywords internal
#' @noRd
coerce_union <- function(value, alternatives, strict) {
  for (alt in alternatives) {
    success <- TRUE
    result <- tryCatch(
      coerce_type_spec(value, alt, strict = strict),
      error = function(e) {
        success <<- FALSE
        NULL
      }
    )
    if (success && is_type(result, alt)) {
      return(result)
    }
  }
  stop(sprintf(
    "Failed to coerce to union<%s>: no alternative matched",
    paste(vapply(alternatives, format, character(1)), collapse = ", ")
  ), call. = FALSE)
}

#' @keywords internal
#' @noRd
coerce_enum <- function(value, spec, strict) {
  if (all(value %in% spec$values)) {
    return(value)
  }
  coerced <- tryCatch(
    coerce_type(value, spec$value_type, strict = strict),
    error = function(e) NULL
  )
  if (!is.null(coerced) && all(coerced %in% spec$values)) {
    return(coerced)
  }
  stop(sprintf(
    "Failed to coerce to enum<%s>: value not in allowed set",
    paste(utils::head(as.character(spec$values), 5L), collapse = ", ")
  ), call. = FALSE)
}
