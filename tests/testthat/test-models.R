test_that("lme4: advice checks the grouping factor and gives lmer code", {
  skip_if_not_installed("lme4")
  a <- tidyvisor(lme4::sleepstudy, response = "Reaction", predictors = "Days", random = "Subject")
  expect_match(a$advice$code[1], "lme4::lmer\\(Reaction ~ Days \\+ \\(1 \\| Subject\\)")
  expect_true(any(grepl("Levels of Subject", a$checks$check)))
  few <- data.frame(y = rnorm(40), x = rnorm(40), g = rep(letters[1:3], length.out = 40))
  b <- advise(few, question = "mixed", response = "y", predictors = "x", random = "g")
  expect_match(paste(b$advice$recommendation, collapse = " "), "fixed effects")
})

test_that("lme4: interpretation matches Wald intervals and reports the ICC", {
  skip_if_not_installed("lme4")
  m <- lme4::lmer(Reaction ~ Days + (1 | Subject), data = lme4::sleepstudy)
  i <- tidyvisor(m)
  ci <- confint(m, method = "Wald")["Days", ]
  expect_match(i$sections$Effects[1], sprintf("%.2f to %.1f", ci[1], ci[2]), fixed = TRUE)
  vc <- as.data.frame(lme4::VarCorr(m))$vcov
  re <- paste(i$sections$`Random effects`, collapse = " ")
  expect_match(re, sprintf("%.2f", vc[1] / sum(vc)), fixed = TRUE)

  g <- lme4::glmer(cbind(incidence, size - incidence) ~ period + (1 | herd),
    data = lme4::cbpp, family = binomial
  )
  gi <- tidyvisor(g)
  or <- formatC(exp(lme4::fixef(g))[["period2"]], digits = 3, format = "fg", flag = "#")
  expect_match(gi$sections$Effects[1], or, fixed = TRUE)
  expect_match(gi$sections$Effects[1], "odds of incidence")
})

test_that("glmmTMB: zero-inflated advice and interpretation", {
  skip_if_not_installed("glmmTMB")
  sal <- glmmTMB::Salamanders
  a <- advise(sal,
    question = "zero_inflation", response = "count",
    predictors = "mined", random = "site"
  )
  expect_match(a$advice$code[1], "ziformula = ~1")
  expect_match(a$advice$code[1], "nbinom2")
  p <- glmmTMB::glmmTMB(count ~ mined + (1 | site), family = poisson, data = sal)
  d <- paste(tidyvisor(p)$sections$Diagnostics, collapse = " ")
  expect_match(d, "Overdispersion")
  expect_match(d, "zero-inflated")
  z <- glmmTMB::glmmTMB(count ~ mined + (1 | site),
    ziformula = ~1, family = glmmTMB::nbinom2, data = sal
  )
  zi <- tidyvisor(z)
  expect_match(paste(zi$sections$Diagnostics, collapse = " "), "structural")
  rr <- sprintf("%.2f", exp(glmmTMB::fixef(z)$cond[["minedno"]]))
  expect_match(zi$sections$Effects[1], rr, fixed = TRUE)
})

test_that("mgcv: smooths are described by their edf", {
  skip_if_not_installed("mgcv")
  set.seed(2)
  d <- mgcv::gamSim(1, n = 400, verbose = FALSE, scale = 2)
  a <- tidyvisor(d[c("y", "x0", "x2")], response = "y", smooth = c("x0", "x2"))
  expect_match(a$advice$code[1], "mgcv::gam\\(y ~ s\\(x0\\) \\+ s\\(x2\\)")
  m <- mgcv::gam(y ~ s(x0) + s(x2) + s(x3), data = d, method = "REML")
  i <- tidyvisor(m)
  expect_s3_class(i, "tv_interpretation")
  edf <- summary(m)$s.table[, "edf"]
  expect_match(i$sections$Smooths[2], sprintf("%.2f", edf[2]), fixed = TRUE)
  expect_match(i$sections$Smooths[3], "straight line")
  expect_match(i$sections$Fit, sprintf("%.1f%%", 100 * summary(m)$dev.expl), fixed = TRUE)
})

test_that("aods3: beta-binomial advice and interpretation", {
  skip_if_not_installed("aods3")
  data("orob2", package = "aods3")
  a <- advise(orob2,
    question = "overdispersion", response = "m", trials = "n",
    predictors = c("seed", "root")
  )
  expect_match(a$advice$code[1], "family = \"bb\"")
  expect_true(any(grepl("dispersion", a$checks$check)))
  m <- aods3::aodml(cbind(m, n - m) ~ seed + root, data = orob2, family = "bb")
  i <- tidyvisor(m)
  or <- sprintf("%.2f", exp(coef(m))[["rootCUCUMBER"]])
  expect_match(i$sections$Effects[2], or, fixed = TRUE)
  expect_match(i$sections$Overdispersion[1], "phi")
})

test_that("the most specific advisor interprets a model", {
  skip_if_not_installed("mgcv")
  m <- mgcv::gam(mpg ~ s(wt), data = mtcars)
  expect_true("Smooths" %in% names(interpret(m)$sections))
})
