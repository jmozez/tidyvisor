test_that("a package can register an adviser and it is used", {
  old <- tidyvisor:::tv_env$advisors
  withr::defer(assign("advisors", old, envir = tidyvisor:::tv_env))
  # "stats" stands in for an installed package
  register_advisor(
    package = "stats", questions = "toy",
    classes = "toy_fit",
    advise = function(x, ...) structure(list(n = nrow(x)), class = "toy_advice"),
    interpret = function(x, ...) "toy interpretation",
    claims = function(x, args) "toy_col" %in% names(x)
  )
  expect_true("stats" %in% advisors()$package)
  expect_s3_class(advise(data.frame(a = 1), question = "toy"), "toy_advice")
  expect_s3_class(tidyvisor(data.frame(toy_col = 1:3)), "toy_advice")
  expect_identical(tidyvisor(structure(list(), class = "toy_fit")), "toy interpretation")
})

test_that("errors say what is available", {
  expect_error(interpret(structure(list(), class = "nobody_knows")), "No adviser")
  expect_error(advise(data.frame(a = 1), question = "no such question"), "question")
  expect_error(advise(1:3), "data frame")
})

test_that("the built-in advisers are listed", {
  a <- advisors()
  expect_true(all(c("tidydiversity", "tidymapr") %in% a$package))
  expect_true("explain" %in% a$questions[[which(a$package == "tidydiversity")]])
  expect_true("epidemic" %in% a$questions[[which(a$package == "tidymapr")]])
})
