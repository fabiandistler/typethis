#' Reveal Type
#'
#' @description
#' Utility function to reveal the inferred type of an expression.
#' Similar to mypy's reveal_type() in Python.
#'
#' @name reveal_type
NULL

#' Reveal the type of an expression
#'
#' @param x An R expression or value
#' @param context Optional type context
#' @param show_details Logical indicating whether to show detailed type info
#' @return The inferred type (invisibly), and prints type information
#' @export
#' @examples
#' \dontrun{
#' x <- 5L
#' reveal_type(x)  # Reveals: integer
#'
#' y <- data.frame(a = 1:3, b = letters[1:3])
#' reveal_type(y)  # Reveals: data.frame with column types
#' }
reveal_type <- function(x, context = NULL, show_details = TRUE) {
  # Get the expression
  expr <- substitute(x)
  expr_str <- deparse(expr)

  # Infer the type
  inferred <- infer_type(x, context)

  # Print the result
  cat("Type of '", expr_str, "':\n", sep = "")
  cat("  Base type: ", inferred$base_type, "\n", sep = "")

  if (inferred$nullable) {
    cat("  Nullable: TRUE\n")
  }

  if (show_details && length(inferred$attributes) > 0) {
    cat("  Attributes:\n")
    for (attr_name in names(inferred$attributes)) {
      attr_val <- inferred$attributes[[attr_name]]

      if (is.list(attr_val) && attr_name == "columns") {
        cat("    Columns:\n")
        for (col_name in names(attr_val)) {
          cat("      ", col_name, ": ", attr_val[[col_name]], "\n", sep = "")
        }
      } else {
        cat("    ", attr_name, ": ", as.character(attr_val), "\n", sep = "")
      }
    }
  }

  # Return the type invisibly
  invisible(inferred)
}

#' Reveal type from code string
#'
#' @param code Character string containing R code
#' @param variable Variable name to reveal type for
#' @param from_file Logical indicating if code is a file path
#' @return The inferred type
#' @export
#' @examples
#' \dontrun{
#' code <- "x <- 5L\ny <- 3.14"
#' reveal_type_from_code(code, "x")  # integer
#' reveal_type_from_code(code, "y")  # numeric
#' }
reveal_type_from_code <- function(code, variable, from_file = FALSE) {
  parsed <- parse_code(code, from_file)
  context <- build_type_context(parsed)

  if (!variable %in% names(context)) {
    cat("Variable '", variable, "' not found in code\n", sep = "")
    return(invisible(NULL))
  }

  inferred <- context[[variable]]

  cat("Type of '", variable, "':\n", sep = "")
  cat("  Base type: ", inferred$base_type, "\n", sep = "")

  if (inferred$nullable) {
    cat("  Nullable: TRUE\n")
  }

  if (length(inferred$attributes) > 0) {
    cat("  Attributes:\n")
    for (attr_name in names(inferred$attributes)) {
      attr_val <- inferred$attributes[[attr_name]]
      cat("    ", attr_name, ": ", as.character(attr_val), "\n", sep = "")
    }
  }

  invisible(inferred)
}

#' Reveal all types in code
#'
#' @param code Character string containing R code or file path
#' @param from_file Logical indicating if code is a file path
#' @return Data frame with all variables and their types
#' @export
#' @examples
#' \dontrun{
#' code <- "x <- 5L\ny <- 3.14\nz <- 'hello'"
#' reveal_all_types(code)
#' }
reveal_all_types <- function(code, from_file = FALSE) {
  type_info <- infer_types_from_code(code, from_file)

  if (nrow(type_info) == 0) {
    cat("No variables found in code\n")
    return(invisible(data.frame()))
  }

  cat("Types found in code:\n")
  cat("===================\n\n")

  for (i in seq_len(nrow(type_info))) {
    cat(sprintf(
      "Line %d: %s :: %s\n",
      type_info$line[i],
      type_info$variable[i],
      type_info$type[i]
    ))
  }

  invisible(type_info)
}

#' Type assertion for runtime checking
#'
#' @param x Value to check
#' @param expected_type Expected type (string or rtype object)
#' @param var_name Optional variable name for error messages
#' @return TRUE if type matches, otherwise stops with error
#' @export
#' @examples
#' \dontrun{
#' x <- 5L
#' assert_type(x, "integer")  # OK
#' assert_type(x, "character")  # Error!
#' }
assert_type <- function(x, expected_type, var_name = NULL) {
  if (is.character(expected_type)) {
    expected_type <- TYPES[[expected_type]]
  }

  if (is.null(expected_type)) {
    stop("Unknown type: ", expected_type)
  }

  if (!type_matches(x, expected_type)) {
    actual_type <- infer_type(x)

    var_str <- if (!is.null(var_name)) {
      paste0("'", var_name, "'")
    } else {
      "value"
    }

    stop(sprintf(
      "Type assertion failed for %s: expected %s, got %s",
      var_str,
      expected_type$base_type,
      actual_type$base_type
    ))
  }

  TRUE
}

#' Check if expression would have type error (static analysis)
#'
#' @param expr Expression as character string
#' @param context Type context
#' @return List with has_error (logical) and message (if error)
#' @export
check_expr_type <- function(expr, context = NULL) {
  result <- list(has_error = FALSE, message = NULL)

  tryCatch({
    parsed <- parse(text = expr)
    inferred <- infer_type_from_expr(parsed[[1]], context)

    if (inferred$base_type == "unknown") {
      result$has_error <- TRUE
      result$message <- "Could not infer type"
    }
  }, error = function(e) {
    result$has_error <<- TRUE
    result$message <<- paste("Error:", e$message)
  })

  result
}
