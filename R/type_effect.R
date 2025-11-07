#' Type Text with Special Effects
#'
#' Create dramatic typing effects for presentations and demonstrations.
#' Includes presets for common scenarios like errors, warnings, success messages,
#' and dramatic reveals.
#'
#' @param text Character string to type
#' @param effect Effect preset: "error", "warning", "success", "info", "dramatic", "glitch" (default: "info")
#' @param custom_speed Optional custom speed override (default: NULL)
#'
#' @return Invisible NULL
#' @export
#' @importFrom crayon red yellow green cyan bold
#'
#' @examples
#' \dontrun{
#' # Error message with dramatic effect
#' type_effect("Critical error detected!", effect = "error")
#'
#' # Success message
#' type_effect("Deployment successful!", effect = "success")
#'
#' # Warning
#' type_effect("Warning: Low disk space", effect = "warning")
#'
#' # Dramatic reveal
#' type_effect("The winner is...", effect = "dramatic")
#'
#' # Glitch effect
#' type_effect("System compromised", effect = "glitch")
#' }
type_effect <- function(text, effect = "info", custom_speed = NULL) {

  effect_config <- switch(
    effect,
    "error" = list(
      prefix = crayon::red(crayon::bold("ERROR: ")),
      color = "red",
      speed = 15,
      style = "bold",
      delay_start = 0.2,
      typo_prob = 0
    ),
    "warning" = list(
      prefix = crayon::yellow(crayon::bold("WARNING: ")),
      color = "yellow",
      speed = 12,
      style = NULL,
      delay_start = 0.1,
      typo_prob = 0
    ),
    "success" = list(
      prefix = crayon::green(crayon::bold("✓ ")),
      color = "green",
      speed = 10,
      style = NULL,
      delay_start = 0,
      typo_prob = 0
    ),
    "info" = list(
      prefix = crayon::cyan("ℹ "),
      color = "cyan",
      speed = 10,
      style = NULL,
      delay_start = 0,
      typo_prob = 0
    ),
    "dramatic" = list(
      prefix = "",
      color = NULL,
      speed = 3,
      style = "bold",
      delay_start = 0.5,
      delay_end = 1,
      typo_prob = 0,
      cursor = TRUE
    ),
    "glitch" = list(
      prefix = "",
      color = "red",
      speed = 25,
      style = NULL,
      delay_start = 0,
      typo_prob = 0.15,
      speed_var = 0.7
    ),
    # Default info
    list(
      prefix = "",
      color = NULL,
      speed = 10,
      style = NULL,
      delay_start = 0,
      typo_prob = 0
    )
  )

  # Override speed if specified
  if (!is.null(custom_speed)) {
    effect_config$speed <- custom_speed
  }

  # Add prefix to text
  full_text <- paste0(effect_config$prefix, text)

  # Type with effect settings
  do.call(type_this, c(
    list(text = full_text),
    effect_config[names(effect_config) != "prefix"]
  ))

  invisible(NULL)
}


#' Matrix-Style Digital Rain Effect
#'
#' Creates a brief Matrix-like digital rain effect in the console.
#' Great for dramatic tech presentations.
#'
#' @param duration Numeric. Duration in seconds (default: 2)
#' @param density Numeric. Character density 0-1 (default: 0.3)
#' @param width Numeric. Width in characters (default: 60)
#'
#' @return Invisible NULL
#' @export
#' @importFrom crayon green
#'
#' @examples
#' \dontrun{
#' # Brief matrix effect before revealing text
#' matrix_rain(duration = 1)
#' type_effect("Access granted", effect = "success")
#' }
matrix_rain <- function(duration = 2, density = 0.3, width = 60) {
  chars <- c(0:9, letters, LETTERS, "!", "@", "#", "$", "%", "&", "*")
  start_time <- Sys.time()

  while (difftime(Sys.time(), start_time, units = "secs") < duration) {
    line <- sapply(1:width, function(x) {
      if (runif(1) < density) {
        crayon::green(sample(chars, 1))
      } else {
        " "
      }
    })
    cat(paste(line, collapse = ""), "\n", sep = "")
    flush.console()
    Sys.sleep(0.05)
  }

  invisible(NULL)
}
