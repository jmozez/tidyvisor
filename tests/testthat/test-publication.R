test_that("tests come with a Results sentence, a figure and a table for the paper", {
  kw <- tidyvisor(kruskal.test(count ~ spray, data = InsectSprays))
  pub <- kw$sections$`For the paper`
  expect_match(pub[1], "count differed among levels of spray")
  expect_match(pub[1], "H\\(5\\) = 54.7, p < 0.001")
  expect_true(any(grepl("ggplot2::aes(spray, count)", pub, fixed = TRUE)))
  expect_true(any(grepl("ggsave", pub)))
  expect_true(any(grepl("^Table:", pub)))

  ns <- tidyvisor(t.test(extra ~ group, data = sleep))$sections$`For the paper`
  expect_match(ns[1], "did not differ detectably")

  r <- tidyvisor(cor.test(~ mpg + wt, data = mtcars))$sections$`For the paper`
  expect_match(r[1], "r = -0.868")

  sw <- tidyvisor(shapiro.test(mtcars$mpg))$sections$`For the paper`
  expect_match(sw[1], "Assumption checks are not results")
})

test_that("models are reported with factor levels and ratios in words", {
  pg <- tidyvisor(lm(weight ~ group, data = PlantGrowth))$sections$`For the paper`
  expect_true(any(grepl("for group = trt2 than for group = ctrl", pg, fixed = TRUE)))
  expect_true(any(grepl("gtsummary::tbl_regression(m)", pg, fixed = TRUE)))

  ps <- tidyvisor(glm(count ~ spray, poisson, InsectSprays))$sections$`For the paper`
  expect_true(any(grepl("times as high for spray = C as for spray = A", ps, fixed = TRUE)))
  expect_true(any(grepl("exponentiate = TRUE", ps, fixed = TRUE)))

  lg <- tidyvisor(glm(am ~ wt, binomial, mtcars))$sections$`For the paper`
  expect_true(any(grepl("The odds of am were multiplied by", lg, fixed = TRUE)))
})

test_that("tv_practice('report') covers figures, tables and statistics", {
  rep <- tv_practice("report")$advice$recommendation
  expect_true(any(grepl("journal's specification", rep)))
  expect_true(any(grepl("tables lean", rep)))
  expect_true(any(grepl("statistical result in full", rep)))
})
