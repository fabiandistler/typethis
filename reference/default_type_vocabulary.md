# Default prose-to-spec vocabulary for [`as_typed_from_roxygen()`](as_typed_from_roxygen.md)

A named character vector. Names are perl-flavoured regex patterns;
values are spec strings forwarded to [`as_typed()`](as_typed.md).
Patterns are anchored to the start of an argument's prose description,
with optional leading articles (`a`, `an`, `the`, `single`, `optional`,
...). The first match wins.

Extend by combining with your own entries:

    my_vocab <- c(
      "^\\s*(?:a|an)?\\s*tbl[._]df\\b" = "data.frame",
      default_type_vocabulary()
    )
    as_typed_from_roxygen("mypkg", .vocabulary = my_vocab)

## Usage

``` r
default_type_vocabulary()
```

## Value

A named character vector.

## See also

[`as_typed_from_roxygen()`](as_typed_from_roxygen.md) for the consumer;
[`parse_param_type()`](parse_param_type.md) for the per-string
extractor.

Other typed functions: [`as_typed()`](as_typed.md),
[`as_typed_env()`](as_typed_env.md),
[`as_typed_from_roxygen()`](as_typed_from_roxygen.md),
[`disable_typed_namespace()`](disable_typed_namespace.md),
[`enable_for_package()`](enable_for_package.md),
[`enable_typed_namespace()`](enable_typed_namespace.md),
[`get_signature()`](get_signature.md),
[`infer_specs()`](infer_specs.md), [`is_typed()`](is_typed.md),
[`parse_param_type()`](parse_param_type.md),
[`signature()`](signature.md), [`typed_function()`](typed_function.md),
[`typed_method()`](typed_method.md), [`types()`](types.md),
[`validate_call()`](validate_call.md),
[`with_signature()`](with_signature.md)
