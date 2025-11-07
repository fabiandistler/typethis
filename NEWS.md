# typethis 1.0.0

## Initial Release

### Core Functions

* `type_this()`: Main typing animation function with full customization
* `type_line()`: Quick single-line typing with sensible defaults
* `type_code()`: Code-specific typing with language prompts
* `type_effect()`: Pre-configured effects (error, warning, success, dramatic, glitch)
* `type_lines()`: Type multiple lines with consistent styling
* `type_prompt()`: Interactive typing prompts with user input

### Features

* **Speed Control**: Numeric values or presets (cinematic, slow, human, normal, fast, blazing, coder)
* **Realism**: Variable speed, typos with auto-correction, thinking pauses
* **Styling**: Full color support (red, green, yellow, cyan, blue) and text styles (bold, italic, underline)
* **Effects**: Cursor animation, delay controls, punctuation awareness
* **Global Settings**: `set_typing_speed()` and `get_typing_speed()` for session defaults
* **Presets**: `typing_presets()` with detailed configuration options

### Bonus

* `matrix_rain()`: Matrix-style digital rain effect for dramatic presentations

### Documentation

* Comprehensive README with examples
* Detailed vignette with use cases
* Full function documentation
* Unit tests for core functionality

### Dependencies

* crayon (>= 1.5.0) for colors
* cli (>= 3.6.0) for enhanced output
