# Spec 002: OpenAPI 3.1 Bridge (typethis v0.5)

## Goal

Add a thin bridge between typethis typed models / typed functions and
OpenAPI 3.1 documents. Mirrors the v0.4 ODCS bridge in shape and file IO,
but reuses the v0.3 `to_json_schema()` machinery rather than duplicating
the type mapping.

## Why OpenAPI 3.1 specifically

- OpenAPI 3.1 is the first OpenAPI release that is explicitly
  JSON-Schema-Draft-2020-12-compatible. Schemas produced by
  `to_json_schema()` can be lifted into `components.schemas` without
  reformatting.
- 3.0 would have required a custom subset translation (no `$id`,
  different `nullable` handling, `examples` shape).
- 3.1 also makes `paths` optional, which is convenient: a document can
  be just `components.schemas` for plain model export, without needing
  fake operations.

## Public API

All functions live in `R/openapi.R`.

- `to_openapi(x, info = NULL, paths = NULL, ...)` — S3 generic with
  methods for `default` (string class name, model constructor, typed
  function), `typed_model` (instance), `list` (mix of class names,
  instances, constructors, typed functions). Returns an OpenAPI 3.1
  document as a native R list.
- `from_openapi(x, register = TRUE, envir = parent.frame())` — accepts
  a path, URL, or parsed list. Registers each `components.schemas`
  entry as a typed model with `new_*()` / `update_*()` in `envir`.
- `write_openapi(x, path, info = NULL, paths = NULL, format = NULL,
  ...)` — writes YAML by default, JSON for `.json` paths or when
  `format = "json"`.
- `read_openapi(path)` — pure parser, no registration.

## Mapping rules

### Models → schemas

Each top-level model is exported via `to_json_schema(name)`. The
returned schema is split into:

- **Body**: everything except `$schema` and `$defs` (kept as-is).
- **`$defs`**: lifted into `components.schemas`.

Then every `$ref` string is rewritten from `#/$defs/X` to
`#/components/schemas/X`. The rewriter walks the entire schema tree
recursively (no string interpolation tricks).

### Typed functions → paths

For each typed function:

- `path` defaults to `/<op_id>`, `op_id` defaults to `"operation"`.
  Override via `attr(fn, "openapi_op_id")` and
  `attr(fn, "openapi_path")`.
- HTTP method defaults to `post`.
- `requestBody.content."application/json".schema` is `{type: object,
  properties: <each arg as JSON Schema fragment>, required: <args
  without defaults>}`.
- `responses."200".content."application/json".schema` is the JSON
  Schema fragment for `return_spec` (or a placeholder description
  if no return type is declared).

Inline schemas are produced via `type_spec_to_json_schema()` /
`builtin_to_json_schema()` (already in `R/json_schema.R`); refs
discovered along the way are lifted into `components.schemas`.

### Schemas → typethis fields (import)

Mirror of the export, but going JSON Schema → `field()`:

- `type: object` with `properties` → recursive call, registers a
  nested typed model named after `prop$title` or the property key.
- `type: array` → `t_list_of(...)` with `min_length`/`max_length`.
- `enum` → `t_enum(...)`.
- `$ref: #/components/schemas/X` → `t_model("X")`.
- Constraint keywords (`minimum`, `maxLength`, `pattern`) → matching
  validator factories.

`required` membership controls `field(nullable = ...)`.

## File IO

- YAML via `yaml::write_yaml` / `yaml::read_yaml`. Soft dependency
  (already in `Suggests` from v0.4).
- JSON via `jsonlite::toJSON` / `jsonlite::fromJSON` with
  `simplifyVector = FALSE` to preserve the list-of-lists shape.
- Format inferred from extension (`.yaml`/`.yml` → YAML, `.json` →
  JSON). Override via `format = "yaml"` / `"json"`.

## Out of scope (deferred to a later version)

- OpenAPI 3.0 compatibility shim.
- `paths` import (i.e., reconstructing typed functions from `paths`
  entries). Currently `from_openapi()` only consumes
  `components.schemas`.
- Server / security definitions.
- A linter wrapper (analogue to `datacontract_lint()`). The mature
  OpenAPI lint tools — Spectral, Redocly — have heavier install
  footprints, so we wait for a concrete user need before wrapping
  one.

## Verification

- `tests/testthat/test-openapi.R` covers builtins, composite specs,
  nested models with `$ref`, mixed lists, typed-function paths,
  YAML/JSON IO, round-trip, error paths.
- Manual sanity check: round-trip a non-trivial model through
  `write_openapi` → `read_openapi` → `from_openapi` and check the
  rebuilt model accepts the same instances.
- `R CMD check --as-cran` clean (CI workflow runs error-on=warning).
