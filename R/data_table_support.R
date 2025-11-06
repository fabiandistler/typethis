#' data.table Type Support
#'
#' @description
#' Special support for data.table operations and types.
#' Handles NSE (non-standard evaluation) in data.table syntax.
#'
#' @name data_table_support
NULL

#' Infer data.table operation result type
#'
#' @param dt_type Type of the input data.table
#' @param operation The operation being performed (e.g., "[", ":=")
#' @param ... Operation arguments
#' @return Inferred result type
#' @export
#' @examples
#' \dontrun{
#' dt <- data.table(x = 1:5, y = letters[1:5])
#' dt_type <- infer_type(dt)
#' # After dt[, sum(x)], result would be numeric
#' }
infer_dt_operation <- function(dt_type, operation, ...) {
  if (dt_type$base_type != "data.table") {
    warning("Input is not a data.table type")
    return(TYPES$unknown)
  }

  args <- list(...)

  # Handle subset operations: dt[i, j, by]
  if (operation == "[") {
    # If j is provided and is a single column, return that column's type
    # If j computes something, try to infer the result
    # For now, assume it returns a data.table
    return(dt_type)
  }

  # Handle := (reference assignment)
  if (operation == ":=") {
    # Updates the data.table in place
    return(dt_type)
  }

  TYPES$unknown
}

#' Check data.table operation for type errors
#'
#' @param dt_var Variable name of the data.table
#' @param operation Expression of the operation
#' @param context Type context
#' @return List of type errors/warnings
#' @export
check_dt_operation <- function(dt_var, operation, context) {
  errors <- list()
  warnings <- list()

  # Get the data.table type from context
  if (!dt_var %in% names(context)) {
    errors <- c(errors, list(list(
      message = sprintf("Variable '%s' not found in context", dt_var),
      variable = dt_var
    )))
    return(list(errors = errors, warnings = warnings))
  }

  dt_type <- context[[dt_var]]

  if (dt_type$base_type != "data.table") {
    errors <- c(errors, list(list(
      message = sprintf("Variable '%s' is not a data.table (type: %s)", dt_var, dt_type$base_type),
      variable = dt_var
    )))
  }

  # Check for common data.table patterns
  # This is simplified - full NSE analysis would be much more complex

  list(errors = errors, warnings = warnings)
}

#' Get column type from data.table type
#'
#' @param dt_type A data.table type object
#' @param col_name Column name
#' @return Type of the column
#' @export
get_dt_column_type <- function(dt_type, col_name) {
  if (dt_type$base_type != "data.table") {
    return(TYPES$unknown)
  }

  columns <- dt_type$attributes$columns
  if (is.null(columns) || !col_name %in% names(columns)) {
    return(TYPES$unknown)
  }

  # Return the column type
  col_type <- columns[[col_name]]
  if (is.character(col_type)) {
    return(TYPES[[col_type]])
  }

  col_type
}

#' Annotate data.table with column types
#'
#' @param ... Named arguments with column_name = "type"
#' @return A decorator function
#' @export
#' @examples
#' \dontrun{
#' #' @dt_type(id = "integer", name = "character", value = "numeric")
#' my_dt <- data.table(id = 1:3, name = c("a", "b", "c"), value = c(1.1, 2.2, 3.3))
#' }
dt_type <- function(...) {
  col_types <- list(...)

  function(dt) {
    # Store type information as attribute
    attr(dt, "typethis_columns") <- col_types
    dt
  }
}

#' Common data.table operations type signatures
#'
#' @description
#' Type signatures for common data.table operations to assist type inference.
#'
#' @export
DT_OPERATIONS <- list(
  # Aggregation functions that return scalars
  sum = list(args = list(x = "numeric"), return = "numeric"),
  mean = list(args = list(x = "numeric"), return = "numeric"),
  median = list(args = list(x = "numeric"), return = "numeric"),
  sd = list(args = list(x = "numeric"), return = "numeric"),
  var = list(args = list(x = "numeric"), return = "numeric"),
  min = list(args = list(x = "any"), return = "any"),
  max = list(args = list(x = "any"), return = "any"),

  # Count operations
  .N = list(return = "integer"),
  uniqueN = list(args = list(x = "any"), return = "integer"),

  # String operations (common in data.table j expressions)
  paste = list(args = list("..."), return = "character"),
  paste0 = list(args = list("..."), return = "character"),

  # Type conversions
  as.character = list(args = list(x = "any"), return = "character"),
  as.numeric = list(args = list(x = "any"), return = "numeric"),
  as.integer = list(args = list(x = "any"), return = "integer"),
  as.logical = list(args = list(x = "any"), return = "logical")
)

#' Validate data.table column types
#'
#' @param dt A data.table object
#' @param expected_types Named list of expected types
#' @return Logical indicating if types match, with attributes for mismatches
#' @export
validate_dt_types <- function(dt, expected_types) {
  if (!inherits(dt, "data.table")) {
    stop("Input must be a data.table")
  }

  mismatches <- list()

  for (col_name in names(expected_types)) {
    if (!col_name %in% names(dt)) {
      mismatches[[col_name]] <- list(
        expected = expected_types[[col_name]],
        actual = "missing",
        error = "Column not found"
      )
      next
    }

    expected_type <- expected_types[[col_name]]
    actual_col <- dt[[col_name]]
    actual_type <- infer_type(actual_col)

    if (!type_matches(actual_col, expected_type)) {
      mismatches[[col_name]] <- list(
        expected = expected_type,
        actual = actual_type$base_type,
        error = "Type mismatch"
      )
    }
  }

  result <- length(mismatches) == 0
  attr(result, "mismatches") <- mismatches
  result
}
