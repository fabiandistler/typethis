#!/usr/bin/env Rscript
# Test script for typethis package
# Run this locally to test the package

cat("Testing typethis package...\n\n")

# 1. Load the package
cat("1. Loading package functions...\n")
tryCatch({
  source("R/types.R")
  source("R/ast_parser.R")
  source("R/type_inference.R")
  source("R/type_checker.R")
  source("R/data_table_support.R")
  source("R/reveal_type.R")
  source("R/rstudio_addin.R")
  cat("   ✓ All files sourced successfully\n\n")
}, error = function(e) {
  cat("   ✗ Error loading files:", e$message, "\n")
  quit(status = 1)
})

# 2. Test basic type creation
cat("2. Testing basic type creation...\n")
tryCatch({
  int_type <- create_type("integer")
  stopifnot(int_type$base_type == "integer")
  cat("   ✓ Type creation works\n\n")
}, error = function(e) {
  cat("   ✗ Error:", e$message, "\n")
})

# 3. Test type matching
cat("3. Testing type matching...\n")
tryCatch({
  stopifnot(type_matches(5L, "integer") == TRUE)
  stopifnot(type_matches(5.5, "integer") == FALSE)
  cat("   ✓ Type matching works\n\n")
}, error = function(e) {
  cat("   ✗ Error:", e$message, "\n")
})

# 4. Test AST parsing
cat("4. Testing AST parsing...\n")
tryCatch({
  code <- "x <- 5L\ny <- 10"
  parsed <- parse_code(code)
  stopifnot(!is.null(parsed$expr))
  stopifnot(!is.null(parsed$parse_data))
  cat("   ✓ AST parsing works\n\n")
}, error = function(e) {
  cat("   ✗ Error:", e$message, "\n")
})

# 5. Test type inference
cat("5. Testing type inference...\n")
tryCatch({
  type_int <- infer_type(5L)
  stopifnot(type_int$base_type == "integer")

  type_char <- infer_type("hello")
  stopifnot(type_char$base_type == "character")

  cat("   ✓ Type inference works\n\n")
}, error = function(e) {
  cat("   ✗ Error:", e$message, "\n")
})

# 6. Test type checking
cat("6. Testing type checking...\n")
tryCatch({
  code <- "x <- 5L\ny <- 10"
  result <- check_types(code)
  stopifnot(inherits(result, "type_check_result"))
  cat("   ✓ Type checking works\n\n")
}, error = function(e) {
  cat("   ✗ Error:", e$message, "\n")
})

# 7. Test reveal_type
cat("7. Testing reveal_type...\n")
tryCatch({
  x <- 5L
  type_info <- reveal_type(x)
  stopifnot(!is.null(type_info))
  cat("   ✓ reveal_type works\n\n")
}, error = function(e) {
  cat("   ✗ Error:", e$message, "\n")
})

# 8. Test typed decorator
cat("8. Testing typed() decorator...\n")
tryCatch({
  add_typed <- typed(x = "integer", y = "integer", .return = "integer")(
    function(x, y) {
      x + y
    }
  )
  result <- add_typed(x = 5L, y = 3L)
  stopifnot(result == 8L)
  cat("   ✓ typed() decorator works\n\n")
}, error = function(e) {
  cat("   ✗ Error:", e$message, "\n")
})

# 9. Test extract functions
cat("9. Testing extract_assignments...\n")
tryCatch({
  code <- "x <- 5L\ny <- 10"
  parsed <- parse_code(code)
  assignments <- extract_assignments(parsed)
  stopifnot(nrow(assignments) == 2)
  cat("   ✓ extract_assignments works\n\n")
}, error = function(e) {
  cat("   ✗ Error:", e$message, "\n")
})

# 10. Test data.table support (if available)
cat("10. Testing data.table support...\n")
if (requireNamespace("data.table", quietly = TRUE)) {
  tryCatch({
    dt <- data.table::data.table(id = 1:5, name = letters[1:5])
    dt_type <- infer_type(dt)
    stopifnot(dt_type$base_type == "data.table")
    cat("   ✓ data.table support works\n\n")
  }, error = function(e) {
    cat("   ✗ Error:", e$message, "\n")
  })
} else {
  cat("   ⊘ data.table not installed, skipping\n\n")
}

cat("========================================\n")
cat("All tests completed!\n")
cat("========================================\n")
