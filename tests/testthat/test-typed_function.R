test_that("typed_function validates arguments", {
  add <- typed_function(
    fn = function(x, y) x + y,
    arg_types = list(x = "numeric", y = "numeric")
  )

  expect_equal(add(5, 3), 8)
  expect_error(add("a", 3), "Type error")
})

test_that("typed_function validates return type", {
  get_number <- typed_function(
    fn = function() "not a number",
    return_type = "numeric"
  )

  expect_error(get_number(), "Type error")
})

test_that("typed_function coercion works", {
  add <- typed_function(
    fn = function(x, y) x + y,
    arg_types = list(x = "numeric", y = "numeric"),
    coerce = TRUE
  )

  expect_equal(add("5", "3"), 8)
})

test_that("signature and with_signature work", {
  sig <- signature(x = "numeric", y = "numeric", .return = "numeric")
  add <- with_signature(function(x, y) x + y, sig)

  expect_equal(add(5, 3), 8)
  expect_error(add("a", 3), "Type error")
})

test_that("is_typed identifies typed functions", {
  f1 <- function(x) x + 1
  f2 <- typed_function(f1, arg_types = list(x = "numeric"))

  expect_false(is_typed(f1))
  expect_true(is_typed(f2))
})

test_that("get_signature returns signature info", {
  f <- typed_function(
    function(x, y) x + y,
    arg_types = list(x = "numeric", y = "numeric"),
    return_type = "numeric"
  )

  sig <- get_signature(f)
  expect_equal(sig$args, list(x = "numeric", y = "numeric"))
  expect_equal(sig$return, "numeric")
})

test_that("validate_call checks without executing", {
  f <- typed_function(
    function(x, y) x + y,
    arg_types = list(x = "numeric", y = "numeric")
  )

  result <- validate_call(f, x = 5, y = 3)
  expect_true(result$valid)
  expect_null(result$errors)

  result <- validate_call(f, x = "a", y = 3)
  expect_false(result$valid)
  expect_length(result$errors, 1)
})

# T007: Tests for calling conventions

test_that("typed_function handles positional arguments", {
  add <- typed_function(
    fn = function(x, y) x + y,
    arg_specs = c(x = "numeric", y = "numeric")
  )

  expect_equal(add(1, 2), 3)
  expect_equal(add(5, 10), 15)
})

test_that("typed_function handles named arguments", {
  add <- typed_function(
    fn = function(x, y) x + y,
    arg_specs = c(x = "numeric", y = "numeric")
  )

  expect_equal(add(x = 1, y = 2), 3)
  expect_equal(add(y = 2, x = 1), 3) # Reordered named
})

test_that("typed_function handles mixed positional and named arguments", {
  add <- typed_function(
    fn = function(x, y) x + y,
    arg_specs = c(x = "numeric", y = "numeric")
  )

  expect_equal(add(1, y = 2), 3)
  expect_equal(add(x = 1, 2), 3)
})

test_that("typed_function detects missing required arguments", {
  add <- typed_function(
    fn = function(x, y) x + y,
    arg_specs = c(x = "numeric", y = "numeric")
  )

  expect_error(add(1), "missing required argument 'y'")
  expect_error(add(), "missing required argument 'x'")
})

test_that("typed_function allows missing arguments with defaults", {
  add <- typed_function(
    fn = function(x, y = 1) x + y,
    arg_specs = c(x = "numeric", y = "numeric")
  )

  expect_equal(add(5), 6)
  expect_equal(add(5, 2), 7)
})

test_that("typed_function passes ... through unchanged", {
  sum_fn <- typed_function(
    fn = function(x, ...) sum(x, ...),
    arg_specs = c(x = "numeric")
  )

  expect_equal(sum_fn(1, 2, 3, 4), 10)
  expect_equal(sum_fn(c(1, NA, 3), na.rm = TRUE), 4)
})

test_that("typed_function validates type errors for all calling conventions", {
  add <- typed_function(
    fn = function(x, y) x + y,
    arg_specs = c(x = "numeric", y = "numeric")
  )

  # Positional
  expect_error(add("a", 2), "Type error")
  # Named
  expect_error(add(x = "a", y = 2), "Type error")
  # Reordered named
  expect_error(add(y = 2, x = "a"), "Type error")
  # Mixed
  expect_error(add("a", y = 2), "Type error")
})

test_that("typed_function works with new arg_specs parameter", {
  add <- typed_function(
    fn = function(x, y) x + y,
    arg_specs = c(x = "numeric", y = "numeric"),
    return_spec = "numeric"
  )

  expect_equal(add(1, 2), 3)
  expect_error(add("a", 2), "Type error")
})

test_that("typed_function backward compatible with arg_types", {
  add <- typed_function(
    fn = function(x, y) x + y,
    arg_types = c(x = "numeric", y = "numeric"),
    return_type = "numeric"
  )

  expect_equal(add(1, 2), 3)
  expect_error(add("a", 2), "Type error")
})

# T012: Tests for metadata preservation, return validation, and get_signature

test_that("typed_function preserves custom attributes", {
  fn_with_attr <- function(x) x + 1
  attr(fn_with_attr, "custom_attr") <- "my_value"
  attr(fn_with_attr, "source") <- "test_file.R"

  typed_fn <- typed_function(
    fn = fn_with_attr,
    arg_specs = c(x = "numeric")
  )

  expect_equal(attr(typed_fn, "custom_attr"), "my_value")
  expect_equal(attr(typed_fn, "source"), "test_file.R")
})

test_that("typed_function preserves formals", {
  fn <- function(x, y = 1, z = "default") x + y
  typed_fn <- typed_function(fn, arg_specs = c(x = "numeric"))

  expect_equal(names(formals(typed_fn)), c("x", "y", "z"))
})

test_that("typed_function validates return type on success", {
  add <- typed_function(
    fn = function(x, y) x + y,
    arg_specs = c(x = "numeric", y = "numeric"),
    return_spec = "numeric"
  )

  expect_equal(add(1, 2), 3)
  expect_equal(add(1.5, 2.5), 4)
})

test_that("typed_function validates return type on failure", {
  bad_return <- typed_function(
    fn = function() "not numeric",
    return_spec = "numeric"
  )

  expect_error(bad_return(), "Type error.*return value")
})

test_that("get_signature returns complete signature info", {
  fn <- function(x, y = 1) x + y
  typed_fn <- typed_function(
    fn = fn,
    arg_specs = c(x = "numeric", y = "numeric"),
    return_spec = "numeric"
  )

  sig <- get_signature(typed_fn)

  expect_equal(sig$args, c(x = "numeric", y = "numeric"))
  expect_equal(sig$return, "numeric")
  expect_equal(names(sig$formals), c("x", "y"))
})

test_that("get_signature returns NULL for non-typed function", {
  regular_fn <- function(x) x + 1
  expect_null(get_signature(regular_fn))
})

test_that("typed_function wrapper is recognized as function", {
  add <- typed_function(
    fn = function(x, y) x + y,
    arg_specs = c(x = "numeric", y = "numeric")
  )

  expect_true(is.function(add))
  expect_true(is_typed(add))
})
