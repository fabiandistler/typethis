test_that("builtin types map to JSON Schema", {
  expect_equal(to_json_schema("numeric"), list(type = "number"))
  expect_equal(to_json_schema("integer"), list(type = "integer"))
  expect_equal(to_json_schema("character"), list(type = "string"))
  expect_equal(to_json_schema("logical"), list(type = "boolean"))
  expect_equal(to_json_schema("list"), list(type = "array"))
})

test_that("date and posixct map to string with format", {
  expect_equal(to_json_schema("date"), list(type = "string", format = "date"))
  expect_equal(
    to_json_schema("posixct"),
    list(type = "string", format = "date-time")
  )
})

test_that("data.frame and factor map with x-typethis extensions", {
  s <- to_json_schema("data.frame")
  expect_equal(s$type, "array")
  expect_equal(s$`x-typethis-kind`, "data.frame")

  s2 <- to_json_schema("factor")
  expect_equal(s2$type, "string")
  expect_equal(s2$`x-typethis-kind`, "factor")
})

test_that("t_union becomes oneOf", {
  s <- to_json_schema(t_union("integer", "character"))
  expect_named(s, "oneOf")
  expect_equal(s$oneOf[[1]]$type, "integer")
  expect_equal(s$oneOf[[2]]$type, "string")
})

test_that("t_nullable shortens to type-array form when single inner type", {
  s <- to_json_schema(t_nullable("integer"))
  expect_equal(s$type, c("integer", "null"))
})

test_that("t_nullable falls back to oneOf for composite inner", {
  s <- to_json_schema(t_nullable(t_union("integer", "character")))
  expect_named(s, "oneOf")
  expect_equal(s$oneOf[[2]]$type, "null")
})

test_that("t_enum infers value type", {
  s <- to_json_schema(t_enum(c("a", "b")))
  expect_equal(s$type, "string")
  expect_equal(s$enum, list("a", "b"))

  s2 <- to_json_schema(t_enum(1:3))
  expect_equal(s2$type, "integer")
})

test_that("t_list_of becomes array with items", {
  s <- to_json_schema(t_list_of("integer", min_length = 1L))
  expect_equal(s$type, "array")
  expect_equal(s$items, list(type = "integer"))
  expect_equal(s$minItems, 1L)
})

test_that("t_list_of exact_length sets min and max items equal", {
  s <- to_json_schema(t_list_of("integer", exact_length = 3L))
  expect_equal(s$minItems, 3L)
  expect_equal(s$maxItems, 3L)
})

test_that("validator constraints map correctly", {
  expect_equal(
    to_json_schema(numeric_range(0, 10)),
    list(type = "number", minimum = 0, maximum = 10)
  )
  expect_equal(
    to_json_schema(numeric_range(0, 10, exclusive_max = TRUE))$exclusiveMaximum,
    10
  )
  expect_equal(
    to_json_schema(string_length(1, 50)),
    list(type = "string", minLength = 1, maxLength = 50)
  )
  s <- to_json_schema(string_pattern("^x"))
  expect_equal(s$pattern, "^x")
  s2 <- to_json_schema(vector_length(exact_len = 3))
  expect_equal(s2$minItems, 3)
  expect_equal(s2$maxItems, 3)
  s3 <- to_json_schema(enum_validator(c("a", "b")))
  expect_equal(s3$enum, list("a", "b"))
})

test_that("custom predicate function falls back to extension", {
  s <- to_json_schema(function(x) x > 0)
  expect_equal(s$`x-typethis-kind`, "predicate")
})

test_that("field with type and validator merges into one fragment", {
  fld <- field("numeric", validator = numeric_range(0, 10))
  s <- to_json_schema(fld)
  expect_equal(s$type, "number")
  expect_equal(s$minimum, 0)
  expect_equal(s$maximum, 10)
})

test_that("field nullable wraps the fragment", {
  fld <- field("integer", nullable = TRUE)
  s <- to_json_schema(fld)
  expect_equal(s$type, c("integer", "null"))
})

