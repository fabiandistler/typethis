# Enable type checking for an entire package

Convenience wrapper for switching on typethis across every function in a
package namespace, with a single call from the package's `.onLoad()`
hook. Inside `.onLoad()` the namespace bindings are not yet locked, so
each function can be replaced in place with its typed wrapper.

Add `R/zzz.R` to your package containing:

    .onLoad <- function(libname, pkgname) {
      typethis::enable_for_package(pkgname)
    }

That single line walks the namespace, infers type specs from each
function's literal atomic defaults (see
[`infer_specs()`](infer_specs.md)), and replaces every binding with a
typed wrapper. Functions whose defaults cannot be inferred are left
untyped unless you add an explicit override via `.specs`.

Standard package hook functions (`.onLoad`, `.onAttach`, `.onUnload`,
`.onDetach`, `.Last.lib`, `.First.lib`) and primitives are skipped
automatically. A user-supplied `.filter` runs *after* the default skip
list — it can narrow the set of retrofitted functions, not widen it.

Calling `enable_for_package()` from outside `.onLoad()` is safe but
usually redundant: the namespace is locked by then and most bindings
will be skipped with a single warning reporting the count.

## Usage

``` r
enable_for_package(
  pkgname,
  .specs = list(),
  .infer = TRUE,
  .validate = TRUE,
  .coerce = FALSE,
  .filter = NULL,
  .unlock = FALSE
)
```

## Arguments

- pkgname:

  The package name (string), or directly an environment to retrofit.
  Inside `.onLoad()` use the `pkgname` argument R passes to your hook.
  Passing an environment is mainly useful for tests.

- .specs, .infer, .validate, .coerce:

  Forwarded to [`as_typed_env()`](as_typed_env.md). Per-function entries
  in `.specs` win over inference.

- .filter:

  Optional `function(name, fn)` returning a single logical. Applied
  *after* the built-in skip list, so this can only reduce what is
  retrofitted.

- .unlock:

  If `TRUE`, locked bindings are temporarily unlocked and re-locked
  instead of skipped. Used by
  [`enable_typed_namespace()`](enable_typed_namespace.md) when
  retrofitting after the namespace has been locked by R.

## Value

Invisibly, the character vector of names that were retrofitted.

## See also

[`as_typed_env()`](as_typed_env.md) for the underlying engine;
[`as_typed()`](as_typed.md) for per-function retrofits;
[`infer_specs()`](infer_specs.md) for inference rules;
[`enable_typed_namespace()`](enable_typed_namespace.md) for the
`setHook`-driven variant that does not require editing the target
package.

Other typed functions: [`as_typed()`](as_typed.md),
[`as_typed_env()`](as_typed_env.md),
[`as_typed_from_roxygen()`](as_typed_from_roxygen.md),
[`default_type_vocabulary()`](default_type_vocabulary.md),
[`disable_typed_namespace()`](disable_typed_namespace.md),
[`enable_typed_namespace()`](enable_typed_namespace.md),
[`get_signature()`](get_signature.md),
[`infer_specs()`](infer_specs.md), [`is_typed()`](is_typed.md),
[`parse_param_type()`](parse_param_type.md),
[`signature()`](signature.md), [`typed_function()`](typed_function.md),
[`typed_method()`](typed_method.md), [`types()`](types.md),
[`validate_call()`](validate_call.md),
[`with_signature()`](with_signature.md)

## Examples

``` r
# Inside R/zzz.R of your own package:
# .onLoad <- function(libname, pkgname) {
#   typethis::enable_for_package(pkgname)
# }

# Demonstration on an ordinary environment shaped like a namespace:
ns <- new.env()
ns$add <- function(x = 0L, y = 0L) x + y
ns$.onLoad <- function(libname, pkgname) NULL
enable_for_package(ns)
is_typed(ns$add) # TRUE  -- inferred from defaults
#> [1] TRUE
is_typed(ns$.onLoad) # FALSE -- hook skipped
#> [1] FALSE

# Override one function while the rest are inferred
ns2 <- new.env()
ns2$add <- function(x = 0L, y = 0L) x + y
ns2$greet <- function(name = "world") paste0("hi ", name)
enable_for_package(ns2, .specs = list(
  add = list(.return = "integer")
))
```
