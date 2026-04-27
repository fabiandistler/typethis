#' Retrofit type stability onto an existing function
#'
#' @description
#' Convenience wrapper around [typed_function()] for adding type checks to a
#' function you already have. Compared to [typed_function()] it removes two
#' sources of friction:
#'
#' * Argument specs are passed via `...` instead of `arg_specs = list(...)`.
#' * Specs for arguments with literal atomic defaults are inferred
#'   automatically (see [infer_specs()]); only the arguments you care about
#'   need to appear in `...`.
#'
#' Internally `as_typed()` builds an `arg_specs` list and delegates to
#' [typed_function()], so all calling conventions, coercion, and metadata
#' behaviour are identical.
#'
#' @param fn The function to retrofit.
#' @param ... Named type specs. Names must match formals of `fn`. Values may
#'   be character builtins, predicates, or [type_spec][type_spec] objects.
#'   Pass `NULL` to opt a single argument out of inference.
#' @param .return Specification for the return value, or `NULL` to skip.
#'   The return type is never inferred.
#' @param .infer If `TRUE` (default), arguments not named in `...` get a spec
#'   inferred from their default value when possible. See [infer_specs()].
#' @param .validate If `FALSE`, type checks are skipped (useful for hot paths).
#' @param .coerce If `TRUE`, arguments that don't match are first run through
#'   [coerce_type()] before assertion.
#' @return A typed function. Same shape as the result of [typed_function()].
#' @family typed functions
#' @seealso [infer_specs()] for the inference rules; [typed_function()] for
#'   the underlying wrapper.
#' @export
#' @examples
#' # Inferred from defaults — no spec list needed
#' add <- as_typed(function(x = 0L, y = 0L) x + y, .return = "integer")
#' add(2L, 3L)
#'
#' # Override one argument; the rest are inferred
#' greet <- as_typed(
#'   function(name = "world", times = 1L) {
#'     paste(rep(name, times), collapse = " ")
#'   },
#'   name = t_vector_of("character", exact_length = 1L)
#' )
#' greet("hi", times = 3L)
#'
#' # Opt an argument out of validation with NULL
#' f <- as_typed(function(x = 1L, y = 1L) x + y, y = NULL)
#' attr(f, "arg_specs")
#'
#' # Disable inference entirely
#' g <- as_typed(function(x = 1L, y = 2L) x + y, .infer = FALSE)
#' attr(g, "arg_specs")
as_typed <- function(
  fn,
  ...,
  .return = NULL,
  .infer = TRUE,
  .validate = TRUE,
  .coerce = FALSE
) {
  if (!is.function(fn)) {
    stop("fn must be a function")
  }

  overrides <- list(...)
  if (length(overrides) > 0 && is.null(names(overrides))) {
    stop("All arguments in ... must be named")
  }
  if (length(overrides) > 0 && any(names(overrides) == "")) {
    stop("All arguments in ... must be named")
  }

  if (is_typed(fn)) {
    sig <- get_signature(fn)
    base_specs <- sig$args
    if (is.null(base_specs)) {
      base_specs <- list()
    }
    inner_fn <- environment(fn)$fn
    if (is.null(inner_fn) || !is.function(inner_fn)) {
      inner_fn <- fn
    }
    if (is.null(.return)) {
      .return <- sig$return
    }
  } else {
    base_specs <- list()
    inner_fn <- fn
  }

  fn_formal_names <- names(formals(inner_fn))

  inferred <- if (isTRUE(.infer)) infer_specs(inner_fn) else list()

  arg_specs <- merge_arg_specs(base_specs, inferred, overrides)

  unknown <- setdiff(names(arg_specs), fn_formal_names)
  if (length(unknown) > 0) {
    stop(sprintf(
      "Unknown argument name(s) in spec: %s",
      paste(unknown, collapse = ", ")
    ))
  }

  typed_function(
    fn = inner_fn,
    arg_specs = arg_specs,
    return_spec = .return,
    validate = .validate,
    coerce = .coerce
  )
}

#' Infer argument specs from a function's default values
#'
#' Walks the formals of `fn` and returns a named list of inferred type
#' specs, one entry per formal whose default value is a length-1 literal of
#' a recognised atomic type.
#'
#' Recognised defaults:
#'
#' * Integer literal (`1L`) -> `"integer"`
#' * Double literal (`1.0`, `0.5`) -> `"double"`
#' * Character literal (`"a"`) -> `"character"`
#' * Logical literal (`TRUE`, `FALSE`) -> `"logical"`
#'
#' Defaults that are skipped:
#'
#' * `NULL`
#' * Calls (`list()`, `c(1, 2)`, ...) — would require evaluation
#' * Missing defaults
#' * `...`
#'
#' Default expressions are inspected without being evaluated, so this is
#' safe to call on arbitrary functions.
#'
#' @param fn A function.
#' @return A named list of type specs. Empty list if nothing could be
#'   inferred.
#' @family typed functions
#' @export
#' @examples
#' infer_specs(function(x = 1L, y = 1.0, name = "a", flag = TRUE) NULL)
#'
#' # Skipped: NULL default, call default, missing default
#' infer_specs(function(x, y = NULL, z = list()) NULL)
infer_specs <- function(fn) {
  if (!is.function(fn)) {
    stop("fn must be a function")
  }

  fn_formals <- formals(fn)
  if (length(fn_formals) == 0) {
    return(list())
  }

  specs <- list()
  for (nm in names(fn_formals)) {
    if (nm == "...") {
      next
    }
    spec <- infer_default_spec(fn_formals[[nm]])
    if (!is.null(spec)) {
      specs[[nm]] <- spec
    }
  }
  specs
}

# Inspect a single formal's default expression and return a builtin type
# string, or NULL if nothing can be inferred. Defaults are never evaluated.
infer_default_spec <- function(default) {
  if (is.symbol(default) && as.character(default) == "") {
    return(NULL)
  }
  if (is.call(default)) {
    return(NULL)
  }
  if (is.null(default)) {
    return(NULL)
  }
  if (length(default) != 1L) {
    return(NULL)
  }

  if (is.integer(default)) {
    return("integer")
  }
  if (is.double(default)) {
    return("double")
  }
  if (is.character(default)) {
    return("character")
  }
  if (is.logical(default)) {
    return("logical")
  }
  NULL
}

# Combine three layers of specs in increasing precedence: existing specs
# from a re-wrap, inferred specs, explicit user overrides. Entries set to
# NULL by the user are dropped from the result so the corresponding
# argument is left unchecked.
merge_arg_specs <- function(base, inferred, overrides) {
  combined <- base
  combined <- modifyList(combined, inferred, keep.null = FALSE)

  override_names <- names(overrides)
  null_names <- override_names[vapply(
    overrides,
    is.null,
    logical(1)
  )]
  non_null <- overrides[setdiff(override_names, null_names)]

  combined <- modifyList(combined, non_null, keep.null = FALSE)
  combined[setdiff(names(combined), null_names)]
}
