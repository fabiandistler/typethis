# Read the constraint descriptor attached to a validator

Builtin validator factories ([`numeric_range()`](numeric_range.md),
[`string_length()`](string_length.md), ...) attach a structured
`constraint` list to the closure they return so that tooling can
introspect them — most notably [`to_json_schema()`](to_json_schema.md),
which uses it to emit native `minimum` / `maxLength` / `pattern` keys
instead of opaque predicate stubs.

## Usage

``` r
validator_constraint(fn)
```

## Arguments

- fn:

  A validator closure.

## Value

A named list describing the constraint, or `NULL`.

## Details

Plain user-defined validator functions return `NULL`.

## See also

Other validators: [`combine_validators()`](combine_validators.md),
[`dataframe_spec()`](dataframe_spec.md),
[`enum_validator()`](enum_validator.md), [`list_of()`](list_of.md),
[`nullable()`](nullable.md), [`numeric_range()`](numeric_range.md),
[`string_length()`](string_length.md),
[`string_pattern()`](string_pattern.md),
[`vector_length()`](vector_length.md)

## Examples

``` r
validator_constraint(numeric_range(0, 10))
#> $kind
#> [1] "numeric_range"
#> 
#> $min
#> [1] 0
#> 
#> $max
#> [1] 10
#> 
#> $exclusive_min
#> [1] FALSE
#> 
#> $exclusive_max
#> [1] FALSE
#> 
validator_constraint(string_length(max_length = 50))
#> $kind
#> [1] "string_length"
#> 
#> $min_length
#> [1] 0
#> 
#> $max_length
#> [1] 50
#> 
validator_constraint(function(x) x > 0)
#> NULL
```
