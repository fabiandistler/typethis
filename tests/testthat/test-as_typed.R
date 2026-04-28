test_that("infer_specs infers atomic types from literal defaults", {
  f <- function(i = 1L, d = 1.5, s = "a", b = TRUE) NULL
  expect_equal(
    infer_specs(f),
    list(i = "integer", d = "double", s = "character", b = "logical")
  )
})

test_that("infer_specs skips NULL, calls, missing defaults, and ...", {
  f <- function(x, y = NULL, z = list(), q = c(1, 2), ...) NULL
  expect_equal(infer_specs(f), list())
})

test_that("infer_specs returns empty list for zero-arg function", {
  expect_equal(infer_specs(function() NULL), list())
})

test_that("infer_specs only emits entries for inferable formals", {
  f <- function(x, y = 1L, z = NULL) NULL
  expect_equal(infer_specs(f), list(y = "integer"))
})

test_that("infer_specs errors on non-function input", {
  expect_error(infer_specs("not a function"), "must be a function")
})

test_that("as_typed infers specs from defaults by default", {
  add <- as_typed(function(x = 0L, y = 0L) x + y)
  expect_true(is_typed(add))
  expect_equal(
    attr(add, "arg_specs"),
    list(x = "integer", y = "integer")
  )
  expect_equal(add(2L, 3L), 5L)
  expect_error(add("a", 3L), "Type error")
})

test_that("as_typed accepts overrides via ...", {
  f <- as_typed(
    function(x = 0L, y = 0L) x + y,
    x = "numeric"
  )
  specs <- attr(f, "arg_specs")
  expect_equal(specs$x, "numeric")
  expect_equal(specs$y, "integer")
})

test_that("as_typed override wins over inference", {
  f <- as_typed(function(x = 0L) x, x = "character")
  expect_equal(attr(f, "arg_specs")$x, "character")
  expect_equal(f("hi"), "hi")
  expect_error(f(1L), "Type error")
})

test_that("as_typed with NULL override opts an argument out", {
  f <- as_typed(function(x = 1L, y = 1L) list(x, y), y = NULL)
  specs <- attr(f, "arg_specs")
  expect_equal(specs, list(x = "integer"))
  expect_equal(f(1L, "anything"), list(1L, "anything"))
})

test_that("as_typed with .infer = FALSE disables inference", {
  f <- as_typed(function(x = 1L, y = 1L) list(x, y), .infer = FALSE)
  expect_equal(attr(f, "arg_specs"), list())
  expect_equal(f("a", "b"), list("a", "b"))
})

test_that("as_typed with .infer = FALSE still applies overrides", {
  f <- as_typed(
    function(x = 1L, y = 1L) list(x, y),
    x = "integer",
    .infer = FALSE
  )
  expect_equal(attr(f, "arg_specs"), list(x = "integer"))
  expect_error(f("a", "b"), "Type error")
})

test_that("as_typed enforces .return", {
  f <- as_typed(
    function(x = 1L) "not numeric",
    .return = "numeric"
  )
  expect_error(f(1L), "Type error.*return value")
})

test_that("as_typed never infers .return", {
  f <- as_typed(function(x = 1L) "result")
  expect_null(attr(f, "return_spec"))
})

test_that("as_typed supports .coerce", {
  f <- as_typed(
    function(x = 0) x * 2,
    .coerce = TRUE
  )
  expect_equal(f("5"), 10)
})

test_that("as_typed errors on unnamed ...", {
  expect_error(
    as_typed(function(x = 1L) x, "integer"),
    "must be named"
  )
})

test_that("as_typed errors on unknown argument names", {
  expect_error(
    as_typed(function(x = 1L) x, z = "integer"),
    "Unknown argument name"
  )
})

test_that("as_typed errors on non-function input", {
  expect_error(as_typed("not a function"), "must be a function")
})

test_that("as_typed accepts type_spec objects", {
  f <- as_typed(
    function(x = 1L) x,
    x = t_union("integer", "character")
  )
  expect_equal(f(1L), 1L)
  expect_equal(f("hi"), "hi")
  expect_error(f(TRUE), "must be union")
})

