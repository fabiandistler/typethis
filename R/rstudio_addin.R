#' RStudio Addins for typethis
#'
#' @description
#' RStudio integration for type checking.
#' Provides addins to check types in current file, selection, or at cursor.
#'
#' @name rstudio_addin
NULL

#' Check if running in RStudio
#'
#' @return Logical indicating if running in RStudio
#' @keywords internal
is_rstudio <- function() {
  requireNamespace("rstudioapi", quietly = TRUE) &&
    rstudioapi::isAvailable()
}

#' Check types in current file (RStudio Addin)
#'
#' @export
addin_check_current_file <- function() {
  if (!is_rstudio()) {
    message("This function requires RStudio")
    return(invisible(NULL))
  }

  # Get current document
  context <- rstudioapi::getSourceEditorContext()

  if (is.null(context)) {
    message("No active document")
    return(invisible(NULL))
  }

  # Get file contents
  code <- paste(context$contents, collapse = "\n")

  if (nchar(code) == 0) {
    message("Document is empty")
    return(invisible(NULL))
  }

  # Check types
  message("Checking types in current file...\n")
  result <- check_types(code, from_file = FALSE)

  # Print results
  print(result)

  # Show results in RStudio viewer if there are errors/warnings
  if (length(result$errors) > 0 || length(result$warnings) > 0) {
    show_results_in_viewer(result, context$path)
  }

  invisible(result)
}

#' Check type of selection (RStudio Addin)
#'
#' @export
addin_check_selection <- function() {
  if (!is_rstudio()) {
    message("This function requires RStudio")
    return(invisible(NULL))
  }

  # Get current selection
  context <- rstudioapi::getSourceEditorContext()

  if (is.null(context$selection)) {
    message("No selection")
    return(invisible(NULL))
  }

  selection <- context$selection[[1]]
  selected_text <- selection$text

  if (nchar(selected_text) == 0) {
    message("No text selected")
    return(invisible(NULL))
  }

  # Try to infer type
  message("Inferring type of selection...\n")

  result <- tryCatch({
    infer_type(selected_text)
  }, error = function(e) {
    message("Could not infer type: ", e$message)
    return(NULL)
  })

  if (!is.null(result)) {
    cat("Selected text: ", selected_text, "\n", sep = "")
    print(result)
  }

  invisible(result)
}

#' Reveal type at cursor (RStudio Addin)
#'
#' @export
addin_reveal_type_at_cursor <- function() {
  if (!is_rstudio()) {
    message("This function requires RStudio")
    return(invisible(NULL))
  }

  # Get current context
  context <- rstudioapi::getSourceEditorContext()
  cursor_pos <- context$selection[[1]]$range$start

  # Get word at cursor
  word_range <- rstudioapi::primary_selection(context)
  selected_text <- word_range$text

  # If nothing selected, try to get word at cursor
  if (nchar(selected_text) == 0) {
    # Try to extract variable name at cursor position
    line_text <- context$contents[cursor_pos[1]]
    col <- cursor_pos[2]

    # Simple word extraction
    before <- substr(line_text, 1, col)
    after <- substr(line_text, col + 1, nchar(line_text))

    # Extract word boundaries
    word_before <- regmatches(before, regexpr("[a-zA-Z_][a-zA-Z0-9._]*$", before))
    word_after <- regmatches(after, regexpr("^[a-zA-Z0-9._]*", after))

    selected_text <- paste0(word_before, word_after)
  }

  if (nchar(selected_text) == 0) {
    message("No variable at cursor")
    return(invisible(NULL))
  }

  # Get full file content for context
  code <- paste(context$contents, collapse = "\n")

  message("Revealing type of '", selected_text, "'...\n", sep = "")

  # Build context and look up variable
  tryCatch({
    parsed <- parse_code(code)
    type_context <- build_type_context(parsed)

    if (selected_text %in% names(type_context)) {
      inferred <- type_context[[selected_text]]
      cat("Type of '", selected_text, "': ", inferred$base_type, "\n", sep = "")
      print(inferred)
    } else {
      message("Variable '", selected_text, "' not found in current context")
    }
  }, error = function(e) {
    message("Error: ", e$message)
  })

  invisible(NULL)
}

#' Show type check results in RStudio viewer
#'
#' @param result Type check result object
#' @param file_path Optional file path
#' @keywords internal
show_results_in_viewer <- function(result, file_path = NULL) {
  if (!is_rstudio()) {
    return(invisible(NULL))
  }

  # Create HTML report
  html <- paste0(
    "<!DOCTYPE html>\n",
    "<html>\n",
    "<head>\n",
    "<title>Type Check Results</title>\n",
    "<style>\n",
    "body { font-family: monospace; padding: 20px; }\n",
    ".error { color: red; font-weight: bold; }\n",
    ".warning { color: orange; }\n",
    ".info { color: blue; }\n",
    "h1 { color: #333; }\n",
    ".message { margin: 10px 0; padding: 5px; border-left: 3px solid; }\n",
    ".error-msg { border-left-color: red; }\n",
    ".warning-msg { border-left-color: orange; }\n",
    "</style>\n",
    "</head>\n",
    "<body>\n",
    "<h1>Type Check Results</h1>\n"
  )

  if (!is.null(file_path)) {
    html <- paste0(html, "<p>File: ", file_path, "</p>\n")
  }

  # Add errors
  if (length(result$errors) > 0) {
    html <- paste0(html, "<h2 class='error'>Errors</h2>\n")
    for (err in result$errors) {
      html <- paste0(
        html,
        sprintf(
          "<div class='message error-msg'><span class='error'>Line %d:%d</span> - %s</div>\n",
          err$line, err$col, err$message
        )
      )
    }
  }

  # Add warnings
  if (length(result$warnings) > 0) {
    html <- paste0(html, "<h2 class='warning'>Warnings</h2>\n")
    for (warn in result$warnings) {
      html <- paste0(
        html,
        sprintf(
          "<div class='message warning-msg'><span class='warning'>Line %d:%d</span> - %s</div>\n",
          warn$line, warn$col, warn$message
        )
      )
    }
  }

  html <- paste0(html, "</body>\n</html>")

  # Write to temp file
  temp_file <- tempfile(fileext = ".html")
  writeLines(html, temp_file)

  # Show in viewer
  rstudioapi::viewer(temp_file)

  invisible(NULL)
}

#' Insert type annotation at cursor (RStudio Addin)
#'
#' @export
addin_insert_type_annotation <- function() {
  if (!is_rstudio()) {
    message("This function requires RStudio")
    return(invisible(NULL))
  }

  # Get current context
  context <- rstudioapi::getSourceEditorContext()

  # Simple template for type annotation
  annotation <- "#' @type "

  # Insert at cursor
  rstudioapi::insertText(annotation)

  message("Type annotation template inserted")
  invisible(NULL)
}
