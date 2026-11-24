test_that("advice picks the family from the kind of response", {
  a <- tidyvisor(warpbreaks, question = "regression", response = "breaks")
  expect_s3_class(a, "tv_advice")
  # warp-break counts are overdispersed (variance / mean about 6)
  expect_match(a$advice$recommendation[1], "glm.nb")
  expect_match(a$advice$code[1], "breaks ~ wool \\+ tension")

  b <- tidyvisor(mtcars, question = "regression", response = "am", predictors = "wt")
  expect_match(b$advice$code[1], "family = binomial")

  g <- tidyvisor(mtcars, question = "regression", response = "mpg", predictors = c("wt", "hp"))
  expect_match(g$advice$code[1], "^m <- lm\\(")

  # collinear predictors are flagged (disp and cyl, r = 0.90)
  cl <- tidyvisor(mtcars, question = "regression", response = "mpg", predictors = c("disp", "cyl"))
  expect_match(paste(cl$checks$value, collapse = " "), "disp")

  # successes out of trials
  d <- data.frame(dead = c(1, 4, 9, 13, 18, 20), n = 20, dose = 1:6)
  p <- tidyvisor(d, question = "regression", response = "dead", predictors = "dose", trials = "n")
  expect_match(p$advice$code[1], "cbind\\(dead, n - dead\\)")

  expect_error(advise(mtcars, question = "regression"), "response")
})

test_that("a Poisson glm is explained on the rate-ratio scale, matching R", {
  m <- glm(breaks ~ wool + tension, family = poisson, data = warpbreaks)
  i <- tidyvisor(m)
  expect_s3_class(i, "tv_interpretation")
  ci <- exp(confint.default(m))
  expect_match(i$sections$Effects[1], sprintf("%.3f", exp(coef(m))[["woolB"]]), fixed = TRUE)
  ci_txt <- sprintf("%.3f to %.3f", ci["woolB", 1], ci["woolB", 2])
  expect_match(i$sections$Effects[1], ci_txt, fixed = TRUE)
  d2 <- 1 - m$deviance / m$null.deviance
  expect_match(i$sections$Fit[1], sprintf("%.1f%%", 100 * d2), fixed = TRUE)
  expect_match(paste(i$sections$Diagnostics, collapse = " "), "Overdispersion")
})

test_that("a linear model reports R-squared and intervals matching confint()", {
  l <- lm(mpg ~ wt + hp, data = mtcars)
  i <- tidyvisor(l)
  ci <- confint(l)
  expect_match(i$sections$Fit[1], sprintf("%.1f%%", 100 * summary(l)$r.squared), fixed = TRUE)
  lo <- formatC(ci["wt", 1], digits = 3, format = "fg", flag = "#")
  expect_match(i$sections$Effects[1], lo, fixed = TRUE)
  expect_match(paste(i$sections$Diagnostics, collapse = " "), "Breusch-Pagan")
})

test_that("a logistic glm is explained with odds ratios of the named outcome", {
  b <- glm(am ~ wt, family = binomial, data = mtcars)
  i <- tidyvisor(b)
  expect_match(i$sections$Effects[1], "odds of am = 1")
  or <- formatC(exp(coef(b))[["wt"]], digits = 3, format = "fg", flag = "#")
  expect_match(i$sections$Effects[1], or, fixed = TRUE)
})

test_that("the Breusch-Pagan statistic matches the textbook formula", {
  set.seed(1)
  x <- runif(200)
  y <- 1 + x + rnorm(200, sd = 0.2 + 2 * x) # variance grows with x
  bp <- tidyvisor:::tv_breusch_pagan(lm(y ~ x))
  expect_lt(bp$p, 0.001)
  e2 <- residuals(lm(y ~ x))^2
  expect_equal(bp$stat, 200 * summary(lm(e2 ~ x))$r.squared)
})
