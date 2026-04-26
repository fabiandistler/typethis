skip_without_yaml <- function() {
  testthat::skip_if_not_installed("yaml")
}

# ---------------------------------------------------------------------------
# Builtin & type_spec mapping
# ---------------------------------------------------------------------------

test_that("builtin types map to ODCS logicalType", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  define_model("M1", fields = list(
    a = field("character"),
    b = field("integer"),
    c = field("numeric"),
    d = field("logical"),
    e = field("date"),
    f = field("posixct")
  ))
  contract <- to_datacontract("M1")
  props <- contract$schema[[1]]$properties
  named <- setNames(props, vapply(props, `[[`, character(1), "name"))
  expect_equal(named$a$logicalType, "string")
  expect_equal(named$b$logicalType, "integer")
  expect_equal(named$c$logicalType, "number")
  expect_equal(named$d$logicalType, "boolean")
  expect_equal(named$e$logicalType, "date")
  expect_equal(named$f$logicalType, "date")
  expect_equal(named$f$physicalType, "timestamp")
})

test_that("validators emit ODCS constraint fields", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  define_model("M2", fields = list(
    score = field("numeric", validator = numeric_range(0, 100)),
    name  = field("character", validator = string_length(1, 50)),
    code  = field("character", validator = string_pattern("^[A-Z]{3}$"))
  ))
  contract <- to_datacontract("M2")
  props <- contract$schema[[1]]$properties
  named <- setNames(props, vapply(props, `[[`, character(1), "name"))
  expect_equal(named$score$minimum, 0)
  expect_equal(named$score$maximum, 100)
  expect_equal(named$name$minLength, 1)
  expect_equal(named$name$maxLength, 50)
  expect_equal(named$code$pattern, "^[A-Z]{3}$")
})

test_that("t_enum becomes enum field", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  define_model("M3", fields = list(
    status = field(t_enum(c("new", "paid", "shipped")))
  ))
  contract <- to_datacontract("M3")
  prop <- contract$schema[[1]]$properties[[1]]
  expect_equal(prop$logicalType, "string")
  expect_equal(unlist(prop$enum), c("new", "paid", "shipped"))
})

test_that("t_list_of becomes array with items and length bounds", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  define_model("M4", fields = list(
    tags = field(t_list_of("character", min_length = 1L, max_length = 5L))
  ))
  contract <- to_datacontract("M4")
  prop <- contract$schema[[1]]$properties[[1]]
  expect_equal(prop$logicalType, "array")
  expect_equal(prop$items$logicalType, "string")
  expect_equal(prop$minItems, 1L)
  expect_equal(prop$maxItems, 5L)
})

test_that("t_nullable yields required = FALSE in field context", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  define_model("M5", fields = list(
    nick = field(t_nullable("character"), nullable = TRUE)
  ))
  contract <- to_datacontract("M5")
  prop <- contract$schema[[1]]$properties[[1]]
  expect_equal(prop$logicalType, "string")
  expect_false(isTRUE(prop$required))
})

test_that("t_union falls back to first alternative + extension", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  define_model("M6", fields = list(
    val = field(t_union("integer", "character"))
  ))
  contract <- to_datacontract("M6")
  prop <- contract$schema[[1]]$properties[[1]]
  expect_equal(prop$logicalType, "integer")
  expect_length(prop[["x-typethis-union"]], 2L)
})

# ---------------------------------------------------------------------------
# Nested models / $ref
# ---------------------------------------------------------------------------

test_that("nested model produces $ref and includes referenced schema", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  define_model("Address", fields = list(
    zip = field("character")
  ))
  define_model("Person", fields = list(
    name = field("character"),
    home = field(t_model("Address"))
  ))
  contract <- to_datacontract("Person")
  schema_names <- vapply(contract$schema, `[[`, character(1), "name")
  expect_true("Person" %in% schema_names)
  expect_true("Address" %in% schema_names)
  person <- contract$schema[[which(schema_names == "Person")]]
  home_prop <- person$properties[[which(
    vapply(person$properties, `[[`, character(1), "name") == "home"
  )]]
  expect_equal(home_prop[["$ref"]], "#/schema/Address")
})

# ---------------------------------------------------------------------------
# Field metadata (primary_key, pii, tags, examples)
# ---------------------------------------------------------------------------

