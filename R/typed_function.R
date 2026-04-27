#' Wrap a function with input/output type checks
#'
#' @description
#' Returns a wrapped version of `fn` that validates each argument against
#' the spec in `arg_specs` on every call, and (optionally) the return value
#' against `return_spec`. Calls that violate a spec raise an informative
#' error before — or just after — `fn` runs.
#'
#' Argument specs may be character builtins, predicate functions, or any
#' [type_spec][type_spec] (e.g. [t_union()], [t_list_of()]). Coercion can
#' be enabled per call via `coerce = TRUE`.
#'
#' All R calling conventions are supported: positional, named, reordered
#' named, mixed, and `...` passthrough.
#'
#' @param fn The underlying function.
#' @param arg_specs Named list (or character vector) of argument
#'   specifications. Names must match argument names of `fn`.
#' @param return_spec Specification for the return value, or `NULL` to skip.
#' @param validate If `FALSE`, type checks are skipped (useful for hot paths).
#' @param coerce If `TRUE`, arguments that don't match are first run through
#'   [coerce_type()] before assertion.
#' @param arg_types,return_type Deprecated aliases for `arg_specs` /
#'   `return_spec`. New code should use the latter.
#' @return A function with the same formals as `fn`. Carries `arg_specs`,
#'   `return_spec`, and `typed = TRUE` as attributes.
#' @family typed functions
#' @seealso [signature()] / [with_signature()] for a separate-then-attach
#'   workflow; [validate_call()] to dry-run validation; [is_typed()] /
#'   [get_signature()] for introspection.
#' @export
#' @examples
#' add <- typed_function(
#'   function(x, y) x + y,
#'   arg_specs = c(x = "numeric", y = "numeric"),
#'   return_spec = "numeric"
#' )
#' add(2, 3)
#' add(x = 2, y = 3)
#' add(y = 3, x = 2)
#'
#' # Argument violation
#' err <- tryCatch(add("a", "b"), error = function(e) conditionMessage(e))
#' err
#'
#' # ... passthrough
#' total <- typed_function(
#'   function(x, ...) sum(x, ...),
#'   arg_specs = c(x = "numeric")
#' )
#' total(c(1, NA, 3), na.rm = TRUE)
#'
#' # Coercion
#' add_lenient <- typed_function(
#'   function(x, y) x + y,
#'   arg_specs = c(x = "numeric", y = "numeric"),
#'   coerce = TRUE
#' )
#' add_lenient("5", "3")
typed_function <- function(fn, arg_specs = NULL, return_spec = NULL,
                           validate = TRUE, coerce = FALSE,
                           arg_types = NULL, return_type = NULL) {
  if (!is.function(fn)) {
    stop("fn must be a function")
  }

  if (is.null(arg_specs)) arg_specs <- arg_types
  if (is.null(arg_specs)) arg_specs <- list()
  if (is.null(return_spec)) return_spec <- return_type

  fn_formals <- formals(fn)
  has_dots <- "..." %in% names(fn_formals)

  wrapper <- function(...) {
    mc <- match.call(expand.dots = FALSE)
    call_args <- as.list(mc)[-1L]
    named_call_args <- call_args[names(call_args) != "..."]
    caller_env <- parent.frame()

    provided <- lapply(named_call_args, eval, envir = caller_env)

    dots_args <- if (has_dots) list(...) else list()

    if (validate && length(arg_specs) > 0) {
      for (param_name in names(arg_specs)) {
        if (param_name %in% names(provided)) {
          val <- provided[[param_name]]
          expected <- arg_specs[[param_name]]
          if (coerce && !is_type(val, expected)) {
            tryCatch(
              provided[[param_name]] <- coerce_type(val, expected),
              error = function(e) {
                stop(sprintf(
                  "Argument '%s': %s",
                  param_name, e$message
                ), call. = FALSE)
              }
            )
          } else {
            assert_type(val, expected, param_name)
          }
        }
      }

      for (param_name in names(arg_specs)) {
        if (!param_name %in% names(provided)) {
          formal_val <- as.list(fn_formals)[[param_name]]
          has_no_default <- tryCatch(
            {
              is.symbol(formal_val) && as.character(formal_val) == ""
            },
            error = function(e) TRUE
          )
          if (has_no_default) {
            stop(
              sprintf(
                "missing required argument '%s' with no default",
                param_name
              ),
              call. = FALSE
            )
          }
        }
      }
    }

    result <- do.call(fn, c(provided, dots_args))

    if (validate && !is.null(return_spec)) {
      assert_type(result, return_spec, "return value")
    }

    result
  }

  formals(wrapper) <- fn_formals

  fn_attrs <- attributes(fn)
  if (!is.null(fn_attrs)) {
    protected <- c(
      "arg_specs", "return_spec", "arg_types",
      "return_type", "typed", "formals_orig"
    )
    for (nm in setdiff(names(fn_attrs), protected)) {
      attr(wrapper, nm) <- fn_attrs[[nm]]
    }
  }

  attr(wrapper, "arg_specs") <- arg_specs
  attr(wrapper, "arg_types") <- arg_specs
  attr(wrapper, "return_spec") <- return_spec
  attr(wrapper, "return_type") <- return_spec
  attr(wrapper, "typed") <- TRUE
  attr(wrapper, "formals_orig") <- fn_formals

  wrapper
}