test_that("as_typed is idempotent: re-wrapping does not double-wrap", {
  orig <- function(x = 1L, y = 1L) x + y
  once <- as_typed(orig, x = "integer")
  twice <- as_typed(once, y = "integer")

  expect_true(is_typed(twice))
  inner <- environment(twice)$fn
  expect_false(is_typed(inner))
  expect_identical(inner, orig)
})

test_that("as_typed merges specs across re-wraps", {
  orig <- function(x = 1L, y = 1L, z = 1L) x + y + z
  once <- as_typed(orig, x = "integer", .infer = FALSE)
  twice <- as_typed(once, y = "character", .infer = FALSE)

  specs <- attr(twice, "arg_specs")
  expect_equal(specs$x, "integer")
  expect_equal(specs$y, "character")
  expect_null(specs$z)
})

test_that("as_typed preserves .return across re-wraps", {
  orig <- function(x = 1L) x
  once <- as_typed(orig, .return = "integer")
  twice <- as_typed(once, x = "integer")

  expect_equal(attr(twice, "return_spec"), "integer")
})

test_that("as_typed handles positional, named, and reordered named calls", {
  add <- as_typed(function(x = 0L, y = 0L) x + y, .return = "integer")

  expect_equal(add(1L, 2L), 3L)
  expect_equal(add(x = 1L, y = 2L), 3L)
  expect_equal(add(y = 2L, x = 1L), 3L)
  expect_equal(add(1L, y = 2L), 3L)
})

test_that("as_typed passes ... through unchanged", {
  total <- as_typed(function(x = 0, ...) sum(x, ...))
  expect_equal(total(c(1, 2, 3)), 6)
  expect_equal(total(c(1, NA, 3), na.rm = TRUE), 4)
})

test_that("as_typed with no inferable defaults falls back to no specs", {
  f <- as_typed(function(x, y) NULL)
  expect_equal(attr(f, "arg_specs"), list())
})

test_that("as_typed_env retrofits all functions in an environment", {
  e <- new.env()
  e$add <- function(x = 0L, y = 0L) x + y
  e$greet <- function(name = "world") paste0("hi ", name)

  modified <- as_typed_env(e)

  expect_setequal(modified, c("add", "greet"))
  expect_true(is_typed(e$add))
  expect_true(is_typed(e$greet))
  expect_equal(
    attr(e$add, "arg_specs"),
    list(x = "integer", y = "integer")
  )
  expect_equal(attr(e$greet, "arg_specs"), list(name = "character"))
})

test_that("as_typed_env skips non-function bindings", {
  e <- new.env()
  e$add <- function(x = 0L) x
  e$constant <- 42L
  e$msg <- "hello"

  modified <- as_typed_env(e)

  expect_equal(modified, "add")
  expect_true(is_typed(e$add))
  expect_equal(e$constant, 42L)
  expect_equal(e$msg, "hello")
})

test_that("as_typed_env honours .filter", {
  e <- new.env()
  e$keep <- function(x = 1L) x
  e$skip <- function(x = 1L) x

  modified <- as_typed_env(
    e,
    .filter = function(name, fn) name == "keep"
  )

  expect_equal(modified, "keep")
  expect_true(is_typed(e$keep))
  expect_false(is_typed(e$skip))
})

test_that("as_typed_env applies per-function .specs overrides", {
  e <- new.env()
  e$add <- function(x = 0L, y = 0L) x + y

  as_typed_env(e, .specs = list(
    add = list(x = "numeric", .return = "numeric")
  ))

  expect_equal(attr(e$add, "arg_specs")$x, "numeric")
  expect_equal(attr(e$add, "arg_specs")$y, "integer")
  expect_equal(attr(e$add, "return_spec"), "numeric")
})

test_that("as_typed_env per-function .infer FALSE wins over default", {
  e <- new.env()
  e$add <- function(x = 0L, y = 0L) x + y

  as_typed_env(e, .specs = list(add = list(.infer = FALSE)))

  expect_equal(attr(e$add, "arg_specs"), list())
})

