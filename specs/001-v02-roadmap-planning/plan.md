# Implementation Plan: v0.2 Roadmap Planning

**Branch**: `001-v02-roadmap-planning` | **Date**: 2026-04-23 | **Spec**: [ROADMAP.md](/home/fabian/dev/r-projects/typethis/ROADMAP.md)

**Input**: v0.2 Roadmap defining the direction for typethis package improvements

## Summary

Plan the v0.2 release of the typethis R package. The roadmap prioritizes making typed functions the flagship feature with reliable argument binding (positional and named), and keeping typed classes as lightweight S3-validated records. Key outcomes include improved error messages, metadata preservation, and clear documentation distinguishing runtime validation from static analysis.

## Technical Context

**Language/Version**: R 4.0+ (uses Roxygen2, testthat)  
**Primary Dependencies**: methods (base R)  
**Storage**: N/A (R package, no external storage)  
**Testing**: testthat (>= 3.0.0) with RoxygenNote 7.2.3  
**Target Platform**: R >= 4.0, all platforms  
**Project Type**: R package (library)  
**Performance Goals**: Runtime validation should be fast (<1ms per check for typical use cases)  
**Constraints**: Must maintain backward compatibility; no breaking API changes in minor release  
**Scale/Scope**: Single R package with 4 core modules (typed_function, model, type_check, validators)

## Constitution Check

*Note: This is a planning task for the typethis package. The project does not have a customized constitution - it uses the template. This is a documentation/planning task rather than a code feature, so no TDD or library-first gates apply.*

**GATE: Planning Documentation** ✓
- Roadmap clearly defines scope and success criteria
- Phases are sequenced logically (functions → models → docs)

## Project Structure

### Documentation (this feature)

```text
specs/001-v02-roadmap-planning/
├── plan.md              # This file
├── research.md           # Phase 0 output
├── data-model.md         # Phase 1 output
├── quickstart.md         # Phase 1 output (examples for v0.2 features)
└── contracts/            # Phase 1 output (API contracts)
    └── typed-function.md
```

### Source Code (existing structure - to be modified)

```text
R/
├── typed_function.R      # Core: typed_function(), validate_call()
├── model.R              # Core: define_model(), typed_model()
├── type_check.R         # Core: type checking utilities
└── validators.R         # Core: validation helpers

tests/testthat/
├── test-typed-function.R
├── test-model.R
└── test-type-check.R

vignettes/
└── typethis.Rmd          # Main vignette (to be updated)
```

**Structure Decision**: Single R package with S3 OOP. No changes to project structure required for v0.2 - modifications are within existing modules.

## Phase 1: Design - Research Findings

### Typed Functions (Phase 1)

**Current State**: 
- `typed_function()` wraps functions with type validation
- `validate_call()` provides standalone call validation
- Argument binding may not respect function's real formals consistently

**Required Improvements**:
1. Bind arguments against wrapped function's actual signature
2. Support positional AND named argument validation
3. Handle defaults and missing arguments correctly
4. Preserve ... (ellipsis) semantics
5. Preserve wrapper metadata without clobbering type info
6. Return value validation parity with input validation

**API Contract**:
```r
# Current (to be improved):
typed_function(fn, arg_specs, return_spec)

# Must support:
typed_function(fn, 
  arg_specs = c(x = "integer", y = "numeric"),
  return_spec = "logical"
)

# Positional call: fn(1, 2.0) 
# Named call: fn(x = 1, y = 2.0)
# Mixed: fn(1, y = 2.0)
```

### Typed Models (Phase 2)

**Current State**:
- `define_model()` creates validated record-like classes
- S3-based, list-backed
- Basic validation on construction

**Required Improvements**:
1. Formalize construction/validation/printing/conversion contract
2. `update_model()` for safe mutation with revalidation
3. Nested model support
4. Field defaults consistently honored
5. `nullable` metadata respected

**API Contract**:
```r
define_model("Person",
  fields = list(
    name = field("character", nullable = FALSE, default = "Unknown"),
    age = field("integer", nullable = FALSE)
  )
)

# Construction
p <- new_Person(name = "Alice", age = 30)

# Safe update
p2 <- update_Person(p, age = 31)

# Nested models
define_model("Company",
  fields = list(
    name = field("character"),
    ceo = field("Person")  # Nested model
  )
)
```

## Phase 2: Tasks

### Phase 1 Tasks (Typed Functions)

| Task | Description | Priority |
|------|-------------|----------|
| F1 | Fix argument binding to use function's actual formals | High |
| F2 | Add positional argument validation | High |
| F3 | Add missing argument detection | High |
| F4 | Handle ... (ellipsis) properly | High |
| F5 | Preserve wrapper metadata | Medium |
| F6 | Return value validation parity | Medium |
| F7 | Introspection metadata for tools | Medium |
| F8 | Tests for all calling conventions | High |

### Phase 2 Tasks (Typed Models)

| Task | Description | Priority |
|------|-------------|----------|
| M1 | Formalize typed_model contract | High |
| M2 | Implement update_model() with revalidation | High |
| M3 | Nested model support | Medium |
| M4 | Field defaults consistently honored | Medium |
| M5 | Tests for model lifecycle | High |

### Phase 3 Tasks (Documentation)

| Task | Description | Priority |
|------|-------------|----------|
| D1 | Update README to clarify runtime-only scope | High |
| D2 | Add positional arg examples to README | High |
| D3 | Document typed_function() vs define_model() choice | Medium |
| D4 | Update vignette with v0.2 examples | Medium |

## Complexity Tracking

No violations to track - this is a planned improvement within existing architecture.