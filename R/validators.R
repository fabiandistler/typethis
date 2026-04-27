#' Read the constraint descriptor attached to a validator
#'
#' Builtin validator factories ([numeric_range()], [string_length()], ...)
#' attach a structured `constraint` list to the closure they return so that
#' tooling can introspect them — most notably [to_json_schema()], which uses
#' it to emit native `minimum` / `maxLength` / `pattern` keys instead of
#' opaque predicate stubs.
#'
#' Plain user-defined validator functions return `NULL`.
#'
#' @param fn A validator closure.
#' @return A named list describing the constraint, or `NULL`.
#' @family validators
#' @export
#' @examples
#' validator_constraint(numeric_range(0, 10))
#' validator_constraint(string_length(max_length = 50))
#' validator_constraint(function(x) x > 0)
validator_constraint <- function(fn) {
  if (!is.function(fn)) {
    return(NULL)
  }
  attr(fn, "constraint")
}

#' @keywords internal
#' @noRd
with_constraint <- function(fn, constraint) {
  attr(fn, "constraint") <- constraint
  fn
}

#' Validate a numeric range
#'
#' Returns a validator closure that accepts numeric values inside the
#' `[min, max]` interval. Endpoints can be excluded with `exclusive_min`
#' or `exclusive_max`.
#'
#' @param min Lower bound (inclusive unless `exclusive_min = TRUE`).
#' @param max Upper bound (inclusive unless `exclusive_max = TRUE`).
#' @param exclusive_min If `TRUE`, the lower bound is excluded.
#' @param exclusive_max If `TRUE`, the upper bound is excluded.
#' @return A validator function `function(value) -> logical`.
#' @family validators
#' @export
#' @examples
#' age <- numeric_range(0, 120)
#' age(25)
#' age(150)
#'
#' # Probability in (0, 1) — both endpoints excluded
#' p <- numeric_range(0, 1, exclusive_min = TRUE, exclusive_max = TRUE)
#' p(0.5)
#' p(0)
numeric_range <- function(
  min = -Inf,
  max = Inf,
  exclusive_min = FALSE,
  exclusive_max = FALSE
) {
  fn <- function(value) {
    if (!is.numeric(value)) {
      return(FALSE)
    }

    min_ok <- if (exclusive_min) all(value > min) else all(value >= min)
    max_ok <- if (exclusive_max) all(value < max) else all(value <= max)

    min_ok && max_ok
  }
  with_constraint(
    fn,
    list(
      kind = "numeric_range",
      min = min,
      max = max,
      exclusive_min = exclusive_min,
      exclusive_max = exclusive_max
    )
  )
}

#' Validate string length
#'
#' Returns a validator closure that accepts character values whose every
#' element has length between `min_length` and `max_length` (inclusive).
#'
#' @param min_length Minimum number of characters.
#' @param max_length Maximum number of characters (defaults to `Inf`).
#' @return A validator function `function(value) -> logical`.
#' @family validators
#' @export
#' @examples
#' name <- string_length(min_length = 1, max_length = 50)
#' name("Ada Lovelace")
#' name("")
#' name(c("ok", "also ok"))
string_length <- function(min_length = 0, max_length = Inf) {
  fn <- function(value) {
    if (!is.character(value)) {
      return(FALSE)
    }

    lengths <- nchar(value)
    all(lengths >= min_length & lengths <= max_length)
  }
  with_constraint(
    fn,
    list(
      kind = "string_length",
      min_length = min_length,
      max_length = max_length
    )
  )
}

#' Validate strings against a regular expression
#'
#' Returns a validator closure that accepts character values where every
#' element matches `pattern` (a POSIX extended regex). Set `ignore_case`
#' for case-insensitive matching.
#'
#' @param pattern Regular expression pattern.
#' @param ignore_case If `TRUE`, matching is case-insensitive.
#' @return A validator function `function(value) -> logical`.
#' @family validators
#' @export
#' @examples
#' email <- string_pattern("^[^@]+@[^@]+\\.[^@]+$")
#' email("user@example.com")
#' email("not-an-email")
#'
#' phone <- string_pattern("^[0-9 +()-]+$")
#' phone("+49 (0)30 1234 5678")
string_pattern <- function(pattern, ignore_case = FALSE) {
  fn <- function(value) {
    if (!is.character(value)) {
      return(FALSE)
    }

    all(grepl(pattern, value, ignore.case = ignore_case))
  }
  with_constraint(
    fn,
    list(
      kind = "string_pattern",
      pattern = pattern,
      ignore_case = ignore_case
    )
  )
}

#' Validate vector or list length
#'
#' Returns a validator closure that accepts values whose `length()` matches
#' the requested constraint. Pass either `min_len` / `max_len`, or a single
#' `exact_len` (which overrides the bounds).
#'
#' @param min_len Minimum length (inclusive).
#' @param max_len Maximum length (inclusive, defaults to `Inf`).
#' @param exact_len If non-`NULL`, the value must have exactly this length.
#' @return A validator function `function(value) -> logical`.
#' @family validators
#' @export
#' @examples
#' pair <- vector_length(exact_len = 2)
#' pair(c(1, 2))
#' pair(c(1, 2, 3))
#'
#' nonempty <- vector_length(min_len = 1)
#' nonempty(integer())
#' nonempty(1:5)
vector_length <- function(min_len = 0, max_len = Inf, exact_len = NULL) {
  fn <- function(value) {
    len <- length(value)

    if (!is.null(exact_len)) {
      return(len == exact_len)
    }

    len >= min_len && len <= max_len
  }
  with_constraint(
    fn,
    list(
      kind = "vector_length",
      min_len = min_len,
      max_len = max_len,
      exact_len = exact_len
    )
  )
}