test_that("as_typed_env returns invisibly", {
  e <- new.env()
  e$add <- function(x = 0L) x

  out <- withVisible(as_typed_env(e))
  expect_false(out$visible)
  expect_equal(out$value, "add")
})

test_that("as_typed_env is idempotent across re-runs", {
  e <- new.env()
  e$add <- function(x = 0L, y = 0L) x + y

  as_typed_env(e)
  once <- e$add
  as_typed_env(e)
  twice <- e$add

  expect_true(is_typed(twice))
  inner <- environment(twice)$fn
  expect_false(is_typed(inner))
  expect_equal(attr(once, "arg_specs"), attr(twice, "arg_specs"))
})

test_that("as_typed_env warns and skips locked bindings", {
  e <- new.env()
  e$open <- function(x = 0L) x
  e$frozen <- function(x = 0L) x
  lockBinding("frozen", e)

  expect_warning(
    modified <- as_typed_env(e),
    "locked"
  )

  expect_equal(modified, "open")
  expect_true(is_typed(e$open))
  expect_false(is_typed(e$frozen))
})

test_that("as_typed_env errors on non-environment input", {
  expect_error(as_typed_env(list()), "must be an environment")
})

test_that("as_typed_env errors on bad .specs shape", {
  e <- new.env()
  e$add <- function(x = 0L) x

  expect_error(as_typed_env(e, .specs = "not a list"), "must be a named list")
  expect_error(
    as_typed_env(e, .specs = list("integer")),
    "must be named"
  )
  expect_error(
    as_typed_env(e, .specs = list(add = "not a list")),
    "must be lists"
  )
  expect_error(
    as_typed_env(e, .specs = list(missing = list(x = "integer"))),
    "Unknown name"
  )
})

test_that("as_typed_env errors on non-function .filter", {
  e <- new.env()
  e$add <- function(x = 0L) x
  expect_error(as_typed_env(e, .filter = "no"), "must be a function")
})

test_that("types() returns empty list for an untyped function", {
  expect_equal(types(function(x) x), list())
})

test_that("types() returns named arg specs and .return for typed functions", {
  f <- as_typed(
    function(x = 1L, y = 1L) x + y,
    .return = "integer"
  )
  out <- types(f)
  expect_equal(out$x, "integer")
  expect_equal(out$y, "integer")
  expect_equal(out$.return, "integer")
})

test_that("types() omits .return when no return spec is set", {
  f <- as_typed(function(x = 1L) x)
  out <- types(f)
  expect_false(".return" %in% names(out))
})

test_that("types() errors on non-function input", {
  expect_error(types("nope"), "must be a function")
})

test_that("types(f) <- list(...) wraps via as_typed", {
  f <- function(x = 0L, y = 0L) x + y
  types(f) <- list(x = "integer", y = "integer", .return = "integer")

  expect_true(is_typed(f))
  expect_equal(attr(f, "arg_specs"), list(x = "integer", y = "integer"))
  expect_equal(attr(f, "return_spec"), "integer")
})

test_that("types(f) <- NULL un-types a typed function", {
  orig <- function(x = 0L) x
  f <- as_typed(orig)
  types(f) <- NULL

  expect_false(is_typed(f))
  expect_identical(f, orig)
})

test_that("types(f) <- NULL on an untyped function is a no-op", {
  f <- function(x) x
  types(f) <- NULL
  expect_false(is_typed(f))
})

test_that("types(f) <- value errors on non-list, non-NULL value", {
  f <- function(x = 0L) x
  expect_error(`types<-`(f, value = "integer"), "must be a list")
  expect_error(`types<-`(f, value = 42), "must be a list")
})

test_that("types() round-trips through types<-", {
  src <- as_typed(
    function(x = 1L, y = 1L) x + y,
    .return = "integer"
  )
  dst <- function(x = 0L, y = 0L) x + y
  types(dst) <- types(src)

  expect_equal(attr(dst, "arg_specs"), attr(src, "arg_specs"))
  expect_equal(attr(dst, "return_spec"), attr(src, "return_spec"))
})
