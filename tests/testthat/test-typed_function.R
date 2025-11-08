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