test_that("field default and description are propagated", {
  fld <- field("integer", default = 0L, description = "an int")
  s <- to_json_schema(fld)
  expect_equal(s$default, 0L)
  expect_equal(s$description, "an int")
})

test_that("model export produces top-level object schema", {
  define_model(
    "JS_Person",
    fields = list(
      name = field("character", nullable = FALSE),
      age = field("integer", validator = numeric_range(0, 120)),
      role = field(t_enum(c("admin", "user")), default = "user")
    )
  )
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  s <- to_json_schema("JS_Person")
  expect_equal(s$`$schema`, "https://json-schema.org/draft/2020-12/schema")
  expect_equal(s$title, "JS_Person")
  expect_equal(s$type, "object")
  expect_named(s$properties, c("name", "age", "role"))
  expect_equal(s$properties$age$minimum, 0)
  expect_equal(s$properties$age$maximum, 120)
  expect_equal(s$properties$role$default, "user")
  # name is required (not nullable, no default)
  expect_true("name" %in% unlist(s$required))
  # role has a default — not required
  expect_false("role" %in% unlist(s$required))
  expect_true(s$additionalProperties)
})

test_that("strict mode flips additionalProperties to FALSE", {
  define_model("JS_Strict", fields = list(x = field("integer")), .strict = TRUE)
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  s <- to_json_schema("JS_Strict")
  expect_false(s$additionalProperties)
})

test_that("nested model becomes $ref + $defs entry", {
  define_model("JS_Addr", fields = list(zip = field("character")))
  define_model(
    "JS_User",
    fields = list(
      addr = field(t_model("JS_Addr"))
    )
  )
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  s <- to_json_schema("JS_User")
  expect_equal(s$properties$addr$`$ref`, "#/$defs/JS_Addr")
  expect_true("JS_Addr" %in% names(s$`$defs`))
  expect_equal(s$`$defs`$JS_Addr$type, "object")
})

test_that("model registered as character field name auto-creates $ref", {
  define_model("JS_Inner", fields = list(v = field("integer")))
  define_model("JS_Outer", fields = list(inner = field("JS_Inner")))
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  s <- to_json_schema("JS_Outer")
  expect_equal(s$properties$inner$`$ref`, "#/$defs/JS_Inner")
  expect_true("JS_Inner" %in% names(s$`$defs`))
})

test_that("cyclic models terminate via stub-then-fill protocol", {
  define_model(
    "JS_A",
    fields = list(
      b = field(t_nullable(t_model("JS_B")))
    )
  )
  define_model(
    "JS_B",
    fields = list(
      a = field(t_nullable(t_model("JS_A")))
    )
  )
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  s <- to_json_schema("JS_A")
  expect_true("JS_B" %in% names(s$`$defs`))
  # JS_A should NOT appear in its own $defs (it's the top-level schema)
  expect_false("JS_A" %in% names(s$`$defs`))
})

test_that("typed_model instance dispatches to class name", {
  define_model("JS_Tag", fields = list(label = field("character")))
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  inst <- new_JS_Tag(label = "x")
  s <- to_json_schema(inst)
  expect_equal(s$title, "JS_Tag")
})

test_that("jsonlite roundtrip serializes without error", {
  skip_if_not_installed("jsonlite")
  define_model(
    "JS_Round",
    fields = list(
      name = field("character"),
      tags = field(t_list_of("character"), default = list())
    )
  )
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  s <- to_json_schema("JS_Round")
  out <- jsonlite::toJSON(s, auto_unbox = TRUE)
  expect_true(nchar(out) > 10)
  parsed <- jsonlite::fromJSON(out, simplifyVector = FALSE)
  expect_equal(parsed$type, "object")
})

test_that("bare type_spec export works without model wrapper", {
  s <- to_json_schema(t_list_of(t_union("integer", "character")))
  expect_equal(s$type, "array")
  expect_named(s$items, "oneOf")
})
