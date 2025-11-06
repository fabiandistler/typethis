test_that("check_types runs without errors", {
  code <- "x <- 5L\ny <- 10"
  result <- check_types(code)

  expect_s3_class(result, "type_check_result")
  expect_type(result$errors, "list")
  expect_type(result$warnings, "list")
})

test_that("check_types detects type reassignment", {
  code <- "x <- 5L\nx <- 'hello'"
  result <- check_types(code)

  expect_gt(length(result$warnings), 0)
  # Should warn about type change from integer to character
})

test_that("typed decorator validates types", {
  add_typed <- typed(x = "integer", y = "integer", .return = "integer")(
    function(x, y) {
      x + y
    }
  )

  # Valid call
  expect_equal(add_typed(x = 5L, y = 3L), 8L)

  # Invalid call (wrong type)
  expect_error(add_typed(x = "hello", y = 3L), "Type error")
})

test_that("check_types handles parse errors", {
  code <- "x <- "  # Invalid
  result <- check_types(code)

  expect_gt(length(result$errors), 0)
})

test_that("print.type_check_result works", {
  code <- "x <- 5L"
  result <- check_types(code)

  expect_output(print(result), "Type Check Results")
})
