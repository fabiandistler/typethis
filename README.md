# typethis

> Animated typing effects for R console output

Create realistic, character-by-character typing animations in the R console. Perfect for presentations, tutorials, live demos, and creating engaging command-line experiences.

## Features

- **Realistic Typing**: Variable speed with human-like delays and optional typos
- **Multiple Speed Presets**: From cinematic slow reveals to blazing fast output
- **Color & Styling**: Full color support using crayon with bold, italic, and more
- **Special Effects**: Error messages, warnings, success notifications, glitch effects
- **Code Typing**: Syntax-aware typing for code demonstrations
- **Interactive Prompts**: Type out questions and collect user input
- **Matrix Rain**: Bonus digital rain effect for dramatic tech presentations

## Installation

```r
# Install from GitHub
# install.packages("devtools")
devtools::install_github("fabiandistler/typethis")
```

## Quick Start

```r
library(typethis)

# Basic typing
type_this("Hello, World!")

# Fast typing with color
type_this("Success!", speed = "fast", color = "green")

# Human-like typing with typos
type_this("This feels realistic", speed = "human", typo_prob = 0.05)

# Dramatic reveal
type_this("The answer is...", speed = "cinematic", cursor = TRUE)
```

## Core Functions

### `type_this()` - Main Function

The primary function with full control over typing animation:

```r
# Slow, dramatic typing
type_this("Critical system message",
          speed = "slow",
          color = "red",
          style = "bold")

# Human-like with mistakes
type_this("I'm typing like a real person!",
          speed = "human",
          typo_prob = 0.03,
          pause_prob = 0.15)

# Blazing fast for long output
type_this("Installing packages...", speed = "blazing")
```

**Parameters:**
- `speed`: Characters per second or preset ("slow", "human", "fast", "blazing", "cinematic")
- `speed_var`: Variation factor (0-1) for human-like randomness
- `color`: Text color ("red", "green", "yellow", "cyan", "blue")
- `style`: Text style ("bold", "italic", "underline")
- `typo_prob`: Probability of typos (0-1)
- `pause_prob`: Probability of thinking pauses (0-1)
- `cursor`: Show blinking cursor at end
- `delay_start/delay_end`: Delays before/after typing

### `type_line()` - Quick Single Lines

Convenience function for single lines:

```r
# Command prompt simulation
type_line("npm install --save-dev typescript",
          prefix = "$ ",
          speed = "human")

# Success message
type_line("Build completed!", color = "green")
```

### `type_code()` - Code Demonstrations

Type code with language-specific prompts:

```r
# R code
type_code("library(dplyr)")
type_code("mtcars %>% filter(mpg > 20)")

# Multi-line function
type_code(c(
  "calculate <- function(x, y) {",
  "  result <- x + y",
  "  return(result)",
  "}"
))

# Python code
type_code("def hello():\n    print('Hello!')", language = "python")
```

### `type_effect()` - Special Effects

Pre-configured effects for common scenarios:

```r
# Error message
type_effect("File not found!", effect = "error")

# Warning
type_effect("Deprecated function", effect = "warning")

# Success
type_effect("Deployment successful!", effect = "success")

# Dramatic reveal
type_effect("The winner is...", effect = "dramatic")

# Glitch effect with typos
type_effect("System compromised", effect = "glitch")
```

### `type_lines()` - Multiple Lines

Type paragraphs or lists:

```r
# Type a bullet list
type_lines(c(
  "Set up environment",
  "Install dependencies",
  "Run tests",
  "Deploy to production"
), prefix = "• ", speed = "fast")
```

### `type_prompt()` - Interactive Input

Create interactive experiences:

```r
# Ask for input
name <- type_prompt("What is your name?", color = "cyan")
type_effect(paste0("Welcome, ", name, "!"), effect = "success")

# Confirmation
response <- type_prompt("Continue? (y/n)")
if (response == "y") {
  type_line("Processing...", speed = "fast")
}
```

## Speed Presets

Access preset configurations:

```r
presets <- typing_presets()

# Available presets:
# - cinematic: 2 chars/sec  - Very slow, dramatic
# - slow: 4 chars/sec        - Emphasis, tutorials
# - human: 8 chars/sec       - Realistic with typos
# - normal: 10 chars/sec     - Default speed
# - fast: 20 chars/sec       - Quick output
# - blazing: 50 chars/sec    - Minimal delay
# - coder: 12 chars/sec      - Realistic coding rhythm
```

Set global default speed:

```r
# Set for entire session
set_typing_speed("fast")

# All subsequent calls use this speed
type_this("This is fast")
type_this("This too!")

# Get current speed
current <- get_typing_speed()
```

## Advanced Examples

### Live Coding Demo

```r
type_line("Let's create a data visualization", color = "cyan")
Sys.sleep(0.5)

type_code("library(ggplot2)")
Sys.sleep(0.3)

type_code(c(
  "ggplot(mtcars, aes(x = mpg, y = hp)) +",
  "  geom_point(color = 'blue') +",
  "  theme_minimal()"
), speed = "coder")

type_effect("Plot created successfully!", effect = "success")
```

### Terminal Simulation

```r
# Simulate package installation
type_line("npm install", prefix = "$ ", speed = "human")
Sys.sleep(0.5)

type_lines(c(
  "Downloading packages...",
  "Resolving dependencies...",
  "Building node_modules..."
), prefix = "  ", speed = "fast", delay_between = 0.2)

type_effect("Installation complete!", effect = "success")
```

### Presentation Opener

```r
# Dramatic intro
matrix_rain(duration = 2, density = 0.2)

type_this("Welcome to the Future of Data Science",
          speed = "cinematic",
          style = "bold",
          delay_start = 0.5,
          cursor = TRUE)

Sys.sleep(1)

type_effect("Let's begin...", effect = "info")
```

### Error Recovery Simulation

```r
type_line("Deploying application...", speed = "fast")
Sys.sleep(1)

type_effect("Error: Connection timeout", effect = "error")
Sys.sleep(0.5)

type_line("Retrying...", color = "yellow")
Sys.sleep(1)

type_effect("Deployment successful!", effect = "success")
```

## Use Cases

- **Presentations**: Add drama and engagement to technical talks
- **Tutorials**: Simulate live typing for educational content
- **Demos**: Create realistic command-line demonstrations
- **Videos**: Record screencasts with professional typing effects
- **Interactive Apps**: Build engaging CLI applications
- **Documentation**: Make examples more dynamic
- **Teaching**: Demonstrate coding in real-time style

## Tips & Tricks

1. **Human Realism**: Use `speed = "human"` with `typo_prob = 0.02-0.05` for maximum realism

2. **Performance**: Use `speed = "blazing"` or high numeric values for long text

3. **Emphasis**: Combine `speed = "slow"` with `style = "bold"` for important messages

4. **Pauses**: Use `pause_prob` and `pause_duration` to simulate thinking

5. **Consistency**: Set global speed with `set_typing_speed()` for uniform sessions

6. **Colors**: Match colors to message type (red=error, green=success, yellow=warning)

## Matrix Rain Bonus

```r
# Brief digital rain effect
matrix_rain(duration = 1.5)

# Dense rain
matrix_rain(duration = 3, density = 0.5, width = 80)

# Quick flash
matrix_rain(duration = 0.5, density = 0.2)
```

## Requirements

- R >= 3.5.0
- crayon >= 1.5.0 (for colors)
- cli >= 3.6.0 (for enhanced output)

## License

MIT License - see LICENSE file

## Author

Fabian Distler

## Contributing

Issues and pull requests welcome at https://github.com/fabiandistler/typethis

---

Made with ❤️ for the R community
