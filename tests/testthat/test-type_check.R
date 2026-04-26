test_that("is_type works for basic types", {
  expect_true(is_type(5, "numeric"))
  expect_true(is_type(5L, "integer"))
  expect_true(is_type("hello", "character"))
  expect_true(is_type(TRUE, "logical"))
  expect_true(is_type(list(1, 2), "list"))
  expect_true(is_type(data.frame(x = 1), "data.frame"))

  expect_false(is_type("hello", "numeric"))
  expect_false(is_type(5, "character"))
})

test_that("is_type handles NULL correctly", {
  expect_false(is_type(NULL, "numeric"))
  expect_true(is_type(NULL, "numeric", nullable = TRUE))
})

test_that("is_type works with custom validators", {
  is_positive <- function(x) is.numeric(x) && all(x > 0)
  expect_true(is_type(5, is_positive))
  expect_false(is_type(-5, is_positive))
})

test_that("assert_type throws errors correctly", {
  expect_silent(assert_type(5, "numeric", "x"))
  expect_error(
    assert_type("hello", "numeric", "x"),
    "Type error: 'x' must be numeric"
  )
})

test_that("validate_type returns correct structure", {
  result <- validate_type(5, "numeric", "x")
  expect_true(result$valid)
  expect_null(result$error)

  result <- validate_type("hello", "numeric", "x")
  expect_false(result$valid)
  expect_match(result$error, "Type error")
})

test_that("is_one_of works with multiple types", {
  expect_true(is_one_of(5, c("numeric", "character")))
  expect_true(is_one_of("hello", c("numeric", "character")))
  expect_false(is_one_of(TRUE, c("numeric", "character")))
})

test_that("coerce_type works", {
  expect_equal(coerce_type("123", "numeric"), 123)
  expect_equal(coerce_type(123, "character"), "123")
  expect_equal(coerce_type(c(1, 2), "integer"), c(1L, 2L))
})

test_that("coerce_type handles errors", {
  expect_error(
    coerce_type("abc", "numeric", strict = TRUE),
    "Coercion to numeric resulted in NA"
  )
})

test_that("coerce_type accepts t_nullable", {
  spec <- t_nullable("numeric")
  expect_null(coerce_type(NULL, spec))
  expect_equal(coerce_type("123", spec), 123)
  expect_equal(coerce_type(5, spec), 5)
})

test_that("coerce_type accepts t_union by trying alternatives in order", {
  spec <- t_union("integer", "character")
  # "5" already validates as integer after as.integer(): first wins
  expect_equal(coerce_type("5", spec), 5L)
  # Reversing alternative order keeps the input as character
  expect_equal(coerce_type("5", t_union("character", "integer")), "5")
})

test_that("coerce_type errors when no union alternative matches", {
  spec <- t_union("integer", "logical")
  expect_error(
    coerce_type(function() 1, spec),
    "no alternative matched"
  )
})

test_that("coerce_type accepts t_enum", {
  spec <- t_enum(c("admin", "user"))
  expect_equal(coerce_type("admin", spec), "admin")
  expect_error(
    coerce_type("guest", spec),
    "value not in allowed set"
  )
})

test_that("coerce_type rejects unsupported type_spec kinds with clear error", {
  expect_error(
    coerce_type(list(1, 2), t_list_of("integer")),
    "type_spec kind 'list_of'"
  )
  expect_error(
    coerce_type(5, t_predicate(function(x) x > 0)),
    "type_spec kind 'predicate'"
  )
})
