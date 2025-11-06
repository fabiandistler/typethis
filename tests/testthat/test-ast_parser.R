test_that("parse_code works with simple code", {
  code <- "x <- 5"
  parsed <- parse_code(code)

  expect_type(parsed, "list")
  expect_true("expr" %in% names(parsed))
  expect_true("parse_data" %in% names(parsed))
  expect_true("code" %in% names(parsed))
})

test_that("extract_assignments finds assignments", {
  code <- "x <- 5\ny <- 10"
  parsed <- parse_code(code)
  assignments <- extract_assignments(parsed)

  expect_s3_class(assignments, "data.frame")
  expect_equal(nrow(assignments), 2)
  expect_true("x" %in% assignments$variable)
  expect_true("y" %in% assignments$variable)
})

test_that("extract_function_calls finds function calls", {
  code <- "x <- sum(1, 2, 3)\ny <- mean(x)"
  parsed <- parse_code(code)
  calls <- extract_function_calls(parsed)

  expect_s3_class(calls, "data.frame")
  expect_true("sum" %in% calls$function_name)
  expect_true("mean" %in% calls$function_name)
})

test_that("extract_functions finds function definitions", {
  code <- "add <- function(x, y) { x + y }"
  parsed <- parse_code(code)
  functions <- extract_functions(parsed)

  expect_type(functions, "list")
  expect_gt(length(functions), 0)
})

test_that("parse_code handles errors gracefully", {
  code <- "x <- "  # Invalid code
  expect_error(parse_code(code), "Parse error")
})

test_that("extract_assignments returns empty for no assignments", {
  code <- "print('hello')"
  parsed <- parse_code(code)
  assignments <- extract_assignments(parsed)

  expect_equal(nrow(assignments), 0)
})
