# Validators and models

``` r

library(typethis)
#> 
#> Attaching package: 'typethis'
#> The following object is masked from 'package:methods':
#> 
#>     signature
```

This vignette covers the built-in validators and the full
[`define_model()`](../reference/define_model.md) /
[`field()`](../reference/field.md) API. If you haven’t read [Getting
Started](getting-started.md) yet, start there.

## Validators

A validator is just a function `function(value) -> logical`. The package
ships with factories for the most common rules; their results carry a
`constraint` attribute so that bridges (JSON Schema, ODCS, OpenAPI) can
emit native keywords (`minimum`, `maxLength`, `pattern`, …) instead of
opaque predicate stubs.

### Numeric ranges

``` r

age <- numeric_range(0, 120)
age(25)
#> [1] TRUE
age(150)
#> [1] FALSE

# Probability strictly in (0, 1)
prob <- numeric_range(0, 1, exclusive_min = TRUE, exclusive_max = TRUE)
prob(0.5)
#> [1] TRUE
prob(0)
#> [1] FALSE
```

### Strings

``` r

name <- string_length(min_length = 1, max_length = 50)
name("Ada Lovelace")
#> [1] TRUE
name("")
#> [1] FALSE

email <- string_pattern("^[^@]+@[^@]+\\.[^@]+$")
email("user@example.com")
#> [1] TRUE
email("not-an-email")
#> [1] FALSE
```

### Vectors and lists

``` r

pair <- vector_length(exact_len = 2)
pair(c(1, 2))
#> [1] TRUE
pair(c(1, 2, 3))
#> [1] FALSE

nums <- list_of("numeric", min_length = 1)
nums(list(1, 2, 3))
#> [1] TRUE
nums(list("a"))
#> [1] FALSE

# Optional values: wrap any validator with `nullable()`
optional_num <- nullable(function(x) is.numeric(x))
optional_num(NULL)
#> [1] TRUE
optional_num(5)
#> [1] TRUE
```

### Data frames

``` r

is_orders <- dataframe_spec(
  required_cols = c("id", "amount"),
  min_rows = 1
)
is_orders(data.frame(id = 1:3, amount = c(10, 20, 30)))
#> [1] TRUE
is_orders(data.frame(id = integer()))
#> [1] FALSE
is_orders(data.frame(name = "Ada"))
#> [1] FALSE
```

### Enums

``` r

status <- enum_validator(c("active", "inactive", "pending"))
status("active")
#> [1] TRUE
status("deleted")
#> [1] FALSE
```

For the equivalent that doubles as a [type spec](type-specs.md) — usable
inside [`field()`](../reference/field.md) and
[`typed_function()`](../reference/typed_function.md) — see
[`t_enum()`](../reference/t_enum.md).

### Combining validators

``` r

positive_num <- combine_validators(
  function(x) is.numeric(x),
  function(x) all(x > 0)
)
positive_num(5)
#> [1] TRUE
positive_num(-1)
#> [1] FALSE

num_or_str <- combine_validators(
  function(x) is.numeric(x),
  function(x) is.character(x),
  all_of = FALSE
)
num_or_str(5)
#> [1] TRUE
num_or_str("hi")
#> [1] TRUE
num_or_str(TRUE)
#> [1] FALSE
```

### Reading constraint metadata

[`validator_constraint()`](../reference/validator_constraint.md) exposes
the structured constraint attached by the built-in factories — useful
for tooling and for the bridge functions:

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
validator_constraint(function(x) x > 0) # NULL for plain user predicates
#> NULL
```

## Models

Use [`define_model()`](../reference/define_model.md) to describe a
record. It creates a `new_<Class>()` constructor and an
`update_<Class>()` helper in the calling environment.

``` r

define_model("Person", fields = list(
  name = field("character"),
  age = field("integer", validator = numeric_range(0, 120)),
  email = field("character",
    validator = string_pattern("^[^@]+@[^@]+$")
  )
))

p <- new_Person(name = "Ada", age = 36L, email = "ada@example.com")
p
#> <Typed Model: Person>
#> Fields:
#>   name: character = Ada
#>   age: integer = 36
#>   email: character = ada@example.com
```

### Defaults

``` r

define_model("Config", fields = list(
  host  = field("character", default = "localhost"),
  port  = field("integer", default = 8080L),
  debug = field("logical", default = FALSE)
))

new_Config()$host
#> [1] "localhost"
new_Config(host = "api.example.com", port = 443L)$port
#> [1] 443
```

### Nullable fields

A field with `nullable = TRUE` is allowed to be `NULL` (and to be
omitted at construction without a default). Without it, omission is an
error unless a default is set.

``` r

