#' Composable type specifications
#'
#' @description
#' Structured, composable type specifications. They work everywhere a type
#' name does — [is_type()], [assert_type()], [validate_type()], [field()],
#' [typed_function()], [to_json_schema()] — and they compose:
#' `t_list_of(t_union("integer", "character"))` is valid.
#'
#' @details
#' All constructors return objects of class `type_spec`. Plain character
#' strings (e.g. `"numeric"`) and predicate functions continue to work as
#' type arguments without change; internally they are normalized to
#' `type_spec` objects.
#'
#' Available constructors:
#'
#' - [t_union()] — match any of several alternatives.
#' - [t_nullable()] — also accept `NULL`.
#' - [t_list_of()] — list of elements of a given type, with optional length.
#' - [t_vector_of()] — atomic vector of a given builtin type, with length.
#' - [t_enum()] — value in a fixed set.
#' - [t_model()] — instance of a registered typed model.
#' - [t_predicate()] — wrap a predicate function with a description.
#'
#' Use [is_type_spec()] to detect a composite spec at runtime.
#'
#' @name type_spec
#' @family type specifications
NULL

#' Test whether an object is a type spec
#'
#' Returns `TRUE` if `x` was created by one of the `t_*()` constructors.
#'
#' @param x Object to test.
#' @return `TRUE` or `FALSE`.
#' @family type specifications
#' @export
#' @examples
#' is_type_spec(t_union("numeric", "character"))
#' is_type_spec("numeric")
is_type_spec <- function(x) {
  inherits(x, "type_spec")
}

#' @keywords internal
#' @noRd
as_type_spec <- function(x) {
  if (inherits(x, "type_spec")) {
    return(x)
  }

  if (is.character(x) && length(x) == 1L && !is.na(x)) {
    registry <- getOption("typethis_model_registry", list())
    if (x %in% names(registry)) {
      return(new_type_spec("model_ref", class_name = x))
    }
    if (!is_known_builtin(x)) {
      stop(sprintf("Unknown type: '%s'", x), call. = FALSE)
    }
    return(new_type_spec("builtin", name = x))
  }

  if (is.function(x)) {
    return(new_type_spec("predicate", fn = x, description = NULL))
  }

  stop(
    "Type must be a character string, function, or type_spec",
    call. = FALSE
  )
}

#' @keywords internal
#' @noRd
new_type_spec <- function(kind, ...) {
  structure(list(kind = kind, ...), class = "type_spec")
}

#' @keywords internal
#' @noRd
is_known_builtin <- function(name) {
  name %in%
    c(
      "numeric",
      "integer",
      "double",
      "character",
      "logical",
      "list",
      "data.frame",
      "matrix",
      "factor",
      "date",
      "posixct",
      "function",
      "environment"
    )
}

#' Union of type specifications
#'
#' Matches if the value matches any of the given alternatives.
#'
#' @param ... Type specifications — character builtin names, predicate
#'   functions, or other `type_spec` objects.
#' @return A `type_spec` of kind `"union"`.
#' @family type specifications
#' @export
#' @examples
#' id <- t_union("integer", "character")
#' is_type(1L, id)
#' is_type("u-42", id)
#' is_type(1.5, id)
t_union <- function(...) {
  alternatives <- lapply(list(...), as_type_spec)
  if (length(alternatives) == 0L) {
    stop("t_union() requires at least one alternative", call. = FALSE)
  }
  new_type_spec("union", alternatives = alternatives)
}

#' Allow `NULL` in addition to an inner type
#'
#' @param type Inner type specification.
#' @return A `type_spec` of kind `"nullable"`.
#' @family type specifications
#' @export
#' @examples
#' maybe_int <- t_nullable("integer")
#' is_type(NULL, maybe_int)
#' is_type(1L, maybe_int)
#' is_type("hi", maybe_int)
t_nullable <- function(type) {
  new_type_spec("nullable", inner = as_type_spec(type))
}

#' List of elements of a given type
#'
#' Matches a list whose every element matches `type`. Optional length
#' constraints follow the semantics of [vector_length()].
#'
#' @param type Element type specification.
#' @param min_length Minimum number of elements.
#' @param max_length Maximum number of elements (defaults to `Inf`).
#' @param exact_length If non-`NULL`, the list must have exactly this length.
#' @return A `type_spec` of kind `"list_of"`.
#' @family type specifications
#' @export
#' @examples
#' tags <- t_list_of("character", min_length = 1L)
#' is_type(list("alpha", "beta"), tags)
#' is_type(list(), tags)
#'
#' # Mixed-type list
#' mixed <- t_list_of(t_union("integer", "character"))
#' is_type(list(1L, "two", 3L), mixed)
t_list_of <- function(
  type,
  min_length = 0,
  max_length = Inf,
  exact_length = NULL
) {
  new_type_spec(
    "list_of",
    element = as_type_spec(type),
    min_length = min_length,
    max_length = max_length,
    exact_length = exact_length
  )
}

#' Atomic vector of a given builtin type
#'
#' Like [t_list_of()] but for atomic vectors. The element type must be a
#' builtin scalar type name (`"numeric"`, `"integer"`, `"character"`, ...).
#'
#' @param type Builtin element type name.
#' @param min_length Minimum length.
#' @param max_length Maximum length (defaults to `Inf`).
#' @param exact_length If non-`NULL`, vector must have exactly this length.
#' @return A `type_spec` of kind `"vector_of"`.
#' @family type specifications
#' @export
#' @examples
#' triple <- t_vector_of("integer", exact_length = 3L)
#' is_type(1:3, triple)
#' is_type(1:5, triple)
t_vector_of <- function(
  type,
  min_length = 0,
  max_length = Inf,
  exact_length = NULL
) {
  inner <- as_type_spec(type)
  if (inner$kind != "builtin") {
    stop(
      "t_vector_of() requires a builtin scalar type for `type`",
      call. = FALSE
    )
  }
  new_type_spec(
    "vector_of",
    element = inner,
    min_length = min_length,
    max_length = max_length,
    exact_length = exact_length
  )
}

