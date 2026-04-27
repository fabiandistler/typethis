# Composable type specifications

Structured, composable type specifications. They work everywhere a type
name does —
[`is_type()`](https://fabiandistler.github.io/typethis/reference/is_type.md),
[`assert_type()`](https://fabiandistler.github.io/typethis/reference/assert_type.md),
[`validate_type()`](https://fabiandistler.github.io/typethis/reference/validate_type.md),
[`field()`](https://fabiandistler.github.io/typethis/reference/field.md),
[`typed_function()`](https://fabiandistler.github.io/typethis/reference/typed_function.md),
[`to_json_schema()`](https://fabiandistler.github.io/typethis/reference/to_json_schema.md)
— and they compose: `t_list_of(t_union("integer", "character"))` is
valid.

## Details

All constructors return objects of class `type_spec`. Plain character
strings (e.g. `"numeric"`) and predicate functions continue to work as
type arguments without change; internally they are normalized to
`type_spec` objects.

Available constructors:

- [`t_union()`](https://fabiandistler.github.io/typethis/reference/t_union.md)
  — match any of several alternatives.

- [`t_nullable()`](https://fabiandistler.github.io/typethis/reference/t_nullable.md)
  — also accept `NULL`.

- [`t_list_of()`](https://fabiandistler.github.io/typethis/reference/t_list_of.md)
  — list of elements of a given type, with optional length.

- [`t_vector_of()`](https://fabiandistler.github.io/typethis/reference/t_vector_of.md)
  — atomic vector of a given builtin type, with length.

- [`t_enum()`](https://fabiandistler.github.io/typethis/reference/t_enum.md)
  — value in a fixed set.

- [`t_model()`](https://fabiandistler.github.io/typethis/reference/t_model.md)
  — instance of a registered typed model.

- [`t_predicate()`](https://fabiandistler.github.io/typethis/reference/t_predicate.md)
  — wrap a predicate function with a description.

Use
[`is_type_spec()`](https://fabiandistler.github.io/typethis/reference/is_type_spec.md)
to detect a composite spec at runtime.

## See also

Other type specifications:
[`is_type_spec()`](https://fabiandistler.github.io/typethis/reference/is_type_spec.md),
[`t_enum()`](https://fabiandistler.github.io/typethis/reference/t_enum.md),
[`t_list_of()`](https://fabiandistler.github.io/typethis/reference/t_list_of.md),
[`t_model()`](https://fabiandistler.github.io/typethis/reference/t_model.md),
[`t_nullable()`](https://fabiandistler.github.io/typethis/reference/t_nullable.md),
[`t_predicate()`](https://fabiandistler.github.io/typethis/reference/t_predicate.md),
[`t_union()`](https://fabiandistler.github.io/typethis/reference/t_union.md),
[`t_vector_of()`](https://fabiandistler.github.io/typethis/reference/t_vector_of.md)
