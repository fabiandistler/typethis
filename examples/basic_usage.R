# Basic Usage Examples for typethis
# ==================================

library(typethis)

# 1. Type Inference for Basic Values
# -----------------------------------

x <- 5L
reveal_type(x)  # integer

y <- 3.14
reveal_type(y)  # numeric

z <- "hello"
reveal_type(z)  # character

flag <- TRUE
reveal_type(flag)  # logical


# 2. Type Inference for Data Structures
# --------------------------------------

my_list <- list(a = 1, b = 2)
reveal_type(my_list)  # list

my_df <- data.frame(
  id = 1:5,
  name = letters[1:5]
)
reveal_type(my_df)  # data.frame with column types


# 3. Check Types in Code
# ----------------------

code <- "
x <- 5L
y <- 'hello'
z <- x + 10
w <- paste(y, 'world')
"

result <- check_types(code)
print(result)


# 4. Detect Type Inconsistencies
# -------------------------------

code_with_error <- "
x <- 5L
x <- 'hello'  # Type reassignment warning!
"

result <- check_types(code_with_error)
print(result)


# 5. Runtime Type Checking with typed()
# --------------------------------------

# Define a typed function
add_integers <- typed(x = "integer", y = "integer", .return = "integer")(
  function(x, y) {
    x + y
  }
)

# Valid calls
add_integers(5L, 3L)  # OK: 8

# Invalid calls (will error)
tryCatch({
  add_integers(5.5, 3.2)  # Error: expected integer
}, error = function(e) {
  cat("Error caught:", e$message, "\n")
})


# 6. Type Assertions
# ------------------

x <- 5L
assert_type(x, "integer")  # OK

tryCatch({
  assert_type(x, "character")  # Error!
}, error = function(e) {
  cat("Assertion failed:", e$message, "\n")
})


# 7. Reveal All Types in Code
# ----------------------------

code <- "
a <- 1L
b <- 2.5
c <- 'text'
d <- a + 10
e <- as.character(b)
"

reveal_all_types(code)


# 8. Check a File
# ---------------

# Create a temporary file
temp_file <- tempfile(fileext = ".R")
writeLines("
x <- 5L
y <- x * 2
z <- as.character(y)
", temp_file)

# Check types in the file
result <- check_file(temp_file)
print(result)

# Clean up
unlink(temp_file)


# 9. Type Inference from Expressions
# -----------------------------------

# Numeric operations
reveal_type(5 + 3)  # numeric

# Comparison operations
reveal_type(5 > 3)  # logical

# String operations
reveal_type(paste("hello", "world"))  # character


# 10. Working with Functions
# ---------------------------

my_function <- function(x, y) {
  x + y
}

reveal_type(my_function)  # function

# Type a function with signature
calc <- typed(
  x = "numeric",
  y = "numeric",
  operation = "character",
  .return = "numeric"
)(
  function(x, y, operation = "add") {
    switch(operation,
           add = x + y,
           subtract = x - y,
           multiply = x * y,
           divide = x / y,
           stop("Unknown operation")
    )
  }
)

# Use the typed function
calc(10, 5, "add")       # 15
calc(10, 5, "multiply")  # 50

cat("\nAll basic examples completed successfully!\n")
