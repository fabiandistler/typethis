# Repo-tracked git hooks

Run once per clone:

```sh
git config core.hooksPath .githooks
```

Hooks installed:

- **`pre-commit`** — runs `lintr::lint_package()` (with
  `LINTR_ERROR_ON_LINT=true`) so commits fail locally for the same
  reasons CI's `lint.yaml` workflow would. Only runs when the staged
  change touches `R/`, `tests/`, `vignettes/`, `.lintr`, `DESCRIPTION`,
  or `NAMESPACE`. Skips silently if `Rscript` or `lintr` aren't
  available. Bypass for a single commit with `git commit --no-verify`.
