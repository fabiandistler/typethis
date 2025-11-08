#' Type a Single Line Quickly
#'
#' Convenience wrapper around type_this() optimized for single lines
#' with sensible defaults for common use cases.
#'
#' @param text Character string to type
#' @param speed Typing speed preset: "slow", "human", "fast", "blazing" (default: "fast")
#' @param color Text color (default: NULL)
#' @param prefix Character string to prepend (e.g., "> ", "$ ") (default: "")
#'
#' @return Invisible NULL
#' @export
#'
#' @examples
#' \dontrun{
#' # Quick command prompt simulation
#' type_line("npm install", prefix = "$ ", speed = "human")
#'
#' # Success message
#' type_line("Build completed successfully!", color = "green")
#'
#' # Error message
#' type_line("Error: File not found", color = "red", speed = "fast")
#' }
type_line <- function(text, speed = "fast", color = NULL, prefix = "") {
  full_text <- paste0(prefix, text)
  type_this(full_text, speed = speed, color = color, newline = TRUE)
}


#' Type Code with Syntax Highlighting
#'
#' Types out code snippets with basic syntax highlighting and
#' realistic coding rhythm (faster for keywords, slower for thinking).
#'
#' @param code Character string or vector of code lines
#' @param language Language for styling hints: "r", "python", "javascript" (default: "r")
#' @param speed Base typing speed (default: "human")
#' @param show_prompt Logical. Show language-specific prompt (default: TRUE)
#' @param indent Numeric. Number of spaces for indentation (default: 0)
#'
#' @return Invisible NULL
#' @export
#' @importFrom crayon cyan green yellow
#'
#' @examples
#' \dontrun{
#' # Type R code
#' type_code("x <- 1:10")
#' type_code("plot(x, x^2)")
#'
#' # Type function definition
#' type_code(c(
#'   "my_function <- function(x) {",
#'   "  x * 2",
#'   "}"
#' ))
#'
#' # Python code
#' type_code("def hello():\n    print('Hello!')", language = "python")
#' }
type_code <- function(code,
                      language = "r",
                      speed = "human",
                      show_prompt = TRUE,
                      indent = 0) {

  # Get prompt for language
  prompt <- if (show_prompt) {
    switch(
      tolower(language),
      "r" = crayon::cyan("> "),
      "python" = crayon::cyan(">>> "),
      "javascript" = crayon::cyan("$ "),
      "bash" = crayon::cyan("$ "),
      ""
    )
  } else {
    ""
  }

  # Handle multiple lines
  if (length(code) > 1) {
    for (line in code) {
      if (nchar(line) > 0) {
        indented <- paste0(strrep(" ", indent), line)
        type_this(paste0(prompt, indented), speed = speed, newline = TRUE)
      } else {
        cat("\n")
      }
    }
  } else {
    # Single line
    indented <- paste0(strrep(" ", indent), code)
    type_this(paste0(prompt, indented), speed = speed, newline = TRUE)
  }

  invisible(NULL)
}
