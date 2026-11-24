test_that("practice checklists by stage, design and field", {
  p <- tv_practice("plan", design = "experiment")
  expect_s3_class(p, "tv_advice")
  expect_true(any(grepl("Randomise", p$advice$recommendation)))
  expect_false(any(grepl("confounders", p$advice$recommendation)))
  expect_match(tv_practice("report", field = "sdm")$advice$reason[1], "ODMAP")
  expect_match(tv_practice("report", field = "animal")$advice$reason[1], "ARRIVE")
  expect_match(tv_practice("report", field = "trial")$advice$reason[1], "CONSORT")
  expect_match(tv_practice("report", field = "basket weaving")$advice$reason[1], "EQUATOR")
  expect_gt(nrow(tv_practice()$advice), nrow(p$advice))
})

test_that("design audit finds pseudoreplication and confounding", {
  a <- advise(ChickWeight, question = "design", response = "weight",
              group = "Diet", unit = "Chick", time = "Time")
  expect_true(any(grepl("pseudoreplicates", a$advice$reason)))
  expect_true(any(grepl("lmer", a$advice$code)))
  d <- data.frame(
    y = rnorm(12), trt = rep(c("a", "b"), each = 6),
    year = rep(c(2020, 2021), each = 6)
  )
  b <- advise(d, question = "design", response = "y", group = "trt", time = "year")
  expect_true(any(grepl("confounded", b$advice$recommendation)))
  m <- advise(airquality, question = "design", response = "Ozone")
  expect_match(m$checks$value[m$checks$check == "Missing values"], "Ozone")
  expect_error(advise(iris, question = "design", response = "nope"), "Unknown column")
})

test_that("tidyvisor always answers with the audit as fallback", {
  a <- tidyvisor(iris)
  expect_identical(a$question, "design")
})
