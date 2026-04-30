# Retrofit a package using its roxygen / Rd documentation

Reads installed `.Rd` documentation for `pkgname`, extracts a type spec
for every documented `\\arguments` item and `\\value` block, and applies
the result via [`enable_for_package()`](enable_for_package.md).

Two extraction layers run in sequence:

- **Explicit tag.** A description that begins with `[type]` (e.g.
  `@param x [integer] Number of iterations`) is parsed verbatim.
  Whatever sits between the brackets becomes the spec string.

- **Vocabulary heuristic.** Otherwise the description's leading prose is
  matched against a small vocabulary of common R type names (`numeric`,
  `integer`, `character`, `logical`, ...). The patterns are anchored to
  the start of the description, so prose like "A numeric vector" matches
  but "the function applied to..." does not. See
  [`default_type_vocabulary()`](default_type_vocabulary.md).

The resulting `.specs` list is merged with anything you pass in
explicitly (your overrides win), filtered to formals that actually exist
on each function, then forwarded to
[`enable_for_package()`](enable_for_package.md). That means inference
from defaults still runs for arguments the docs do not describe.

Use this when an existing package already has decent prose docs but no
type information — typethis lifts what is already written. For specs the
heuristics cannot recover, add explicit `[type]` tags in your roxygen,
or pass them via `.specs`.

## Usage

``` r
as_typed_from_roxygen(
  pkgname,
  .specs = list(),
  .infer = TRUE,
  .validate = TRUE,
  .coerce = FALSE,
  .filter = NULL,
  .vocabulary = default_type_vocabulary(),
  .rd_dir = NULL
)
```

## Arguments

- pkgname:

  Package name (string) for an installed package, or an environment
  together with `.rd_dir` for testing / source workflows.

- .specs, .infer, .validate, .coerce, .filter:

  Forwarded to [`enable_for_package()`](enable_for_package.md).
  Per-function entries in `.specs` win over Rd-derived specs.

- .vocabulary:

  A named character vector mapping perl-regex patterns to spec strings.
  The first matching pattern wins, so order matters. Defaults to
  [`default_type_vocabulary()`](default_type_vocabulary.md).

- .rd_dir:

  Optional path to a directory containing `.Rd` files. When supplied,
  files are parsed from disk instead of via
  [`tools::Rd_db()`](https://rdrr.io/r/tools/Rdutils.html). Useful for
  testing and for source packages that have not been installed.

## Value

Invisibly, the character vector of names that were retrofitted.

## See also

[`enable_for_package()`](enable_for_package.md) for the underlying
retrofit; [`parse_param_type()`](parse_param_type.md) for the per-string
extractor; [`default_type_vocabulary()`](default_type_vocabulary.md) for
the prose-to-spec mapping.

Other typed functions: [`as_typed()`](as_typed.md),
[`as_typed_env()`](as_typed_env.md),
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
# Inside R/zzz.R of your package:
# .onLoad <- function(libname, pkgname) {
#   typethis::as_typed_from_roxygen(pkgname)
# }

# Demonstration with a synthetic Rd directory:
rd_dir <- tempfile("rd")
dir.create(rd_dir)
writeLines(c(
  "\\name{add}",
  "\\alias{add}",
  "\\title{Add two numbers}",
  "\\arguments{",
  "\\item{x}{A numeric vector.}",
  "\\item{y}{[integer] Number of times.}",
  "}",
  "\\value{A numeric vector.}"
), file.path(rd_dir, "add.Rd"))

ns <- new.env()
ns$add <- function(x, y) rep(x, y)
as_typed_from_roxygen(ns, .rd_dir = rd_dir)
get_signature(ns$add)
#> $args
#> $args$x
#> [1] "numeric"
#> 
#> $args$y
#> [1] "integer"
#> 
#> 
#> $return
#> [1] "numeric"
#> 
#> $formals
#> $formals$x
#> 
#> 
#> $formals$y
#> 
#> 
#> 
```
