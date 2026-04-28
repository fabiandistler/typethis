# Getting started with typethis

`typethis` adds runtime type safety to R. This vignette is a 10-minute
tour of the four things you’ll reach for most: type checks, typed
functions, typed models, and composable type specs.

``` r
library(typethis)
#> 
#> Attaching package: 'typethis'
#> The following object is masked from 'package:methods':
#> 
#>     signature
```

## 1. Type checks

The lowest-level entry points test, assert, and validate types. Use them
at function boundaries, when parsing inputs, or anywhere a quick sanity
check is enough.

``` r
is_type(5, "numeric")
#> [1] TRUE
is_type("hello", "numeric")
#> [1] FALSE

# assert_type() throws on mismatch
assert_type(5, "numeric", "x")

# validate_type() returns a list instead of throwing
validate_type("hello", "numeric", "x")
#> $valid
#> [1] FALSE
#> 
#> $error
#> [1] "Type error: 'x' must be numeric, got character"
```

[`is_type()`](../reference/is_type.md) accepts any of:

- a builtin name — `"numeric"`, `"integer"`, `"character"`, `"logical"`,
  `"list"`, `"data.frame"`, `"matrix"`, `"factor"`, `"date"`,
  `"posixct"`, `"function"`, `"environment"`;
- a predicate function `function(value) -> logical`;
- a [type spec](type-specs.md) such as
  `t_union("integer", "character")`.

For safe coercion, use [`coerce_type()`](../reference/coerce_type.md):

``` r
coerce_type("123", "numeric")
#> [1] 123
coerce_type(c(1, 0, 1), "logical")
#> [1]  TRUE FALSE  TRUE
```

## 2. Typed functions

[`typed_function()`](../reference/typed_function.md) wraps a function so
each call is validated.

``` r
greet <- typed_function(
  function(name, times = 1L) paste(rep(name, times), collapse = " "),
  arg_specs = list(name = "character", times = "integer"),
  return_spec = "character"
)

greet("hi", times = 3L)
#> [1] "hi hi hi"
```

A bad call fails before the body runs:

``` r
greet("hi", times = "three")
#> Error:
#> ! Type error: 'times' must be integer, got character
```

[`typed_function()`](../reference/typed_function.md) supports every R
calling convention — positional, named, mixed, reordered, and `...`
passthrough — and respects argument defaults. Set `coerce = TRUE` to
convert mismatches before checking, or `validate = FALSE` for hot paths
where you’ve already validated upstream.

For the full feature set see
[`?typed_function`](../reference/typed_function.md) and the
[validators-and-models](validators-and-models.md) vignette.

### Retrofitting existing functions

When you want to add type checks to a function you already have,
[`as_typed()`](../reference/as_typed.md) removes the boilerplate of
restating every argument. Specs for arguments with literal atomic
defaults are inferred automatically; only arguments you want to override
appear in the call.

``` r
add <- as_typed(function(x = 0L, y = 0L) x + y, .return = "integer")
add(2L, 3L)
#> [1] 5
```

``` r
add("two", 3L)
#> Error:
#> ! Type error: 'x' must be integer, got character
```

Pass overrides by name. Inference fills in the rest:

``` r
greet <- as_typed(
  function(name = "world", times = 1L) {
    paste(rep(name, times), collapse = " ")
  },
  name = t_vector_of("character", exact_length = 1L)
)
greet("hi", times = 3L)
#> [1] "hi hi hi"
```

Pass `name = NULL` to opt one argument out of validation, or
`.infer = FALSE` to disable inference entirely. See
[`?as_typed`](../reference/as_typed.md) and
[`?infer_specs`](../reference/infer_specs.md) for the full inference
rules.

For an existing typed function, [`types()`](../reference/types.md) is a
symmetric replacement-form accessor over
[`as_typed()`](../reference/as_typed.md):

``` r
greet_clone <- function(name = "world", times = 1L) {
  paste(rep(name, times), collapse = " ")
}
types(greet_clone) <- types(greet)
is_typed(greet_clone)
#> [1] TRUE

# NULL un-types
types(greet_clone) <- NULL
is_typed(greet_clone)
#> [1] FALSE
```

