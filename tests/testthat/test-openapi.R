skip_without_yaml <- function() {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    testthat::skip("yaml not available")
  }
}

skip_without_jsonlite <- function() {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    testthat::skip("jsonlite not available")
  }
}

# ---------------------------------------------------------------------------
# Export: to_openapi
# ---------------------------------------------------------------------------

test_that("to_openapi produces a valid OpenAPI 3.1 document for a model", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  define_model("User", fields = list(
    id   = field("integer", primary_key = TRUE),
    name = field("character"),
    role = field("character", validator = enum_validator(c("admin", "user")))
  ))
  doc <- to_openapi("User", info = list(title = "Users", version = "1.0.0"))

  expect_equal(doc$openapi, "3.1.0")
  expect_equal(doc$info$title, "Users")
  expect_equal(doc$info$version, "1.0.0")
  schemas <- doc$components$schemas
  expect_true("User" %in% names(schemas))
  expect_equal(schemas$User$type, "object")
  expect_true("id" %in% names(schemas$User$properties))
  expect_equal(schemas$User$properties$role$enum, list("admin", "user"))
})

test_that("info defaults are filled in when omitted", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  define_model("Thing", fields = list(name = field("character")))

  doc <- to_openapi("Thing")
  expect_equal(doc$info$title, "Thing")
  expect_equal(doc$info$version, "0.1.0")
})

test_that("nested model becomes $ref under components.schemas", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  define_model("Address", fields = list(
    street = field("character"),
    city   = field("character")
  ))
  define_model("Customer", fields = list(
    id      = field("integer", primary_key = TRUE),
    address = field("Address")
  ))
  doc <- to_openapi("Customer")
  expect_true(all(c("Customer", "Address") %in%
                    names(doc$components$schemas)))
  ref <- doc$components$schemas$Customer$properties$address$`$ref`
  expect_equal(ref, "#/components/schemas/Address")
  # Nothing should leak with the JSON Schema $defs convention
  expect_false(any(grepl("\\$defs",
                         unlist(doc$components$schemas$Customer))))
})

test_that("composite type specs flow through (t_list_of, t_union)", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  define_model("Tag", fields = list(name = field("character")))
  define_model("Doc", fields = list(
    tags  = field(t_list_of("Tag")),
    score = field(t_union("integer", "numeric"))
  ))
  doc <- to_openapi("Doc")
  schemas <- doc$components$schemas
  expect_true(all(c("Doc", "Tag") %in% names(schemas)))
  expect_equal(schemas$Doc$properties$tags$type, "array")
  expect_equal(schemas$Doc$properties$tags$items$`$ref`,
               "#/components/schemas/Tag")
  expect_true(!is.null(schemas$Doc$properties$score$oneOf))
})

test_that("vector input bundles multiple models and dedupes", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  define_model("A", fields = list(x = field("integer")))
  define_model("B", fields = list(y = field("character")))
  doc <- to_openapi(list("A", "B", "A"))
  expect_equal(sort(names(doc$components$schemas)), c("A", "B"))
})

test_that("typed_function becomes a /op POST path with JSON body", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  add <- typed_function(function(x, y) x + y,
                        arg_specs = list(x = "integer", y = "integer"),
                        return_spec = "integer")
  attr(add, "openapi_op_id") <- "add"
  doc <- to_openapi(list(add))

  expect_true("/add" %in% names(doc$paths))
  op <- doc$paths$`/add`$post
  expect_equal(op$operationId, "add")
  expect_true(op$requestBody$required)
  body_schema <- op$requestBody$content$`application/json`$schema
  expect_equal(body_schema$type, "object")
  expect_equal(sort(names(body_schema$properties)), c("x", "y"))
  expect_equal(sort(unlist(body_schema$required)), c("x", "y"))
  resp_schema <- op$responses$`200`$content$`application/json`$schema
  expect_equal(resp_schema$type, "integer")
})

test_that("typed_function with optional argument leaves it out of required", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  greet <- typed_function(function(name, greeting = "Hi") {
                            paste(greeting, name)
                          },
                          arg_specs = list(name = "character",
                                           greeting = "character"),
                          return_spec = "character")
  attr(greet, "openapi_op_id") <- "greet"
  doc <- to_openapi(list(greet))
  body <- doc$paths$`/greet`$post$requestBody$content$`application/json`$schema
  expect_equal(unlist(body$required), "name")
})

test_that("typed_function whose return type is a model emits $ref response", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  define_model("U", fields = list(id = field("integer")))
  fetch <- typed_function(function(id) list(id = id),
                          arg_specs = list(id = "integer"),
                          return_spec = "U")
  attr(fetch, "openapi_op_id") <- "fetch_u"
  doc <- to_openapi(list(fetch))
  resp <- doc$paths$`/fetch_u`$post$responses$`200`$content$`application/json`$schema
  expect_equal(resp$`$ref`, "#/components/schemas/U")
  expect_true("U" %in% names(doc$components$schemas))
})

