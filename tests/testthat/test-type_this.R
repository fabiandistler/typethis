test_that("type_this works with basic input", {
  # Should complete without error
  expect_silent(type_this("test", speed = 100, newline = FALSE))
})

test_that("type_this handles speed presets", {
  expect_silent(type_this("test", speed = "fast", newline = FALSE))
  expect_silent(type_this("test", speed = "slow", newline = FALSE))
  expect_silent(type_this("test", speed = "human", newline = FALSE))
})

test_that("calc_delay returns reasonable values", {
  delay <- calc_delay(10, 0.3)
  expect_true(delay > 0)
  expect_true(delay < 1)
})

test_that("type_this handles empty string", {
  expect_silent(type_this("", speed = 100))
})

test_that("type_this handles multiple lines", {
  expect_silent(type_this(c("line1", "line2"), speed = 100))
})

test_that("style_text works with colors", {
  styled <- style_text("test", color = "red")
  expect_type(styled, "character")
})

test_that("style_text works with styles", {
  styled <- style_text("test", style = "bold")
  expect_type(styled, "character")
})