To retrofit a whole environment in one call,
[`as_typed_env()`](../reference/as_typed_env.md) walks the environment,
applies [`as_typed()`](../reference/as_typed.md) to every function it
finds, and writes the typed versions back. Per-function overrides flow
through `.specs`:

``` r
e <- new.env()
e$add <- function(x = 0L, y = 0L) x + y
e$greet <- function(name = "world") paste0("hi ", name)

as_typed_env(e, .specs = list(
  add = list(.return = "integer")
))
is_typed(e$add)
#> [1] TRUE
attr(e$add, "return_spec")
#> [1] "integer"
```

## 3. Typed models

Use [`define_model()`](../reference/define_model.md) to describe a
record type — a configuration object, an API request body, a domain
entity. It generates a `new_<Class>()` constructor and an
`update_<Class>()` updater in the calling environment.

``` r
define_model("User", fields = list(
  name = field("character"),
  age = field("integer",
    validator = numeric_range(0, 120),
    default = 0L
  ),
  email = field("character",
    validator = string_pattern("^[^@]+@[^@]+\\.[^@]+$")
  )
))

ada <- new_User(name = "Ada Lovelace", email = "ada@example.com")
ada
#> <Typed Model: User>
#> Fields:
#>   name: character = Ada Lovelace
#>   email: character = ada@example.com
#>   age: integer = 0
```

Validation runs at construction time:

``` r
new_User(name = "Ada", age = 200L, email = "ada@example.com")
#> Error:
#> ! Validation failed for field 'age' in User
```

`update_User()` returns a fresh instance with the named fields replaced
and revalidated:

``` r
ada <- update_User(ada, age = 36L)
ada$age
#> [1] 36
```

Models nest. Reference one model from another by class name:

``` r
define_model("Address", fields = list(
  street = field("character"),
  city   = field("character")
))

define_model("Person", fields = list(
  name    = field("character"),
  address = field("Address")
))

p <- new_Person(
  name    = "Ada",
  address = new_Address(street = "Newstead Abbey", city = "Nottingham")
)
p$address$city
#> [1] "Nottingham"
```

For defaults, nullability, strict mode, and validators, see the
[validators-and-models](validators-and-models.md) vignette.

## 4. Composable type specs

The `t_*()` family builds richer specifications that work everywhere a
plain type name does ([`is_type()`](../reference/is_type.md),
[`assert_type()`](../reference/assert_type.md),
[`field()`](../reference/field.md),
[`typed_function()`](../reference/typed_function.md),
[`to_json_schema()`](../reference/to_json_schema.md)).

``` r
id <- t_union("integer", "character")
is_type(1L, id)
#> [1] TRUE
is_type("u-42", id)
#> [1] TRUE

maybe_int <- t_nullable("integer")
is_type(NULL, maybe_int)
#> [1] TRUE

tags <- t_list_of("character", min_length = 1L)
is_type(list("alpha", "beta"), tags)
#> [1] TRUE

role <- t_enum(c("admin", "user", "guest"))
is_type("admin", role)
#> [1] TRUE
```

Specs compose:

``` r
mixed <- t_list_of(t_union("integer", "character"))
is_type(list(1L, "two", 3L), mixed)
#> [1] TRUE
```

Use any spec inside a [`field()`](../reference/field.md) or as
[`typed_function()`](../reference/typed_function.md)’s `arg_specs`
entry. See the [type-specs](type-specs.md) vignette for the full
reference.

## Where to go next

- [`validators-and-models`](validators-and-models.md) — built-in
  validators, defaults, nullability, strict mode, the
  [`field()`](../reference/field.md) metadata.
- [`type-specs`](type-specs.md) — every `t_*()` constructor and how they
  compose.
- [`interop`](interop.md) — JSON Schema, Open Data Contract Standard,
  and OpenAPI 3.1 export and import.

For function reference, [`?typethis`](../reference/typethis-package.md)
is a topic-grouped index and each function’s help page has a “See also”
section linking to its family.
