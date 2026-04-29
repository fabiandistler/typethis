#' Enable type checking for an installed package, without editing it
#'
#' @description
#' Registers a `setHook(packageEvent(pkgname, "onLoad"), ...)` handler
#' that runs [enable_for_package()] over `pkgname`'s namespace each
#' time it loads, and applies the retrofit immediately if the package
#' is already loaded. Use this when you cannot — or do not want to —
#' add a `R/zzz.R` to the target package.
#'
#' Because the hook fires *after* R locks the namespace bindings,
#' `enable_typed_namespace()` retrofits each binding via the
#' unlock-modify-relock dance (see `as_typed_env(.unlock = TRUE)`).
#' Re-locking is guaranteed by `on.exit` even if a wrap step errors.
#'
#' Typical use is from `.Rprofile` or an interactive session:
#'
#' ```r
#' typethis::enable_typed_namespace("dplyr")
#' library(dplyr)   # functions are now wrapped on load
#' ```
#'
#' Standard package hook functions (`.onLoad`, `.onAttach`, ...) and
#' primitives are skipped automatically by [enable_for_package()].
#'
#' This pattern is **not for CRAN-bound code**: modifying another
#' package's namespace from outside is a developer convenience, not a
#' shipping feature. Use [enable_for_package()] from your own
#' package's `.onLoad` for production code.
#'
#' @param pkgname Single string. Name of an installed package.
#' @param .specs,.infer,.validate,.coerce,.filter Forwarded to
#'   [enable_for_package()] every time the hook fires.
#' @return Invisibly, `pkgname`.
#' @family typed functions
#' @seealso [disable_typed_namespace()] to remove the hook and revert
#'   the retrofit; [enable_for_package()] for the inside-the-package
#'   variant that is suitable for CRAN.
#' @export
#' @examples
#' \dontrun{
#' # In .Rprofile or an interactive session:
#' typethis::enable_typed_namespace("dplyr")
#' library(dplyr)
#'
#' # Later, undo:
#' typethis::disable_typed_namespace("dplyr")
#' }
enable_typed_namespace <- function(
  pkgname,
  .specs = list(),
  .infer = TRUE,
  .validate = TRUE,
  .coerce = FALSE,
  .filter = NULL
) {
  validate_pkgname(pkgname)

  forwarded <- list(
    .specs = .specs,
    .infer = .infer,
    .validate = .validate,
    .coerce = .coerce,
    .filter = .filter,
    .unlock = TRUE
  )

  hook <- function(pkgname_, pkgpath_) {
    do.call(
      enable_for_package,
      c(list(pkgname = pkgname_), forwarded)
    )
  }
  attr(hook, "typethis_hook") <- TRUE

  setHook(packageEvent(pkgname, "onLoad"), hook)

  if (isNamespaceLoaded(pkgname)) {
    do.call(
      enable_for_package,
      c(list(pkgname = pkgname), forwarded)
    )
  }

  invisible(pkgname)
}

#' Remove a typethis hook and revert the typed wrappers
#'
#' @description
#' The inverse of [enable_typed_namespace()]. Removes any typethis
#' hook previously registered for `pkgname` so future loads of the
#' package are not wrapped, and (by default) walks the currently
#' loaded namespace to replace each typed wrapper with the original
#' inner function.
#'
#' Hooks added by other code (anything *not* tagged by typethis) are
#' left intact, so this is safe to call when third-party hooks coexist
#' on the same package event.
#'
#' @param pkgname Single string. Name of an installed package.
#' @param .revert If `TRUE` (default), each currently typed binding in
#'   `pkgname`'s namespace is reverted to its inner function via the
#'   same unlock-modify-relock dance. Pass `FALSE` to leave the loaded
#'   namespace as-is and only stop the retrofit on future loads.
#' @return Invisibly, the character vector of names that were
#'   reverted (empty when `.revert` is `FALSE` or the package is not
#'   loaded).
#' @family typed functions
#' @seealso [enable_typed_namespace()] for the registration side.
#' @export
#' @examples
#' \dontrun{
#' typethis::enable_typed_namespace("dplyr")
#' library(dplyr)
#' typethis::disable_typed_namespace("dplyr")
#' }
disable_typed_namespace <- function(pkgname, .revert = TRUE) {
  validate_pkgname(pkgname)

  event <- packageEvent(pkgname, "onLoad")
  hooks <- getHook(event)
  if (length(hooks) > 0L) {
    keep <- !vapply(
      hooks,
      function(h) isTRUE(attr(h, "typethis_hook")),
      logical(1)
    )
    setHook(event, hooks[keep], action = "replace")
  }

  reverted <- character(0)
  if (isTRUE(.revert) && isNamespaceLoaded(pkgname)) {
    reverted <- revert_typed_namespace(asNamespace(pkgname))
  }

  invisible(reverted)
}

# ----- internals -----

# Walk `ns` and replace every typed binding with its inner (untyped)
# function. Locked bindings are unlocked, reassigned, then re-locked.
# Re-locking is guaranteed by on.exit so a mid-loop error cannot leave
# the namespace partially unlocked.
revert_typed_namespace <- function(ns) {
  if (!is.environment(ns)) {
    stop("ns must be an environment")
  }

  candidates <- ls(envir = ns, all.names = TRUE)
  reverted <- character(0)
  unlocked_during_loop <- character(0)

  on.exit(
    {
      for (nm in unlocked_during_loop) {
        if (exists(nm, envir = ns, inherits = FALSE)) {
          lockBinding(nm, ns)
        }
      }
    },
    add = TRUE
  )

  for (nm in candidates) {
    fn <- get(nm, envir = ns, inherits = FALSE)
    if (!is.function(fn) || !is_typed(fn)) {
      next
    }
    inner <- environment(fn)$fn
    if (is.null(inner) || !is.function(inner)) {
      next
    }
    if (bindingIsLocked(nm, ns)) {
      unlockBinding(nm, ns)
      unlocked_during_loop <- c(unlocked_during_loop, nm)
    }
    assign(nm, inner, envir = ns)
    reverted <- c(reverted, nm)
  }

  reverted
}

# Shared validator for the public-API string argument.
validate_pkgname <- function(pkgname) {
  if (
    !is.character(pkgname) ||
      length(pkgname) != 1L ||
      is.na(pkgname) ||
      !nzchar(pkgname)
  ) {
    stop("pkgname must be a single non-empty string")
  }
  invisible(TRUE)
}
