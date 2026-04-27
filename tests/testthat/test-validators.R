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
  validator <- numeric_range(
    min = 0, max = 100, exclusive_min = TRUE, exclusive_max = TRUE
  )

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
  email_validator <- string_pattern(
    "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
  )

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

test_that("validator_constraint exposes numeric_range parameters", {
  c <- validator_constraint(numeric_range(0, 10, exclusive_max = TRUE))
  expect_equal(c$kind, "numeric_range")
  expect_equal(c$min, 0)
  expect_equal(c$max, 10)
  expect_false(c$exclusive_min)
  expect_true(c$exclusive_max)
})

test_that("validator_constraint exposes string_length parameters", {
  c <- validator_constraint(string_length(1, 50))
  expect_equal(c$kind, "string_length")
  expect_equal(c$min_length, 1)
  expect_equal(c$max_length, 50)
})

test_that("validator_constraint exposes string_pattern parameters", {
  c <- validator_constraint(string_pattern("^x", ignore_case = TRUE))
  expect_equal(c$kind, "string_pattern")
  expect_equal(c$pattern, "^x")
  expect_true(c$ignore_case)
})

test_that("validator_constraint exposes vector_length parameters", {
  c <- validator_constraint(vector_length(exact_len = 3))
  expect_equal(c$kind, "vector_length")
  expect_equal(c$exact_len, 3)
})

test_that("validator_constraint exposes enum_validator values", {
  c <- validator_constraint(enum_validator(c("a", "b", "c")))
  expect_equal(c$kind, "enum")
  expect_equal(c$values, c("a", "b", "c"))
})

test_that("validator_constraint exposes list_of parameters", {
  c <- validator_constraint(list_of("numeric", min_length = 1))
  expect_equal(c$kind, "list_of")
  expect_equal(c$element_type, "numeric")
  expect_equal(c$min_length, 1)
})

test_that("validator_constraint exposes dataframe_spec parameters", {
  c <- validator_constraint(dataframe_spec(c("a", "b"), min_rows = 1))
  expect_equal(c$kind, "dataframe_spec")
  expect_equal(c$required_cols, c("a", "b"))
  expect_equal(c$min_rows, 1)
})

test_that("nullable wraps inner constraint", {
  c <- validator_constraint(nullable(numeric_range(0, 10)))
  expect_equal(c$kind, "nullable")
  expect_equal(c$inner_constraint$kind, "numeric_range")
  expect_equal(c$inner_constraint$min, 0)
})

test_that("combine_validators captures parts", {
  c <- validator_constraint(combine_validators(
    numeric_range(0, 10), function(x) x != 5,
    all_of = FALSE
  ))
  expect_equal(c$kind, "combine")
  expect_false(c$all_of)
  expect_equal(c$parts[[1]]$kind, "numeric_range")
  expect_null(c$parts[[2]])  # plain function has no constraint
})

test_that("validator_constraint returns NULL for plain functions", {
  expect_null(validator_constraint(function(x) x > 0))
  expect_null(validator_constraint("not a function"))
})

test_that("validator behaviour unchanged after constraint attribute", {
  v <- numeric_range(0, 10)
  expect_true(v(5))
  expect_false(v(11))
  expect_true(is.function(v))
})