test_that("ODCS metadata round-trips through field()", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  define_model("M7", fields = list(
    id = field("character",
               primary_key = TRUE,
               unique = TRUE,
               pii = TRUE,
               classification = "confidential",
               tags = c("billing", "core"),
               examples = list("ORD-001", "ORD-002"),
               description = "Order identifier")
  ))
  contract <- to_datacontract("M7")
  prop <- contract$schema[[1]]$properties[[1]]
  expect_true(prop$primaryKey)
  expect_true(prop$unique)
  expect_true(prop$pii)
  expect_equal(prop$classification, "confidential")
  expect_equal(unlist(prop$tags), c("billing", "core"))
  expect_equal(prop$description, "Order identifier")
  expect_length(prop$examples, 2L)
})

# ---------------------------------------------------------------------------
# Top-level info / servers
# ---------------------------------------------------------------------------

test_that("info and servers land at the top level", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  define_model("Foo", fields = list(x = field("integer")))
  contract <- to_datacontract(
    "Foo",
    info = list(name = "foo-contract",
                version = "2.1.0",
                description = "Test"),
    servers = list(prod = list(type = "bigquery", project = "p"))
  )
  expect_equal(contract$apiVersion, "v3.0.2")
  expect_equal(contract$kind, "DataContract")
  expect_equal(contract$name, "foo-contract")
  expect_equal(contract$version, "2.1.0")
  expect_equal(contract$description$purpose, "Test")
  expect_equal(contract$servers$prod$type, "bigquery")
})

# ---------------------------------------------------------------------------
# Multi-model contract from list / vector
# ---------------------------------------------------------------------------

test_that("vector input bundles multiple models", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  define_model("Cust", fields = list(id = field("character")))
  define_model("Order", fields = list(
    id = field("character"),
    cust_id = field("character")
  ))
  contract <- to_datacontract(c("Cust", "Order"))
  schema_names <- vapply(contract$schema, `[[`, character(1), "name")
  expect_setequal(schema_names, c("Cust", "Order"))
})

# ---------------------------------------------------------------------------
# YAML write / read round-trip
# ---------------------------------------------------------------------------

test_that("write_datacontract produces YAML readable by read_datacontract", {
  skip_without_yaml()
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  define_model("Order", fields = list(
    order_id = field("character", primary_key = TRUE),
    amount   = field("numeric", validator = numeric_range(0, 1e6)),
    status   = field(t_enum(c("new", "paid", "shipped")))
  ))
  tmp <- tempfile(fileext = ".yaml")
  on.exit(unlink(tmp), add = TRUE)
  write_datacontract("Order", tmp,
                     info = list(name = "orders", version = "1.0.0"))

  parsed <- read_datacontract(tmp)
  expect_equal(parsed$apiVersion, "v3.0.2")
  expect_equal(parsed$name, "orders")
  expect_equal(parsed$schema[[1]]$name, "Order")
  field_names <- vapply(parsed$schema[[1]]$properties,
                        `[[`, character(1), "name")
  expect_setequal(field_names, c("order_id", "amount", "status"))
})

# ---------------------------------------------------------------------------
# Import: from_datacontract
# ---------------------------------------------------------------------------

test_that("from_datacontract registers models and constructors", {
  skip_without_yaml()
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  contract <- list(
    apiVersion = "v3.0.2",
    kind = "DataContract",
    name = "demo",
    version = "1.0.0",
    schema = list(
      list(
        name = "User",
        logicalType = "object",
        properties = list(
          list(name = "id", logicalType = "string",
               required = TRUE, primaryKey = TRUE),
          list(name = "age", logicalType = "integer",
               required = TRUE, minimum = 0, maximum = 150),
          list(name = "role", logicalType = "string",
               enum = list("admin", "user"))
        )
      )
    )
  )
  env <- new.env()
  registered <- from_datacontract(contract, register = TRUE, envir = env)
  expect_equal(as.character(registered), "User")
  expect_true("User" %in% names(getOption("typethis_model_registry")))
  expect_true(exists("new_User", envir = env))

  u <- env$new_User(id = "u1", age = 30L, role = "admin")
  expect_true(is_model(u))
  expect_error(env$new_User(id = "u1", age = 200L, role = "admin"))
  expect_error(env$new_User(id = "u1", age = 30L, role = "guest"))
})

test_that("from_datacontract round-trips an exported contract", {
  skip_without_yaml()
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  define_model("Sample", fields = list(
    id  = field("character", primary_key = TRUE),
    qty = field("integer", validator = numeric_range(0, 100))
  ))
  tmp <- tempfile(fileext = ".yaml")
  on.exit(unlink(tmp), add = TRUE)
  write_datacontract("Sample", tmp)

  options(typethis_model_registry = list())
  env <- new.env()
  from_datacontract(tmp, register = TRUE, envir = env)

  reg <- getOption("typethis_model_registry")
  expect_true("Sample" %in% names(reg))
  imported_fields <- reg$Sample$fields
  expect_true(imported_fields$id$primary_key)
  expect_equal(imported_fields$qty$type, "integer")
  expect_true(is.function(imported_fields$qty$validator))
})

