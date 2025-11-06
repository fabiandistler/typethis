#' AST Parser for Static Analysis
#'
#' @description
#' Parse R code into an Abstract Syntax Tree (AST) for static analysis
#' without code execution.
#'
#' @name ast_parser
NULL

#' Parse R code to AST
#'
#' @param code Character string or file path containing R code
#' @param from_file Logical indicating if code is a file path
#' @return Parsed expression with parse data
#' @export
parse_code <- function(code, from_file = FALSE) {
  if (from_file) {
    if (!file.exists(code)) {
      stop("File not found: ", code)
    }
    code <- readLines(code, warn = FALSE)
    code <- paste(code, collapse = "\n")
  }

  # Parse the code
  expr <- tryCatch(
    parse(text = code, keep.source = TRUE),
    error = function(e) {
      stop("Parse error: ", e$message)
    }
  )

  # Get parse data for detailed analysis
  parse_data <- getParseData(expr)

  list(
    expr = expr,
    parse_data = parse_data,
    code = code
  )
}

#' Extract function definitions from parsed code
#'
#' @param parsed_code Output from parse_code()
#' @return List of function definitions with metadata
#' @export
extract_functions <- function(parsed_code) {
  pd <- parsed_code$parse_data
  if (is.null(pd) || nrow(pd) == 0) {
    return(list())
  }

  # Find function definitions
  # Look for SYMBOL_FORMALS followed by FUNCTION keyword
  func_indices <- which(pd$token == "FUNCTION")

  if (length(func_indices) == 0) {
    return(list())
  }

  functions <- lapply(func_indices, function(idx) {
    # Get function name (if assigned)
    func_name <- NULL
    parent_id <- pd$parent[idx]

    # Look backwards for assignment
    assign_idx <- which(
      pd$token %in% c("EQ_ASSIGN", "LEFT_ASSIGN") &
        pd$parent == parent_id
    )
    if (length(assign_idx) > 0) {
      # Find the symbol being assigned to
      symbol_idx <- which(
        pd$token == "SYMBOL" &
          pd$line1 == pd$line1[assign_idx[1]] &
          pd$col1 < pd$col1[assign_idx[1]]
      )
      if (length(symbol_idx) > 0) {
        func_name <- pd$text[symbol_idx[length(symbol_idx)]]
      }
    }

    # Extract function formals (parameters)
    formals_parent <- pd$id[idx]
    formals_idx <- which(
      pd$parent == formals_parent &
        pd$token == "SYMBOL_FORMALS"
    )
    params <- pd$text[formals_idx]

    list(
      name = func_name,
      params = params,
      line = pd$line1[idx],
      col = pd$col1[idx],
      text = pd$text[idx]
    )
  })

  functions
}

#' Extract variable assignments from parsed code
#'
#' @param parsed_code Output from parse_code()
#' @return Data frame of variable assignments
#' @export
extract_assignments <- function(parsed_code) {
  pd <- parsed_code$parse_data
  if (is.null(pd) || nrow(pd) == 0) {
    return(data.frame(
      variable = character(0),
      line = integer(0),
      col = integer(0),
      value_text = character(0),
      stringsAsFactors = FALSE
    ))
  }

  # Find assignment operators
  assign_idx <- which(
    pd$token %in% c("EQ_ASSIGN", "LEFT_ASSIGN", "RIGHT_ASSIGN")
  )

  if (length(assign_idx) == 0) {
    return(data.frame(
      variable = character(0),
      line = integer(0),
      col = integer(0),
      value_text = character(0),
      stringsAsFactors = FALSE
    ))
  }

  assignments <- lapply(assign_idx, function(idx) {
    assign_line <- pd$line1[idx]
    parent_id <- pd$parent[idx]

    # Find variable being assigned
    var_idx <- which(
      pd$token == "SYMBOL" &
      pd$parent == parent_id &
      pd$line1 == assign_line &
      pd$col1 < pd$col1[idx]
    )

    if (length(var_idx) == 0) {
      return(NULL)
    }

    var_name <- pd$text[var_idx[length(var_idx)]]

    # Find value being assigned (everything after the assignment)
    value_idx <- which(
      pd$parent == parent_id &
      pd$line1 >= assign_line &
      pd$col1 > pd$col1[idx]
    )

    value_text <- if (length(value_idx) > 0) {
      paste(pd$text[value_idx], collapse = " ")
    } else {
      ""
    }

    list(
      variable = var_name,
      line = assign_line,
      col = pd$col1[idx],
      value_text = value_text
    )
  })

  assignments <- Filter(Negate(is.null), assignments)

  if (length(assignments) == 0) {
    return(data.frame(
      variable = character(0),
      line = integer(0),
      col = integer(0),
      value_text = character(0),
      stringsAsFactors = FALSE
    ))
  }

  do.call(
    rbind,
    lapply(assignments, as.data.frame, stringsAsFactors = FALSE)
  )
}

#' Extract function calls from parsed code
#'
#' @param parsed_code Output from parse_code()
#' @return Data frame of function calls
#' @export
extract_function_calls <- function(parsed_code) {
  pd <- parsed_code$parse_data
  if (is.null(pd) || nrow(pd) == 0) {
    return(data.frame(
      function_name = character(0),
      line = integer(0),
      col = integer(0),
      stringsAsFactors = FALSE
    ))
  }

  # Find function calls (SYMBOL_FUNCTION_CALL)
  call_idx <- which(pd$token == "SYMBOL_FUNCTION_CALL")

  if (length(call_idx) == 0) {
    return(data.frame(
      function_name = character(0),
      line = integer(0),
      col = integer(0),
      stringsAsFactors = FALSE
    ))
  }

  calls <- data.frame(
    function_name = pd$text[call_idx],
    line = pd$line1[call_idx],
    col = pd$col1[call_idx],
    stringsAsFactors = FALSE
  )

  calls
}

#' Get token information at specific location
#'
#' @param parsed_code Output from parse_code()
#' @param line Line number
#' @param col Column number
#' @return Token information at that location
#' @export
get_token_at_location <- function(parsed_code, line, col) {
  pd <- parsed_code$parse_data
  if (is.null(pd) || nrow(pd) == 0) {
    return(NULL)
  }

  # Find token at location
  token_idx <- which(
    pd$line1 <= line & pd$line2 >= line &
    pd$col1 <= col & pd$col2 >= col
  )

  if (length(token_idx) == 0) {
    return(NULL)
  }

  # Return the most specific token (smallest range)
  token_idx <- token_idx[which.min(
    (pd$line2[token_idx] - pd$line1[token_idx]) * 1000 +
      (pd$col2[token_idx] - pd$col1[token_idx])
  )]

  as.list(pd[token_idx, ])
}
