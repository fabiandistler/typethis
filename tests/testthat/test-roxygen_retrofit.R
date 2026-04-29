# ---- parse_param_type --------------------------------------------------------

test_that("parse_param_type honours explicit [type] prefix", {
  expect_equal(parse_param_type("[integer] count"), "integer")
  expect_equal(parse_param_type("  [ double ]  prose"), "double")
  expect_equal(parse_param_type("[character] anything"), "character")
})

test_that("parse_param_type explicit prefix wins over vocabulary", {
  expect_equal(
    parse_param_type("[character] A numeric vector of values"),
    "character"
  )
})

test_that("parse_param_type matches leading articles plus type word", {
  expect_equal(parse_param_type("A numeric vector of values"), "numeric")
  expect_equal(parse_param_type("An integer vector"), "integer")
  expect_equal(parse_param_type("a character string"), "character")
  expect_equal(parse_param_type("The data frame to write"), "data.frame")
  expect_equal(parse_param_type("a data.frame of rows"), "data.frame")
  expect_equal(parse_param_type("logical scalar"), "logical")
  expect_equal(parse_param_type("boolean flag"), "logical")
  expect_equal(parse_param_type("a list of items"), "list")
  expect_equal(parse_param_type("an environment"), "environment")
  expect_equal(parse_param_type("a function to apply"), "function")
})

test_that("parse_param_type matches 'If TRUE/FALSE' style logical prose", {
  expect_equal(parse_param_type("If TRUE, return early"), "logical")
  expect_equal(parse_param_type("if false, do nothing"), "logical")
  expect_equal(parse_param_type("TRUE or FALSE"), "logical")
})

test_that("parse_param_type returns NULL when nothing matches", {
  expect_null(parse_param_type("Some unrelated description"))
  expect_null(parse_param_type("Whatever you want to pass through"))
  expect_null(parse_param_type("Internal state. See Details."))
})

test_that("parse_param_type returns NULL on empty / invalid input", {
  expect_null(parse_param_type(""))
  expect_null(parse_param_type("   "))
  expect_null(parse_param_type(NA_character_))
  expect_null(parse_param_type(character(0)))
  expect_null(parse_param_type(c("a", "b")))
  expect_null(parse_param_type(42))
})

test_that("parse_param_type honours a custom vocabulary entry", {
  vocab <- c(
    setNames("data.frame", "(?i)^\\s*(?:a|an)?\\s*tbl[._]df\\b"),
    default_type_vocabulary()
  )
  expect_equal(parse_param_type("A tbl_df of rows", vocab), "data.frame")
})

test_that("default_type_vocabulary returns a non-empty named character vector", {
  v <- default_type_vocabulary()
  expect_type(v, "character")
  expect_true(length(v) > 0L)
  expect_false(any(is.na(v)))
  expect_false(any(names(v) == ""))
})

# ---- Rd extraction helpers ---------------------------------------------------

write_rd <- function(content, dir, name = "f.Rd") {
  path <- file.path(dir, name)
  writeLines(content, path)
  path
}

test_that("as_typed_from_roxygen reads Rd files from .rd_dir", {
  rd_dir <- tempfile("rd")
  dir.create(rd_dir)
  write_rd(
    c(
      "\\name{add}",
      "\\alias{add}",
      "\\title{Add}",
      "\\arguments{",
      "\\item{x}{A numeric vector.}",
      "\\item{y}{[integer] Number of times.}",
      "}",
      "\\value{A numeric vector.}"
    ),
    rd_dir
  )

  ns <- new.env()
  ns$add <- function(x, y) rep(x, y)

  modified <- as_typed_from_roxygen(ns, .rd_dir = rd_dir)

  expect_equal(modified, "add")
  expect_true(is_typed(ns$add))
  expect_equal(
    attr(ns$add, "arg_specs"),
    list(x = "numeric", y = "integer")
  )
  expect_equal(attr(ns$add, "return_spec"), "numeric")
})

