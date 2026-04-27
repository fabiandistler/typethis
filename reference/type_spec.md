# Composable type specifications

Structured, composable type specifications. They work everywhere a type
name does — [`is_type()`](is_type.md),
[`assert_type()`](assert_type.md),
[`validate_type()`](validate_type.md), [`field()`](field.md),
[`typed_function()`](typed_function.md),
[`to_json_schema()`](to_json_schema.md) — and they compose:
`t_list_of(t_union("integer", "character"))` is valid.

## Details

All constructors return objects of class `type_spec`. Plain character
strings (e.g. `"numeric"`) and predicate functions continue to work as
type arguments without change; internally they are normalized to
`type_spec` objects.

Available constructors:

- [`t_union()`](t_union.md) — match any of several alternatives.

- [`t_nullable()`](t_nullable.md) — also accept `NULL`.

- [`t_list_of()`](t_list_of.md) — list of elements of a given type, with
  optional length.

- [`t_vector_of()`](t_vector_of.md) — atomic vector of a given builtin
  type, with length.

- [`t_enum()`](t_enum.md) — value in a fixed set.

- [`t_model()`](t_model.md) — instance of a registered typed model.

- [`t_predicate()`](t_predicate.md) — wrap a predicate function with a
  description.

Use [`is_type_spec()`](is_type_spec.md) to detect a composite spec at
runtime.

## See also

Other type specifications: [`is_type_spec()`](is_type_spec.md),
[`t_enum()`](t_enum.md), [`t_list_of()`](t_list_of.md),
[`t_model()`](t_model.md), [`t_nullable()`](t_nullable.md),
[`t_predicate()`](t_predicate.md), [`t_union()`](t_union.md),
[`t_vector_of()`](t_vector_of.md)
