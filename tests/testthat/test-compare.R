test_that("compare advice follows the checks", {
  a <- advise(InsectSprays, response = "count", group = "spray")
  expect_s3_class(a, "tv_advice")
  expect_match(a$advice$recommendation[a$advice$step == "Test"], "GLM for counts")
  b <- advise(sleep, response = "extra", group = "group")
  expect_match(b$advice$recommendation[b$advice$step == "Test"], "t-test")
  expect_true(any(grepl("wilcox.test", b$advice$code)))
  set.seed(1)
  skewed <- data.frame(y = c(rlnorm(30), rlnorm(30, 1, 1)), g = rep(c("a", "b"), each = 30))
  s <- advise(skewed, response = "y", group = "g")
  expect_match(s$advice$recommendation[s$advice$step == "Test"], "Log-transform")
  out <- data.frame(y = c(rnorm(20), 15, rnorm(20, 1)), g = rep(c("a", "b"), c(21, 20)))
  o <- advise(out, response = "y", group = "g")
  expect_match(o$advice$recommendation[o$advice$step == "Test"], "trimmed")
  expect_error(advise(sleep, response = "extra", group = "nope"), "Unknown column")
})

test_that("paired comparisons use the differences", {
  a <- advise(sleep, response = "extra", group = "group", paired = "ID")
  expect_true(any(a$checks$check == "Complete pairs"))
  expect_match(a$advice$code[a$advice$step == "Test"], "order\\(ID\\)")
  expect_true(any(grepl("paired = TRUE", a$advice$code)))
})

test_that("htest results are explained with next steps", {
  k <- tidyvisor(kruskal.test(count ~ spray, data = InsectSprays))
  expect_s3_class(k, "tv_interpretation")
  expect_true(any(grepl("pairwise.wilcox", k$sections$`What to do next`)))
  sw <- interpret(shapiro.test(InsectSprays$count))
  expect_true(any(grepl("log transformation", sw$sections$`What to do next`)))
  tt <- interpret(t.test(extra ~ group, data = sleep))
  expect_match(tt$sections$Meaning[1], "means")
  ct <- interpret(cor.test(~ mpg + wt, data = mtcars))
  expect_true(any(grepl("spearman", ct$sections$`What to do next`)))
})

test_that("lm interpretation says what to do when assumptions fail", {
  m <- lm(count ~ spray, data = InsectSprays)
  nx <- interpret(m)$sections$`What to do next`
  expect_true(any(grepl("negative binomial", nx)))
  set.seed(2)
  d <- data.frame(x = runif(80, 1, 10))
  d$y <- exp(0.3 * d$x + rnorm(80, 0, 0.6))
  nx2 <- interpret(lm(y ~ x, data = d))$sections$`What to do next`
  expect_true(any(grepl("log\\(y\\)", nx2)))
  ok <- interpret(lm(mpg ~ wt, data = mtcars))$sections$`What to do next`
  expect_type(ok, "character")
})

test_that("regression advice is unchanged without a group", {
  a <- advise(mtcars, response = "mpg", predictors = "wt")
  expect_identical(a$question, "regression")
})

test_that("power analysis gives sizes and sensitivity", {
  p <- tv_power("two_groups", delta = 5, sd = 8)
  expect_equal(p$n, ceiling(power.t.test(delta = 5, sd = 8, power = 0.8)$n))
  expect_true(any(p$checks$check == "If the effect is half as large"))
  s <- tv_power("sites", delta = 5, sd = 8, icc = 0.2, per_site = 5)
  expect_gt(s$n * 5, p$n)
  expect_match(s$advice$recommendation[2], "more sites")
  for (d in list(
    list("counts", mean1 = 4, ratio = 1.5, theta = 2),
    list("groups", means = c(10, 12, 14), sd = 5),
    list("proportions", p1 = 0.2, p2 = 0.4),
    list("regression", r2 = 0.1, predictors = 3),
    list("correlation", r = 0.3),
    list("paired", delta = 2, sd = 4)
  )) {
    expect_gt(do.call(tv_power, d)$n, 1)
  }
  expect_error(tv_power("two_groups", delta = 5), "needs")
})

test_that("power from pilot data", {
  a <- advise(PlantGrowth, question = "power", response = "weight", group = "group", delta = 0.5)
  expect_identical(a$question, "power")
  expect_match(a$checks$meaning[1], "SD")
  expect_error(advise(PlantGrowth, question = "power", response = "weight"), "effect")
  c <- advise(InsectSprays, question = "power", response = "count", ratio = 1.5)
  expect_true(any(grepl("counts", c$checks$value)))
})
