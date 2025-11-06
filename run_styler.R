#!/usr/bin/env Rscript
# Run styler on all R files

if (!requireNamespace("styler", quietly = TRUE)) {
  cat("Installing styler...\n")
  install.packages("styler", repos = "https://cloud.r-project.org")
}

library(styler)

cat("Running styler on R/ directory...\n")
styler::style_dir("R/", filetype = "R")

cat("\nRunning styler on tests/testthat/ directory...\n")
styler::style_dir("tests/testthat/", filetype = "R")

cat("\nRunning styler on examples/ directory...\n")
styler::style_dir("examples/", filetype = "R")

cat("\nStyler completed!\n")
