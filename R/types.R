#' Type System for typethis
#'
#' @description
#' Core type system definitions for static type checking in R.
#' Supports basic types, complex types, and R-specific types.
#'
#' @name types
NULL

#' Create a type object
#'
#' @param base_type Character string of base type (e.g., "integer", "numeric")
#' @param nullable Logical indicating if NULL is allowed
#' @param ... Additional attributes for complex types
#' @return A type object
#' @export
create_type <- function(base_type, nullable = FALSE, ...) {
  structure(
    list(
      base_type = base_type,
      nullable = nullable,
      attributes = list(...)
    ),
    class = "rtype"
  )
}

#' Print method for rtype
#' @param x An rtype object
#' @param ... Additional arguments (unused)
#' @export
print.rtype <- function(x, ...) {
  type_str <- x$base_type
  if (x$nullable) {
    type_str <- paste0(type_str, " | NULL")
  }
  if (length(x$attributes) > 0) {
    attr_str <- paste(
      names(x$attributes), x$attributes,
      sep = "=", collapse = ", "
    )
    type_str <- paste0(type_str, "[", attr_str, "]")
  }
  cat("Type:", type_str, "\n")
  invisible(x)
}

#' Standard R type definitions
#' @export
TYPES <- list(
  # Basic types
  integer = create_type("integer"),
  numeric = create_type("numeric"),
  double = create_type("double"),
  character = create_type("character"),
  logical = create_type("logical"),
  complex = create_type("complex"),
  raw = create_type("raw"),

  # Special types
  `NULL` = create_type("NULL"),
  any = create_type("any"),
  unknown = create_type("unknown"),

  # Container types
  list = create_type("list"),
  vector = create_type("vector"),

  # Data frame types
  data.frame = create_type("data.frame"),
  data.table = create_type("data.table"),
  tibble = create_type("tibble"),

  # Function type
  `function` = create_type("function"),

  # Formula type
  formula = create_type("formula"),

  # S3/S4/R6
  S3 = create_type("S3"),
  S4 = create_type("S4"),
  R6 = create_type("R6"),

  # Environment
  environment = create_type("environment")
)

#' Check if object is of expected type
#'
#' @param obj Object to check
#' @param expected_type Expected type (rtype object or string)
#' @return Logical indicating if types match
#' @export
type_matches <- function(obj, expected_type) {
  if (is.character(expected_type)) {
    expected_type <- TYPES[[expected_type]]
  }

  if (is.null(expected_type)) {
    return(FALSE)
  }

  # Handle nullable
  if (is.null(obj) && expected_type$nullable) {
    return(TRUE)
  }

  if (is.null(obj) && !expected_type$nullable) {
    return(FALSE)
  }

  # Handle "any" type
  if (expected_type$base_type == "any") {
    return(TRUE)
  }

  # Basic type checking
  actual_type <- class(obj)[1]

  # Handle numeric vs double vs integer
  if (expected_type$base_type == "numeric" && is.numeric(obj)) {
    return(TRUE)
  }

  if (expected_type$base_type == "integer" && is.integer(obj)) {
    return(TRUE)
  }

  if (expected_type$base_type == "double" && is.double(obj)) {
    return(TRUE)
  }

  # Direct class match
  if (expected_type$base_type == actual_type) {
    return(TRUE)
  }

  # Check inheritance
  if (expected_type$base_type %in% class(obj)) {
    return(TRUE)
  }

  FALSE
}

#' Create a data.table type with column specifications
#'
#' @param ... Named arguments specifying column types
#' @return An rtype object for data.table
#' @export
#' @examples
#' \dontrun{
#' dt_type <- data_table_type(
#'   id = "integer",
#'   name = "character",
#'   value = "numeric"
#' )
#' }
data_table_type <- function(...) {
  cols <- list(...)
  create_type("data.table", columns = cols)
}

#' Create a function type with signature
#'
#' @param args List of argument types
#' @param return_type Return type
#' @return An rtype object for function
#' @export
#' @examples
#' \dontrun{
#' fn_type <- function_type(
#'   args = list(x = "integer"),
#'   return_type = "numeric"
#' )
#' }
function_type <- function(args = list(), return_type = "any") {
  create_type("function", args = args, return_type = return_type)
}
