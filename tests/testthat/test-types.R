test_that("Basic type creation works", {
  int_type <- create_type("integer")
  expect_s3_class(int_type, "rtype")
  expect_equal(int_type$base_type, "integer")
  expect_false(int_type$nullable)
})

test_that("Type matching works for basic types", {
  expect_true(type_matches(5L, "integer"))
  expect_true(type_matches(5.0, "numeric"))
  expect_true(type_matches("hello", "character"))
  expect_true(type_matches(TRUE, "logical"))

  expect_false(type_matches(5L, "character"))
  expect_false(type_matches("hello", "numeric"))
})

test_that("Nullable types work", {
  nullable_int <- create_type("integer", nullable = TRUE)
  expect_true(type_matches(NULL, nullable_int))
  expect_true(type_matches(5L, nullable_int))

  non_nullable_int <- create_type("integer", nullable = FALSE)
  expect_false(type_matches(NULL, non_nullable_int))
})

test_that("Any type matches everything", {
  any_type <- TYPES$any
  expect_true(type_matches(5L, any_type))
  expect_true(type_matches("hello", any_type))
  expect_true(type_matches(list(), any_type))
})

test_that("data.table type creation works", {
  dt_type <- data_table_type(id = "integer", name = "character")
  expect_equal(dt_type$base_type, "data.table")
  expect_equal(dt_type$attributes$columns$id, "integer")
  expect_equal(dt_type$attributes$columns$name, "character")
})

test_that("function type creation works", {
  fn_type <- function_type(args = list(x = "integer"), return_type = "numeric")
  expect_equal(fn_type$base_type, "function")
  expect_equal(fn_type$attributes$args$x, "integer")
  expect_equal(fn_type$attributes$return_type, "numeric")
})
