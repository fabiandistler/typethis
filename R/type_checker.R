#' Type Checker
#'
#' @description
#' Main type checking functionality for static analysis.
#' Checks function signatures, variable assignments, and type consistency.
#'
#' @name type_checker
NULL

#' Check types in R code
#'
#' @param code R code as character string
#' @param from_file Logical indicating if code is a file path
#' @param strict Logical indicating strict mode (all types must be annotated)
#' @return A type_check_result object with errors and warnings
#' @export
#' @examples
#' \dontrun{
#' code <- "
#' add <- function(x, y) {
#'   x + y
#' }
#' result <- add(5, 'hello')  # Type error!
#' "
#' check_types(code)
#' }
check_types <- function(code, from_file = FALSE, strict = FALSE) {
  # Parse code
  parsed <- tryCatch({
    parse_code(code, from_file)
  }, error = function(e) {
    return(structure(
      list(
        errors = list(list(message = paste("Parse error:", e$message), line = 0, col = 0)),
        warnings = list(),
        info = list()
      ),
      class = "type_check_result"
    ))
  })

  errors <- list()
  warnings <- list()
  info <- list()

  # Check assignments for type consistency
  # Build context incrementally to detect reassignments
  assignments <- extract_assignments(parsed)
  local_context <- list()

  if (nrow(assignments) > 0) {
    for (i in seq_len(nrow(assignments))) {
      var_name <- assignments$variable[i]
      line <- assignments$line[i]
      curr_value <- assignments$value_text[i]

      # Infer current type by parsing the value text as code
      curr_type <- tryCatch({
        if (nchar(curr_value) > 0) {
          parsed_value <- parse(text = curr_value)[[1]]
          infer_type_from_expr(parsed_value, local_context)
        } else {
          TYPES$unknown
        }
      }, error = function(e) {
        TYPES$unknown
      })

      # Check if variable was assigned before with different type
      if (var_name %in% names(local_context)) {
        prev_type <- local_context[[var_name]]

        if (prev_type$base_type != "unknown" &&
            curr_type$base_type != "unknown" &&
            prev_type$base_type != curr_type$base_type) {
          warnings <- c(warnings, list(list(
            message = sprintf(
              paste0(
                "Variable '%s' reassigned with different type: ",
                "was %s, now %s"
              ),
              var_name, prev_type$base_type, curr_type$base_type
            ),
            line = line,
            col = assignments$col[i],
            variable = var_name
          )))
        }
      }

      # Update context with current assignment
      local_context[[var_name]] <- curr_type
    }
  }

  # Use the final context for function call checks
  context <- local_context

  # Check function calls
  calls <- extract_function_calls(parsed)
  if (nrow(calls) > 0) {
    for (i in seq_len(nrow(calls))) {
      func_name <- calls$function_name[i]
      line <- calls$line[i]

      # Check for common type errors in known functions
      # This is a simple example - can be extended
      if (func_name %in% c("sum", "mean", "median")) {
        # These functions expect numeric input
        # We would need more context to check arguments properly
        info <- c(info, list(list(
          message = sprintf(
            "Function '%s' expects numeric arguments",
            func_name
          ),
          line = line,
          col = calls$col[i]
        )))
      }
    }
  }

  structure(
    list(
      errors = errors,
      warnings = warnings,
      info = info,
      context = context
    ),
    class = "type_check_result"
  )
}

#' Print method for type_check_result
#'
#' @param x A type_check_result object
#' @param ... Additional arguments (unused)
#' @export
print.type_check_result <- function(x, ...) {
  cat("Type Check Results\n")
  cat("==================\n\n")

  if (length(x$errors) > 0) {
    cat("Errors:\n")
    for (err in x$errors) {
      cat(sprintf("  Line %d:%d - %s\n", err$line, err$col, err$message))
    }
    cat("\n")
  } else {
    cat("No errors found.\n\n")
  }

  if (length(x$warnings) > 0) {
    cat("Warnings:\n")
    for (warn in x$warnings) {
      cat(sprintf("  Line %d:%d - %s\n", warn$line, warn$col, warn$message))
    }
    cat("\n")
  }

  if (length(x$info) > 0 && length(x$info) <= 5) {
    cat("Info:\n")
    for (inf in x$info) {
      cat(sprintf("  Line %d:%d - %s\n", inf$line, inf$col, inf$message))
    }
    cat("\n")
  }

  invisible(x)
}

#' Check types in an R file
#'
#' @param file_path Path to R file
#' @param strict Logical indicating strict mode
#' @return A type_check_result object
#' @export
#' @examples
#' \dontrun{
#' check_file("my_script.R")
#' }
check_file <- function(file_path, strict = FALSE) {
  if (!file.exists(file_path)) {
    stop("File not found: ", file_path)
  }
  check_types(file_path, from_file = TRUE, strict = strict)
}

#' Check types in all R files in a package
#'
#' @param package_path Path to package directory
#' @param strict Logical indicating strict mode
#' @return A list of type_check_result objects, one per file
#' @export
#' @examples
#' \dontrun{
#' check_package("path/to/package")
#' }
check_package <- function(package_path, strict = FALSE) {
  r_dir <- file.path(package_path, "R")

  if (!dir.exists(r_dir)) {
    stop("R directory not found in package: ", package_path)
  }

  r_files <- list.files(r_dir, pattern = "\\.R$", full.names = TRUE)

  if (length(r_files) == 0) {
    message("No R files found in package")
    return(list())
  }

  message(sprintf("Checking %d R files...\n", length(r_files)))

  results <- lapply(r_files, function(file) {
    message(sprintf("  Checking %s...", basename(file)))
    check_file(file, strict = strict)
  })

  names(results) <- basename(r_files)

  # Summary
  total_errors <- sum(sapply(results, function(r) length(r$errors)))
  total_warnings <- sum(sapply(results, function(r) length(r$warnings)))

  message(sprintf("\nSummary: %d errors, %d warnings", total_errors, total_warnings))

  invisible(results)
}

#' Type annotation decorator for functions
#'
#' @param ... Type annotations for function arguments
#' @param .return Return type annotation
#' @return A function decorator
#' @export
#' @examples
#' \dontrun{
#' my_func <- typed(x = "integer", y = "numeric", .return = "numeric")(
#'   function(x, y) {
#'     x + y
#'   }
#' )
#' }
typed <- function(..., .return = "any") {
  arg_types <- list(...)

  function(f) {
    # Store type annotations as attributes
    attr(f, "typethis_arg_types") <- arg_types
    attr(f, "typethis_return_type") <- .return

    # Return wrapped function that checks types at runtime
    function(...) {
      args <- list(...)
      arg_names <- names(arg_types)

      # Check argument types
      for (i in seq_along(arg_names)) {
        arg_name <- arg_names[i]
        expected_type <- arg_types[[i]]

        if (arg_name %in% names(args)) {
          actual_val <- args[[arg_name]]
          if (!type_matches(actual_val, expected_type)) {
            stop(sprintf(
              "Type error in argument '%s': expected %s, got %s",
              arg_name, expected_type, class(actual_val)[1]
            ))
          }
        }
      }

      # Call original function
      result <- f(...)

      # Check return type
      if (.return != "any" && !type_matches(result, .return)) {
        warning(sprintf(
          "Return type mismatch: expected %s, got %s",
          .return, class(result)[1]
        ))
      }

      result
    }
  }
}
