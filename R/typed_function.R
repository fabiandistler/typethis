#' Typed Function Decorators
#'
#' @description
#' Create type-safe functions with automatic validation of inputs and outputs.
#' Similar to Python type hints with runtime enforcement.

#' Create a typed function with input/output validation
#'
#' @param fn The function to wrap
#' @param arg_types Named list of argument types
#' @param return_type Expected return type
#' @param validate If TRUE, validate at runtime
#' @param coerce If TRUE, attempt type coercion
#' @return Wrapped function with type checking
#' @export
#' @examples
#' add_numbers <- typed_function(
#'   fn = function(x, y) x + y,
#'   arg_types = list(x = "numeric", y = "numeric"),
#'   return_type = "numeric"
#' )
#' add_numbers(5, 3)  # 8
#' \dontrun{
#' add_numbers("a", "b")  # Error: type mismatch
#' }
typed_function <- function(fn, arg_types = list(), return_type = NULL,
                          validate = TRUE, coerce = FALSE) {
  if (!is.function(fn)) {
    stop("fn must be a function")
  }

  # Create wrapper function
  wrapper <- function(...) {
    args <- list(...)
    arg_names <- names(args)

    if (validate && length(arg_types) > 0) {
      # Validate arguments
      for (param_name in names(arg_types)) {
        if (param_name %in% arg_names) {
          param_value <- args[[param_name]]
          expected_type <- arg_types[[param_name]]

          # Try coercion if enabled
          if (coerce && !is_type(param_value, expected_type)) {
            tryCatch({
              args[[param_name]] <- coerce_type(param_value, expected_type)
            }, error = function(e) {
              stop(sprintf(
                "Argument '%s': %s", param_name, e$message
              ), call. = FALSE)
            })
          } else {
            # Validate type
            assert_type(param_value, expected_type, param_name)
          }
        }
      }
    }

    # Call original function
    result <- do.call(fn, args)

    # Validate return type
    if (validate && !is.null(return_type)) {
      assert_type(result, return_type, "return value")
    }

    result
  }

  # Preserve function attributes
  attributes(wrapper) <- attributes(fn)
  attr(wrapper, "arg_types") <- arg_types
  attr(wrapper, "return_type") <- return_type
  attr(wrapper, "typed") <- TRUE

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
    arg_types = sig$args,
    return_type = sig$return
  )
}

#' Check if function is typed
#'
#' @param fn Function to check
#' @return logical
#' @export
#' @examples
#' f1 <- function(x) x + 1
#' f2 <- typed_function(f1, arg_types = list(x = "numeric"))
#' is_typed(f1)  # FALSE
#' is_typed(f2)  # TRUE
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
#'   arg_types = list(x = "numeric", y = "numeric"),
#'   return_type = "numeric"
#' )
#' get_signature(f)
get_signature <- function(fn) {
  if (!is_typed(fn)) {
    return(NULL)
  }

  list(
    args = attr(fn, "arg_types"),
    return = attr(fn, "return_type")
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
      arg_types = arg_types,
      return_type = return_type
    )
  }
}

#' Validate function call without executing
#'
#' @param fn Typed function
#' @param ... Arguments to validate
#' @return list with valid (logical) and errors (character vector)
#' @export
#' @examples
#' f <- typed_function(
#'   function(x, y) x + y,
#'   arg_types = list(x = "numeric", y = "numeric")
#' )
#' validate_call(f, x = 5, y = 3)
#' validate_call(f, x = "a", y = 3)
validate_call <- function(fn, ...) {
  if (!is_typed(fn)) {
    return(list(valid = TRUE, errors = NULL))
  }

  args <- list(...)
  arg_types <- attr(fn, "arg_types")
  errors <- character(0)

  for (param_name in names(arg_types)) {
    if (param_name %in% names(args)) {
      param_value <- args[[param_name]]
      expected_type <- arg_types[[param_name]]

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