#' Validate a data frame's structure
#'
#' Returns a validator closure that accepts data frames containing every
#' column listed in `required_cols` and whose row count is within
#' `[min_rows, max_rows]`.
#'
#' @param required_cols Character vector of required column names.
#' @param min_rows Minimum number of rows.
#' @param max_rows Maximum number of rows (defaults to `Inf`).
#' @return A validator function `function(value) -> logical`.
#' @family validators
#' @export
#' @examples
#' is_orders <- dataframe_spec(
#'   required_cols = c("id", "amount"),
#'   min_rows = 1
#' )
#' is_orders(data.frame(id = 1:3, amount = c(10, 20, 30)))
#' is_orders(data.frame(id = integer()))
#' is_orders(data.frame(name = "Ada"))
dataframe_spec <- function(required_cols = NULL, min_rows = 0, max_rows = Inf) {
  fn <- function(value) {
    if (!is.data.frame(value)) {
      return(FALSE)
    }

    if (!is.null(required_cols)) {
      if (!all(required_cols %in% names(value))) {
        return(FALSE)
      }
    }

    nrow_val <- nrow(value)
    nrow_val >= min_rows && nrow_val <= max_rows
  }
  with_constraint(
    fn,
    list(
      kind = "dataframe_spec",
      required_cols = required_cols,
      min_rows = min_rows,
      max_rows = max_rows
    )
  )
}

#' Combine multiple validators
#'
#' Returns a single validator that delegates to each of `...`. With
#' `all_of = TRUE` (the default) every validator must pass; with
#' `all_of = FALSE` any one of them is enough.
#'
#' @param ... Validator functions.
#' @param all_of If `TRUE`, all must pass; if `FALSE`, any one suffices.
#' @return A validator function `function(value) -> logical`.
#' @family validators
#' @export
#' @examples
#' positive_num <- combine_validators(
#'   function(x) is.numeric(x),
#'   function(x) all(x > 0)
#' )
#' positive_num(5)
#' positive_num(-5)
#'
#' num_or_str <- combine_validators(
#'   function(x) is.numeric(x),
#'   function(x) is.character(x),
#'   all_of = FALSE
#' )
#' num_or_str(5)
#' num_or_str("hi")
#' num_or_str(TRUE)
combine_validators <- function(..., all_of = TRUE) {
  validators <- list(...)

  fn <- function(value) {
    results <- sapply(validators, function(v) v(value))

    if (all_of) {
      all(results)
    } else {
      any(results)
    }
  }
  with_constraint(
    fn,
    list(
      kind = "combine",
      all_of = all_of,
      parts = lapply(validators, validator_constraint)
    )
  )
}

#' Validate a value against a fixed set of allowed values
#'
#' Returns a validator closure that accepts values where every element is
#' in `allowed_values`. For an equivalent that doubles as a type
#' specification (usable with [field()] and [typed_function()]) see
#' [t_enum()].
#'
#' @param allowed_values Atomic vector of allowed values.
#' @return A validator function `function(value) -> logical`.
#' @family validators
#' @seealso [t_enum()] for the composable type-spec form.
#' @export
#' @examples
#' status <- enum_validator(c("active", "inactive", "pending"))
#' status("active")
#' status("deleted")
#' status(c("active", "pending"))
enum_validator <- function(allowed_values) {
  fn <- function(value) {
    all(value %in% allowed_values)
  }
  with_constraint(fn, list(kind = "enum", values = allowed_values))
}

#' Validate a list whose elements share a type
#'
#' Returns a validator closure that accepts a list whose every element
#' matches `element_type` and whose length is within `[min_length,
#' max_length]`. For an equivalent that doubles as a type specification,
#' see [t_list_of()].
#'
#' @param element_type Type of list elements (character builtin name,
#'   predicate function, or `type_spec`).
#' @param min_length Minimum number of elements.
#' @param max_length Maximum number of elements (defaults to `Inf`).
#' @return A validator function `function(value) -> logical`.
#' @family validators
#' @seealso [t_list_of()] for the composable type-spec form.
#' @export
#' @examples
#' nums <- list_of("numeric", min_length = 1)
#' nums(list(1, 2, 3))
#' nums(list("a", "b"))
#' nums(list())
list_of <- function(element_type, min_length = 0, max_length = Inf) {
  fn <- function(value) {
    if (!is.list(value)) {
      return(FALSE)
    }

    len <- length(value)
    if (len < min_length || len > max_length) {
      return(FALSE)
    }

    all(sapply(value, function(elem) is_type(elem, element_type)))
  }
  with_constraint(
    fn,
    list(
      kind = "list_of",
      element_type = element_type,
      min_length = min_length,
      max_length = max_length
    )
  )
}

#' Make a validator accept `NULL`
#'
#' Wraps `validator` so that `NULL` is also accepted. Useful for optional
#' fields. For a composable type-spec equivalent, see [t_nullable()].
#'
#' @param validator Underlying validator function.
#' @return A validator function `function(value) -> logical`.
#' @family validators
#' @seealso [t_nullable()] for the composable type-spec form.
#' @export
#' @examples
#' optional_num <- nullable(function(x) is.numeric(x))
#' optional_num(5)
#' optional_num(NULL)
#' optional_num("hi")
nullable <- function(validator) {
  fn <- function(value) {
    is.null(value) || validator(value)
  }
  with_constraint(
    fn,
    list(
      kind = "nullable",
      inner_constraint = validator_constraint(validator)
    )
  )
}
