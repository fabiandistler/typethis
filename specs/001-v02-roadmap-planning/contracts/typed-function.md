# Typed Function Contract

## Overview

The typed_function() and validate_call() APIs provide runtime type validation for R functions.

## typed_function()

### Signature

```r
typed_function(fn, arg_specs = NULL, return_spec = NULL, coerce = FALSE)
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| fn | function | Function to wrap |
| arg_specs | named character list | Type specifications for arguments |
| return_spec | character | Type specification for return value |
| coerce | logical | Whether to attempt type coercion |

### Return Value

A wrapped function with type validation.

### Contract

1. **Argument Binding**: Arguments bound against fn's actual formals
2. **Named Calls**: `fn(x = 1)` works identically to `fn(1)`
3. **Positional Calls**: `fn(1, 2)` works with named specs
4. **Defaults**: Missing arguments evaluated from formals defaults
5. **Ellipsis**: `...` passed through without type checking
6. **Return**: Validated against return_spec if provided

### Examples

```r
# Named arguments
add <- typed_function(function(x, y) x + y, c(x = "numeric", y = "numeric"), "numeric")
add(x = 1, y = 2)  # OK

# Positional arguments
add(1, 2)  # Also OK

# Type error
add("a", 2)  # Error
```

## validate_call()

### Signature

```r
validate_call(fn, args, arg_specs, return_spec = NULL)
```

### Parameters

Same as typed_function().

### Return Value

Validated arguments as named list.

## Error Format

```r
# Error structure
stop("typethis_type_error: argument 'x' must be numeric, got character")
```