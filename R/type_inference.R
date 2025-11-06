#' Type Inference Engine
#'
#' @description
#' Automatically infer types from R code without execution.
#' Supports basic literals, function calls, and data structures.
#'
#' @name type_inference
NULL

#' Infer type from R expression or value
#'
#' @param x R object or expression
#' @param context Optional context with known types
#' @return An rtype object representing the inferred type
#' @export
#' @examples
#' \dontrun{
#' infer_type(5L)  # integer
#' infer_type(5.0) # numeric
#' infer_type("hello") # character
#' }
infer_type <- function(x, context = NULL) {
  UseMethod("infer_type")
}

#' @export
infer_type.default <- function(x, context = NULL) {
  # For actual R objects, determine type directly
  if (is.null(x)) {
    return(TYPES$NULL)
  }
  if (is.integer(x)) {
    return(TYPES$integer)
  }
  if (is.double(x)) {
    return(TYPES$double)
  }
  if (is.numeric(x)) {
    return(TYPES$numeric)
  }
  if (is.character(x)) {
    return(TYPES$character)
  }
  if (is.logical(x)) {
    return(TYPES$logical)
  }
  if (is.complex(x)) {
    return(TYPES$complex)
  }
  if (is.raw(x)) {
    return(TYPES$raw)
  }
  if (is.list(x)) {
    # Check for data.frame/data.table/tibble
    if (inherits(x, "data.table")) {
      return(create_type("data.table", columns = infer_column_types(x)))
    }
    if (inherits(x, "tbl_df") || inherits(x, "tibble")) {
      return(create_type("tibble", columns = infer_column_types(x)))
    }
    if (is.data.frame(x)) {
      return(create_type("data.frame", columns = infer_column_types(x)))
    }
    return(TYPES$list)
  }
  if (is.function(x)) {
    return(TYPES$function)
  }
  if (inherits(x, "formula")) {
    return(TYPES$formula)
  }
  if (is.environment(x)) {
    return(TYPES$environment)
  }

  # Check for S4
  if (isS4(x)) {
    return(create_type("S4", class = class(x)[1]))
  }

  # Check for R6
  if (inherits(x, "R6")) {
    return(create_type("R6", class = class(x)[1]))
  }

  # Default to S3 with class info
  create_type("S3", class = class(x)[1])
}

#' @export
infer_type.character <- function(x, context = NULL) {
  # x is a character string representing code
  # Try to parse and infer
  tryCatch({
    parsed <- parse(text = x)
    infer_type_from_expr(parsed[[1]], context)
  }, error = function(e) {
    TYPES$unknown
  })
}

#' Infer type from parsed expression
#'
#' @param expr Parsed R expression
#' @param context Optional context with known types
#' @return An rtype object
#' @export
infer_type_from_expr <- function(expr, context = NULL) {
  if (is.null(context)) {
    context <- list()
  }

  # Handle NULL
  if (is.null(expr)) {
    return(TYPES$NULL)
  }

  # Handle literals
  if (is.numeric(expr)) {
    if (is.integer(expr)) {
      return(TYPES$integer)
    }
    return(TYPES$numeric)
  }
  if (is.character(expr)) {
    return(TYPES$character)
  }
  if (is.logical(expr)) {
    return(TYPES$logical)
  }

  # Handle symbols - look up in context
  if (is.symbol(expr)) {
    var_name <- as.character(expr)
    if (var_name %in% names(context)) {
      return(context[[var_name]])
    }
    return(TYPES$unknown)
  }

  # Handle calls
  if (is.call(expr)) {
    func_name <- as.character(expr[[1]])

    # Special handling for known functions
    inferred <- infer_type_from_call(func_name, expr, context)
    return(inferred)
  }

  TYPES$unknown
}

#' Infer type from function call
#'
#' @param func_name Name of the function
#' @param call The call expression
#' @param context Type context
#' @return An rtype object
#' @keywords internal
infer_type_from_call <- function(func_name, call, context) {
  # Known constructors
  if (func_name == "c") {
    # Vector construction - infer from first element
    if (length(call) > 1) {
      return(infer_type_from_expr(call[[2]], context))
    }
    return(TYPES$vector)
  }

  if (func_name == "list") {
    return(TYPES$list)
  }

  if (func_name == "data.frame") {
    # Try to infer column types
    return(TYPES$data.frame)
  }

  if (func_name == "data.table") {
    return(TYPES$data.table)
  }

  if (func_name == "tibble") {
    return(TYPES$tibble)
  }

  # Type conversion functions
  if (func_name == "as.integer") {
    return(TYPES$integer)
  }
  if (func_name %in% c("as.numeric", "as.double")) {
    return(TYPES$numeric)
  }
  if (func_name == "as.character") {
    return(TYPES$character)
  }
  if (func_name == "as.logical") {
    return(TYPES$logical)
  }

  # Mathematical operations return numeric
  if (func_name %in% c("+", "-", "*", "/", "^", "%%", "%/%")) {
    return(TYPES$numeric)
  }

  # Comparison operations return logical
  if (func_name %in% c("<", ">", "<=", ">=", "==", "!=", "&", "|", "!")) {
    return(TYPES$logical)
  }

  # String operations
  if (func_name %in% c("paste", "paste0", "sprintf", "substr", "gsub", "sub")) {
    return(TYPES$character)
  }

  # Default: unknown
  TYPES$unknown
}

#' Infer column types from data frame
#'
#' @param df A data frame, data.table, or tibble
#' @return Named list of column types
#' @keywords internal
infer_column_types <- function(df) {
  if (!is.data.frame(df) || ncol(df) == 0) {
    return(list())
  }

  col_types <- lapply(df, function(col) {
    infer_type(col)$base_type
  })

  names(col_types) <- names(df)
  col_types
}

#' Build type context from assignments
#'
#' @param parsed_code Parsed code from parse_code()
#' @return Named list of variable types
#' @export
build_type_context <- function(parsed_code) {
  assignments <- extract_assignments(parsed_code)
  context <- list()

  if (nrow(assignments) == 0) {
    return(context)
  }

  for (i in seq_len(nrow(assignments))) {
    var_name <- assignments$variable[i]
    value_text <- assignments$value_text[i]

    # Try to infer type from value
    inferred_type <- tryCatch({
      infer_type(value_text, context)
    }, error = function(e) {
      TYPES$unknown
    })

    context[[var_name]] <- inferred_type
  }

  context
}

#' Infer types for all assignments in code
#'
#' @param code R code as character string or file path
#' @param from_file Logical indicating if code is a file path
#' @return Data frame with variables and inferred types
#' @export
#' @examples
#' \dontrun{
#' code <- "x <- 5L\ny <- 3.14\nz <- 'hello'"
#' infer_types_from_code(code)
#' }
infer_types_from_code <- function(code, from_file = FALSE) {
  parsed <- parse_code(code, from_file)
  assignments <- extract_assignments(parsed)

  if (nrow(assignments) == 0) {
    return(data.frame(
      variable = character(0),
      type = character(0),
      line = integer(0),
      stringsAsFactors = FALSE
    ))
  }

  context <- list()

  types <- character(nrow(assignments))
  for (i in seq_len(nrow(assignments))) {
    value_text <- assignments$value_text[i]
    inferred_type <- tryCatch({
      infer_type(value_text, context)
    }, error = function(e) {
      TYPES$unknown
    })

    types[i] <- inferred_type$base_type
    context[[assignments$variable[i]]] <- inferred_type
  }

  data.frame(
    variable = assignments$variable,
    type = types,
    line = assignments$line,
    stringsAsFactors = FALSE
  )
}
