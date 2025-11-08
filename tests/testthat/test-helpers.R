test_that("typing_presets returns valid structure", {
  presets <- typing_presets()
  expect_type(presets, "list")
  expect_true("human" %in% names(presets))
  expect_true("fast" %in% names(presets))
  expect_true("slow" %in% names(presets))
})

test_that("set_typing_speed changes global option", {
  old_speed <- set_typing_speed(20)
  expect_equal(getOption("typethis.speed"), 20)
  # Restore
  set_typing_speed(old_speed)
})

test_that("get_typing_speed retrieves current speed", {
  set_typing_speed(15)
  expect_equal(get_typing_speed(), 15)
})

test_that("type_line works", {
  expect_silent(type_line("test", speed = 100))
})

test_that("type_lines handles multiple lines", {
  expect_silent(type_lines(c("a", "b", "c"), speed = 100, delay_between = 0))
})

test_that("type_code works", {
  expect_silent(type_code("x <- 1", speed = 100))
})

test_that("type_effect works with presets", {
  expect_silent(type_effect("error", effect = "error", custom_speed = 100))
  expect_silent(type_effect("warning", effect = "warning", custom_speed = 100))
  expect_silent(type_effect("success", effect = "success", custom_speed = 100))
})
