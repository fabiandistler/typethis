# Retrofit type stability onto an existing function

Convenience wrapper around [`typed_function()`](typed_function.md) for
adding type checks to a function you already have. Compared to
[`typed_function()`](typed_function.md) it removes two sources of
friction:

- Argument specs are passed via `...` instead of
  `arg_specs = list(...)`.

- Specs for arguments with literal atomic defaults are inferred
  automatically (see [`infer_specs()`](infer_specs.md)); only the
  arguments you care about need to appear in `...`.

Internally `as_typed()` builds an `arg_specs` list and delegates to
[`typed_function()`](typed_function.md), so all calling conventions,
coercion, and metadata behaviour are identical.

## Usage

``` r
as_typed(
  fn,
  ...,
  .return = NULL,
  .infer = TRUE,
  .validate = TRUE,
  .coerce = FALSE
)
```

## Arguments

- fn:

  The function to retrofit.

- ...:

  Named type specs. Names must match formals of `fn`. Values may be
  character builtins, predicates, or [type_spec](type_spec.md) objects.
  Pass `NULL` to opt a single argument out of inference.

- .return:

  Specification for the return value, or `NULL` to skip. The return type
  is never inferred.

- .infer:

  If `TRUE` (default), arguments not named in `...` get a spec inferred
  from their default value when possible. See
  [`infer_specs()`](infer_specs.md).

- .validate:

  If `FALSE`, type checks are skipped (useful for hot paths).

- .coerce:

  If `TRUE`, arguments that don't match are first run through
  [`coerce_type()`](coerce_type.md) before assertion.

## Value

A typed function. Same shape as the result of
[`typed_function()`](typed_function.md).

## See also

[`infer_specs()`](infer_specs.md) for the inference rules;
[`typed_function()`](typed_function.md) for the underlying wrapper.

Other typed functions: [`as_typed_env()`](as_typed_env.md),
[`as_typed_from_roxygen()`](as_typed_from_roxygen.md),
[`default_type_vocabulary()`](default_type_vocabulary.md),
[`disable_typed_namespace()`](disable_typed_namespace.md),
[`enable_for_package()`](enable_for_package.md),
[`enable_typed_namespace()`](enable_typed_namespace.md),
[`get_signature()`](get_signature.md),
[`infer_specs()`](infer_specs.md), [`is_typed()`](is_typed.md),
[`parse_param_type()`](parse_param_type.md),
[`signature`](signature.md), [`typed_function()`](typed_function.md),
[`typed_method()`](typed_method.md), [`types()`](types.md),
[`validate_call()`](validate_call.md),
[`with_signature()`](with_signature.md)

## Examples

``` r
# Inferred from defaults — no spec list needed
add <- as_typed(function(x = 0L, y = 0L) x + y, .return = "integer")
add(2L, 3L)
#> [1] 5

# Override one argument; the rest are inferred
greet <- as_typed(
  function(name = "world", times = 1L) {
    paste(rep(name, times), collapse = " ")
  },
  name = t_vector_of("character", exact_length = 1L)
)
greet("hi", times = 3L)
#> [1] "hi hi hi"

# Opt an argument out of validation with NULL
f <- as_typed(function(x = 1L, y = 1L) x + y, y = NULL)
attr(f, "arg_specs")
#> $x
#> [1] "integer"
#> 

# Disable inference entirely
g <- as_typed(function(x = 1L, y = 2L) x + y, .infer = FALSE)
attr(g, "arg_specs")
#> list()
```
