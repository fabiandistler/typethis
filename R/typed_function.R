#' Typed Function Decorators
#'
#' @description
#' Create type-safe functions with automatic validation of inputs and outputs.
#' Similar to Python type hints with runtime enforcement.

#' Create a typed function with input/output validation
#'
#' @param fn The function to wrap
#' @param arg_types Named list of argument types (use arg_specs instead)
#' @param return_type Expected return type (use return_spec instead)
#' @param validate If TRUE, validate at runtime
#' @param coerce If TRUE, attempt type coercion
#' @param arg_specs Named character vector of argument type specifications
#' @param return_spec Expected return type specification
#' @return Wrapped function with type checking
#' @export
#' @examples
#' add_numbers <- typed_function(
#'   fn = function(x, y) x + y,
#'   arg_specs = c(x = "numeric", y = "numeric"),
#'   return_spec = "numeric"
#' )
#' add_numbers(5, 3) # 8
#' \dontrun{
#' add_numbers("a", "b") # Error: type mismatch
#' }
typed_function <- function(fn, arg_types = NULL, return_type = NULL,
                           validate = TRUE, coerce = FALSE,
                           arg_specs = NULL, return_spec = NULL) {
  if (!is.function(fn)) {
    stop("fn must be a function")
  }

  if (is.null(arg_specs)) arg_specs <- arg_types
  if (is.null(arg_specs)) arg_specs <- list()
  if (is.null(return_spec)) return_spec <- return_type

  fn_formals <- formals(fn)
  has_dots <- "..." %in% names(fn_formals)

  wrapper <- function() {
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
                stop(sprintf("Argument '%s': %s",
                 param_name, e$message), call. = FALSE)
              }
            )
          } else {
            assert_type(val, expected, param_name)
          }
        }
      }

      for (param_name in names(arg_specs)) {
        if (!param_name %in% names(provided)) {
          # Check if formal exists and has no default
          # Use as.list() to avoid triggering evaluation of empty symbols
          formal_val <- as.list(fn_formals)[[param_name]]
          # An empty symbol means "no default" - use tryCatch to handle safely
          has_no_default <- tryCatch(
            {
              is.symbol(formal_val) && as.character(formal_val) == ""
            },
            error = function(e) TRUE
          )
          if (has_no_default) {
            stop(
              sprintf("missing required argument '%s' with no default",
               param_name),
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

  # Copy formals preserves original signature including empty symbols
  # (empty symbol = no default, NULL = default is NULL - these are different!)
  formals(wrapper) <- fn_formals

  fn_attrs <- attributes(fn)
  if (!is.null(fn_attrs)) {
    protected <- c("arg_specs", "return_spec", "arg_types",
                "return_type", "typed", "formals_orig")
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

#' Define function signature with types
#'
#' @param ... Named arguments with type specifications
#' @param .return Return type specification
#' @return Function signature object
#' @export
#' @examples
#' sig <- signature(x = "numeric", y = "numeric", .return = "numeric")
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

#' Apply type signature to function
#'
#' @param fn Function to type
#' @param sig Signature object from signature()
#' @return Typed function
#' @export
#' @examples
#' sig <- signature(x = "numeric", y = "numeric", .return = "numeric")
#' add <- with_signature(function(x, y) x + y, sig)
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

#' Check if function is typed
#'
#' @param fn Function to check
#' @return logical
#' @export
#' @examples
#' f1 <- function(x) x + 1
#' f2 <- typed_function(f1, arg_specs = c(x = "numeric"))
#' is_typed(f1) # FALSE
#' is_typed(f2) # TRUE
is_typed <- function(fn) {
  isTRUE(attr(fn, "typed"))
}

#' Get function signature
#'
#' @param fn Typed function
#' @return Signature information or NULL
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

#' Create method validator for R6 or S3 classes
#'
#' @param class_name Name of the class
#' @param method_name Name of the method
#' @param arg_types Argument types
#' @param return_type Return type
#' @return Typed method wrapper
#' @export
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

#' Validate function call without executing
#'
#' @param fn Typed function
#' @param ... Arguments to validate
#' @param return_spec Return type specification (unused, for API parity)
#' @return list with valid (logical) and errors (character vector)
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
