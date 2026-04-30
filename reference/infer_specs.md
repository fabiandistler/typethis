# Infer argument specs from a function's default values

Walks the formals of `fn` and returns a named list of inferred type
specs, one entry per formal whose default value is a length-1 literal of
a recognised atomic type.

## Usage

``` r
infer_specs(fn)
```

## Arguments

- fn:

  A function.

## Value

A named list of type specs. Empty list if nothing could be inferred.

## Details

Recognised defaults:

- Integer literal (`1L`) -\> `"integer"`

- Double literal (`1.0`, `0.5`) -\> `"double"`

- Character literal (`"a"`) -\> `"character"`

- Logical literal (`TRUE`, `FALSE`) -\> `"logical"`

Defaults that are skipped:

- `NULL`

- Calls ([`list()`](https://rdrr.io/r/base/list.html), `c(1, 2)`, ...) —
  would require evaluation

- Missing defaults

- `...`

Default expressions are inspected without being evaluated, so this is
safe to call on arbitrary functions.

## See also

Other typed functions: [`as_typed()`](as_typed.md),
[`as_typed_env()`](as_typed_env.md),
[`as_typed_from_roxygen()`](as_typed_from_roxygen.md),
[`default_type_vocabulary()`](default_type_vocabulary.md),
[`disable_typed_namespace()`](disable_typed_namespace.md),
[`enable_for_package()`](enable_for_package.md),
[`enable_typed_namespace()`](enable_typed_namespace.md),
[`get_signature()`](get_signature.md), [`is_typed()`](is_typed.md),
[`parse_param_type()`](parse_param_type.md),
[`signature`](signature.md), [`typed_function()`](typed_function.md),
[`typed_method()`](typed_method.md), [`types()`](types.md),
[`validate_call()`](validate_call.md),
[`with_signature()`](with_signature.md)

## Examples

``` r
infer_specs(function(x = 1L, y = 1.0, name = "a", flag = TRUE) NULL)
#> $x
#> [1] "integer"
#> 
#> $y
#> [1] "double"
#> 
#> $name
#> [1] "character"
#> 
#> $flag
#> [1] "logical"
#> 

# Skipped: NULL default, call default, missing default
infer_specs(function(x, y = NULL, z = list()) NULL)
#> list()
```