test_that("to_openapi errors on unsupported input", {
  expect_error(to_openapi(42), "expected a model class name")
})

# ---------------------------------------------------------------------------
# write_openapi / read_openapi
# ---------------------------------------------------------------------------

test_that("write_openapi produces YAML readable by read_openapi", {
  skip_without_yaml()
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  define_model("Sample", fields = list(
    id  = field("character"),
    qty = field("integer", validator = numeric_range(0, 100))
  ))
  tmp <- tempfile(fileext = ".yaml")
  on.exit(unlink(tmp), add = TRUE)
  write_openapi("Sample", tmp,
                info = list(title = "Samples", version = "1.0.0"))
  doc <- read_openapi(tmp)
  expect_equal(doc$openapi, "3.1.0")
  expect_true("Sample" %in% names(doc$components$schemas))
})

test_that("write_openapi can emit JSON when extension is .json", {
  skip_without_jsonlite()
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  define_model("Tiny", fields = list(name = field("character")))
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp), add = TRUE)
  write_openapi("Tiny", tmp)

  raw <- paste(readLines(tmp), collapse = "\n")
  parsed <- jsonlite::fromJSON(raw, simplifyVector = FALSE)
  expect_equal(parsed$openapi, "3.1.0")
  expect_true("Tiny" %in% names(parsed$components$schemas))
})

# ---------------------------------------------------------------------------
# Import: from_openapi
# ---------------------------------------------------------------------------

test_that("from_openapi registers schemas as typed models", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  doc <- list(
    openapi = "3.1.0",
    info = list(title = "X", version = "1.0.0"),
    components = list(schemas = list(
      User = list(
        type = "object",
        required = list("id", "role"),
        properties = list(
          id   = list(type = "integer", minimum = 1),
          role = list(type = "string", enum = list("admin", "user"))
        )
      )
    ))
  )
  env <- new.env()
  registered <- from_openapi(doc, register = TRUE, envir = env)
  expect_equal(as.character(registered), "User")
  expect_true(exists("new_User", envir = env))

  u <- env$new_User(id = 5L, role = "admin")
  expect_true(is_model(u))
  expect_error(env$new_User(id = 0L, role = "admin"))
  expect_error(env$new_User(id = 5L, role = "guest"))
})

test_that("from_openapi resolves $ref to nested schemas", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  doc <- list(
    openapi = "3.1.0",
    info = list(title = "X", version = "1.0.0"),
    components = list(schemas = list(
      Address = list(
        type = "object",
        required = list("street"),
        properties = list(street = list(type = "string"))
      ),
      Customer = list(
        type = "object",
        required = list("id", "address"),
        properties = list(
          id      = list(type = "integer"),
          address = list(`$ref` = "#/components/schemas/Address")
        )
      )
    ))
  )
  env <- new.env()
  from_openapi(doc, envir = env)
  expect_true(all(c("new_Address", "new_Customer") %in% ls(env)))
  cust <- env$new_Customer(id = 1L,
                           address = env$new_Address(street = "Main 1"))
  expect_true(is_model(cust))
})

test_that("from_openapi registers inline nested object as its own model", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  doc <- list(
    openapi = "3.1.0",
    info = list(title = "X", version = "1.0.0"),
    components = list(schemas = list(
      Customer = list(
        type = "object",
        required = list("id", "address"),
        properties = list(
          id = list(type = "integer"),
          address = list(
            type = "object",
            required = list("street"),
            properties = list(street = list(type = "string"))
          )
        )
      )
    ))
  )
  env <- new.env()
  from_openapi(doc, envir = env)
  expect_true(all(c("new_Customer", "new_address") %in% ls(env)))
})

test_that("from_openapi roundtrips an exported document", {
  skip_without_yaml()
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  define_model("RoundTrip", fields = list(
    id   = field("character", primary_key = TRUE),
    note = field("character",
                 validator = string_pattern("^[A-Z][a-z]+$"))
  ))
  tmp <- tempfile(fileext = ".yaml")
  on.exit(unlink(tmp), add = TRUE)
  write_openapi("RoundTrip", tmp)

  options(typethis_model_registry = list())
  env <- new.env()
  from_openapi(tmp, envir = env)
  reg <- getOption("typethis_model_registry")
  expect_true("RoundTrip" %in% names(reg))
  expect_equal(reg$RoundTrip$fields$id$type, "character")
  expect_true(is.function(reg$RoundTrip$fields$note$validator))
})

# ---------------------------------------------------------------------------
# Error paths
# ---------------------------------------------------------------------------

test_that("from_openapi errors when components.schemas is missing", {
  expect_error(from_openapi(list(openapi = "3.1.0")),
               "components.schemas")
})
