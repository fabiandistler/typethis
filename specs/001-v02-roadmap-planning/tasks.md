# Tasks: typethis v0.2 Roadmap Implementation

**Input**: Design documents from `/specs/001-v02-roadmap-planning/`
**Branch**: `001-typed-functions`

**Organization**: Tasks are grouped by feature area to enable independent implementation.
No `spec.md` present — user stories derived from `plan.md` task groups F (functions), M (models), D (docs).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Feature area — [US1] Typed Functions Core, [US2] Typed Models, [US3] Documentation

---

## Phase 1: Setup (Baseline Verification)

**Purpose**: Confirm the current test suite state before any modifications

- [X] T001 Run `devtools::test()` and record any pre-existing failures as known baseline <!-- #9 -->

---

## Phase 2: Foundational (API Alignment)

**Purpose**: Align internal parameter names with the contract spec before implementing new behaviour

**⚠️ CRITICAL**: Both the function and model user stories depend on the API naming being correct first

- [X] T002 Add backward-compatible parameter aliases in `typed_function()` — accept both `arg_types`/`return_type` (old) and `arg_specs`/`return_spec` (new contract) in `R/typed_function.R` <!-- #8 -->
- [X] T003 Update `validate_call()` signature to match contract (`fn, ..., return_spec = NULL`) and read `arg_specs` attribute in `R/typed_function.R` <!-- #6 -->

**Checkpoint**: Foundation ready — user story implementation can now begin

---

## Phase 3: User Story 1 — Typed Function Core (Priority: P1) 🎯 MVP

**Goal**: `typed_function()` correctly validates arguments regardless of whether the caller uses positional, named, or mixed calling conventions, and detects missing required arguments.

**Independent Test**:
```r
add <- typed_function(function(x, y) x + y, arg_specs = c(x = "numeric", y = "numeric"))
add(1, 2)        # passes — positional
add(x = 1, y = 2)  # passes — named
add(y = 2, x = 1)  # passes — reordered named
add("a", 2)      # error — type mismatch
add(1)           # error — missing required arg y
```

### Implementation for User Story 1

- [X] T004 [US1] Rewrite the wrapper body in `typed_function()` to bind positional and named args against `formals(fn)` using `match.call()` + `sys.function()` semantics in `R/typed_function.R` (plan F1 + F2) <!-- #10 -->
- [X] T005 [US1] Add missing-argument detection — after binding, check which `arg_specs` names have no value and no formal default, then error clearly in `R/typed_function.R` (plan F3) <!-- #7 -->
- [X] T006 [US1] Preserve `...` passthrough — exclude `...` from binding and type-check loops so variadic functions work correctly in `R/typed_function.R` (plan F4) <!-- #13 -->
- [X] T007 [US1] Write tests covering named, positional, mixed, reordered-named, missing-arg error, and `...` passthrough in `tests/testthat/test-typed_function.R` (plan F8) <!-- #11 -->

**Checkpoint**: User Story 1 complete — `typed_function()` handles all calling conventions

---

## Phase 4: User Story 2 — Typed Function Metadata & Return Validation (Priority: P1)

**Goal**: Wrapper functions preserve the original function's metadata without clobbering wrapper attributes, expose introspection data, and validate return values with the same rigour as inputs.

**Independent Test**:
```r
add <- typed_function(function(x, y) x + y, arg_specs = c(x = "numeric", y = "numeric"), return_spec = "numeric")
is.function(add)         # TRUE
formals(add)             # x, y (not empty)
sig <- get_signature(add)
sig$args                 # c(x = "numeric", y = "numeric")
sig$return               # "numeric"
sig$formals              # formals(fn)
```

### Implementation for User Story 2

