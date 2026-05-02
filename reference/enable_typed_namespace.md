# Enable type checking for an installed package, without editing it

Registers a `setHook(packageEvent(pkgname, "onLoad"), ...)` handler that
runs [`enable_for_package()`](enable_for_package.md) over `pkgname`'s
namespace each time it loads, and applies the retrofit immediately if
the package is already loaded. Use this when you cannot — or do not want
to — add a `R/zzz.R` to the target package.

Because the hook fires *after* R locks the namespace bindings,
`enable_typed_namespace()` retrofits each binding via the
unlock-modify-relock dance (see `as_typed_env(.unlock = TRUE)`).
Re-locking is guaranteed by `on.exit` even if a wrap step errors.

Typical use is from `.Rprofile` or an interactive session:

    typethis::enable_typed_namespace("dplyr")
    library(dplyr) # functions are now wrapped on load

Standard package hook functions (`.onLoad`, `.onAttach`, ...) and
primitives are skipped automatically by
[`enable_for_package()`](enable_for_package.md).

This pattern is **not for CRAN-bound code**: modifying another package's
namespace from outside is a developer convenience, not a shipping
feature. Use [`enable_for_package()`](enable_for_package.md) from your
own package's `.onLoad` for production code.

## Usage

``` r
enable_typed_namespace(
  pkgname,
  .specs = list(),
  .infer = TRUE,
  .validate = TRUE,
  .coerce = FALSE,
  .filter = NULL
)
```

## Arguments

- pkgname:

  Single string. Name of an installed package.

- .specs, .infer, .validate, .coerce, .filter:

  Forwarded to [`enable_for_package()`](enable_for_package.md) every
  time the hook fires.

## Value

Invisibly, `pkgname`.

## See also

[`disable_typed_namespace()`](disable_typed_namespace.md) to remove the
hook and revert the retrofit;
[`enable_for_package()`](enable_for_package.md) for the
inside-the-package variant that is suitable for CRAN.

Other typed functions: [`as_typed()`](as_typed.md),
[`as_typed_env()`](as_typed_env.md),
[`as_typed_from_roxygen()`](as_typed_from_roxygen.md),
[`default_type_vocabulary()`](default_type_vocabulary.md),
[`disable_typed_namespace()`](disable_typed_namespace.md),
[`enable_for_package()`](enable_for_package.md),
[`get_signature()`](get_signature.md),
[`infer_specs()`](infer_specs.md), [`is_typed()`](is_typed.md),
[`parse_param_type()`](parse_param_type.md),
[`signature()`](signature.md), [`typed_function()`](typed_function.md),
[`typed_method()`](typed_method.md), [`types()`](types.md),
[`validate_call()`](validate_call.md),
[`with_signature()`](with_signature.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# In .Rprofile or an interactive session:
typethis::enable_typed_namespace("dplyr")
library(dplyr)

# Later, undo:
typethis::disable_typed_namespace("dplyr")
} # }
```
