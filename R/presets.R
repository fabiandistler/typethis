#' Get Typing Speed Presets
#'
#' Returns a list of predefined typing speed configurations with
#' descriptions and recommended use cases.
#'
#' @return A list of typing speed presets
#' @export
#'
#' @examples
#' \dontrun{
#' # View all presets
#' presets <- typing_presets()
#' print(presets)
#'
#' # Use a preset
#' type_this("Hello!", speed = presets$human$speed)
#' }
typing_presets <- function() {
  list(
    cinematic = list(
      speed = 2,
      speed_var = 0.4,
      description = "Very slow, dramatic reveal for presentations",
      use_case = "Dramatic moments, title reveals"
    ),
    slow = list(
      speed = 4,
      speed_var = 0.3,
      description = "Slow typing for emphasis",
      use_case = "Important messages, tutorials"
    ),
    human = list(
      speed = 8,
      speed_var = 0.35,
      typo_prob = 0.02,
      pause_prob = 0.15,
      description = "Realistic human typing with occasional mistakes",
      use_case = "Demos, realistic simulations"
    ),
    normal = list(
      speed = 10,
      speed_var = 0.25,
      description = "Standard typing speed",
      use_case = "General purpose, default speed"
    ),
    fast = list(
      speed = 20,
      speed_var = 0.2,
      description = "Quick typing for efficiency",
      use_case = "Long text, less dramatic effect"
    ),
    blazing = list(
      speed = 50,
      speed_var = 0.1,
      description = "Very fast, minimal delay",
      use_case = "Quick output, terminal feel"
    ),
    coder = list(
      speed = 12,
      speed_var = 0.4,
      typo_prob = 0.03,
      pause_prob = 0.2,
      pause_duration = 0.8,
      description = "Realistic coding rhythm with thinking pauses",
      use_case = "Live coding demos"
    )
  )
}


#' Set Global Typing Speed
#'
#' Sets a default typing speed for the current session.
#' All subsequent type_this() calls will use this speed unless overridden.
#'
#' @param speed Numeric or character speed preset (default: 10)
#'
#' @return Previous speed setting (invisible)
#' @export
#'
#' @examples
#' \dontrun{
#' # Set global speed
#' old_speed <- set_typing_speed("fast")
#'
#' # All typing now uses fast speed
#' type_this("This is fast")
#' type_this("This too!")
#'
#' # Restore old speed
#' set_typing_speed(old_speed)
#' }
set_typing_speed <- function(speed = 10) {
  old_speed <- getOption("typethis.speed", 10)
  options(typethis.speed = speed)
  invisible(old_speed)
}


#' Get Current Typing Speed
#'
#' Retrieves the current global typing speed setting.
#'
#' @return Current speed setting
#' @export
#'
#' @examples
#' \dontrun{
#' current <- get_typing_speed()
#' print(current)
#' }
get_typing_speed <- function() {
  getOption("typethis.speed", 10)
}


#' Type Multiple Lines with Consistent Styling
#'
#' Types multiple lines of text with consistent speed and styling.
#' Useful for typing paragraphs or lists.
#'
#' @param lines Character vector of lines to type
#' @param speed Typing speed (default: "normal")
#' @param color Text color (default: NULL)
#' @param prefix Character to prepend to each line (default: "")
#' @param delay_between Delay between lines in seconds (default: 0.3)
#'
#' @return Invisible NULL
#' @export
#'
#' @examples
#' \dontrun{
#' # Type a list
#' type_lines(c(
#'   "First item",
#'   "Second item",
#'   "Third item"
#' ), prefix = "• ")
#'
#' # Type a paragraph
#' type_lines(c(
#'   "This is the first sentence.",
#'   "This is the second sentence.",
#'   "This is the third sentence."
#' ), speed = "human")
#' }
type_lines <- function(lines,
                       speed = "normal",
                       color = NULL,
                       prefix = "",
                       delay_between = 0.3) {

  for (i in seq_along(lines)) {
    type_this(
      paste0(prefix, lines[i]),
      speed = speed,
      color = color,
      newline = TRUE
    )
    if (i < length(lines)) {
      Sys.sleep(delay_between)
    }
  }

  invisible(NULL)
}


#' Interactive Typing Prompt
#'
#' Creates an interactive prompt that types out a question and waits for user input.
#'
#' @param prompt Character string for the prompt text
#' @param speed Typing speed (default: "human")
#' @param color Text color (default: "cyan")
#'
#' @return User input as character string
#' @export
#' @importFrom crayon cyan
#'
#' @examples
#' \dontrun{
#' # Ask for user's name
#' name <- type_prompt("What is your name?")
#' type_this(paste0("Hello, ", name, "!"))
#'
#' # Confirm action
#' confirm <- type_prompt("Continue? (y/n)")
#' }
type_prompt <- function(prompt, speed = "human", color = "cyan") {
  type_this(paste0(prompt, " "), speed = speed, color = color, newline = FALSE)
  response <- readline()
  return(response)
}
