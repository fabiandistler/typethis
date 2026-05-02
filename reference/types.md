# Get or set the type specs of a function

Symmetric replacement-form accessor over [`as_typed()`](as_typed.md).
The setter delegates to [`as_typed()`](as_typed.md); the getter returns
specs in the shape the setter accepts, so `types(f) <- types(g)`
round-trips.

- `types(f)` returns a list whose named entries are argument specs and
  whose `.return` entry (if present) is the return spec. Returns
  [`list()`](https://rdrr.io/r/base/list.html) for an untyped function,
  so it is cheap to use in `if (length(types(f))) ...` checks.

- `types(f) <- value` retrofits `f` via [`as_typed()`](as_typed.md).
  `value` must be a list — named arg specs plus any of `.return`,
  `.infer`, `.validate`, `.coerce`.

- `types(f) <- NULL` un-types `f` (returns the original inner function)
  — the natural inverse.

## Usage

``` r
types(f)

types(f) <- value
```

## Arguments

- f:

  A function.

- value:

  A list of specs (or `NULL` to un-type).

## Value

`types(f)` returns a list of specs. `types(f) <- value` returns the
modified function (assigned back to `f` by R).

## See also

[`as_typed()`](as_typed.md) for the underlying retrofit;
[`as_typed_env()`](as_typed_env.md) for bulk retrofits.

Other typed functions: [`as_typed()`](as_typed.md),
[`as_typed_env()`](as_typed_env.md),
[`as_typed_from_roxygen()`](as_typed_from_roxygen.md),
[`default_type_vocabulary()`](default_type_vocabulary.md),
[`disable_typed_namespace()`](disable_typed_namespace.md),
[`enable_for_package()`](enable_for_package.md),
[`enable_typed_namespace()`](enable_typed_namespace.md),
[`get_signature()`](get_signature.md),
[`infer_specs()`](infer_specs.md), [`is_typed()`](is_typed.md),
[`parse_param_type()`](parse_param_type.md),
[`signature()`](signature.md), [`typed_function()`](typed_function.md),
[`typed_method()`](typed_method.md),
[`validate_call()`](validate_call.md),
[`with_signature()`](with_signature.md)

## Examples

``` r
add <- function(x = 0L, y = 0L) x + y
types(add) <- list(x = "integer", y = "integer", .return = "integer")
is_typed(add)
#> [1] TRUE
types(add)
#> $x
#> [1] "integer"
#> 
#> $y
#> [1] "integer"
#> 
#> $.return
#> [1] "integer"
#> 

# NULL un-types
types(add) <- NULL
is_typed(add)
#> [1] FALSE
```
