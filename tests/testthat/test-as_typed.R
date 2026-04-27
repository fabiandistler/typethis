test_that("infer_specs infers integer/double/character/logical from literal defaults", {
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
