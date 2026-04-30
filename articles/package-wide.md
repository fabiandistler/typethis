# Type-checking your whole package

You have an existing R package and want every function inside it to
become typed. Rewriting each function with
[`typed_function()`](../reference/typed_function.md) would be a large
diff. This vignette shows how to do it in three lines of code, without
touching any existing function definition.

``` r

library(typethis)
#> 
#> Attaching package: 'typethis'
#> The following object is masked from 'package:methods':
#> 
#>     signature
```

## The one-line setup

Add a single file `R/zzz.R` to your package:

``` r

.onLoad <- function(libname, pkgname) {
  typethis::enable_for_package(pkgname)
}
```

That’s it. When R loads your package,
[`enable_for_package()`](../reference/enable_for_package.md) walks the
namespace, infers a type spec for every argument with a literal atomic
default, and replaces each binding with a typed wrapper.

## Why this works

`.onLoad()` is called by R *before* the namespace bindings are locked,
so this is the one window where typethis can rewrite each function in
place. Calling the same function from a console or a test (after the
namespace is already locked) will still work, but most bindings will
already be locked and skipped with a single warning.

## What gets typed

Inference covers any argument whose default is a length-1 literal of a
recognised atomic type:

``` r

infer_specs(function(x = 1L, y = 1.0, name = "a", flag = TRUE) NULL)
#> $x
#> [1] "integer"
#> 
#> $y
#> [1] "double"
#> 
#> $name
#> [1] "character"
#> 
#> $flag
#> [1] "logical"
```

