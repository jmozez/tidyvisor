test_that("a significant overall test leads to post hoc comparisons", {
  kw <- tidyvisor(kruskal.test(count ~ spray, data = InsectSprays))
  after <- kw$sections$`After the overall test`
  expect_match(after[1], "6 groups are not all alike")
  expect_true(any(grepl("pairwise.wilcox.test(data$count, data$spray", after, fixed = TRUE)))

  aov1 <- tidyvisor(oneway.test(weight ~ group, data = PlantGrowth))
  after1 <- aov1$sections$`After the overall test`
  expect_true(any(grepl("TukeyHSD(aov(weight ~ group", after1, fixed = TRUE)))
})

test_that("a non-significant overall test stops post hoc fishing", {
  pg <- subset(PlantGrowth, group != "trt2")
  same <- rbind(pg, transform(pg[pg$group == "ctrl", ], group = "x"))
  kw <- tidyvisor(kruskal.test(weight ~ group, data = same))
  after <- kw$sections$`After the overall test`
  expect_true(any(grepl("Do not go on to pairwise", after)))
})

test_that("two groups need no post hoc tests", {
  tt <- tidyvisor(t.test(extra ~ group, data = sleep))
  expect_match(tt$sections$`After the overall test`[1], "no post hoc tests are needed")
  two <- droplevels(subset(PlantGrowth, group != "ctrl"))
  kw2 <- tidyvisor(kruskal.test(weight ~ group, data = two))
  expect_match(kw2$sections$`After the overall test`[1], "no post hoc tests are needed")
})

test_that("models compare the levels of a significant factor, within an interaction if needed", {
  m <- lm(weight ~ group, data = PlantGrowth)
  after <- tidyvisor(m)$sections$`After the overall test`
  expect_match(after[1], "group \\(3 levels\\) has an overall effect")
  expect_true(any(grepl("emmeans::emmeans(m, pairwise ~ group)", after, fixed = TRUE)))

  tg <- tidyvisor(lm(len ~ factor(dose) * supp, data = ToothGrowth))
  tg <- tg$sections$`After the overall test`
  expect_match(tg[1], "interacts with supp")
  expect_true(any(grepl("pairwise ~ dose | supp", tg, fixed = TRUE)))

  expect_null(tidyvisor(lm(mpg ~ wt + hp, data = mtcars))$sections$`After the overall test`)
  expect_s3_class(tidyvisor(aov(weight ~ group, data = PlantGrowth)), "tv_interpretation")
})

test_that("a non-significant factor is not followed by pairwise comparisons", {
  set.seed(1)
  d <- data.frame(y = rnorm(30), g = gl(3, 10))
  after <- tidyvisor(lm(y ~ g, data = d))$sections$`After the overall test`
  expect_match(after[1], "no overall effect")
  expect_match(after[1], "do not go on to pairwise")
})
