# Research: typethis v0.2 Roadmap

## Overview

This document captures research findings for implementing typethis v0.2 improvements.

## Decision: S3 for Typed Models

**Decision**: Keep typed models on S3, treat as list-backed validated records.

**Rationale**:
- Matches how R users already work with records/lists
- Lightweight, dependency-free
- Fits current package shape
- Avoids R6/S4 complexity before real need
- S3 dispatch works naturally with R's ecosystem

**Alternatives Considered**:
- R6: Adds mutable reference semantics, heavier than needed
- S4: Complex, verbose, poor interoperability with existing R patterns
- RC: Deprecated, rarely used in modern R packages

## Decision: Argument Binding in typed_function()

**Decision**: Bind arguments against wrapped function's actual formals using R's standard dispatch.

**Rationale**:
- R's `formals()`, `alist()`, `match.call()` provide reliable signature introspection
- Consistent with R's lazy evaluation model
- Matches how `typed_function()` should behave vs `validate_call()`

**Implementation Approach**:
```r
# Use match.call() to capture actual arguments
# Then evaluate in evaluation environment
# Compare against formal arguments + types
```

**Alternatives Considered**:
- Custom binding logic: Too error-prone
- String matching: Loses R's semantics

## Decision: Return Value Validation

**Decision**: Validate return values with same rigor as inputs.

**Rationale**:
- Symmetry important for API trust
- Users expect validation to apply to outputs
- Currently inputs validated but returns may bypass checks

## Decision: No Breaking API Changes

**Decision**: All v0.2 changes maintain backward compatibility.

**Rationale**:
- Minor version bump (0.1.0 → 0.2.0)
- Existing code must continue to work
- Deprecation path for any future breaking changes