test_that("from_datacontract registers nested object properties as models", {
  skip_without_yaml()
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  contract <- list(
    apiVersion = "v3.0.2",
    kind = "DataContract",
    name = "demo",
    version = "1.0.0",
    schema = list(
      list(
        name = "Customer",
        logicalType = "object",
        properties = list(
          list(name = "id", logicalType = "string",
               required = TRUE, primaryKey = TRUE),
          list(
            name = "address",
            logicalType = "object",
            properties = list(
              list(name = "street", logicalType = "string", required = TRUE),
              list(name = "city",   logicalType = "string", required = TRUE)
            )
          )
        )
      )
    )
  )
  env <- new.env()
  from_datacontract(contract, register = TRUE, envir = env)

  expect_true(exists("new_Customer", envir = env))
  expect_true(exists("new_address",  envir = env))
  expect_true(exists("update_address", envir = env))

  reg <- getOption("typethis_model_registry")
  expect_true(all(c("Customer", "address") %in% names(reg)))
  expect_equal(names(reg$address$fields), c("street", "city"))

  addr <- env$new_address(street = "Main 1", city = "Munich")
  expect_true(is_model(addr))
})

# ---------------------------------------------------------------------------
# Error paths
# ---------------------------------------------------------------------------

test_that("to_datacontract errors on unknown class", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  expect_error(to_datacontract("Nope"), "Unknown model class")
})

test_that("from_datacontract errors when schema section missing", {
  options(typethis_model_registry = list())
  on.exit(options(typethis_model_registry = list()), add = TRUE)
  expect_error(from_datacontract(list(apiVersion = "v3.0.2")),
               "no `schema`")
})

# ---------------------------------------------------------------------------
# CLI wrappers (mocked via package-internal bindings)
# ---------------------------------------------------------------------------

test_that("datacontract_cli_available returns logical", {
  expect_true(is.logical(datacontract_cli_available()))
  expect_length(datacontract_cli_available(), 1L)
})

test_that("CLI wrappers refuse to run without binary", {
  testthat::local_mocked_bindings(
    datacontract_cli_available = function() FALSE
  )
  expect_error(datacontract_lint("x.yaml"), "datacontract CLI not found")
  expect_error(datacontract_test("x.yaml"), "datacontract CLI not found")
  expect_error(datacontract_export("x.yaml", "jsonschema"),
               "datacontract CLI not found")
})

test_that("datacontract_lint surfaces non-zero exit status", {
  testthat::local_mocked_bindings(
    datacontract_cli_available = function() TRUE,
    cli_invoke = function(args, ...) {
      list(success = FALSE, status = 1L,
           stdout = "schema invalid", stderr = "error: bad")
    }
  )
  expect_error(datacontract_lint("x.yaml"), "datacontract lint failed")
})

test_that("datacontract_lint succeeds on zero exit", {
  testthat::local_mocked_bindings(
    datacontract_cli_available = function() TRUE,
    cli_invoke = function(args, ...) {
      list(success = TRUE, status = 0L,
           stdout = "ok", stderr = character(0))
    }
  )
  result <- datacontract_lint("x.yaml")
  expect_true(result$success)
  expect_equal(result$stdout, "ok")
})

test_that("datacontract_export captures stdout when no output path", {
  testthat::local_mocked_bindings(
    datacontract_cli_available = function() TRUE,
    cli_invoke = function(args, ...) {
      list(success = TRUE, status = 0L,
           stdout = c("{", "  \"type\": \"object\"", "}"),
           stderr = character(0))
    }
  )
  out <- datacontract_export("x.yaml", "jsonschema")
  expect_match(out, "\"type\": \"object\"")
})

test_that("datacontract_export writes to output path when provided", {
  captured_args <- NULL
  testthat::local_mocked_bindings(
    datacontract_cli_available = function() TRUE,
    cli_invoke = function(args, ...) {
      captured_args <<- args
      list(success = TRUE, status = 0L,
           stdout = character(0), stderr = character(0))
    }
  )
  result <- datacontract_export("x.yaml", "sql", output = "out.sql")
  expect_equal(result, "out.sql")
  expect_true("--output" %in% captured_args)
  expect_true("out.sql" %in% captured_args)
})
