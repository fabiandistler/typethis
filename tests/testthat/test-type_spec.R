test_that("is_type_spec recognises type_spec objects", {
  expect_true(is_type_spec(t_union("numeric", "character")))
  expect_false(is_type_spec("numeric"))
  expect_false(is_type_spec(function(x) TRUE))
})

test_that("character builtins are normalized to builtin type_specs", {
  spec <- typethis:::as_type_spec("numeric")
  expect_true(is_type_spec(spec))
  expect_equal(spec$kind, "builtin")
  expect_equal(spec$name, "numeric")
})

test_that("character that matches a registered model becomes a model_ref", {
  define_model("TS_Person", fields = list(name = field("character")))
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  spec <- typethis:::as_type_spec("TS_Person")
  expect_equal(spec$kind, "model_ref")
  expect_equal(spec$class_name, "TS_Person")
})

test_that("functions become predicate type_specs", {
  spec <- typethis:::as_type_spec(function(x) x > 0)
  expect_equal(spec$kind, "predicate")
  expect_true(is.function(spec$fn))
})

test_that("unknown builtin name raises informative error", {
  expect_error(typethis:::as_type_spec("not_a_type"), "Unknown type")
})

test_that("t_union accepts mixed types and validates correctly", {
  spec <- t_union("numeric", "character")
  expect_true(is_type(1, spec))
  expect_true(is_type("hi", spec))
  expect_false(is_type(TRUE, spec))
})

test_that("t_union requires at least one alternative", {
  expect_error(t_union(), "at least one alternative")
})

test_that("t_nullable accepts NULL and inner type", {
  spec <- t_nullable("integer")
  expect_true(is_type(NULL, spec))
  expect_true(is_type(1L, spec))
  expect_false(is_type("a", spec))
})

test_that("t_list_of validates elements and length constraints", {
  spec <- t_list_of("character", min_length = 1L)
  expect_true(is_type(list("a", "b"), spec))
  expect_false(is_type(list(), spec))
  expect_false(is_type(list("a", 1), spec))
  expect_false(is_type(c("a", "b"), spec))  # atomic, not list
})

test_that("t_list_of supports nested compositions", {
  spec <- t_list_of(t_union("integer", "character"))
  expect_true(is_type(list(1L, "a", 2L), spec))
  expect_false(is_type(list(1L, TRUE), spec))
})

test_that("t_list_of exact_length is enforced", {
  spec <- t_list_of("integer", exact_length = 2L)
  expect_true(is_type(list(1L, 2L), spec))
  expect_false(is_type(list(1L), spec))
  expect_false(is_type(list(1L, 2L, 3L), spec))
})

test_that("t_vector_of enforces atomic and mode", {
  spec <- t_vector_of("integer", exact_length = 3L)
  expect_true(is_type(1:3, spec))
  expect_false(is_type(list(1L, 2L, 3L), spec))
  expect_false(is_type(c("a", "b", "c"), spec))
})

test_that("t_vector_of rejects non-builtin element types", {
  expect_error(t_vector_of(t_union("integer")), "builtin scalar type")
})

test_that("t_enum matches values in the set", {
  spec <- t_enum(c("admin", "user", "guest"))
  expect_true(is_type("admin", spec))
  expect_false(is_type("root", spec))
})

test_that("t_enum requires non-empty atomic values", {
  expect_error(t_enum(list()), "non-empty atomic")
  expect_error(t_enum(character(0)), "non-empty atomic")
})

test_that("t_model references registered models at validation time", {
  define_model("TS_Address", fields = list(zip = field("character")))
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  addr <- new_TS_Address(zip = "12345")
  spec <- t_model("TS_Address")
  expect_true(is_type(addr, spec))
  expect_false(is_type(list(zip = "12345"), spec))
})

test_that("t_predicate wraps a function and respects description", {
  spec <- t_predicate(function(x) is.numeric(x) && x > 0,
                      description = "positive number")
  expect_true(is_type(5, spec))
  expect_false(is_type(-1, spec))
  expect_match(format(spec), "positive number")
})

test_that("format.type_spec produces stable strings", {
  expect_equal(format(t_union("numeric", "character")),
               "union<numeric, character>")
  expect_equal(format(t_nullable("integer")), "nullable<integer>")
  expect_equal(format(t_list_of("character")), "list_of<character>")
  expect_equal(format(t_enum(c("a", "b"))), "enum<a, b>")
})

test_that("backward compatibility: character and closure still work", {
  expect_true(is_type(5, "numeric"))
  expect_true(is_type(5, function(x) is.numeric(x)))
  expect_false(is_type("hi", "numeric"))
})

test_that("assert_type uses formatted spec in error messages", {
  spec <- t_union("integer", "character")
  expect_error(
    assert_type(TRUE, spec, "x"),
    "must be union<integer, character>",
    fixed = TRUE
  )
})

test_that("validate_type returns formatted spec in errors", {
  spec <- t_list_of("integer")
  res <- validate_type(list("a"), spec, "items")
  expect_false(res$valid)
  expect_match(res$error, "list_of<integer>", fixed = TRUE)
})

test_that("coerce_type rejects unsupported type_spec kinds", {
  # Supported kinds (nullable, union, enum) covered in test-type_check.R.
  # Other type_spec kinds remain unsupported and signal a clear error.
  expect_error(
    coerce_type(list(1, 2), t_list_of("integer")),
    "type_spec kind 'list_of'"
  )
})

test_that("nullable=TRUE flag still works with type_spec", {
  expect_true(is_type(NULL, t_union("integer", "character"), nullable = TRUE))
  expect_false(is_type(NULL, t_union("integer", "character")))
})
