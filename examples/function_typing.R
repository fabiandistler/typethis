# Function Typing Examples for typethis
# ======================================

library(typethis)

# 1. Basic Function Type Annotation
# ----------------------------------

# Define a typed function that adds two integers
add <- typed(x = "integer", y = "integer", .return = "integer")(
  function(x, y) {
    x + y
  }
)

cat("Testing typed add function:\n")
result <- add(5L, 3L)
cat("add(5L, 3L) =", result, "\n")

# This will error:
tryCatch({
  add(5.5, 3.2)
}, error = function(e) {
  cat("Error:", e$message, "\n")
})


# 2. Function with Multiple Types
# --------------------------------

process_data <- typed(
  data = "data.frame",
  column = "character",
  threshold = "numeric",
  .return = "data.frame"
)(
  function(data, column, threshold) {
    data[data[[column]] > threshold, ]
  }
)

# Test
df <- data.frame(x = 1:5, y = c(10, 20, 15, 25, 30))
filtered <- process_data(df, "y", 15)
cat("\nFiltered data frame:\n")
print(filtered)


# 3. Function Type Inference
# ---------------------------

code <- "
simple_add <- function(a, b) {
  a + b
}

multiply <- function(x, y) {
  x * y
}
"

parsed <- parse_code(code)
functions <- extract_functions(parsed)
cat("\nFunctions found in code:\n")
print(functions)


# 4. Generic Function with Any Type
# ----------------------------------

identity_fn <- typed(x = "any", .return = "any")(
  function(x) {
    x
  }
)

cat("\nTesting identity function:\n")
cat("identity_fn(5L) =", identity_fn(5L), "\n")
cat("identity_fn('hello') =", identity_fn("hello"), "\n")
cat("identity_fn(list(a=1)) = ")
print(identity_fn(list(a = 1)))


# 5. Function with Optional Arguments
# ------------------------------------

greet <- typed(
  name = "character",
  greeting = "character",
  .return = "character"
)(
  function(name, greeting = "Hello") {
    paste(greeting, name)
  }
)

cat("\nTesting greet function:\n")
cat(greet("Alice"), "\n")
cat(greet("Bob", "Hi"), "\n")


# 6. Function Returning Different Types
# --------------------------------------

convert_type <- typed(
  x = "any",
  to_type = "character",
  .return = "any"
)(
  function(x, to_type) {
    switch(to_type,
           integer = as.integer(x),
           numeric = as.numeric(x),
           character = as.character(x),
           logical = as.logical(x),
           stop("Unknown type")
    )
  }
)

cat("\nTesting type conversion function:\n")
cat("convert_type('5', 'integer') =", convert_type("5", "integer"), "\n")
cat("convert_type(5, 'character') =", convert_type(5, "character"), "\n")


# 7. Function Type from Signature
# --------------------------------

fn_type <- function_type(
  args = list(x = "integer", y = "integer"),
  return_type = "integer"
)

cat("\nFunction type created:\n")
print(fn_type)


# 8. Checking Function Calls
# ---------------------------

code_with_calls <- "
add <- function(x, y) {
  x + y
}

result1 <- add(5, 3)
result2 <- add('hello', 'world')  # May cause issues
result3 <- sum(1, 2, 3)
"

result <- check_types(code_with_calls)
cat("\nType checking function calls:\n")
print(result)


# 9. Higher-Order Function
# -------------------------

apply_fn <- typed(
  fn = "function",
  x = "numeric",
  .return = "numeric"
)(
  function(fn, x) {
    fn(x)
  }
)

cat("\nTesting higher-order function:\n")
cat("apply_fn(sqrt, 16) =", apply_fn(sqrt, 16), "\n")
cat("apply_fn(log, 10) =", apply_fn(log, 10), "\n")


# 10. Documenting Function Types
# -------------------------------

#' Calculate the mean of a numeric vector
#'
#' @param x Numeric vector
#' @param na.rm Logical, remove NA values
#' @return Numeric, the mean value
#'
#' @examples
#' calculate_mean(c(1, 2, 3, 4, 5))
calculate_mean <- typed(
  x = "numeric",
  na.rm = "logical",
  .return = "numeric"
)(
  function(x, na.rm = TRUE) {
    mean(x, na.rm = na.rm)
  }
)

cat("\nTesting documented function:\n")
cat("calculate_mean(c(1, 2, 3, 4, 5)) =", calculate_mean(c(1, 2, 3, 4, 5)), "\n")


# 11. Function with Complex Return Type
# --------------------------------------

create_summary <- typed(
  data = "data.frame",
  .return = "list"
)(
  function(data) {
    list(
      nrows = nrow(data),
      ncols = ncol(data),
      names = names(data),
      types = sapply(data, class)
    )
  }
)

df <- data.frame(
  x = 1:5,
  y = letters[1:5],
  z = rnorm(5)
)

summary_info <- create_summary(df)
cat("\nData frame summary:\n")
print(summary_info)


# 12. Revealing Function Return Types
# ------------------------------------

code_fn <- "
square <- function(x) {
  x * x
}

is_even <- function(n) {
  n %% 2 == 0
}

concatenate <- function(a, b) {
  paste(a, b)
}
"

# Parse and analyze
parsed <- parse_code(code_fn)
functions <- extract_functions(parsed)

cat("\nFunctions in code:\n")
for (fn in functions) {
  if (!is.null(fn$name)) {
    cat("  Function:", fn$name, "at line", fn$line, "\n")
  }
}


cat("\nAll function typing examples completed successfully!\n")
