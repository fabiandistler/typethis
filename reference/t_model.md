# Reference to a registered model class

Matches a typed model instance whose S3 class is `class_name`. The class
need not exist when the spec is constructed — the registry is consulted
at validation time, which makes forward references possible.

## Usage

``` r
t_model(class_name)
```

## Arguments

- class_name:

  Character scalar — the registered model class name.

## Value

A `type_spec` of kind `"model_ref"`.

## See also

Other type specifications: [`is_type_spec()`](is_type_spec.md),
[`t_enum()`](t_enum.md), [`t_list_of()`](t_list_of.md),
[`t_nullable()`](t_nullable.md), [`t_predicate()`](t_predicate.md),
[`t_union()`](t_union.md), [`t_vector_of()`](t_vector_of.md),
[`type_spec`](type_spec.md)

## Examples

``` r
define_model("Address", fields = list(zip = field("character")))
addr_spec <- t_model("Address")
is_type(new_Address(zip = "10115"), addr_spec)
#> [1] TRUE
```
