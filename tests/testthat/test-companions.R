test_that("tidydiversity data and results go to tidydiversity", {
  skip_if_not_installed("tidydiversity")
  skip_if_not_installed("vegan")
  frogs <- tidydiversity::png_frogs
  expect_s3_class(tidyvisor(frogs, abundance = abundance), "td_ord_advice")
  ord <- tidydiversity::ord_fit(frogs,
    abundance = abundance, method = "pca", transform = "hellinger"
  )
  expect_s3_class(tidyvisor(ord), "td_ord_interpretation")
})

test_that("tidymapr data and results go to tidymapr", {
  skip_if_not_installed("tidymapr")
  cases <- data.frame(
    week = seq(as.Date("2024-01-01"), by = "week", length.out = 12),
    n = c(2, 3, 5, 4, 9, 12, 15, 24, 30, 41, 60, 77)
  )
  expect_s3_class(
    tidyvisor(cases, question = "epidemic", date = "week", cases = "n"),
    "tmr_advice"
  )
  g <- tidymapr::epi_growth_rate(cases, date = week, cases = n, unit = "week")
  expect_s3_class(tidyvisor(g), "tmr_interpretation")
})

test_that("epidemiological data and results go to tidyepidemio", {
  skip_if_not_installed("tidyepidemio")
  skip_if_not(exists("tep_advise", asNamespace("tidyepidemio")))
  d <- data.frame(exposure = rep(0:1, each = 40), outcome = rep(c(0, 1, 0, 1), c(30, 10, 18, 22)))
  expect_s3_class(tidyvisor(d, exposure = "exposure", outcome = "outcome"), "tep_advice")
  rr <- tidyepidemio::epi_risk_ratio(d, exposure, outcome)
  expect_s3_class(tidyvisor(rr), "tep_interpretation")
  counts <- data.frame(day = 1:8, cases = c(2, 3, 5, 8, 12, 20, 31, 50))
  expect_s3_class(
    tidyvisor(counts, question = "outbreak", time = "day", cases = "cases"),
    "tep_advice"
  )
})
