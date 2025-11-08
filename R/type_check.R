#' Core Type Checking Functions
#'
#' @description
#' Provides fundamental type checking capabilities for R objects.
#' Similar to mypy/pydantic for Python.

#' Check if a value matches a type specification
#'
#' @param value The value to check
#' @param type The expected type (character or function)
#' @param nullable Allow NULL values
#' @return logical indicating if value matches type
#' @export
#' @examples
#' is_type(5, "numeric")
#' is_type("hello", "character")
#' is_type(NULL, "numeric", nullable = TRUE)
is_type <- function(value, type, nullable = FALSE) {
  if (is.null(value)) {
    return(nullable)
  }

  if (is.function(type)) {
    return(type(value))
  }

  if (is.character(type)) {
    return(check_builtin_type(value, type))
  }

  stop("Type must be a character string or function")
}

#' Check builtin R types
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

#' Assert that a value has the correct type
#'
#' @param value The value to check
#' @param type The expected type
#' @param name Variable name for error messages
#' @param nullable Allow NULL values
#' @return invisible(TRUE) or throws error
#' @export
#' @examples
#' assert_type(5, "numeric", "my_var")
#' \dontrun{
#' assert_type("hello", "numeric", "my_var")  # throws error
#' }
assert_type <- function(value, type, name = "value", nullable = FALSE) {
  if (!is_type(value, type, nullable)) {
    actual_type <- class(value)[1]
    expected_type <- if (is.function(type)) deparse(substitute(type)) else type
    stop(sprintf(
      "Type error: '%s' must be %s, got %s",
      name, expected_type, actual_type
    ), call. = FALSE)
  }
  invisible(TRUE)
}

#' Validate type with detailed error message
#'
#' @param value The value to check
#' @param type The expected type
#' @param name Variable name
#' @param nullable Allow NULL
#' @return list with valid (logical) and error (character or NULL)
#' @export
#' @examples
#' validate_type(5, "numeric", "x")
#' validate_type("hello", "numeric", "x")
validate_type <- function(value, type, name = "value", nullable = FALSE) {
  if (is_type(value, type, nullable)) {
    return(list(valid = TRUE, error = NULL))
  }

  actual_type <- class(value)[1]
  expected_type <- if (is.function(type)) deparse(substitute(type)) else type
  error_msg <- sprintf(
    "Type error: '%s' must be %s, got %s",
    name, expected_type, actual_type
  )

  list(valid = FALSE, error = error_msg)
}

#' Check multiple type constraints
#'
#' @param value The value to check
#' @param types Vector of allowed types
#' @return logical
#' @export
#' @examples
#' is_one_of(5, c("numeric", "character"))
#' is_one_of("hello", c("numeric", "character"))
is_one_of <- function(value, types) {
  any(sapply(types, function(t) is_type(value, t)))
}

#' Type coercion with validation
#'
#' @param value The value to coerce
#' @param type Target type
#' @param strict If TRUE, fail on coercion warnings
#' @return Coerced value or error
#' @export
#' @examples
#' coerce_type("123", "numeric")
#' coerce_type(c(1, 2, 3), "character")
coerce_type <- function(value, type, strict = FALSE) {
  if (is_type(value, type)) {
    return(value)
  }

  tryCatch({
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
  }, error = function(e) {
    stop(sprintf("Failed to coerce to %s: %s", type, e$message), call. = FALSE)
  })
}
