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
[`get_signature()`](get_signature.md), [`is_typed()`](is_typed.md),
[`signature`](signature.md), [`typed_function()`](typed_function.md),
[`typed_method()`](typed_method.md),
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