test_that("as_typed_from_roxygen splits 'x,y' shared item names", {
  rd_dir <- tempfile("rd")
  dir.create(rd_dir)
  write_rd(
    c(
      "\\name{xy}",
      "\\alias{xy}",
      "\\title{XY}",
      "\\arguments{",
      "\\item{x,y}{A numeric vector.}",
      "}"
    ),
    rd_dir
  )

  ns <- new.env()
  ns$xy <- function(x, y) x + y

  as_typed_from_roxygen(ns, .rd_dir = rd_dir)

  expect_equal(
    attr(ns$xy, "arg_specs"),
    list(x = "numeric", y = "numeric")
  )
})

test_that("as_typed_from_roxygen ignores `...` items", {
  rd_dir <- tempfile("rd")
  dir.create(rd_dir)
  write_rd(
    c(
      "\\name{f}",
      "\\alias{f}",
      "\\title{F}",
      "\\arguments{",
      "\\item{x}{A numeric vector.}",
      "\\item{...}{A list of extras.}",
      "}"
    ),
    rd_dir
  )

  ns <- new.env()
  ns$f <- function(x, ...) x

  as_typed_from_roxygen(ns, .rd_dir = rd_dir)

  expect_equal(attr(ns$f, "arg_specs"), list(x = "numeric"))
})

test_that("as_typed_from_roxygen drops Rd args that are not formals", {
  rd_dir <- tempfile("rd")
  dir.create(rd_dir)
  write_rd(
    c(
      "\\name{f}",
      "\\alias{f}",
      "\\title{F}",
      "\\arguments{",
      "\\item{x}{A numeric vector.}",
      "\\item{old_name}{[character] Renamed away.}",
      "}"
    ),
    rd_dir
  )

  ns <- new.env()
  ns$f <- function(x) x

  expect_silent(as_typed_from_roxygen(ns, .rd_dir = rd_dir))
  expect_equal(attr(ns$f, "arg_specs"), list(x = "numeric"))
})

test_that("as_typed_from_roxygen routes Rd entries through every alias", {
  rd_dir <- tempfile("rd")
  dir.create(rd_dir)
  write_rd(
    c(
      "\\name{primary}",
      "\\alias{primary}",
      "\\alias{secondary}",
      "\\title{P}",
      "\\arguments{",
      "\\item{x}{A numeric vector.}",
      "}"
    ),
    rd_dir
  )

  ns <- new.env()
  ns$primary <- function(x) x
  ns$secondary <- function(x) x

  modified <- as_typed_from_roxygen(ns, .rd_dir = rd_dir)

  expect_setequal(modified, c("primary", "secondary"))
  expect_equal(attr(ns$primary, "arg_specs"), list(x = "numeric"))
  expect_equal(attr(ns$secondary, "arg_specs"), list(x = "numeric"))
})

test_that("as_typed_from_roxygen leaves functions untyped when no docs match", {
  rd_dir <- tempfile("rd")
  dir.create(rd_dir)
  write_rd(
    c(
      "\\name{f}",
      "\\alias{f}",
      "\\title{F}",
      "\\arguments{",
      "\\item{x}{Some opaque thing. See Details.}",
      "}"
    ),
    rd_dir
  )

  ns <- new.env()
  ns$f <- function(x) x

  as_typed_from_roxygen(ns, .rd_dir = rd_dir)

  # Inference cannot help (no default) and Rd was unparseable; the
  # wrapper still goes on but with no specs.
  expect_true(is_typed(ns$f))
  expect_equal(attr(ns$f, "arg_specs"), list())
})

test_that("as_typed_from_roxygen falls back to inference for undocumented args", {
  rd_dir <- tempfile("rd")
  dir.create(rd_dir)
  write_rd(
    c(
      "\\name{f}",
      "\\alias{f}",
      "\\title{F}",
      "\\arguments{",
      "\\item{x}{A numeric vector.}",
      "}"
    ),
    rd_dir
  )

  ns <- new.env()
  ns$f <- function(x, y = 1L) x + y

  as_typed_from_roxygen(ns, .rd_dir = rd_dir)

  specs <- attr(ns$f, "arg_specs")
  expect_equal(specs$x, "numeric") # from Rd
  expect_equal(specs$y, "integer") # from default-value inference
})

