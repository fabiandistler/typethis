# Quickstart: typethis v0.2

## Installation

```r
# Install from GitHub
remotes::install_github("fabiandistler/typethis")
```

## Basic Usage

### Typed Functions

```r
library(typethis)

# Create a typed function with validation
add <- typed_function(
  function(x, y) x + y,
  arg_specs = c(x = "numeric", y = "numeric"),
  return_spec = "numeric"
)

# Named arguments
add(x = 1, y = 2)  # Returns 3

# Positional arguments  
add(1, 2)  # Also returns 3

# Type errors caught at runtime
add("a", 2)  # Error: x must be numeric, got character
```

### Typed Models

```r
# Define a model
Person <- define_model("Person",
  fields = list(
    name = field("character", nullable = FALSE),
    age = field("integer", nullable = FALSE, default = 0L)
  )
)

# Create an instance
alice <- new_Person(name = "Alice", age = 30)

# Safe update with revalidation
bob <- update_Person(alice, name = "Bob")

# Type checking
is_valid(alice)  # TRUE
```

## Key Differences

| Function | Use When |
|----------|----------|
| `typed_function()` | Wrapping functions that need argument/return validation |
| `define_model()` | Creating structured data records with validation |
| `validate_call()` | Validating a call without wrapping |

## Runtime Only

typethis provides **runtime validation**, not static type checking. It does not replace tools like static analyzers. It catches type errors when R code executes.