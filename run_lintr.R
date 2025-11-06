#!/usr/bin/env Rscript
# Run lintr on all R files

if (!requireNamespace("lintr", quietly = TRUE)) {
  cat("Installing lintr...\n")
  install.packages("lintr", repos = "https://cloud.r-project.org")
}

library(lintr)

cat("Running lintr on package...\n\n")

# Lint R files
r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
test_files <- list.files("tests/testthat", pattern = "\\.R$", full.names = TRUE)
example_files <- list.files("examples", pattern = "\\.R$", full.names = TRUE)

all_files <- c(r_files, test_files, example_files)

results <- list()

for (file in all_files) {
  cat("Checking:", file, "\n")
  lints <- lintr::lint(file)

  if (length(lints) > 0) {
    cat("  Issues found:\n")
    print(lints)
    results[[file]] <- lints
  } else {
    cat("  ✓ No issues\n")
  }
  cat("\n")
}

# Summary
cat("========================================\n")
cat("Summary:\n")
total_issues <- sum(sapply(results, length))
cat("Total files checked:", length(all_files), "\n")
cat("Files with issues:", length(results), "\n")
cat("Total issues:", total_issues, "\n")
cat("========================================\n")

if (total_issues > 0) {
  cat("\nPlease review and fix the issues above.\n")
}
