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
  combined <- utils::modifyList(combined, inferred, keep.null = FALSE)

  override_names <- names(overrides)
  null_names <- override_names[vapply(
    overrides,
    is.null,
    logical(1)
  )]
  non_null <- overrides[setdiff(override_names, null_names)]

  combined <- utils::modifyList(combined, non_null, keep.null = FALSE)
  combined[setdiff(names(combined), null_names)]
}

#' Bulk-retrofit every function in an environment
#'
#' @description
#' Walks `envir`, applies [as_typed()] to every function it finds, and
#' reassigns the result back into `envir` in place. Useful for adding
#' type checks across a script, a chunk of analysis code in
#' [globalenv()], or a private environment held by a package.
#'
#' Per-function overrides flow through `.specs`, a named list of lists
#' whose entries match the `as_typed()` argument shape (named arg specs
#' plus optional `.return`/`.infer`/`.validate`/`.coerce`). Functions
#' without a `.specs` entry are still retrofitted via inference (when
#' `.infer = TRUE`) and the function-level defaults.
#'
#' Already-typed functions are re-wrapped through `as_typed()`'s
#' idempotent merge path — no double-wrapping. Locked bindings (common
#' for namespaces) are skipped by default; a single warning reports the
#' count. Pass `.unlock = TRUE` to unlock-modify-relock each binding in
#' place — this is what [enable_typed_namespace()] uses to retrofit
#' bindings *after* a namespace has been locked.
#'
#' @param envir An environment. Use [new.env()] or [globalenv()] for
#'   ordinary cases; passing a namespace is supported but most
#'   bindings will be locked.
#' @param .specs Named list of per-function override lists. Each entry
#'   has the same shape as `as_typed()`'s `...` plus the dotted
#'   options. Names must correspond to functions in `envir`; unknown
#'   names are an error.
#' @param .infer,.validate,.coerce Function-level defaults forwarded
#'   to [as_typed()]. Per-function entries in `.specs` win.
#' @param .filter Optional `function(name, fn)` returning a single
#'   logical; functions for which this returns `FALSE` are skipped.
#' @param .unlock If `TRUE`, locked bindings are temporarily unlocked,
#'   reassigned to their typed wrapper, and re-locked. Defaults to
#'   `FALSE`, in which case locked bindings are skipped with a
#'   warning. Re-locking is guaranteed by `on.exit` even if a wrap
#'   step errors.
#' @return Invisibly, the character vector of names that were
#'   retrofitted.
#' @family typed functions
#' @seealso [as_typed()] for the per-function form; [types()] for
#'   the replacement-form accessor; [enable_typed_namespace()] for
#'   the `setHook`-based whole-package wrapper.
#' @export
#' @examples
#' e <- new.env()
#' e$add <- function(x = 0L, y = 0L) x + y
#' e$greet <- function(name = "world") paste0("hi ", name)
#' as_typed_env(e)
#' is_typed(e$add)
#' is_typed(e$greet)
#'
#' # Per-function overrides
#' e2 <- new.env()
#' e2$add <- function(x = 0L, y = 0L) x + y
#' as_typed_env(e2, .specs = list(
#'   add = list(x = "integer", y = "integer", .return = "integer")
#' ))
#'
#' # Filter to a subset
#' e3 <- new.env()
#' e3$keep <- function(x = 1L) x
#' e3$skip <- function(x = 1L) x
#' as_typed_env(e3, .filter = function(name, fn) name == "keep")
#'
#' # Unlock-and-modify locked bindings (e.g. after a namespace lock)
#' e4 <- new.env()
#' e4$add <- function(x = 0L) x
#' lockBinding("add", e4)
#' as_typed_env(e4, .unlock = TRUE)
#' is_typed(e4$add)
as_typed_env <- function(
  envir,
  .specs = list(),
  .infer = TRUE,
  .validate = TRUE,
  .coerce = FALSE,
  .filter = NULL,
  .unlock = FALSE
) {
  if (!is.environment(envir)) {
    stop("envir must be an environment")
  }
  if (!is.list(.specs)) {
    stop(".specs must be a named list of override lists")
  }
  if (length(.specs) > 0) {
    spec_names <- names(.specs)
    if (is.null(spec_names) || any(spec_names == "")) {
      stop("All entries of .specs must be named")
    }
    not_lists <- !vapply(.specs, is.list, logical(1))
    if (any(not_lists)) {
      stop(sprintf(
        "Entries of .specs must be lists; bad entries: %s",
        paste(spec_names[not_lists], collapse = ", ")
      ))
    }
  }
  if (!is.null(.filter) && !is.function(.filter)) {
    stop(".filter must be a function or NULL")
  }

  candidates <- ls(envir = envir, all.names = TRUE)
  unknown <- setdiff(names(.specs), candidates)
  if (length(unknown) > 0) {
    stop(sprintf(
      "Unknown name(s) in .specs: %s",
      paste(unknown, collapse = ", ")
    ))
  }

  modified <- character(0)
  skipped_locked <- character(0)
  unlocked_during_loop <- character(0)

  on.exit(
    {
      for (nm in unlocked_during_loop) {
        if (exists(nm, envir = envir, inherits = FALSE)) {
          lockBinding(nm, envir)
        }
      }
    },
    add = TRUE
  )

  for (nm in candidates) {
    fn <- get(nm, envir = envir, inherits = FALSE)
    if (!is.function(fn)) {
      next
    }
    if (!is.null(.filter) && !isTRUE(.filter(nm, fn))) {
      next
    }
    if (bindingIsLocked(nm, envir)) {
      if (!isTRUE(.unlock)) {
        skipped_locked <- c(skipped_locked, nm)
        next
      }
      unlockBinding(nm, envir)
      unlocked_during_loop <- c(unlocked_during_loop, nm)
    }

    overrides <- .specs[[nm]]
    if (is.null(overrides)) {
      overrides <- list()
    }
    call_args <- list(
      fn = fn,
      .infer = .infer,
      .validate = .validate,
      .coerce = .coerce
    )
    call_args <- utils::modifyList(call_args, overrides, keep.null = TRUE)

    typed_fn <- do.call(as_typed, call_args)
    assign(nm, typed_fn, envir = envir)
    modified <- c(modified, nm)
  }

  if (length(skipped_locked) > 0) {
    warning(sprintf(
      "Skipped %d locked binding(s): %s",
      length(skipped_locked),
      paste(skipped_locked, collapse = ", ")
    ))
  }

  invisible(modified)
}