define_model("Profile", fields = list(
  name = field("character"),
  bio  = field("character", nullable = TRUE)
))

new_Profile(name = "Ada")$bio
#> NULL
new_Profile(name = "Ada", bio = "Mathematician")$bio
#> [1] "Mathematician"
```

### Strict mode

`.strict = TRUE` rejects unknown fields at construction:

``` r

define_model("StrictPoint", fields = list(
  x = field("numeric"),
  y = field("numeric")
), .strict = TRUE)

new_StrictPoint(x = 1, y = 2, z = 3)
#> Error:
#> ! Extra fields not allowed for StrictPoint: z
```

### Nested models

A field’s `type` may be a registered model class name. The constructor
will check that the value is an instance of that class.

``` r

define_model("Address", fields = list(
  street = field("character"),
  city   = field("character")
))

define_model("Person2", fields = list(
  name    = field("character"),
  address = field("Address")
))

new_Person2(
  name    = "Ada",
  address = new_Address(street = "Newstead", city = "Nottingham")
)
#> <Typed Model: Person2>
#> Fields:
#>   name: character = Ada
#>   address: Address = <Address of length 2>
```

Use `t_model("Address")` if you want a [type spec](type-specs.md) form
that can be combined with [`t_nullable()`](../reference/t_nullable.md)
or [`t_list_of()`](../reference/t_list_of.md).

### Field-level validators

[`field()`](../reference/field.md) accepts a `validator` callback that
runs after the type check:

``` r

define_model("Coupon", fields = list(
  code = field("character",
    validator = string_length(min_length = 4, max_length = 12)
  ),
  discount = field("numeric",
    validator = numeric_range(0, 1, exclusive_max = TRUE)
  )
))

new_Coupon(code = "SAVE20", discount = 0.2)
#> <Typed Model: Coupon>
#> Fields:
#>   code: character = SAVE20
#>   discount: numeric = 0.2
new_Coupon(code = "AB", discount = 0.2)
#> Error:
#> ! Validation failed for field 'code' in Coupon
```

### Working with instances

``` r

schema_keys <- names(get_schema(p))
schema_keys
#> [1] "name"  "age"   "email"

is_model(p)
#> [1] TRUE
model_to_list(p)
#> <Typed Model: Person>
#> Fields:
#>   name: character = Ada
#>   age: integer = 36
#>   email: character = ada@example.com

result <- validate_model(p)
result$valid
#> [1] TRUE
```

`update_<Class>()` is the preferred way to mutate — it preserves the S3
class and revalidates:

``` r

p2 <- update_Person(p, age = 37L)
p2$age
#> [1] 37
```

For mutation across models without a class-specific updater, use
[`update_model()`](../reference/update_model.md).

### Field metadata for bridges

[`field()`](../reference/field.md) accepts metadata that travels through
to the [`to_json_schema()`](../reference/to_json_schema.md),
[`to_datacontract()`](../reference/to_datacontract.md), and
[`to_openapi()`](../reference/to_openapi.md) exporters but has no effect
on runtime validation. See the [interop](interop.md) vignette for what
each key does.

``` r

field(
  "character",
  primary_key    = TRUE,
  pii            = TRUE,
  classification = "confidential",
  tags           = c("audit", "lifecycle"),
  examples       = list("ORD-1", "ORD-2")
)
#> $type
#> [1] "character"
#> 
#> $default
#> NULL
#> 
#> $validator
#> NULL
#> 
#> $nullable
#> [1] FALSE
#> 
#> $description
#> [1] ""
#> 
#> $primary_key
#> [1] TRUE
#> 
#> $unique
#> [1] FALSE
#> 
#> $pii
#> [1] TRUE
#> 
#> $classification
#> [1] "confidential"
#> 
#> $tags
#> [1] "audit"     "lifecycle"
#> 
#> $examples
#> $examples[[1]]
#> [1] "ORD-1"
#> 
#> $examples[[2]]
#> [1] "ORD-2"
#> 
#> 
#> $references
#> NULL
#> 
#> $quality
#> NULL
```

## Performance

Validation has a per-call cost. For hot paths:

- pass `.validate = FALSE` to
  [`define_model()`](../reference/define_model.md) to disable checks at
  construction;
- pass `validate = FALSE` to
  [`typed_function()`](../reference/typed_function.md) for the same
  effect on function calls;
- check upstream once and trust your boundaries.

You can still call [`validate_model()`](../reference/validate_model.md)
on demand to re-check an instance after a series of unchecked updates.
