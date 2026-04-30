# Bulk-retrofit every function in an environment

Walks `envir`, applies [`as_typed()`](as_typed.md) to every function it
finds, and reassigns the result back into `envir` in place. Useful for
adding type checks across a script, a chunk of analysis code in
[`globalenv()`](https://rdrr.io/r/base/environment.html), or a private
environment held by a package.

Per-function overrides flow through `.specs`, a named list of lists
whose entries match the [`as_typed()`](as_typed.md) argument shape
(named arg specs plus optional
`.return`/`.infer`/`.validate`/`.coerce`). Functions without a `.specs`
entry are still retrofitted via inference (when `.infer = TRUE`) and the
function-level defaults.

Already-typed functions are re-wrapped through
[`as_typed()`](as_typed.md)'s idempotent merge path — no
double-wrapping. Locked bindings (common for namespaces) are skipped by
default; a single warning reports the count. Pass `.unlock = TRUE` to
unlock-modify-relock each binding in place — this is what
[`enable_typed_namespace()`](enable_typed_namespace.md) uses to retrofit
bindings *after* a namespace has been locked.

## Usage

``` r
as_typed_env(
  envir,
  .specs = list(),
  .infer = TRUE,
  .validate = TRUE,
  .coerce = FALSE,
  .filter = NULL,
  .unlock = FALSE
)
```

## Arguments

- envir:

  An environment. Use
  [`new.env()`](https://rdrr.io/r/base/environment.html) or
  [`globalenv()`](https://rdrr.io/r/base/environment.html) for ordinary
  cases; passing a namespace is supported but most bindings will be
  locked.

- .specs:

  Named list of per-function override lists. Each entry has the same
  shape as [`as_typed()`](as_typed.md)'s `...` plus the dotted options.
  Names must correspond to functions in `envir`; unknown names are an
  error.

- .infer, .validate, .coerce:

  Function-level defaults forwarded to [`as_typed()`](as_typed.md).
  Per-function entries in `.specs` win.

- .filter:

  Optional `function(name, fn)` returning a single logical; functions
  for which this returns `FALSE` are skipped.

- .unlock:

  If `TRUE`, locked bindings are temporarily unlocked, reassigned to
  their typed wrapper, and re-locked. Defaults to `FALSE`, in which case
  locked bindings are skipped with a warning. Re-locking is guaranteed
  by `on.exit` even if a wrap step errors.

## Value

Invisibly, the character vector of names that were retrofitted.

## See also

[`as_typed()`](as_typed.md) for the per-function form;
[`types()`](types.md) for the replacement-form accessor;
[`enable_typed_namespace()`](enable_typed_namespace.md) for the
`setHook`-based whole-package wrapper.

Other typed functions: [`as_typed()`](as_typed.md),
[`as_typed_from_roxygen()`](as_typed_from_roxygen.md),
[`default_type_vocabulary()`](default_type_vocabulary.md),
[`disable_typed_namespace()`](disable_typed_namespace.md),
[`enable_for_package()`](enable_for_package.md),
[`enable_typed_namespace()`](enable_typed_namespace.md),
[`get_signature()`](get_signature.md),
[`infer_specs()`](infer_specs.md), [`is_typed()`](is_typed.md),
[`parse_param_type()`](parse_param_type.md),
[`signature`](signature.md), [`typed_function()`](typed_function.md),
[`typed_method()`](typed_method.md), [`types()`](types.md),
[`validate_call()`](validate_call.md),
[`with_signature()`](with_signature.md)

## Examples

``` r
e <- new.env()
e$add <- function(x = 0L, y = 0L) x + y
e$greet <- function(name = "world") paste0("hi ", name)
as_typed_env(e)
is_typed(e$add)
#> [1] TRUE
is_typed(e$greet)
#> [1] TRUE

# Per-function overrides
e2 <- new.env()
e2$add <- function(x = 0L, y = 0L) x + y
as_typed_env(e2, .specs = list(
  add = list(x = "integer", y = "integer", .return = "integer")
))

# Filter to a subset
e3 <- new.env()
e3$keep <- function(x = 1L) x
e3$skip <- function(x = 1L) x
as_typed_env(e3, .filter = function(name, fn) name == "keep")

# Unlock-and-modify locked bindings (e.g. after a namespace lock)
e4 <- new.env()
e4$add <- function(x = 0L) x
lockBinding("add", e4)
as_typed_env(e4, .unlock = TRUE)
is_typed(e4$add)
#> [1] TRUE
```