#' Enable type checking for an entire package
#'
#' @description
#' Convenience wrapper for switching on typethis across every function in a
#' package namespace, with a single call from the package's `.onLoad()` hook.
#' Inside `.onLoad()` the namespace bindings are not yet locked, so each
#' function can be replaced in place with its typed wrapper.
#'
#' Add `R/zzz.R` to your package containing:
#'
#' ```r
#' .onLoad <- function(libname, pkgname) {
#'   typethis::enable_for_package(pkgname)
#' }
#' ```
#'
#' That single line walks the namespace, infers type specs from each
#' function's literal atomic defaults (see [infer_specs()]), and replaces
#' every binding with a typed wrapper. Functions whose defaults cannot be
#' inferred are left untyped unless you add an explicit override via
#' `.specs`.
#'
#' Standard package hook functions (`.onLoad`, `.onAttach`, `.onUnload`,
#' `.onDetach`, `.Last.lib`, `.First.lib`) and primitives are skipped
#' automatically. A user-supplied `.filter` runs *after* the default skip
#' list — it can narrow the set of retrofitted functions, not widen it.
#'
#' Calling `enable_for_package()` from outside `.onLoad()` is safe but
#' usually redundant: the namespace is locked by then and most bindings
#' will be skipped with a single warning reporting the count.
#'
#' @param pkgname The package name (string), or directly an environment
#'   to retrofit. Inside `.onLoad()` use the `pkgname` argument R passes
#'   to your hook. Passing an environment is mainly useful for tests.
#' @param .specs,.infer,.validate,.coerce Forwarded to [as_typed_env()].
#'   Per-function entries in `.specs` win over inference.
#' @param .filter Optional `function(name, fn)` returning a single
#'   logical. Applied *after* the built-in skip list, so this can only
#'   reduce what is retrofitted.
#' @param .unlock If `TRUE`, locked bindings are temporarily unlocked
#'   and re-locked instead of skipped. Used by [enable_typed_namespace()]
#'   when retrofitting after the namespace has been locked by R.
#' @return Invisibly, the character vector of names that were
#'   retrofitted.
#' @family typed functions
#' @seealso [as_typed_env()] for the underlying engine; [as_typed()]
#'   for per-function retrofits; [infer_specs()] for inference rules;
#'   [enable_typed_namespace()] for the `setHook`-driven variant that
#'   does not require editing the target package.
#' @export
#' @examples
#' # Inside R/zzz.R of your own package:
#' # .onLoad <- function(libname, pkgname) {
#' #   typethis::enable_for_package(pkgname)
#' # }
#'
#' # Demonstration on an ordinary environment shaped like a namespace:
#' ns <- new.env()
#' ns$add <- function(x = 0L, y = 0L) x + y
#' ns$.onLoad <- function(libname, pkgname) NULL
#' enable_for_package(ns)
#' is_typed(ns$add) # TRUE  -- inferred from defaults
#' is_typed(ns$.onLoad) # FALSE -- hook skipped
#'
#' # Override one function while the rest are inferred
#' ns2 <- new.env()
#' ns2$add <- function(x = 0L, y = 0L) x + y
#' ns2$greet <- function(name = "world") paste0("hi ", name)
#' enable_for_package(ns2, .specs = list(
#'   add = list(.return = "integer")
#' ))
enable_for_package <- function(
  pkgname,
  .specs = list(),
  .infer = TRUE,
  .validate = TRUE,
  .coerce = FALSE,
  .filter = NULL,
  .unlock = FALSE
) {
  if (is.environment(pkgname)) {
    ns <- pkgname
  } else if (
    is.character(pkgname) &&
      length(pkgname) == 1L &&
      !is.na(pkgname) &&
      nzchar(pkgname)
  ) {
    ns <- asNamespace(pkgname)
  } else {
    stop("pkgname must be a single non-empty string (or an environment)")
  }

  if (!is.null(.filter) && !is.function(.filter)) {
    stop(".filter must be a function or NULL")
  }

  user_filter <- .filter
  combined_filter <- function(name, fn) {
    if (is.primitive(fn)) {
      return(FALSE)
    }
    if (name %in% PACKAGE_HOOK_NAMES) {
      return(FALSE)
    }
    if (is.null(user_filter)) {
      return(TRUE)
    }
    isTRUE(user_filter(name, fn))
  }

  as_typed_env(
    envir = ns,
    .specs = .specs,
    .infer = .infer,
    .validate = .validate,
    .coerce = .coerce,
    .filter = combined_filter,
    .unlock = .unlock
  )
}

