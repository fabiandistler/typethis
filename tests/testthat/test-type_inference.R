test_that("infer_type works for basic literals", {
  expect_equal(infer_type(5L)$base_type, "integer")
  expect_equal(infer_type(5.0)$base_type, "double")
  expect_equal(infer_type("hello")$base_type, "character")
  expect_equal(infer_type(TRUE)$base_type, "logical")
  expect_equal(infer_type(NULL)$base_type, "NULL")
})

test_that("infer_type works for data structures", {
  expect_equal(infer_type(list())$base_type, "list")
  expect_equal(infer_type(data.frame())$base_type, "data.frame")
  expect_equal(infer_type(function() {})$base_type, "function")
})

test_that("infer_type_from_expr works for literals", {
  expr <- quote(5L)
  expect_equal(infer_type_from_expr(expr)$base_type, "integer")

  expr <- quote("hello")
  expect_equal(infer_type_from_expr(expr)$base_type, "character")
})

test_that("infer_type_from_call recognizes constructors", {
  expr <- quote(c(1, 2, 3))
  result <- infer_type_from_expr(expr)
  expect_equal(result$base_type, "numeric")

  expr <- quote(list(a = 1, b = 2))
  result <- infer_type_from_expr(expr)
  expect_equal(result$base_type, "list")

  expr <- quote(data.frame(x = 1:3))
  result <- infer_type_from_expr(expr)
  expect_equal(result$base_type, "data.frame")
})

test_that("infer_type_from_call handles type conversions", {
  expr <- quote(as.integer(5.5))
  result <- infer_type_from_expr(expr)
  expect_equal(result$base_type, "integer")

  expr <- quote(as.character(123))
  result <- infer_type_from_expr(expr)
  expect_equal(result$base_type, "character")
})

test_that("infer_type_from_call handles operations", {
  expr <- quote(5 + 3)
  result <- infer_type_from_expr(expr)
  expect_equal(result$base_type, "numeric")

  expr <- quote(5 > 3)
  result <- infer_type_from_expr(expr)
  expect_equal(result$base_type, "logical")
})

test_that("infer_types_from_code works", {
  code <- "x <- 5L\ny <- 3.14\nz <- 'hello'"
  result <- infer_types_from_code(code)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3)
  expect_true("integer" %in% result$type)
  expect_true("numeric" %in% result$type)
  expect_true("character" %in% result$type)
})

test_that("build_type_context creates proper context", {
  code <- "x <- 5L\ny <- x"
  parsed <- parse_code(code)
  context <- build_type_context(parsed)

  expect_type(context, "list")
  expect_true("x" %in% names(context))
  expect_equal(context$x$base_type, "integer")
})
