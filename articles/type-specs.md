# Composable type specifications

``` r
library(typethis)
#> 
#> Attaching package: 'typethis'
#> The following object is masked from 'package:methods':
#> 
#>     signature
```

A *type spec* is a structured, composable type description. The `t_*()`
constructors build them; they work everywhere a plain type name does —
[`is_type()`](../reference/is_type.md),
[`assert_type()`](../reference/assert_type.md),
[`validate_type()`](../reference/validate_type.md),
[`field()`](../reference/field.md),
[`typed_function()`](../reference/typed_function.md), and
[`to_json_schema()`](../reference/to_json_schema.md).

Plain character builtins (`"numeric"`) and predicate functions still
work as type arguments without change. Type specs are an additive layer
for when those aren’t expressive enough.

## The constructors

| Constructor                    | Matches                                   |
|--------------------------------|-------------------------------------------|
| `t_union(...)`                 | any of the alternatives                   |
| `t_nullable(type)`             | `type` or `NULL`                          |
| `t_list_of(type, …)`           | a list whose every element matches `type` |
| `t_vector_of(type, …)`         | an atomic vector of a builtin type        |
| `t_enum(values)`               | values in a fixed allowed set             |
| `t_model(class)`               | an instance of a registered typed model   |
| `t_predicate(fn, description)` | predicate with a documented description   |

Use [`is_type_spec()`](../reference/is_type_spec.md) to detect a
composite spec at runtime.

## Examples

### Union

``` r
id <- t_union("integer", "character")
is_type(1L,    id)
#> [1] TRUE
is_type("u-1", id)
#> [1] TRUE
is_type(1.5,   id)
#> [1] FALSE
```

### Nullable

``` r
maybe_int <- t_nullable("integer")
is_type(NULL, maybe_int)
#> [1] TRUE
is_type(1L,   maybe_int)
#> [1] TRUE
is_type("hi", maybe_int)
#> [1] FALSE
```

### Lists and vectors

``` r
tags <- t_list_of("character", min_length = 1L)
is_type(list("alpha", "beta"), tags)
#> [1] TRUE
is_type(list(),                tags)
#> [1] FALSE

triple <- t_vector_of("integer", exact_length = 3L)
is_type(1:3, triple)
#> [1] TRUE
is_type(1:5, triple)
#> [1] FALSE
```

[`t_list_of()`](../reference/t_list_of.md) accepts any element type
spec, including other composites:

``` r
mixed <- t_list_of(t_union("integer", "character"))
is_type(list(1L, "two", 3L), mixed)
#> [1] TRUE
```

### Enum

``` r
role <- t_enum(c("admin", "user", "guest"))
is_type("admin", role)
#> [1] TRUE
is_type("root",  role)
#> [1] FALSE
```

[`t_enum()`](../reference/t_enum.md) is the type-spec sibling of
[`enum_validator()`](../reference/enum_validator.md). Use the type-spec
form when you want the enum to appear as a true type in
[`field()`](../reference/field.md) and
[`typed_function()`](../reference/typed_function.md) and to surface in
JSON Schema as a typed `enum` keyword.

### Model references

References resolve at validation time, which makes forward references
(and cycles) possible:

``` r
define_model("Address", fields = list(zip = field("character")))
addr <- t_model("Address")
is_type(new_Address(zip = "10115"), addr)
#> [1] TRUE
```

### Predicates with a description

[`t_predicate()`](../reference/t_predicate.md) is a thin wrapper around
a custom predicate that carries a description. The description surfaces
in error messages and in JSON Schema output.

``` r
positive <- t_predicate(
  function(x) is.numeric(x) && all(x > 0),
  description = "positive number"
)
is_type(5,  positive)
#> [1] TRUE
is_type(-1, positive)
#> [1] FALSE
```

## Using specs in models and functions

Anywhere `type =` or `arg_specs =` accepts a builtin name, it also
accepts a spec.

``` r
define_model("Order", fields = list(
  id     = field(t_union("integer", "character")),
  status = field(t_enum(c("new", "paid", "shipped")), default = "new"),
  tags   = field(t_list_of("character"), default = list())
))

ord <- new_Order(id = "ord-1", tags = list("priority", "rush"))
ord$status
#> [1] "new"
ord$tags
#> [[1]]
#> [1] "priority"
#> 
#> [[2]]
#> [1] "rush"
```

``` r
greet <- typed_function(
  function(name, n = 1L) paste(rep(name, n), collapse = " "),
  arg_specs = list(
    name = "character",
    n    = t_union("integer", "numeric")
  ),
  return_spec = "character"
)
greet("hi", n = 3)
#> [1] "hi hi hi"
```

## Coercion

[`coerce_type()`](../reference/coerce_type.md) understands a subset of
specs where coercion has a clear meaning:

- `t_nullable(...)` — `NULL` passes through; otherwise the inner spec
  drives coercion;
- `t_union(...)` — each alternative is tried in order; the first that
  coerces and validates wins;
- `t_enum(...)` — values already in the allowed set pass through;
  otherwise the value is coerced to the enum’s value type and
  re-checked.

Other kinds ([`t_list_of()`](../reference/t_list_of.md),
[`t_vector_of()`](../reference/t_vector_of.md),
[`t_model()`](../reference/t_model.md),
[`t_predicate()`](../reference/t_predicate.md)) raise an explicit error.

``` r
coerce_type("paid", t_enum(c("new", "paid", "shipped")))
#> [1] "paid"
coerce_type(NULL,   t_nullable("integer"))
#> NULL
coerce_type("123",  t_union("integer", "character"))
#> [1] 123
```