# R hook function names skipped by enable_for_package() so they remain
# callable by R's namespace machinery rather than being wrapped in a
# typed shell that would change their argument-checking behaviour.
PACKAGE_HOOK_NAMES <- c(
  ".onLoad",
  ".onAttach",
  ".onUnload",
  ".onDetach",
  ".Last.lib",
  ".First.lib"
)

#' Get or set the type specs of a function
#'
#' @description
#' Symmetric replacement-form accessor over [as_typed()]. The setter
#' delegates to `as_typed()`; the getter returns specs in the shape
#' the setter accepts, so `types(f) <- types(g)` round-trips.
#'
#' * `types(f)` returns a list whose named entries are argument specs
#'   and whose `.return` entry (if present) is the return spec.
#'   Returns `list()` for an untyped function, so it is cheap to use
#'   in `if (length(types(f))) ...` checks.
#' * `types(f) <- value` retrofits `f` via `as_typed()`. `value` must
#'   be a list — named arg specs plus any of `.return`, `.infer`,
#'   `.validate`, `.coerce`.
#' * `types(f) <- NULL` un-types `f` (returns the original inner
#'   function) — the natural inverse.
#'
#' @param f A function.
#' @param value A list of specs (or `NULL` to un-type).
#' @return `types(f)` returns a list of specs. `types(f) <- value`
#'   returns the modified function (assigned back to `f` by R).
#' @family typed functions
#' @seealso [as_typed()] for the underlying retrofit;
#'   [as_typed_env()] for bulk retrofits.
#' @export
#' @examples
#' add <- function(x = 0L, y = 0L) x + y
#' types(add) <- list(x = "integer", y = "integer", .return = "integer")
#' is_typed(add)
#' types(add)
#'
#' # NULL un-types
#' types(add) <- NULL
#' is_typed(add)
types <- function(f) {
  if (!is.function(f)) {
    stop("f must be a function")
  }
  if (!is_typed(f)) {
    return(list())
  }
  sig <- get_signature(f)
  out <- sig$args
  if (is.null(out)) {
    out <- list()
  }
  if (!is.null(sig$return)) {
    out[[".return"]] <- sig$return
  }
  out
}

#' @rdname types
#' @export
`types<-` <- function(f, value) {
  if (!is.function(f)) {
    stop("f must be a function")
  }
  if (is.null(value)) {
    if (!is_typed(f)) {
      return(f)
    }
    inner <- environment(f)$fn
    if (is.null(inner) || !is.function(inner)) {
      return(f)
    }
    return(inner)
  }
  if (!is.list(value)) {
    stop("value must be a list (or NULL)")
  }
  do.call(as_typed, c(list(f), value))
}
