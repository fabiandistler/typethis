# data.table Examples for typethis
# =================================

library(typethis)

# Check if data.table is available
if (requireNamespace("data.table", quietly = TRUE)) {
  library(data.table)

  # 1. Basic data.table Type Inference
  # -----------------------------------

  dt <- data.table(
    id = 1:5,
    name = letters[1:5],
    value = rnorm(5),
    flag = c(TRUE, FALSE, TRUE, FALSE, TRUE)
  )

  reveal_type(dt)
  # Should show:
  # Type: data.table
  #   Columns:
  #     id: integer
  #     name: character
  #     value: double
  #     flag: logical


  # 2. Type-Annotated data.table Creation
  # --------------------------------------

  # Define expected types
  expected_types <- list(
    id = "integer",
    name = "character",
    value = "numeric"
  )

  # Validate data.table against expected types
  dt_valid <- data.table(
    id = 1:3,
    name = c("a", "b", "c"),
    value = c(1.1, 2.2, 3.3)
  )

  validation <- validate_dt_types(dt_valid, expected_types)
  cat("Validation passed:", validation, "\n")


  # 3. Get Column Type
  # ------------------

  dt_type <- infer_type(dt)
  id_type <- get_dt_column_type(dt_type, "id")
  cat("Type of 'id' column:", id_type$base_type, "\n")


  # 4. Type Checking with data.table Operations
  # --------------------------------------------

  code <- "
  library(data.table)

  dt <- data.table(
    x = 1:5,
    y = letters[1:5]
  )

  # Subset
  dt_subset <- dt[x > 2]

  # Compute
  dt_sum <- dt[, sum(x)]
  "

  result <- check_types(code)
  print(result)


  # 5. Creating Typed data.table Constructor
  # -----------------------------------------

  create_typed_dt <- typed(
    id = "integer",
    name = "character",
    .return = "data.table"
  )(
    function(id, name) {
      data.table(id = id, name = name)
    }
  )

  # Valid call
  dt_new <- create_typed_dt(id = 1:3L, name = c("a", "b", "c"))
  print(dt_new)

  # Invalid call (wrong types)
  tryCatch({
    dt_bad <- create_typed_dt(id = "not_int", name = c("a", "b", "c"))
  }, error = function(e) {
    cat("Type error caught:", e$message, "\n")
  })


  # 6. Type-Safe data.table Aggregation
  # ------------------------------------

  aggregate_dt <- typed(
    dt = "data.table",
    col = "character",
    .return = "numeric"
  )(
    function(dt, col) {
      dt[, sum(get(col))]
    }
  )

  dt_sales <- data.table(
    product = c("A", "B", "A", "B"),
    amount = c(100, 200, 150, 250)
  )

  total <- aggregate_dt(dt_sales, "amount")
  cat("Total amount:", total, "\n")


  # 7. Validating data.table with Expected Schema
  # ----------------------------------------------

  expected_schema <- list(
    user_id = "integer",
    username = "character",
    age = "integer",
    score = "numeric"
  )

  # Valid data.table
  users_dt <- data.table(
    user_id = 1:3,
    username = c("alice", "bob", "charlie"),
    age = c(25L, 30L, 35L),
    score = c(9.5, 8.7, 9.2)
  )

  is_valid <- validate_dt_types(users_dt, expected_schema)
  cat("Users data.table is valid:", is_valid, "\n")

  # Invalid data.table (wrong type for age)
  users_dt_bad <- data.table(
    user_id = 1:3,
    username = c("alice", "bob", "charlie"),
    age = c(25, 30, 35),  # numeric instead of integer!
    score = c(9.5, 8.7, 9.2)
  )

  is_valid_bad <- validate_dt_types(users_dt_bad, expected_schema)
  cat("Bad users data.table is valid:", is_valid_bad, "\n")

  if (!is_valid_bad) {
    mismatches <- attr(is_valid_bad, "mismatches")
    cat("Type mismatches found:\n")
    print(mismatches)
  }


  # 8. Type Inference for data.table Chains
  # ----------------------------------------

  code_chain <- "
  library(data.table)

  dt <- data.table(
    id = 1:100,
    category = sample(letters[1:5], 100, replace = TRUE),
    value = rnorm(100)
  )

  # Chain operations
  result <- dt[
    category %in% c('a', 'b')
  ][
    , .(
      mean_value = mean(value),
      count = .N
    ),
    by = category
  ]
  "

  result <- check_types(code_chain)
  print(result)


  cat("\nAll data.table examples completed successfully!\n")

} else {
  cat("data.table package not installed. Skipping data.table examples.\n")
  cat("Install with: install.packages('data.table')\n")
}
