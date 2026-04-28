# Wrap a function with input/output type checks

Returns a wrapped version of `fn` that validates each argument against
the spec in `arg_specs` on every call, and (optionally) the return value
against `return_spec`. Calls that violate a spec raise an informative
error before — or just after — `fn` runs.

Argument specs may be character builtins, predicate functions, or any
[type_spec](type_spec.md) (e.g. [`t_union()`](t_union.md),
[`t_list_of()`](t_list_of.md)). Coercion can be enabled per call via
`coerce = TRUE`.

All R calling conventions are supported: positional, named, reordered
named, mixed, and `...` passthrough.

## Usage

``` r
typed_function(
  fn,
  arg_specs = NULL,
  return_spec = NULL,
  validate = TRUE,
  coerce = FALSE,
  arg_types = NULL,
  return_type = NULL
)
```

## Arguments

- fn:

  The underlying function.

- arg_specs:

  Named list (or character vector) of argument specifications. Names
  must match argument names of `fn`.

- return_spec:

  Specification for the return value, or `NULL` to skip.

- validate:

  If `FALSE`, type checks are skipped (useful for hot paths).

- coerce:

  If `TRUE`, arguments that don't match are first run through
  [`coerce_type()`](coerce_type.md) before assertion.

- arg_types, return_type:

  Deprecated aliases for `arg_specs` / `return_spec`. New code should
  use the latter.

## Value

A function with the same formals as `fn`. Carries `arg_specs`,
`return_spec`, and `typed = TRUE` as attributes.

## See also

[`signature()`](signature.md) / [`with_signature()`](with_signature.md)
for a separate-then-attach workflow;
[`validate_call()`](validate_call.md) to dry-run validation;
[`is_typed()`](is_typed.md) / [`get_signature()`](get_signature.md) for
introspection.

Other typed functions: [`as_typed()`](as_typed.md),
[`as_typed_env()`](as_typed_env.md),
[`get_signature()`](get_signature.md),
[`infer_specs()`](infer_specs.md), [`is_typed()`](is_typed.md),
[`signature`](signature.md), [`typed_method()`](typed_method.md),
[`types()`](types.md), [`validate_call()`](validate_call.md),
[`with_signature()`](with_signature.md)

## Examples

``` r
add <- typed_function(
  function(x, y) x + y,
  arg_specs = c(x = "numeric", y = "numeric"),
  return_spec = "numeric"
)
add(2, 3)
#> [1] 5
add(x = 2, y = 3)
#> [1] 5
add(y = 3, x = 2)
#> [1] 5

# Argument violation
err <- tryCatch(add("a", "b"), error = function(e) conditionMessage(e))
err
#> [1] "Type error: 'x' must be numeric, got character"

# ... passthrough
total <- typed_function(
  function(x, ...) sum(x, ...),
  arg_specs = c(x = "numeric")
)
total(c(1, NA, 3), na.rm = TRUE)
#> [1] 4

# Coercion
add_lenient <- typed_function(
  function(x, y) x + y,
  arg_specs = c(x = "numeric", y = "numeric"),
  coerce = TRUE
)
add_lenient("5", "3")
#> [1] 8
```