Arguments without inferable defaults — no default, `NULL` default, calls
like [`list()`](https://rdrr.io/r/base/list.html), `...` — are left
unchecked. Their function still becomes a typed wrapper, just with fewer
specs attached.

## Filling in the gaps

Pass `.specs` to add overrides for any function you want to type more
strictly than inference can figure out by itself:

``` r

ns <- new.env()
ns$add <- function(x = 0L, y = 0L) x + y
ns$normalise <- function(s) tolower(trimws(s))

enable_for_package(ns, .specs = list(
  add = list(.return = "integer"),
  normalise = list(s = "character", .return = "character")
))

attr(ns$add, "return_spec")
#> [1] "integer"
attr(ns$normalise, "arg_specs")
#> $s
#> [1] "character"
```

In your package this would live in `R/zzz.R` next to `.onLoad`:

``` r

.onLoad <- function(libname, pkgname) {
  typethis::enable_for_package(
    pkgname,
    .specs = list(
      normalise = list(s = "character", .return = "character"),
      parse_date = list(x = "character", .return = t_predicate(inherits, "Date"))
    )
  )
}
```

## What is skipped

[`enable_for_package()`](../reference/enable_for_package.md) skips two
categories automatically:

- **Primitives** — there is nothing to wrap.
- **Package hooks** — `.onLoad`, `.onAttach`, `.onUnload`, `.onDetach`,
  `.Last.lib`, `.First.lib`. These are called by R’s namespace machinery
  with a fixed argument shape and should not be wrapped.

You can narrow further with `.filter` (a `function(name, fn)` returning
`TRUE` to retrofit, `FALSE` to skip). The user filter runs *after* the
built-in skip list, so it can only narrow, never widen:

``` r

ns2 <- new.env()
ns2$public <- function(x = 1L) x
ns2$internal_helper <- function(x = 1L) x

enable_for_package(ns2, .filter = function(name, fn) {
  !startsWith(name, "internal_")
})

is_typed(ns2$public)
#> [1] TRUE
is_typed(ns2$internal_helper)
#> [1] FALSE
```

## Verifying the result

After your package loads, every typed binding answers
[`is_typed()`](../reference/is_typed.md):

``` r

ns3 <- new.env()
ns3$add <- function(x = 0L, y = 0L) x + y
enable_for_package(ns3)

is_typed(ns3$add)
#> [1] TRUE
get_signature(ns3$add)
#> $args
#> $args$x
#> [1] "integer"
#> 
#> $args$y
#> [1] "integer"
#> 
#> 
#> $return
#> NULL
#> 
#> $formals
#> $formals$x
#> [1] 0
#> 
#> $formals$y
#> [1] 0
```

Calling `add()` with the wrong type now produces the typethis error
you’d get from a hand-written
[`typed_function()`](../reference/typed_function.md):

``` r

ns3$add("a", 3L)
#> Error:
#> ! Type error: 'x' must be integer, got character
```

## Lifting types from your existing roxygen docs

If your package already has prose documentation, swap
[`enable_for_package()`](../reference/enable_for_package.md) for
[`as_typed_from_roxygen()`](../reference/as_typed_from_roxygen.md). It
reads the installed `.Rd` files (which roxygen generates), extracts a
type spec for every documented `@param` and `@return`, then forwards to
[`enable_for_package()`](../reference/enable_for_package.md). Specs
derived from docs cover *every* documented argument, including those
without literal defaults — which is the gap inference cannot fill.

``` r

.onLoad <- function(libname, pkgname) {
  typethis::as_typed_from_roxygen(pkgname)
}
```

Two extraction layers run in sequence:

1.  **Explicit `[type]` tag.** A `@param` description that begins with
    bracketed text is read verbatim:

    ``` r

    #' @param x [integer] Number of iterations
    ```

    Anything between the brackets becomes the spec string — useful when
    prose is ambiguous or the type is one of typethis’s compound spec
    constructors (e.g. `[t_vector_of("integer", min_length = 1)]`).

2.  **Vocabulary heuristic.** Otherwise the leading prose is matched
    against
    \[[`default_type_vocabulary()`](../reference/default_type_vocabulary.md)\].
    Patterns are anchored to the start of the description, so “A numeric
    vector” matches but “Returns a numeric value when…” does not.

Demonstration with a synthetic Rd directory:

``` r

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

ns4 <- new.env()
ns4$add <- function(x, y) rep(x, y)

as_typed_from_roxygen(ns4, .rd_dir = rd_dir)

attr(ns4$add, "arg_specs")
#> $x
#> [1] "numeric"
#> 
#> $y
#> [1] "integer"
attr(ns4$add, "return_spec")
#> [1] "numeric"
```

Inference still runs alongside, so undocumented arguments with literal
defaults still get specs from
[`infer_specs()`](../reference/infer_specs.md). User `.specs` win over
both, just like with
[`enable_for_package()`](../reference/enable_for_package.md).

To extend the prose vocabulary — e.g. recognise `tbl_df` as `data.frame`
— prepend an entry:

``` r

my_vocab <- c(
  "(?i)^\\s*(?:a|an)?\\s*tbl[._]df\\b" = "data.frame",
  default_type_vocabulary()
)
as_typed_from_roxygen("mypkg", .vocabulary = my_vocab)
```

## Type-checking a package you do not own

The two patterns above edit the target package — fine when it is yours,
awkward when it is a dependency.
[`enable_typed_namespace()`](../reference/enable_typed_namespace.md)
takes the third route: register a `setHook(packageEvent(..., "onLoad"))`
handler from outside the target, so the next
[`library()`](https://rdrr.io/r/base/library.html) call wraps the
package’s bindings without ever touching its source.

``` r

typethis::enable_typed_namespace("dplyr")
library(dplyr)   # bindings are typed once loaded
```

Because the hook fires *after* R locks the namespace, retrofit goes
through an unlock-modify-relock dance (`as_typed_env(.unlock = TRUE)`).
Re-locking is guaranteed by `on.exit` even if a wrap step errors, so the
namespace cannot end up half-unlocked.

If the package is already loaded when you call
[`enable_typed_namespace()`](../reference/enable_typed_namespace.md),
the retrofit also runs immediately on the live namespace.

To stop retrofitting a package on future loads — and revert the typed
wrappers on the currently loaded copy — call
[`disable_typed_namespace()`](../reference/disable_typed_namespace.md):

``` r

typethis::disable_typed_namespace("dplyr")
```

Foreign hooks on the same `packageEvent` are left intact: only hooks
tagged by typethis are removed.

This pattern is meant for development, debugging, and exploratory work.
**Do not ship code that calls
[`enable_typed_namespace()`](../reference/enable_typed_namespace.md) on
another package’s namespace** — modifying namespaces you do not own is a
developer convenience, not a CRAN-acceptable production pattern. For
production use, use
[`enable_for_package()`](../reference/enable_for_package.md) from inside
your own `.onLoad`.

## Trade-offs

- **Coverage scales with how much you’ve used defaults.** With
  [`enable_for_package()`](../reference/enable_for_package.md) alone,
  functions written without literal defaults (e.g. `function(x, y) ...`)
  get a typed wrapper but no specs unless you fill them in via `.specs`.
  [`as_typed_from_roxygen()`](../reference/as_typed_from_roxygen.md)
  plugs that gap by lifting types out of your existing prose.
- **Heuristics are imperfect.** The vocabulary recognises common type
  language; ambiguous prose silently produces no spec. Use the `[type]`
  prefix or `.specs` overrides for anything you care about precisely.
- **Per-call overhead.** Every call now passes through a wrapper that
  validates arguments. For hot paths, set `.validate = FALSE` per call
  via [`validate_call()`](../reference/validate_call.md) or pass
  `.validate = FALSE` to
  [`enable_for_package()`](../reference/enable_for_package.md) /
  [`as_typed_from_roxygen()`](../reference/as_typed_from_roxygen.md).
- **CRAN.** Modifying your own namespace from your own `.onLoad()` is
  fine. Modifying *another* package’s namespace from outside is a
  separate, more invasive pattern that these functions deliberately do
  not support.

## Related entry points

- \[[`as_typed()`](../reference/as_typed.md)\]\[as_typed\] — retrofit
  one function at a time.
- \[[`as_typed_env()`](../reference/as_typed_env.md)\]\[as_typed_env\] —
  the engine
  [`enable_for_package()`](../reference/enable_for_package.md) is built
  on; gives you full control over filtering and overrides.
- \[[`as_typed_from_roxygen()`](../reference/as_typed_from_roxygen.md)\]\[as_typed_from_roxygen\]
  — lift types out of prose `@param`/`@return` documentation.
- \[[`parse_param_type()`](../reference/parse_param_type.md)\]\[parse_param_type\]
  — inspect what would be derived from a single description string.
- \[[`enable_typed_namespace()`](../reference/enable_typed_namespace.md)\]\[enable_typed_namespace\]
  — retrofit a package you do not own via `setHook(packageEvent(...))`.
- \[[`disable_typed_namespace()`](../reference/disable_typed_namespace.md)\]\[disable_typed_namespace\]
  — revert and unregister.
- \[[`typed_function()`](../reference/typed_function.md)\]\[typed_function\]
  — write a typed function from scratch instead of retrofitting.
