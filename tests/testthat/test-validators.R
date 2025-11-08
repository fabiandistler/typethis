test_that("numeric_range works", {
  validator <- numeric_range(min = 0, max = 100)

  expect_true(validator(50))
  expect_true(validator(0))
  expect_true(validator(100))
  expect_false(validator(-1))
  expect_false(validator(101))
  expect_false(validator("50"))
})

test_that("numeric_range handles exclusive bounds", {
  validator <- numeric_range(min = 0, max = 100, exclusive_min = TRUE, exclusive_max = TRUE)

  expect_true(validator(50))
  expect_false(validator(0))
  expect_false(validator(100))
})

test_that("string_length works", {
  validator <- string_length(min_length = 3, max_length = 10)

  expect_true(validator("hello"))
  expect_true(validator("hi there"))
  expect_false(validator("hi"))
  expect_false(validator("this is too long"))
  expect_false(validator(123))
})

test_that("string_pattern works", {
  email_validator <- string_pattern("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")

  expect_true(email_validator("user@example.com"))
  expect_true(email_validator("test.user@example.co.uk"))
  expect_false(email_validator("invalid-email"))
  expect_false(email_validator("@example.com"))
})

test_that("vector_length works", {
  validator <- vector_length(min_len = 2, max_len = 5)

  expect_true(validator(c(1, 2)))
  expect_true(validator(c(1, 2, 3)))
  expect_false(validator(1))
  expect_false(validator(1:10))
})

test_that("vector_length with exact length", {
  validator <- vector_length(exact_len = 3)

  expect_true(validator(c(1, 2, 3)))
  expect_false(validator(c(1, 2)))
  expect_false(validator(c(1, 2, 3, 4)))
})

test_that("dataframe_spec works", {
  validator <- dataframe_spec(
    required_cols = c("id", "name"),
    min_rows = 1,
    max_rows = 100
  )

  df_valid <- data.frame(id = 1:3, name = c("A", "B", "C"))
  df_missing_col <- data.frame(id = 1:3)
  df_empty <- data.frame(id = integer(0), name = character(0))

  expect_true(validator(df_valid))
  expect_false(validator(df_missing_col))
  expect_false(validator(df_empty))
})

test_that("enum_validator works", {
  validator <- enum_validator(c("red", "green", "blue"))

  expect_true(validator("red"))
  expect_true(validator("blue"))
  expect_false(validator("yellow"))
})

test_that("list_of works", {
  validator <- list_of("numeric", min_length = 1, max_length = 5)

  expect_true(validator(list(1, 2, 3)))
  expect_false(validator(list("a", "b")))
  expect_false(validator(list()))
})

test_that("nullable works", {
  base_validator <- function(x) is.numeric(x)
  validator <- nullable(base_validator)

  expect_true(validator(5))
  expect_true(validator(NULL))
  expect_false(validator("hello"))
})

test_that("combine_validators works with all_of = TRUE", {
  validator <- combine_validators(
    function(x) is.numeric(x),
    function(x) all(x > 0),
    all_of = TRUE
  )

  expect_true(validator(5))
  expect_false(validator(-5))
  expect_false(validator("5"))
})

test_that("combine_validators works with all_of = FALSE", {
  validator <- combine_validators(
    function(x) is.numeric(x),
    function(x) is.character(x),
    all_of = FALSE
  )

  expect_true(validator(5))
  expect_true(validator("hello"))
  expect_false(validator(TRUE))
})
