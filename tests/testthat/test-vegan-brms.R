test_that("vegan: advice uses the gradient length and the design", {
  skip_if_not_installed("vegan")
  data("dune", "dune.env", package = "vegan")
  d <- cbind(dune, dune.env)
  a <- advise(d, question = "vegan", env = c("A1", "Management"))
  expect_true(any(grepl("Gradient length", a$checks$check)))
  rda_code <- "rda\\(vegan::decostand\\(comm, \"hellinger\"\\) ~ A1 \\+ Management"
  expect_match(a$advice$code[1], rda_code)
  expect_true(any(grepl("betadisper", a$advice$code)))
  u <- advise(dune, question = "vegan")
  expect_match(u$advice$code[1], "metaMDS")
})

test_that("vegan: results are explained with the numbers vegan reports", {
  skip_if_not_installed("vegan")
  data("dune", "dune.env", package = "vegan")
  set.seed(1)
  m <- vegan::metaMDS(dune, trace = 0)
  i <- tidyvisor(m)
  expect_match(i$sections$Fit[1], sprintf("%.3f", m$stress), fixed = TRUE)

  r <- vegan::rda(vegan::decostand(dune, "hellinger") ~ A1 + Management, dune.env)
  ri <- tidyvisor(r, permutations = 99)
  expect_match(ri$sections$Fit[1], sprintf("%.1f%%", 100 * r$CCA$tot.chi / r$tot.chi), fixed = TRUE)
  adj <- sprintf("%.1f%%", 100 * vegan::RsquareAdj(r)$adj.r.squared)
  expect_match(ri$sections$Fit[1], adj, fixed = TRUE)
  expect_length(ri$sections$Tests, 3)

  a <- vegan::adonis2(dune ~ Management, dune.env, permutations = 99)
  ai <- tidyvisor(a)
  expect_match(ai$sections$Tests[1], sprintf("%.1f%%", 100 * a$R2[1]), fixed = TRUE)

  b <- vegan::betadisper(vegan::vegdist(dune), dune.env$Management)
  bi <- tidyvisor(b)
  expect_match(bi$sections$Dispersion[2], sprintf("%.2f", anova(b)$`F value`[1]), fixed = TRUE)
})

test_that("brms: advice chooses the family and gives prior checks", {
  skip_if_not_installed("brms")
  a <- advise(mtcars, question = "bayesian", response = "am", predictors = "wt")
  expect_match(a$advice$code[1], "family = bernoulli\\(\\)")
  expect_match(a$advice$code[2], "sample_prior = \"only\"")
  d <- data.frame(dead = c(1, 4, 9, 13, 18, 20), n = 20, dose = 1:6)
  b <- advise(d, question = "bayesian", response = "dead", trials = "n", predictors = "dose")
  expect_match(b$advice$code[1], "dead \\| trials\\(n\\)")
})

test_that("brms: a fit is explained and its poor convergence flagged", {
  skip_if_not_installed("brms")
  # 2 short chains: deliberately too few draws, so R-hat and ESS are poor
  f <- readRDS(test_path("fixtures", "brm_epilepsy.rds"))
  i <- tidyvisor(f)
  fe <- brms::fixef(f)
  expect_match(i$sections$Effects[2], sprintf("%.3f", exp(fe["Trt1", 1])), fixed = TRUE)
  expect_match(i$sections$Effects[2], "probability of a decrease")
  expect_match(i$sections$`Group-level effects`[1], "patient")
  d <- paste(i$sections$`Sampling diagnostics`, collapse = " ")
  expect_match(d, "should be below 1.01")
  expect_match(d, "should exceed 400")
})

test_that("the gradient-length rule follows CANOCO: longest DCA axis, 3 and 4 SD", {
  skip_if_not_installed("vegan")
  data("dune", package = "vegan")
  dca <- vegan::decorana(log1p(as.matrix(dune)))
  sc <- vegan::scores(dca, display = "sites", choices = 1:4)
  longest <- max(apply(sc, 2, function(a) diff(range(a))))
  expect_equal(tidyvisor:::tv_gradient_length(as.matrix(dune)), longest)
  expect_match(tidyvisor:::tv_gradient_rule(2.99), "below 3 SD.*linear")
  expect_match(tidyvisor:::tv_gradient_rule(3), "between 3 and 4 SD")
  expect_match(tidyvisor:::tv_gradient_rule(4), "between 3 and 4 SD")
  expect_match(tidyvisor:::tv_gradient_rule(4.01), "above 4 SD.*unimodal")
})
