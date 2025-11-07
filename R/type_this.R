#' Type Text with Animated Effect
#'
#' Creates a realistic typing animation in the console, character by character.
#' Supports variable speed, human-like delays, colors, and special effects.
#'
#' @param text Character string or vector to type out
#' @param speed Numeric. Characters per second (default: 10). Use presets like "human", "fast", "slow"
#' @param speed_var Numeric. Speed variation factor (0-1). Higher = more human-like (default: 0.3)
#' @param newline Logical. Add newline at end (default: TRUE)
#' @param delay_start Numeric. Delay in seconds before starting (default: 0)
#' @param delay_end Numeric. Delay in seconds after finishing (default: 0)
#' @param color Character. Text color using crayon colors (default: NULL)
#' @param style Character. Text style: "bold", "italic", "underline" (default: NULL)
#' @param typo_prob Numeric. Probability of typos (0-1) for realistic effect (default: 0)
#' @param pause_prob Numeric. Probability of pauses between words (0-1) (default: 0.1)
#' @param pause_duration Numeric. Duration of pauses in seconds (default: 0.5)
#' @param cursor Logical. Show blinking cursor at end (default: FALSE)
#' @param sound Logical. Simulated typing sound (via rapid dots) (default: FALSE)
#'
#' @return Invisible NULL
#' @export
#' @importFrom crayon bold italic red green yellow cyan
#'
#' @examples
#' \dontrun{
#' # Basic typing
#' type_this("Hello, World!")
#'
#' # Fast typing with color
#' type_this("Error occurred!", speed = 30, color = "red")
#'
#' # Human-like typing with typos
#' type_this("This is realistic typing", speed = "human", typo_prob = 0.05)
#'
#' # Slow, dramatic reveal
#' type_this("The answer is...", speed = "slow", delay_end = 1)
#' }
type_this <- function(text,
                      speed = 10,
                      speed_var = 0.3,
                      newline = TRUE,
                      delay_start = 0,
                      delay_end = 0,
                      color = NULL,
                      style = NULL,
                      typo_prob = 0,
                      pause_prob = 0.1,
                      pause_duration = 0.5,
                      cursor = FALSE,
                      sound = FALSE) {

  # Handle speed presets
  if (is.character(speed)) {
    speed <- switch(
      speed,
      "human" = 8,
      "slow" = 4,
      "fast" = 20,
      "blazing" = 50,
      "cinematic" = 2,
      10
    )
    # Adjust typo probability for human preset
    if (speed == 8 && typo_prob == 0) typo_prob <- 0.02
  }

  # Initial delay
  if (delay_start > 0) Sys.sleep(delay_start)

  # Convert text to single string
  text <- paste(text, collapse = " ")

  # Apply styling
  if (!is.null(color) || !is.null(style)) {
    text <- style_text(text, color, style)
  }

  # Split into characters
  chars <- strsplit(text, "")[[1]]

  # Type each character
  for (i in seq_along(chars)) {
    char <- chars[i]

    # Random typo simulation
    if (runif(1) < typo_prob && char != " " && i < length(chars) - 2) {
      # Type wrong character
      wrong_char <- sample(letters, 1)
      cat(wrong_char, sep = "")
      flush.console()
      Sys.sleep(calc_delay(speed, speed_var) * 0.5)

      # Backspace (simulate with \b)
      cat("\b \b", sep = "")
      flush.console()
      Sys.sleep(calc_delay(speed, speed_var) * 0.3)
    }

    # Type the actual character
    cat(char, sep = "")
    flush.console()

    # Calculate delay for this character
    delay <- calc_delay(speed, speed_var)

    # Extra pause after punctuation
    if (char %in% c(".", "!", "?", ",", ";", ":")) {
      delay <- delay * 2
    }

    # Random pause between words
    if (char == " " && runif(1) < pause_prob) {
      delay <- delay + pause_duration
    }

    Sys.sleep(delay)
  }

  # Cursor effect
  if (cursor) {
    for (i in 1:3) {
      cat("_")
      flush.console()
      Sys.sleep(0.3)
      cat("\b \b")
      flush.console()
      Sys.sleep(0.3)
    }
  }

  # Newline
  if (newline) cat("\n")

  # End delay
  if (delay_end > 0) Sys.sleep(delay_end)

  invisible(NULL)
}


#' Calculate Typing Delay
#'
#' Internal function to calculate delay between characters with variation
#'
#' @param speed Characters per second
#' @param speed_var Variation factor (0-1)
#' @return Delay in seconds
#' @keywords internal
calc_delay <- function(speed, speed_var) {
  base_delay <- 1 / speed
  variation <- runif(1, 1 - speed_var, 1 + speed_var)
  base_delay * variation
}


#' Style Text with Colors and Formatting
#'
#' Internal function to apply crayon styling
#'
#' @param text Text to style
#' @param color Color name
#' @param style Style name
#' @return Styled text
#' @keywords internal
style_text <- function(text, color = NULL, style = NULL) {
  result <- text

  # Apply color
  if (!is.null(color)) {
    result <- switch(
      color,
      "red" = crayon::red(result),
      "green" = crayon::green(result),
      "yellow" = crayon::yellow(result),
      "cyan" = crayon::cyan(result),
      "blue" = crayon::blue(result),
      result
    )
  }

  # Apply style
  if (!is.null(style)) {
    result <- switch(
      style,
      "bold" = crayon::bold(result),
      "italic" = crayon::italic(result),
      "underline" = crayon::underline(result),
      result
    )
  }

  result
}