#' Enumerated set of allowed values
#'
#' Matches when every element of the value is in the allowed set.
#'
#' @param values Atomic vector of allowed values.
#' @return A `type_spec` of kind `"enum"`.
#' @family type specifications
#' @seealso [enum_validator()] for a validator-only form.
#' @export
#' @examples
#' role <- t_enum(c("admin", "user", "guest"))
#' is_type("admin", role)
#' is_type("root", role)
t_enum <- function(values) {
  if (!is.atomic(values) || length(values) == 0L) {
    stop("t_enum() requires a non-empty atomic vector", call. = FALSE)
  }
  value_type <- if (is.character(values)) {
    "character"
  } else if (is.integer(values)) {
    "integer"
  } else if (is.numeric(values)) {
    "numeric"
  } else if (is.logical(values)) {
    "logical"
  } else {
    "character"
  }
  new_type_spec("enum", values = values, value_type = value_type)
}

#' Reference to a registered model class
#'
#' Matches a typed model instance whose S3 class is `class_name`. The
#' class need not exist when the spec is constructed — the registry is
#' consulted at validation time, which makes forward references possible.
#'
#' @param class_name Character scalar — the registered model class name.
#' @return A `type_spec` of kind `"model_ref"`.
#' @family type specifications
#' @export
#' @examples
#' define_model("Address", fields = list(zip = field("character")))
#' addr_spec <- t_model("Address")
#' is_type(new_Address(zip = "10115"), addr_spec)
t_model <- function(class_name) {
  if (!is.character(class_name) || length(class_name) != 1L) {
    stop("t_model() requires a character scalar class name", call. = FALSE)
  }
  new_type_spec("model_ref", class_name = class_name)
}

#' Wrap a predicate function as a type spec
#'
#' Equivalent to passing a bare predicate function as a type, but lets you
#' attach a description that surfaces in error messages and JSON Schema
#' output.
#'
#' @param fn Predicate function — `function(value) -> logical`.
#' @param description Optional description string (used in error messages).
#' @return A `type_spec` of kind `"predicate"`.
#' @family type specifications
#' @export
#' @examples
#' positive <- t_predicate(
#'   function(x) is.numeric(x) && all(x > 0),
#'   description = "positive number"
#' )
#' is_type(5, positive)
#' is_type(-1, positive)
t_predicate <- function(fn, description = NULL) {
  if (!is.function(fn)) {
    stop("t_predicate() requires a function", call. = FALSE)
  }
  new_type_spec("predicate", fn = fn, description = description)
}

#' @export
format.type_spec <- function(x, ...) {
  switch(
    x$kind,
    "builtin" = x$name,
    "model_ref" = x$class_name,
    "predicate" = if (!is.null(x$description)) {
      sprintf("predicate<%s>", x$description)
    } else {
      "predicate"
    },
    "nullable" = sprintf("nullable<%s>", format(x$inner)),
    "union" = sprintf(
      "union<%s>",
      paste(vapply(x$alternatives, format, character(1)), collapse = ", ")
    ),
    "list_of" = sprintf("list_of<%s>", format(x$element)),
    "vector_of" = sprintf("vector_of<%s>", format(x$element)),
    "enum" = sprintf(
      "enum<%s>",
      paste(utils::head(as.character(x$values), 5L), collapse = ", ")
    ),
    sprintf("type_spec<%s>", x$kind)
  )
}

#' @export
print.type_spec <- function(x, ...) {
  cat("<type_spec: ", format(x), ">\n", sep = "")
  invisible(x)
}

#' @keywords internal
#' @noRd
check_type_spec <- function(value, spec) {
  switch(
    spec$kind,
    "builtin" = check_builtin_type(value, spec$name),
    "predicate" = isTRUE(spec$fn(value)),
    "nullable" = is.null(value) || is_type(value, spec$inner),
    "union" = any(vapply(
      spec$alternatives,
      function(a) is_type(value, a),
      logical(1)
    )),
    "enum" = all(value %in% spec$values),
    "model_ref" = check_model_ref(value, spec$class_name),
    "list_of" = check_list_of(value, spec),
    "vector_of" = check_vector_of(value, spec),
    stop(sprintf("Unknown type_spec kind: %s", spec$kind), call. = FALSE)
  )
}

#' @keywords internal
#' @noRd
check_model_ref <- function(value, class_name) {
  if (!inherits(value, "typed_model")) {
    return(FALSE)
  }
  inherits(value, class_name)
}

#' @keywords internal
#' @noRd
check_list_of <- function(value, spec) {
  if (!is.list(value) || is.data.frame(value)) {
    return(FALSE)
  }
  if (!check_length(length(value), spec)) {
    return(FALSE)
  }
  all(vapply(value, function(e) is_type(e, spec$element), logical(1)))
}

#' @keywords internal
#' @noRd
check_vector_of <- function(value, spec) {
  if (!is.atomic(value)) {
    return(FALSE)
  }
  if (!check_length(length(value), spec)) {
    return(FALSE)
  }
  is_type(value, spec$element)
}

#' @keywords internal
#' @noRd
check_length <- function(len, spec) {
  if (!is.null(spec$exact_length)) {
    return(len == spec$exact_length)
  }
  len >= spec$min_length && len <= spec$max_length
}