#' Build a function signature object
#'
#' Bundles argument types and an optional return type into a single object
#' that can be applied to one or more functions via [with_signature()].
#' Useful when several functions share the same shape.
#'
#' @param ... Named type specifications (one per argument).
#' @param .return Return-type specification, or `NULL`.
#' @return A `type_signature` object.
#' @family typed functions
#' @export
#' @examples
#' sig <- signature(x = "numeric", y = "numeric", .return = "numeric")
#' add <- with_signature(function(x, y) x + y, sig)
#' add(2, 3)
signature <- function(..., .return = NULL) {
  args <- list(...)

  structure(
    list(
      args = args,
      return = .return
    ),
    class = "type_signature"
  )
}

#' Apply a signature to a function
#'
#' Equivalent to passing `sig$args` and `sig$return` to [typed_function()].
#'
#' @param fn Function to wrap.
#' @param sig A `type_signature` object from [signature()].
#' @return A typed function.
#' @family typed functions
#' @export
#' @examples
#' sig <- signature(x = "numeric", y = "numeric", .return = "numeric")
#' multiply <- with_signature(function(x, y) x * y, sig)
#' multiply(5, 3)
with_signature <- function(fn, sig) {
  if (!inherits(sig, "type_signature")) {
    stop("sig must be a type_signature object")
  }

  typed_function(
    fn = fn,
    arg_specs = sig$args,
    return_spec = sig$return
  )
}

#' Test whether a function was wrapped by `typed_function()`
#'
#' @param fn Function to test.
#' @return `TRUE` if `fn` carries the typed-function metadata.
#' @family typed functions
#' @export
#' @examples
#' f <- function(x) x + 1
#' g <- typed_function(f, arg_specs = c(x = "numeric"))
#' is_typed(f)
#' is_typed(g)
is_typed <- function(fn) {
  isTRUE(attr(fn, "typed"))
}

#' Inspect the signature of a typed function
#'
#' Returns the argument specs, return spec, and original formals attached
#' by [typed_function()]. Returns `NULL` for plain functions.
#'
#' @param fn A typed function.
#' @return Named list with `args`, `return`, and `formals`, or `NULL`.
#' @family typed functions
#' @export
#' @examples
#' f <- typed_function(
#'   function(x, y) x + y,
#'   arg_specs = c(x = "numeric", y = "numeric"),
#'   return_spec = "numeric"
#' )
#' get_signature(f)
get_signature <- function(fn) {
  if (!is_typed(fn)) {
    return(NULL)
  }

  arg_specs <- attr(fn, "arg_specs")
  if (is.null(arg_specs)) arg_specs <- attr(fn, "arg_types")
  return_spec <- attr(fn, "return_spec")
  if (is.null(return_spec)) return_spec <- attr(fn, "return_type")

  list(
    args = arg_specs,
    return = return_spec,
    formals = attr(fn, "formals_orig")
  )
}

#' Build a typed-method decorator
#'
#' Returns a function that wraps an underlying method with type checks
#' suitable for S3 or R6 classes. The returned decorator is a thin shim
#' over [typed_function()] that ignores `class_name` / `method_name` at
#' runtime — they are kept as documentation hooks.
#'
#' @param class_name Class name (informational).
#' @param method_name Method name (informational).
#' @param arg_types Named list of argument type specifications.
#' @param return_type Return-type specification.
#' @return A decorator: `function(fn) -> typed function`.
#' @family typed functions
#' @export
#' @examples
#' decorate <- typed_method(
#'   "Point", "translate",
#'   arg_types = list(dx = "numeric", dy = "numeric"),
#'   return_type = "list"
#' )
#' translate <- decorate(function(dx, dy) list(dx = dx, dy = dy))
#' translate(1, 2)
typed_method <- function(class_name, method_name, arg_types = list(),
                         return_type = NULL) {
  function(fn) {
    typed_function(
      fn = fn,
      arg_specs = arg_types,
      return_spec = return_type
    )
  }
}

#' Validate a call to a typed function without executing it
#'
#' Runs the same checks as a real call but returns the outcome as a list
#' instead of executing the body. Useful for validating user input before
#' performing side effects.
#'
#' @param fn A typed function.
#' @param ... Arguments to validate against `fn`'s spec.
#' @param return_spec Reserved for API parity; currently unused.
#' @return Named list `list(valid, errors)`. `errors` is `NULL` on success.
#' @family typed functions
#' @export
#' @examples
#' f <- typed_function(
#'   function(x, y) x + y,
#'   arg_specs = c(x = "numeric", y = "numeric")
#' )
#' validate_call(f, x = 5, y = 3)
#' validate_call(f, x = "a", y = 3)
validate_call <- function(fn, ..., return_spec = NULL) {
  if (!is_typed(fn)) {
    return(list(valid = TRUE, errors = NULL))
  }

  args <- list(...)
  arg_specs <- attr(fn, "arg_specs")
  if (is.null(arg_specs)) arg_specs <- attr(fn, "arg_types")
  errors <- character(0)

  for (param_name in names(arg_specs)) {
    if (param_name %in% names(args)) {
      param_value <- args[[param_name]]
      expected_type <- arg_specs[[param_name]]

      validation <- validate_type(param_value, expected_type, param_name)
      if (!validation$valid) {
        errors <- c(errors, validation$error)
      }
    }
  }

  list(
    valid = length(errors) == 0,
    errors = if (length(errors) > 0) errors else NULL
  )
}
