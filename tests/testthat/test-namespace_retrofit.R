# Helper: clear all hooks for a package event so leftover state from
# a failing test cannot poison its neighbours.
clear_pkg_hooks <- function(pkgname) {
  setHook(
    packageEvent(pkgname, "onLoad"),
    NULL,
    action = "replace"
  )
}

get_typethis_hooks <- function(pkgname) {
  hooks <- getHook(packageEvent(pkgname, "onLoad"))
  Filter(function(h) isTRUE(attr(h, "typethis_hook")), hooks)
}

# ---- as_typed_env(.unlock = TRUE) ------------------------------------------

test_that("as_typed_env(.unlock = TRUE) retrofits a locked binding in place", {
  e <- new.env()
  e$add <- function(x = 0L, y = 0L) x + y
  lockBinding("add", e)

  modified <- as_typed_env(e, .unlock = TRUE)

  expect_equal(modified, "add")
  expect_true(is_typed(e$add))
  expect_true(bindingIsLocked("add", e))
})

test_that("as_typed_env(.unlock = TRUE) re-locks if the wrap step errors", {
  e <- new.env()
  e$add <- function(x = 0L) x
  lockBinding("add", e)

  bad_filter <- function(name, fn) stop("boom")

  expect_error(
    as_typed_env(e, .unlock = TRUE, .filter = bad_filter),
    "boom"
  )
  expect_true(bindingIsLocked("add", e))
})

test_that("as_typed_env(.unlock = TRUE) keeps originally-open bindings open", {
  e <- new.env()
  e$open <- function(x = 0L) x
  e$frozen <- function(x = 0L) x
  lockBinding("frozen", e)

  as_typed_env(e, .unlock = TRUE)

  expect_false(bindingIsLocked("open", e))
  expect_true(bindingIsLocked("frozen", e))
  expect_true(is_typed(e$open))
  expect_true(is_typed(e$frozen))
})

test_that("as_typed_env(.unlock = FALSE) still skips locked bindings", {
  e <- new.env()
  e$frozen <- function(x = 0L) x
  lockBinding("frozen", e)

  expect_warning(
    modified <- as_typed_env(e),
    "locked"
  )
  expect_length(modified, 0)
  expect_false(is_typed(e$frozen))
})

test_that("enable_for_package forwards .unlock to as_typed_env", {
  e <- new.env()
  e$add <- function(x = 0L) x
  lockBinding("add", e)

  modified <- enable_for_package(e, .unlock = TRUE)

  expect_equal(modified, "add")
  expect_true(is_typed(e$add))
  expect_true(bindingIsLocked("add", e))
})

# ---- enable_typed_namespace -------------------------------------------------

test_that("enable_typed_namespace registers a tagged hook", {
  pkg <- "fakepkg_typethis_test_42"
  on.exit(clear_pkg_hooks(pkg), add = TRUE)

  enable_typed_namespace(pkg)

  hooks <- get_typethis_hooks(pkg)
  expect_length(hooks, 1L)
  expect_true(is.function(hooks[[1]]))
})

test_that("enable_typed_namespace's hook retrofits a locked env when invoked", {
  pkg <- "fakepkg_typethis_test_43"
  on.exit(clear_pkg_hooks(pkg), add = TRUE)

  enable_typed_namespace(pkg)
  hook <- get_typethis_hooks(pkg)[[1]]

  ns <- new.env()
  ns$add <- function(x = 0L, y = 0L) x + y
  lockBinding("add", ns)

  # Hooks fire as fn(pkgname, pkgpath); our closure forwards pkgname
  # to enable_for_package, which accepts an environment too.
  hook(ns, "")

  expect_true(is_typed(ns$add))
  expect_true(bindingIsLocked("add", ns))
})

test_that("enable_typed_namespace forwards .specs through the hook", {
  pkg <- "fakepkg_typethis_test_44"
  on.exit(clear_pkg_hooks(pkg), add = TRUE)

  enable_typed_namespace(
    pkg,
    .specs = list(add = list(.return = "integer"))
  )
  hook <- get_typethis_hooks(pkg)[[1]]

  ns <- new.env()
  ns$add <- function(x = 0L, y = 0L) x + y
  lockBinding("add", ns)

  hook(ns, "")

  expect_equal(attr(ns$add, "return_spec"), "integer")
})