- [X] T008 [US2] Fix attribute preservation — replace `attributes(wrapper) <- attributes(fn)` with selective copying that does not overwrite wrapper's own attrs in `R/typed_function.R` (plan F5) <!-- #12 -->
- [X] T009 [US2] Copy `formals(fn)` onto the wrapper so `formals(wrapper)` reflects the original signature in `R/typed_function.R` (plan F5) <!-- #15 -->
- [X] T010 [US2] Ensure return value is validated against `return_spec` after `do.call(fn, args)` when `return_spec` is non-NULL in `R/typed_function.R` (plan F6) <!-- #14 -->
- [X] T011 [US2] Store `formals(fn)` in wrapper attrs and expose via `get_signature()` under `$formals` key for tooling introspection in `R/typed_function.R` (plan F7) <!-- #18 -->
- [X] T012 [US2] Write tests for metadata preservation (formals, body, attributes), return-type validation pass/fail, and `get_signature()` output in `tests/testthat/test-typed_function.R` <!-- #19 -->

**Checkpoint**: User Story 2 complete — metadata and return validation working

---

## Phase 5: User Story 3 — Typed Models (Priority: P1) 🎯 Can run in parallel with Phase 3/4

**Goal**: `define_model()` supports the new `define_model("ModelName", fields = list(...))` API, generates `new_ModelName()` and `update_ModelName()` in the calling environment, supports field defaults and nested models, and maintains backward compatibility with the existing unnamed-args API.

**Independent Test**:
```r
define_model("Person",
  fields = list(
    name = field("character", nullable = FALSE),
    age  = field("integer", nullable = FALSE, default = 0L)
  )
)
p  <- new_Person(name = "Alice", age = 30L)
p$name                    # "Alice"
p2 <- update_Person(p, age = 31L)
p2$age                    # 31L
update_Person(p, age = "x")  # error — type mismatch
```

### Implementation for User Story 3

- [X] T013 [US3] Extend `define_model()` to detect new-style call `define_model("ModelName", fields = list(...))` and dispatch to a new internal implementation path in `R/model.R` (plan M1) <!-- #16 -->
- [X] T014 [US3] Implement new-style `define_model()` body: validates `fields` list, captures class name, creates S3 model schema, and assigns `new_<ClassName>()` into `parent.env(environment())` in `R/model.R` (plan M1 + M2) <!-- #20 -->
- [X] T015 [US3] Implement `update_<ClassName>()` generator — merges updates onto instance fields, revalidates all non-NULL specs, returns updated S3 instance in `R/model.R` (plan M2) <!-- #17 -->
- [X] T016 [US3] Add nested model support in field validation — when `field$type` matches a known model class name, validate the value with `is_model()` and class check in `R/model.R` (plan M3) <!-- #24 -->
- [X] T017 [US3] Ensure `field(default = ...)` values are applied consistently when a field is absent from the constructor call, including for nested model fields in `R/model.R` (plan M4) <!-- #21 -->
- [X] T018 [US3] Write tests covering: new-style construction, missing required field error, default application, update with revalidation, nested model field, old-style API still works in `tests/testthat/test-model.R` (plan M5) <!-- #22 -->

**Checkpoint**: User Story 3 complete — full model lifecycle working with new API

---

## Phase 6: User Story 4 — Documentation (Priority: P2)

**Goal**: README and vignette reflect v0.2 capabilities, clearly communicate runtime-only scope, and demonstrate positional argument usage.

**Independent Test**: Examples in README run without error; vignette knits cleanly with `devtools::build_vignettes()`.

### Implementation for User Story 4

- [X] T019 [P] [US4] Add or update a "Runtime Only" section in `README.md` that explicitly states typethis performs runtime validation only, not static analysis (plan D1) <!-- #23 -->
- [X] T020 [P] [US4] Add positional, named, and mixed calling convention examples under the `typed_function()` section of `README.md` (plan D2) <!-- #25 -->
- [X] T021 [P] [US4] Add a comparison section to `README.md` — "When to use `typed_function()` vs `define_model()`" with a decision table (plan D3) <!-- #30 -->
- [X] T022 [US4] Update `vignettes/typethis.Rmd` with v0.2 examples from `specs/001-v02-roadmap-planning/quickstart.md` — typed functions and typed models sections (plan D4) <!-- #27 -->

