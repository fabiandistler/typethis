#' Type Validators
#'
#' @description
#' Advanced validators for complex type constraints.
#' Similar to pydantic validators in Python.

#' Numeric range validator
#'
#' @param min Minimum value (inclusive)
#' @param max Maximum value (inclusive)
#' @param exclusive_min Minimum is exclusive
#' @param exclusive_max Maximum is exclusive
#' @return validator function
#' @export
#' @examples
#' age_validator <- numeric_range(min = 0, max = 120)
#' age_validator(25)  # TRUE
#' age_validator(150) # FALSE
numeric_range <- function(min = -Inf, max = Inf,
                         exclusive_min = FALSE, exclusive_max = FALSE) {
  function(value) {
    if (!is.numeric(value)) {
      return(FALSE)
    }

    min_ok <- if (exclusive_min) all(value > min) else all(value >= min)
    max_ok <- if (exclusive_max) all(value < max) else all(value <= max)

    min_ok && max_ok
  }
}

#' String length validator
#'
#' @param min_length Minimum string length
#' @param max_length Maximum string length
#' @return validator function
#' @export
#' @examples
#' name_validator <- string_length(min_length = 1, max_length = 50)
#' name_validator("John")  # TRUE
#' name_validator("")      # FALSE
string_length <- function(min_length = 0, max_length = Inf) {
  function(value) {
    if (!is.character(value)) {
      return(FALSE)
    }

    lengths <- nchar(value)
    all(lengths >= min_length & lengths <= max_length)
  }
}

#' String pattern validator (regex)
#'
#' @param pattern Regular expression pattern
#' @param ignore_case Ignore case in matching
#' @return validator function
#' @export
#' @examples
#' email_validator <- string_pattern("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
#' email_validator("user@example.com")  # TRUE
#' email_validator("invalid-email")     # FALSE
string_pattern <- function(pattern, ignore_case = FALSE) {
  function(value) {
    if (!is.character(value)) {
      return(FALSE)
    }

    all(grepl(pattern, value, ignore.case = ignore_case))
  }
}

#' Vector length validator
#'
#' @param min_len Minimum length
#' @param max_len Maximum length
#' @param exact_len Exact length required
#' @return validator function
#' @export
#' @examples
#' pair_validator <- vector_length(exact_len = 2)
#' pair_validator(c(1, 2))    # TRUE
#' pair_validator(c(1, 2, 3)) # FALSE
vector_length <- function(min_len = 0, max_len = Inf, exact_len = NULL) {
  function(value) {
    len <- length(value)

    if (!is.null(exact_len)) {
      return(len == exact_len)
    }

    len >= min_len && len <= max_len
  }
}

#' Data frame validator
#'
#' @param required_cols Required column names
#' @param min_rows Minimum number of rows
#' @param max_rows Maximum number of rows
#' @return validator function
#' @export
#' @examples
#' df_validator <- dataframe_spec(
#'   required_cols = c("id", "name"),
#'   min_rows = 1
#' )
#' df <- data.frame(id = 1:3, name = c("A", "B", "C"))
#' df_validator(df)  # TRUE
dataframe_spec <- function(required_cols = NULL, min_rows = 0, max_rows = Inf) {
  function(value) {
    if (!is.data.frame(value)) {
      return(FALSE)
    }

    # Check required columns
    if (!is.null(required_cols)) {
      if (!all(required_cols %in% names(value))) {
        return(FALSE)
      }
    }

    # Check row count
    nrow_val <- nrow(value)
    nrow_val >= min_rows && nrow_val <= max_rows
  }
}

#' Custom validator combinator
#'
#' @param ... Validator functions
#' @param all_of If TRUE, all validators must pass; if FALSE, any can pass
#' @return Combined validator function
#' @export
#' @examples
#' validator <- combine_validators(
#'   is_numeric <- function(x) is.numeric(x),
#'   is_positive <- function(x) all(x > 0),
#'   all_of = TRUE
#' )
#' validator(5)  # TRUE
#' validator(-5) # FALSE
combine_validators <- function(..., all_of = TRUE) {
  validators <- list(...)

  function(value) {
    results <- sapply(validators, function(v) v(value))

    if (all_of) {
      all(results)
    } else {
      any(results)
    }
  }
}

#' Create enum validator
#'
#' @param allowed_values Vector of allowed values
#' @return validator function
#' @export
#' @examples
#' status_validator <- enum_validator(c("active", "inactive", "pending"))
#' status_validator("active")   # TRUE
#' status_validator("deleted")  # FALSE
enum_validator <- function(allowed_values) {
  function(value) {
    all(value %in% allowed_values)
  }
}

#' Validate list structure
#'
#' @param element_type Type of list elements
#' @param min_length Minimum list length
#' @param max_length Maximum list length
#' @return validator function
#' @export
#' @examples
#' num_list_validator <- list_of(element_type = "numeric", min_length = 1)
#' num_list_validator(list(1, 2, 3))      # TRUE
#' num_list_validator(list("a", "b"))     # FALSE
list_of <- function(element_type, min_length = 0, max_length = Inf) {
  function(value) {
    if (!is.list(value)) {
      return(FALSE)
    }

    len <- length(value)
    if (len < min_length || len > max_length) {
      return(FALSE)
    }

    all(sapply(value, function(elem) is_type(elem, element_type)))
  }
}

#' Nullable type validator
#'
#' @param validator Base validator function
#' @return Validator that also accepts NULL
#' @export
#' @examples
#' optional_num <- nullable(function(x) is.numeric(x))
#' optional_num(5)    # TRUE
#' optional_num(NULL) # TRUE
nullable <- function(validator) {
  function(value) {
    is.null(value) || validator(value)
  }
}