test_that("enable_typed_namespace errors on bad pkgname", {
  expect_error(enable_typed_namespace(42), "must be a single non-empty string")
  expect_error(enable_typed_namespace(""), "must be a single non-empty string")
  expect_error(
    enable_typed_namespace(c("a", "b")),
    "must be a single non-empty string"
  )
  expect_error(
    enable_typed_namespace(NA_character_),
    "must be a single non-empty string"
  )
})

test_that("enable_typed_namespace returns pkgname invisibly", {
  pkg <- "fakepkg_typethis_test_45"
  on.exit(clear_pkg_hooks(pkg), add = TRUE)

  out <- withVisible(enable_typed_namespace(pkg))
  expect_false(out$visible)
  expect_equal(out$value, pkg)
})

# ---- disable_typed_namespace ------------------------------------------------

test_that("disable_typed_namespace removes typethis hooks", {
  pkg <- "fakepkg_typethis_test_46"
  on.exit(clear_pkg_hooks(pkg), add = TRUE)

  enable_typed_namespace(pkg)
  expect_length(get_typethis_hooks(pkg), 1L)

  disable_typed_namespace(pkg)

  expect_length(get_typethis_hooks(pkg), 0L)
})

test_that("disable_typed_namespace leaves foreign hooks intact", {
  pkg <- "fakepkg_typethis_test_47"
  on.exit(clear_pkg_hooks(pkg), add = TRUE)

  foreign <- function(pkgname_, pkgpath_) NULL
  setHook(packageEvent(pkg, "onLoad"), foreign)

  enable_typed_namespace(pkg)
  expect_length(getHook(packageEvent(pkg, "onLoad")), 2L)

  disable_typed_namespace(pkg)

  remaining <- getHook(packageEvent(pkg, "onLoad"))
  expect_length(remaining, 1L)
  # The remaining hook is the foreign one (no typethis tag).
  expect_false(isTRUE(attr(remaining[[1]], "typethis_hook")))
})

test_that("disable_typed_namespace is a no-op when no hooks are registered", {
  pkg <- "fakepkg_typethis_test_48"
  on.exit(clear_pkg_hooks(pkg), add = TRUE)

  expect_silent(disable_typed_namespace(pkg))
  expect_length(getHook(packageEvent(pkg, "onLoad")), 0L)
})

test_that("disable_typed_namespace returns reverted names invisibly", {
  pkg <- "fakepkg_typethis_test_49"
  on.exit(clear_pkg_hooks(pkg), add = TRUE)

  out <- withVisible(disable_typed_namespace(pkg))
  expect_false(out$visible)
  # No package loaded → nothing to revert.
  expect_equal(out$value, character(0))
})

test_that("disable_typed_namespace errors on bad pkgname", {
  expect_error(disable_typed_namespace(42), "must be a single non-empty string")
  expect_error(disable_typed_namespace(""), "must be a single non-empty string")
})

# ---- revert_typed_namespace (internal, exercised via disable on env) -------

test_that("revert_typed_namespace untypes typed bindings in a locked env", {
  e <- new.env()
  e$add <- function(x = 0L) x
  e$other <- function(y = 0L) y
  enable_for_package(e)
  lockBinding("add", e)
  lockBinding("other", e)

  reverted <- typethis:::revert_typed_namespace(e)

  expect_setequal(reverted, c("add", "other"))
  expect_false(is_typed(e$add))
  expect_false(is_typed(e$other))
  expect_true(bindingIsLocked("add", e))
  expect_true(bindingIsLocked("other", e))
})

test_that("revert_typed_namespace leaves untyped bindings alone", {
  e <- new.env()
  e$plain <- function(x) x
  e$typed <- as_typed(function(x = 0L) x)

  reverted <- typethis:::revert_typed_namespace(e)

  expect_equal(reverted, "typed")
  expect_false(is_typed(e$plain))
  expect_false(is_typed(e$typed))
})

test_that("revert_typed_namespace re-locks even when assign errors mid-loop", {
  # Simulate a scenario where a typed wrapper has no inner fn captured —
  # we just verify the unlock-then-relock guard works under a forced
  # error injected via a malformed binding.
  e <- new.env()
  e$ok <- as_typed(function(x = 0L) x)
  lockBinding("ok", e)

  # Inject a binding that looks typed but has no captured inner fn.
  fake_typed <- function() NULL
  attr(fake_typed, "typed") <- TRUE
  e$bogus <- fake_typed
  lockBinding("bogus", e)

  reverted <- typethis:::revert_typed_namespace(e)

  expect_equal(reverted, "ok")
  expect_true(bindingIsLocked("ok", e))
  expect_true(bindingIsLocked("bogus", e))
})
