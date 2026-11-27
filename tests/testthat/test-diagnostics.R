test_that("tv_check_model() passes a correct model and flags overdispersion", {
  set.seed(5)
  x <- stats::rnorm(200)
  y <- stats::rpois(200, exp(0.5 + 0.4 * x))
  good <- tv_check_model(stats::glm(y ~ x, family = stats::poisson), seed = 2)
  expect_s3_class(good, "tv_advice")
  expect_true(all(good$tests$p_value > 0.05, na.rm = TRUE))
  expect_equal(nrow(good$residuals), 200)
  expect_true(all(good$residuals$scaled > 0 & good$residuals$scaled < 1))
  y2 <- stats::rnbinom(200, mu = exp(0.5 + 0.4 * x), size = 0.5)
  bad <- tv_check_model(stats::glm(y2 ~ x, family = stats::poisson), seed = 2)
  disp <- bad$tests[bad$tests$test == "dispersion", ]
  expect_gt(disp$statistic, 1.5)
  expect_lt(disp$p_value, 0.05)
  expect_true(any(grepl("Overdispersion", bad$advice$step)))
})

test_that("scaled residuals are uniform for a correct model", {
  set.seed(1)
  sim <- matrix(stats::rpois(500 * 200, 3), 500)
  y <- stats::rpois(500, 3)
  r <- tv_scaled_residuals(y, sim)
  expect_gt(stats::ks.test(r, "punif")$p.value, 0.01)
})

test_that("tv_check_model() works for lm and binomial models and is reproducible", {
  a <- tv_check_model(stats::lm(mpg ~ wt, mtcars), seed = 1)
  b <- tv_check_model(stats::lm(mpg ~ wt, mtcars), seed = 1)
  expect_identical(a$residuals, b$residuals)
  expect_true(is.na(a$tests$p_value[a$tests$test == "zero_inflation"]))
  fit <- stats::glm(cbind(ncases, ncontrols) ~ agegp, data = esoph, family = stats::binomial)
  e <- tv_check_model(fit, seed = 1)
  expect_equal(nrow(e$residuals), nrow(esoph))
  expect_error(tv_check_model(fit, nsim = 2), "nsim")
})

# Reference values from EValue 4.1 (evalues.RR, evalues.OR, evalues.HR,
# evalues.MD).
test_that("tv_evalue() matches the EValue package", {
  e <- tv_evalue(3.9, 1.8, 8.7)
  expect_equal(e$evalue, 7.263034, tolerance = 1e-6)
  expect_equal(e$evalue_ci, 3)
  o <- tv_evalue(1.6, 1.1, 2.3, type = "or")
  expect_equal(c(o$evalue, o$evalue_ci), c(1.843780, 1.275063), tolerance = 1e-6)
  h <- tv_evalue(0.7, 0.55, 0.9, type = "hr")
  expect_equal(c(h$evalue, h$evalue_ci), c(1.8786855, 1.3612206), tolerance = 1e-6)
  expect_equal(tv_evalue(0.5, type = "smd")$evalue, 2.529142, tolerance = 1e-6)
  expect_equal(tv_evalue(2, 0.9, 4)$evalue_ci, 1)
  expect_equal(tv_evalue(2, type = "or", rare = TRUE)$evalue, 2 + sqrt(2))
  expect_error(tv_evalue(-1), "positive")
})

test_that("tv_equivalence() runs two one-sided tests", {
  x <- sleep$extra[1:10]
  y <- sleep$extra[11:20]
  q <- tv_equivalence(x, y, low = -0.5, high = 0.5, paired = TRUE)
  expect_false(q$result$equivalent)
  ref <- stats::t.test(x, y, paired = TRUE, mu = -0.5, alternative = "greater")
  expect_equal(q$result$p_lower, ref$p.value)
  expect_equal(q$result$p_tost, max(q$result$p_lower, q$result$p_upper))
  set.seed(3)
  a <- stats::rnorm(400, 10, 1)
  b <- stats::rnorm(400, 10.02, 1)
  w <- tv_equivalence(a, b, low = -0.3, high = 0.3)
  expect_true(w$result$equivalent)
  expect_true(w$result$lower > -0.3 && w$result$upper < 0.3)
  expect_match(w$advice$recommendation[1], "Equivalent")
  expect_error(tv_equivalence(a, b, low = 1, high = 0), "below")
})
