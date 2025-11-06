# Testing Guide for typethis

## Local Testing

Since R is not available in the CI environment, please run these tests locally.

### 1. Basic Package Test

Run the comprehensive test script:

```bash
Rscript test_package.R
```

This will test:
- Type creation and matching
- AST parsing
- Type inference
- Type checking
- reveal_type() functionality
- typed() decorator
- data.table support (if installed)

### 2. Run Code Style Checks

#### Format code with styler:

```bash
Rscript run_styler.R
```

This will automatically format all R code according to the tidyverse style guide.

#### Check code quality with lintr:

```bash
Rscript run_lintr.R
```

This will check for:
- Style violations
- Potential bugs
- Code complexity issues
- Best practice violations

### 3. Run Unit Tests

Using devtools:

```r
library(devtools)
devtools::test()
```

Or with testthat directly:

```r
library(testthat)
test_dir("tests/testthat")
```

### 4. Build and Check Package

Full R CMD check:

```bash
R CMD build .
R CMD check typethis_*.tar.gz
```

Or with devtools:

```r
devtools::check()
```

### 5. Try the Examples

```r
# Source and run examples
source("examples/basic_usage.R")
source("examples/data_table_examples.R")
source("examples/function_typing.R")
```

### 6. Install and Test Locally

```r
devtools::install()
library(typethis)

# Quick test
x <- 5L
reveal_type(x)
```

## Expected Results

All tests should pass with:
- ✓ 0 errors
- ✓ 0 warnings (style-related warnings are acceptable)
- ✓ All 20+ unit tests passing

## Common Issues

### Issue: data.table tests fail

**Solution**: Install data.table
```r
install.packages("data.table")
```

### Issue: styler not found

**Solution**: Install styler
```r
install.packages("styler")
```

### Issue: lintr not found

**Solution**: Install lintr
```r
install.packages("lintr")
```

## Code Style Guidelines

This package follows the tidyverse style guide:
- 2-space indentation
- snake_case for function names
- <- for assignment (not =)
- Maximum line length: 80 characters
- Spaces around operators
- No trailing whitespace

## Continuous Integration

When CI is set up, these checks will run automatically:
- R CMD check
- testthat tests
- lintr code quality checks
- Code coverage (with covr)
