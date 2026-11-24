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