**Checkpoint**: User Story 4 complete — documentation reflects v0.2 API

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final quality pass before release

- [X] T023 [P] Run `lintr::lint_package()` and fix all flagged issues across `R/` <!-- #29 -->
- [X] T024 [P] Run `styler::style_pkg()` to apply tidyverse code style across `R/` <!-- #26 -->
- [X] T025 Run `devtools::check()` and resolve all ERRORs, WARNINGs, and NOTEs <!-- #28 -->
- [X] T026 Bump `Version` field in `DESCRIPTION` from `0.1.0` to `0.2.0` <!-- #32 -->
- [X] T027 Write `NEWS.md` entry for v0.2.0 covering F1–F8, M1–M5, D1–D4 <!-- #31 -->

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — run immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS US1 and US2 (not US3/US4 which touch different files)
- **US1 — Typed Function Core (Phase 3)**: Depends on Phase 2
- **US2 — Typed Function Metadata (Phase 4)**: Depends on Phase 3 (both modify `typed_function()` body)
- **US3 — Typed Models (Phase 5)**: Depends only on Phase 1 — can run in parallel with Phases 2–4
- **US4 — Documentation (Phase 6)**: Depends on Phase 3 and Phase 5 being feature-complete
- **Polish (Phase 7)**: Depends on all prior phases

### User Story Dependencies

- **US1 (P1)**: Requires Foundational (Phase 2) complete
- **US2 (P1)**: Requires US1 complete (same file, sequential edits to `typed_function()`)
- **US3 (P1)**: Independent — starts after Phase 1, parallel to Phases 2–4
- **US4 (P2)**: Requires US1 and US3 complete for accurate examples

### Within Each User Story

- Implementation tasks before test tasks (tests validate the implementation)
- Core binding before missing-arg detection (T004 before T005)
- `new_<ClassName>()` before `update_<ClassName>()` (T014 before T015)

### Parallel Opportunities

- **Phase 5 (US3)** can run in parallel with **Phases 2–4** (completely different files)
- **T019, T020, T021** (README sections) can run in parallel (independent sections)
- **T023, T024** (lint + style) can run in parallel

---

## Parallel Example: US3 + US1 in Parallel

```bash
# Stream A — Typed Functions (sequential within stream):
T002 → T003 → T004 → T005 → T006 → T007 → T008 → T009 → T010 → T011 → T012

# Stream B — Typed Models (independent, start after T001):
T013 → T014 → T015 → T016 → T017 → T018
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002–T003)
3. Complete Phase 3: US1 — Typed Function Core (T004–T007)
4. **STOP and VALIDATE**: `add(1, 2)` and `add("a", 2)` both behave correctly
5. Continue to Phase 4 or Phase 5 next

### Incremental Delivery

1. T001 → T002–T003 → Foundation ready
2. T004–T007 → Typed functions fully validated (MVP!)
3. T008–T012 → Metadata + return validation added
4. T013–T018 → Typed models with new API
5. T019–T022 → Documentation updated
6. T023–T027 → Polish and release

### Single-Developer Recommended Order

Complete streams sequentially: Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7.
Start Phase 5 (models) after Phase 1 if you want a break from the function work — it's fully independent.

---

## Notes

- **Backward compatibility**: `arg_types`/`return_type` parameter names must remain accepted (T002)
- **No static analysis**: typethis is runtime-only — do not add any static inference or import machinery
- **`...` semantics**: F4 means `...` passes through unchanged; only named/positional args are type-checked
- **`new_<ClassName>()` scope**: assigns into the calling frame using `assign(..., envir = parent.frame())` — this is intentional for the model API
- Commit after each phase checkpoint
- Run `devtools::test()` after every task that touches `R/` files
