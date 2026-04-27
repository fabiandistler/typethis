# Validate a single field value against its definition

Internal helper used by [`define_model()`](define_model.md) and the
generated `update_*()` functions. Exported for advanced use cases
(custom model machinery).

## Usage

``` r
validate_field_value(fname, value, field_def, class_name = "model")
```

## Arguments

- fname:

  Field name (used only for error messages).

- value:

  Value to validate.

- field_def:

  Field definition list, as produced by [`field()`](field.md).

- class_name:

  Owning model class name (used only for error messages).

## Value

`invisible(TRUE)` on success; an error otherwise.
