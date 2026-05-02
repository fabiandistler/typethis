# Map a single prose description to a type spec

The per-string extractor used by
[`as_typed_from_roxygen()`](as_typed_from_roxygen.md). Tries an explicit
`[type]` prefix first, then falls back to the supplied vocabulary.
Returns `NULL` when nothing matches.

## Usage

``` r
parse_param_type(desc, vocabulary = default_type_vocabulary())
```

## Arguments

- desc:

  A character string — typically the prose body of a `@param` tag (or
  the contents of a `\\value{}` block).

- vocabulary:

  A named character vector as returned by
  [`default_type_vocabulary()`](default_type_vocabulary.md).

## Value

A spec string, or `NULL` if no rule matched.

## See also

[`default_type_vocabulary()`](default_type_vocabulary.md) for the
default rules.

Other typed functions: [`as_typed()`](as_typed.md),
[`as_typed_env()`](as_typed_env.md),
[`as_typed_from_roxygen()`](as_typed_from_roxygen.md),
[`default_type_vocabulary()`](default_type_vocabulary.md),
[`disable_typed_namespace()`](disable_typed_namespace.md),
[`enable_for_package()`](enable_for_package.md),
[`enable_typed_namespace()`](enable_typed_namespace.md),
[`get_signature()`](get_signature.md),
[`infer_specs()`](infer_specs.md), [`is_typed()`](is_typed.md),
[`signature()`](signature.md), [`typed_function()`](typed_function.md),
[`typed_method()`](typed_method.md), [`types()`](types.md),
[`validate_call()`](validate_call.md),
[`with_signature()`](with_signature.md)

## Examples

``` r
parse_param_type("[integer] number of iterations")
#> [1] "integer"
parse_param_type("A numeric vector of values")
#> [1] "numeric"
parse_param_type("If TRUE, return early")
#> [1] "logical"
parse_param_type("Some unrelated description")
#> NULL
```