test_that("as_typed_from_roxygen lets user .specs override Rd-derived specs", {
  rd_dir <- tempfile("rd")
  dir.create(rd_dir)
  write_rd(
    c(
      "\\name{f}",
      "\\alias{f}",
      "\\title{F}",
      "\\arguments{",
      "\\item{x}{A numeric vector.}",
      "}"
    ),
    rd_dir
  )

  ns <- new.env()
  ns$f <- function(x) x

  as_typed_from_roxygen(
    ns,
    .rd_dir = rd_dir,
    .specs = list(f = list(x = "character"))
  )

  expect_equal(attr(ns$f, "arg_specs")$x, "character")
})

test_that("as_typed_from_roxygen accepts a custom .vocabulary", {
  rd_dir <- tempfile("rd")
  dir.create(rd_dir)
  write_rd(
    c(
      "\\name{f}",
      "\\alias{f}",
      "\\title{F}",
      "\\arguments{",
      "\\item{x}{A tbl_df of rows.}",
      "}"
    ),
    rd_dir
  )

  ns <- new.env()
  ns$f <- function(x) x

  vocab <- c(
    setNames("data.frame", "(?i)^\\s*(?:a|an)?\\s*tbl[._]df\\b"),
    default_type_vocabulary()
  )
  as_typed_from_roxygen(ns, .rd_dir = rd_dir, .vocabulary = vocab)

  expect_equal(attr(ns$f, "arg_specs")$x, "data.frame")
})

test_that("as_typed_from_roxygen handles missing \\arguments gracefully", {
  rd_dir <- tempfile("rd")
  dir.create(rd_dir)
  write_rd(
    c(
      "\\name{f}",
      "\\alias{f}",
      "\\title{F}"
    ),
    rd_dir
  )

  ns <- new.env()
  ns$f <- function(x = 1L) x

  modified <- as_typed_from_roxygen(ns, .rd_dir = rd_dir)

  # Nothing came from Rd, but inference still applies via enable_for_package.
  expect_equal(modified, "f")
  expect_equal(attr(ns$f, "arg_specs"), list(x = "integer"))
})

test_that("as_typed_from_roxygen ignores Rd entries whose alias has no fn", {
  rd_dir <- tempfile("rd")
  dir.create(rd_dir)
  write_rd(
    c(
      "\\name{ghost}",
      "\\alias{ghost}",
      "\\title{Ghost}",
      "\\arguments{",
      "\\item{x}{A numeric vector.}",
      "}"
    ),
    rd_dir
  )

  ns <- new.env()
  ns$real <- function(x = 1L) x

  modified <- as_typed_from_roxygen(ns, .rd_dir = rd_dir)

  expect_equal(modified, "real")
  expect_equal(attr(ns$real, "arg_specs"), list(x = "integer"))
})

test_that("as_typed_from_roxygen errors on bad inputs", {
  expect_error(
    as_typed_from_roxygen(42),
    "must be a single non-empty string"
  )
  expect_error(
    as_typed_from_roxygen(""),
    "must be a single non-empty string"
  )
  expect_error(
    as_typed_from_roxygen(new.env(), .rd_dir = "/no/such/dir"),
    "must be an existing directory path"
  )
})

test_that("as_typed_from_roxygen parses an empty .rd_dir with no error", {
  rd_dir <- tempfile("rd")
  dir.create(rd_dir)

  ns <- new.env()
  ns$f <- function(x = 1L) x

  modified <- as_typed_from_roxygen(ns, .rd_dir = rd_dir)

  # No Rd input, falls through to plain inference.
  expect_equal(modified, "f")
  expect_equal(attr(ns$f, "arg_specs"), list(x = "integer"))
})

test_that("as_typed_from_roxygen retrofitted functions enforce types", {
  rd_dir <- tempfile("rd")
  dir.create(rd_dir)
  write_rd(
    c(
      "\\name{add}",
      "\\alias{add}",
      "\\title{Add}",
      "\\arguments{",
      "\\item{x}{A numeric vector.}",
      "\\item{y}{[integer] count.}",
      "}"
    ),
    rd_dir
  )

  ns <- new.env()
  ns$add <- function(x, y) rep(x, y)

  as_typed_from_roxygen(ns, .rd_dir = rd_dir)

  expect_equal(ns$add(1.5, 3L), c(1.5, 1.5, 1.5))
  expect_error(ns$add("a", 3L), "Type error")
  expect_error(ns$add(1.5, 3.5), "Type error")
})
