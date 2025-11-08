test_that("define_model creates valid models", {
  User <- define_model(
    name = "character",
    age = "numeric"
  )

  user <- User(name = "John", age = 30)

  expect_true(is_model(user))
  expect_equal(user$name, "John")
  expect_equal(user$age, 30)
})

test_that("define_model validates types", {
  User <- define_model(
    name = "character",
    age = "numeric"
  )

  expect_error(
    User(name = "John", age = "thirty"),
    "Type error"
  )
})

test_that("define_model handles missing required fields", {
  User <- define_model(
    name = "character",
    age = "numeric"
  )

  expect_error(
    User(name = "John"),
    "Missing required fields: age"
  )
})

test_that("field with default values", {
  User <- define_model(
    name = "character",
    age = field("numeric", default = 0)
  )

  user <- User(name = "John")
  expect_equal(user$age, 0)
})

test_that("field with custom validator", {
  User <- define_model(
    name = "character",
    age = field("numeric", validator = function(x) x >= 0 && x <= 120)
  )

  user <- User(name = "John", age = 30)
  expect_equal(user$age, 30)

  expect_error(
    User(name = "John", age = 150),
    "Validation failed"
  )
})

test_that("strict mode rejects extra fields", {
  User <- define_model(
    name = "character",
    age = "numeric",
    .strict = TRUE
  )

  expect_error(
    User(name = "John", age = 30, email = "john@example.com"),
    "Extra fields not allowed"
  )
})

test_that("get_schema returns schema", {
  User <- define_model(
    name = "character",
    age = "numeric"
  )

  schema <- get_schema(User)
  expect_equal(names(schema), c("name", "age"))

  user <- User(name = "John", age = 30)
  schema <- get_schema(user)
  expect_equal(names(schema), c("name", "age"))
})

test_that("validate_model validates instance", {
  User <- define_model(
    name = "character",
    age = "numeric"
  )

  user <- User(name = "John", age = 30, .validate_instance = FALSE)
  user$age <- "thirty"  # Invalid

  result <- validate_model(user)
  expect_false(result$valid)
  expect_length(result$errors, 1)
})

test_that("update_model updates fields", {
  User <- define_model(
    name = "character",
    age = "numeric"
  )

  user <- User(name = "John", age = 30)
  user <- update_model(user, age = 31)

  expect_equal(user$age, 31)
})

test_that("update_model validates updates", {
  User <- define_model(
    name = "character",
    age = "numeric"
  )

  user <- User(name = "John", age = 30)

  expect_error(
    update_model(user, age = "thirty"),
    "Type error"
  )
})

test_that("model_to_list converts model", {
  User <- define_model(
    name = "character",
    age = "numeric"
  )

  user <- User(name = "John", age = 30)
  lst <- model_to_list(user)

  expect_type(lst, "list")
  expect_equal(lst$name, "John")
  expect_equal(lst$age, 30)
})
