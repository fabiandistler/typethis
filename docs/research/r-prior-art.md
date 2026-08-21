# Prior Art: Annotation-Style Typing in R

Research for [typethis](https://github.com/fabiandistler/typethis) — what existing R packages attempt to bring type/validation annotations into function signatures, how they work, and why they succeeded or stalled.

---

## Comparison Table

| Package | Status | Syntax | Mechanism | Closest to `x: int`? | Adoption |
|---------|--------|--------|-----------|----------------------|----------|
| **types** (Jim Hester) | CRAN, unmaintained | `function(x = ? numeric)` | Default-value trick: `?` as a unary operator on the RHS of `=`. Annotations are no-op; stored for other tools to consume. | Partial — `?` prefix on defaults, not `x: type`. | Low — convention-only, no runtime enforcement. |
| **typed** (Antoine Fabri / moodymudskipper) | CRAN, maintained | `? function(x = ? Integer) { }` or `Integer ? function(x) { }` | NSE + formals rewriting. `?` is a unary operator; `typed` rewrites function body to insert `check_arg()` calls and active bindings. | Closest to literal annotation — `?` prefix on formals with NSE. | Growing — active development, used in packages. |
| **valaddin** (Eugene Ha) | CRAN, unmaintained | `firmly(. ~ vld_number)` + `%checkin%` operator | Check formulae — `~predicate` on LHS (scope), RHS (predicate). `firmly()` rewrites function to insert checks. | Distant — separate `firmly()` call, not inline. | Very low — novel but niche syntax. |
| **checkmate** (Michel Lang) | CRAN, widely used | `assert_numeric(x)` inside body | Plain function calls. No annotation syntax. Optional `qassert(x, "I+")` mini-DSL for compact checks. | None — body-level, not signature. | Very high — de facto standard for arg checking in R packages. |
| **typer** (mb706) | GitHub only, archived | `@numeric x` in formals (via comments/doc-like syntax) | `compileTypes()` rewrites functions discovered in an environment, generating checkmate calls from annotation comments. | Closest literal — `@type name` prefix syntax. | Negligible — proof-of-concept, never reached CRAN. |
| **rtype** (renkun-ken) | CRAN, unmaintained | `x <- 1 : integer` for assignment | Overloaded `:` operator + active bindings. | Distant — assignment-level, not function signatures. | Very low — experimental, no updates since 2016. |
| **assertr** (Tony Fischetti / rOpenSci) | CRAN, maintained | `assert(predicate, cols)` in pipeline | dplyr-pipe integration; NSE column selection. Not for function arguments. | None — data validation, not function arg typing. | Moderate — popular in data pipelines. |
| **pointblank** (RStudio/Posit) | CRAN, maintained | `col_vals_gt(warn, 0)` in agent workflow | OOP agent object collecting validation steps; reporting-focused. | None — data quality, not function args. | High — industry tool for data quality. |
| **arg** (Noah Greifer) | CRAN, maintained | `arg_match(x, c("a", "b"))` inside body | Thin wrappers around `rlang` + `cli` for clean error messages. No annotation syntax. | None — body-level helper functions. | New — clean API, growing but body-level. |
| **contractr** (aviralg) | GitHub only, research | `@:numeric x` in formals | Forked R parser (patch to gram.y) — annotations stored as attributes on the function object via `@:` syntax. | Literal annotation in signature — true parser-level. | None — requires patched R interpreter, pure research. |
| **@:annotations** proposal (Peta M, DSC 2017) | Proposal only | `@:numeric[] x` in formals | Parser modification to R's grammar (gram.y), 179 lines of changes. Annotations stored as AST attributes. | Full — native syntax proposal, never merged. | None — never implemented in mainline R. |
| **lambda.r** (Brian Lee Yung Rowe) | CRAN, unmaintained | `seal( f(x :: numeric) %::% numeric )` | Overloaded `::` and `%::%` operators + NSE + formals rewriting. Multi-dispatch on types. | Partial — `x :: numeric` inside wrapper, not native formals. | Very low — ambitious but complex syntax. |

---

## Detailed Explanations

### 1. `types` — Jim Hester (CRAN)

**Mechanism:** `?` is a valid unary operator in R. In `function(x = 1 ? numeric)`, R parses `1 ? numeric` as an expression `?` with two arguments — this is syntactically valid R. The `types` package stores these annotations as attributes on the function but does *nothing* at runtime. The intended workflow was that IDEs, linters, or compilers would consume the metadata.

**Why it stalled:** It provided *no runtime enforcement*, making it invisible to most users. The annotations were a convention without a consumer. As Jim Hester himself noted, it was meant as "a convention to allow other packages to use the type information."

**Relevance to typethis:** The `? numeric` default-value trick is the most elegant way to embed annotations in syntactically valid R. The failure was in not providing enforcement, not in the syntax.

### 2. `typed` — Antoine Fabri (CRAN, active)

**Mechanism:** `typed` reused the `?` trick from `types` but added runtime enforcement. `? function(x = ? Integer)` uses `?` as both a function-declaration marker and a formal annotation. The package uses `formals()` to analyze the function signature, then rewrites the body to insert `check_arg()` calls and optionally wraps arguments in active bindings (via `makeActiveBinding()`) to enforce invariants throughout the function body.

**Syntax examples:**
```r
Integer ? function(x, y = ? Integer) { x + y }
```

**Adoption:** Actively maintained, has a pkgdown site, and is starting to be used in other packages. The `?` prefix syntax is the closest thing R has to `x: int` without modifying the parser.

**Limitations:** The `?` trick breaks for `NULL` defaults (`function(x = NULL ? Integer)` does not read as "nullable integer"). Requires `?` before `function`, which is a new top-level syntax R users must learn.

### 3. `valaddin` — Eugene Ha (CRAN)

**Mechanism:** Check formulae like `~ vld_number` combined with `firmly(f)` to wrap a function. Inside, `firmly()` inspects the function and prepends validation code. The `%checkin%` operator allows inline checks adjacent to arguments.

**Why it stalled:** The formula-based syntax (`firmly(f ~ vld_number)`) was far from the natural `f(x: int)` that users wanted. Despite the clever `%checkin%` operator, the cognitive overhead of learning check formulae was too high.

### 4. `checkmate` — Michel Lang (CRAN, de facto standard)

**Mechanism:** Pure assertion functions (`assert_numeric(x)`, `qassert(x, "I+")`) placed inside the function body. The `qassert` mini-DSL provides a compact string syntax: `"I+"` means "integer vector, non-empty, no NAs." C implementation for performance.

**Why it succeeded:** It solved a concrete pain — writing argument checks in R was "cumbersome and annoying" — with simple function calls and excellent error messages. It didn't try to change the language or introduce new syntax; it just made the boring boilerplate fast and readable.

**Relevance to typethis:** checkmate's success proves R users *want* argument validation, but they prefer simple function calls to novel syntax. Any annotation system must produce equally good error messages to compete.

### 5. `typer` — mb706 (GitHub, archived)

**Mechanism:** Used a comment-like annotation syntax where `@type` prefixes declared type expectations. `compileTypes()` scanned the environment post-definition and rewrote functions to call checkmate.

**Syntax example:**
```r
foo <- function(@numeric x, @integer y) x + y
compileTypes()
```

**Why it stalled:** Required a separate compilation step (`compileTypes()`) after definition. The `@` syntax is not valid R (it's the slot-access operator in binary form), so it relied on comment-based annotation or the library's own parsing. Never reached CRAN maturity.

### 6. `rtype` — Kun Ren (CRAN, archived on GitHub)

**Mechanism:** Overloaded `:` and `::` operators plus active bindings. `x <- 1 : integer` defines a typed variable. For functions, `f <- function(x) x + 1 : numeric` attempted return-type declaration.

**Why it stalled:** The `:` overloading conflicted with base R's sequence operator (`1:10`). The syntax was fragile and never achieved stable function-signature annotation.

### 7. `assertr` — Tony Fischetti / rOpenSci (CRAN)

**Mechanism:** Data-frame-level assertions in dplyr pipelines. Uses NSE to select columns, then applies predicates per element. Not a function-argument system.

**Relevance:** Proves the appetite for *data validation* in R but does not address *function argument* annotation.

### 8. `pointblank` — RStudio/Posit (CRAN)

**Mechanism:** Agent-object-based data validation with rich reporting. Database-backed, not function-argument-focused.

**Relevance:** The most commercially successful R validation package, but serves a completely different purpose (data quality vs. type safety).

### 9. `arg` — Noah Greifer (CRAN)

**Mechanism:** Helper functions like `arg_match(x, c("a", "b"))` and `arg_numeric(x)` that live in function bodies. Uses rlang's `caller_arg()` for intelligent error messages. No annotation syntax.

**Relevance:** Represents the current best practice for body-level argument checking, with clean `cli`-powered error messages.

### 10. `contractr` + `@:annotations` — Peta M, aviralg (Research)

**Mechanism:** A patched R parser (branch `R-defs` on SVN) that recognizes `@:` syntax in formal parameters. The parser stores annotations as attributes on the function object, accessible via an `annotations()` API. Required rebuilding R from source.

**Syntax example:**
```r
cSqrt <- function(@:+numeric x) sqrt(x)
annotations(cSqrt, "formals")  # returns $x: list(+numeric)
```

This was presented at DSC 2017 as a proof-of-concept, with a companion package `contractr` that consumed the annotation attributes to enforce contracts.

**Why it stalled:** Requires patching R itself. The R Core team was (and remains) conservative about adding syntax. The `@` operator was already used for slot access on S4 objects, and the proposal to repurpose it in formals faced compatibility concerns.

**Relevance to typethis:** This is the gold standard for what typethis would do if R had native annotation support. It shows that parser-level annotations are feasible but politically blocked.

### 11. `lambda.r` — Brian Lee Yung Rowe (CRAN)

**Mechanism:** NSE wrapper `seal()` that processes `::` as a type annotation operator inside a special function definition syntax: `f(x :: numeric) %::% numeric %as% { x + 1 }`. Supports multi-dispatch on types.

**Why it stalled:** The syntax is heavy (`%::%`, `%as%`, `seal()`), the package required a new way of writing functions, and the multi-dispatch feature introduced complexity few R users needed.

### 12. `ensurer` — Stefan Milton Bache (CRAN)

**Mechanism:** Pipeline-style contracts: `x %ensure% is.numeric`. Not function-argument-level. Lightweight, but data-pipeline-only.

---

## Key Findings for typethis

1. **The `?` default-value trick is the best current syntax.** It's valid R, doesn't require a parser patch, and `typed` proved it works. `function(x = ? numeric)` is as close as you get without forking R.

2. **Parser-level `@:` annotations are the ideal but blocked.** The DSC 2017 proposal and `contractr` prototype show what's possible, but R Core has not adopted it. typethis could target this as a future goal if R ever supports formal annotations.

3. **checkmate's dominance sets the bar.** Any annotation system must produce comparable error messages, be equally fast, and integrate with existing checkmate-aware code. Several tools (typer) used checkmate as a backend; typethis should consider the same.

4. **All prior NSE-based approaches share a limitation:** they cannot annotate arguments without default values (e.g., `function(x)`) because there's nothing to attach the `?` expression to. This is a fundamental constraint of not modifying the parser.

5. **Adoption correlates inversely with syntax novelty.** checkmate (simple function calls) → widest adoption. typed (`?` syntax) → growing. valaddin/typer/lambda.r (novel DSLs) → stalled. Users want validation, but they don't want to learn a new language.

6. **No existing package provides both** (a) signature-level annotations and (b) static analysis / IDE integration. `types` attempted the metadata side without enforcement; `typed` does enforcement without metadata export.

---

## References

- Jim Hester, *types*: https://cran.r-project.org/package=types
- Antoine Fabri, *typed*: https://cran.r-project.org/package=typed, https://moodymudskipper.github.io/typed/
- Eugene Ha, *valaddin*: https://cran.r-project.org/package=valaddin
- Michel Lang, *checkmate*: https://cran.r-project.org/package=checkmate, https://mllg.github.io/checkmate/
- mb706, *typer*: https://github.com/mb706/typer
- Kun Ren, *rtype*: https://github.com/renkun-ken/rtype
- Tony Fischetti, *assertr*: https://cran.r-project.org/package=assertr
- RStudio/Posit, *pointblank*: https://cran.r-project.org/package=pointblank
- Noah Greifer, *arg*: https://cran.r-project.org/package=arg
- Peta M, "@:annotations", DSC 2017: https://www.r-project.org/dsc/2017/slides/Annotations_for_R.pdf
- aviralg, *contractr*: https://github.com/aviralg/contractr (requires patched R)
- Brian Lee Yung Rowe, *lambda.r*: https://cran.r-project.org/package=lambda.r
- Stefan Milton Bache, *ensurer*: https://cran.r-project.org/package=ensurer
- R-devel thread, "RFC: native unquoting": https://stat.ethz.ch/pipermail/r-devel/2017-March/thread.html
- Lukas Rohde, *typeR* (static inference, not annotation): https://doi.org/10.18725/oparu-59821