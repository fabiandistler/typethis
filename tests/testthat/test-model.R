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
  user$age <- "thirty" # Invalid

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

# =============================================================================
# New-style API tests (v0.2+)
# =============================================================================

test_that("new-style define_model creates new_<ClassName> function", {
  define_model("Person",
    fields = list(
      name = field("character", nullable = FALSE),
      age = field("integer", nullable = FALSE, default = 0L)
    )
  )

  expect_true(exists("new_Person", envir = environment()))
  expect_true(is.function(new_Person))
})

test_that("new-style define_model creates update_<ClassName> function", {
  define_model("Employee",
    fields = list(
      name = field("character", nullable = FALSE),
      salary = field("numeric", nullable = FALSE)
    )
  )

  expect_true(exists("update_Employee", envir = environment()))
  expect_true(is.function(update_Employee))
})

test_that("new-style constructor creates valid instance", {
  define_model("Person",
    fields = list(
      name = field("character", nullable = FALSE),
      age = field("integer", nullable = FALSE, default = 0L)
    )
  )

  p <- new_Person(name = "Alice", age = 30L)

  expect_true(is_model(p))
  expect_true(inherits(p, "Person"))
  expect_equal(p$name, "Alice")
  expect_equal(p$age, 30L)
})

test_that("new-style missing required field error", {
  define_model("RequiredTest",
    fields = list(
      name = field("character", nullable = FALSE),
      value = field("numeric", nullable = FALSE)
    )
  )

  expect_error(
    new_RequiredTest(name = "test"),
    "Missing required fields"
  )
})

test_that("new-style default values applied", {
  define_model("DefaultTest",
    fields = list(
      name = field("character", nullable = FALSE),
      count = field("integer", nullable = FALSE, default = 42L)
    )
  )

  d <- new_DefaultTest(name = "test")
  expect_equal(d$count, 42L)
})

test_that("new-style type validation works", {
  define_model("TypeTest",
    fields = list(
      name = field("character", nullable = FALSE),
      age = field("integer", nullable = FALSE)
    )
  )

  expect_error(
    new_TypeTest(name = "Alice", age = "not an integer"),
    "Type error"
  )
})

test_that("new-style update function works", {
  define_model("UpdateTest",
    fields = list(
      name = field("character", nullable = FALSE),
      age = field("integer", nullable = FALSE, default = 0L)
    )
  )

  p <- new_UpdateTest(name = "Alice", age = 30L)
  p2 <- update_UpdateTest(p, age = 31L)

  expect_equal(p2$age, 31L)
  expect_equal(p2$name, "Alice")
})

test_that("new-style update validates type", {
  define_model("UpdateValidate",
    fields = list(
      name = field("character", nullable = FALSE),
      age = field("integer", nullable = FALSE)
    )
  )

  p <- new_UpdateValidate(name = "Alice", age = 30L)

  expect_error(
    update_UpdateValidate(p, age = "not an integer"),
    "Type error"
  )
})

test_that("new-style nullable fields accept NULL", {
  define_model("NullableTest",
    fields = list(
      name = field("character", nullable = FALSE),
      nickname = field("character", nullable = TRUE)
    )
  )

  p <- new_NullableTest(name = "Alice", nickname = NULL)
  expect_true(is_model(p))
  expect_null(p$nickname)
})

test_that("new-style non-nullable fields reject NULL", {
  define_model("NonNullableTest",
    fields = list(
      name = field("character", nullable = FALSE)
    )
  )

  expect_error(
    new_NonNullableTest(name = NULL),
    "cannot be NULL"
  )
})

test_that("new-style nested model support", {
  # Define inner model first
  define_model("Address",
    fields = list(
      street = field("character", nullable = FALSE),
      city = field("character", nullable = FALSE)
    )
  )

  # Define outer model with nested model field
  define_model("PersonWithAddress",
    fields = list(
      name = field("character", nullable = FALSE),
      address = field("Address", nullable = FALSE)
    )
  )

  addr <- new_Address(street = "123 Main St", city = "Springfield")
  p <- new_PersonWithAddress(name = "Alice", address = addr)

  expect_true(is_model(p))
  expect_true(inherits(p, "PersonWithAddress"))
  expect_true(inherits(p$address, "Address"))
  expect_equal(p$address$city, "Springfield")
})

test_that("new-style nested model validates type", {
  # Define inner model
  define_model("InnerModel",
    fields = list(
      value = field("numeric", nullable = FALSE)
    )
  )

  # Define outer model
  define_model("OuterModel",
    fields = list(
      inner = field("InnerModel", nullable = FALSE)
    )
  )

  # Should fail with wrong type
  expect_error(
    new_OuterModel(inner = "not a model"),
    "must be a typed model"
  )

  # Should fail with wrong model class
  define_model("WrongModel",
    fields = list(x = field("numeric", nullable = FALSE))
  )
  wrong <- new_WrongModel(x = 1)

  expect_error(
    new_OuterModel(inner = wrong),
    "must be of class 'InnerModel'"
  )
})

test_that("new-style custom validator works", {
  define_model("ValidatedModel",
    fields = list(
      age = field("integer", nullable = FALSE, validator = function(x) x >= 0 && x <= 120)
    )
  )

  p <- new_ValidatedModel(age = 30L)
  expect_equal(p$age, 30L)

  expect_error(
    new_ValidatedModel(age = 150L),
    "Validation failed"
  )
})

test_that("new-style with fields parameter", {
  define_model("FieldsParam",
    fields = list(
      x = field("numeric", nullable = FALSE),
      y = field("character", nullable = FALSE, default = "default")
    )
  )

  f <- new_FieldsParam(x = 1)
  expect_equal(f$x, 1)
  expect_equal(f$y, "default")
})

test_that("new-style strict mode rejects extra fields", {
  define_model("StrictModel",
    fields = list(
      name = field("character", nullable = FALSE)
    ),
    .strict = TRUE
  )

  expect_error(
    new_StrictModel(name = "test", extra = "field"),
    "Extra fields not allowed"
  )
})
