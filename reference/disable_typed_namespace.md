# Remove a typethis hook and revert the typed wrappers

The inverse of [`enable_typed_namespace()`](enable_typed_namespace.md).
Removes any typethis hook previously registered for `pkgname` so future
loads of the package are not wrapped, and (by default) walks the
currently loaded namespace to replace each typed wrapper with the
original inner function.

Hooks added by other code (anything *not* tagged by typethis) are left
intact, so this is safe to call when third-party hooks coexist on the
same package event.

## Usage

``` r
disable_typed_namespace(pkgname, .revert = TRUE)
```

## Arguments

- pkgname:

  Single string. Name of an installed package.

- .revert:

  If `TRUE` (default), each currently typed binding in `pkgname`'s
  namespace is reverted to its inner function via the same
  unlock-modify-relock dance. Pass `FALSE` to leave the loaded namespace
  as-is and only stop the retrofit on future loads.

## Value

Invisibly, the character vector of names that were reverted (empty when
`.revert` is `FALSE` or the package is not loaded).

## See also

[`enable_typed_namespace()`](enable_typed_namespace.md) for the
registration side.

Other typed functions: [`as_typed()`](as_typed.md),
[`as_typed_env()`](as_typed_env.md),
[`as_typed_from_roxygen()`](as_typed_from_roxygen.md),
[`default_type_vocabulary()`](default_type_vocabulary.md),
[`enable_for_package()`](enable_for_package.md),
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
if (FALSE) { # \dontrun{
typethis::enable_typed_namespace("dplyr")
library(dplyr)
typethis::disable_typed_namespace("dplyr")
} # }
```
