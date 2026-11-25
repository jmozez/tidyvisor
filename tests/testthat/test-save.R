test_that("tv_save() writes advice and interpretations as text and Markdown", {
  adv <- tv_power("two_groups", delta = 5, sd = 8)
  res <- tidyvisor(lm(mpg ~ wt, data = mtcars))

  txt <- format(adv)
  expect_type(txt, "character")
  expect_true(any(grepl("Needed: 42 samples per group (84 in total)", txt, fixed = TRUE)))

  f <- tempfile(fileext = ".md")
  expect_identical(tv_save(adv, res, file = f), f)
  out <- readLines(f)
  expect_true(any(out == "## `adv`"))
  expect_true(any(out == "## `res`"))
  expect_true(any(grepl("what the results show", out)))

  f2 <- tempfile(fileext = ".txt")
  tv_save(adv, file = f2)
  tv_save(res, file = f2, append = TRUE)
  out2 <- readLines(f2)
  expect_false(any(grepl("^## ", out2)))
  expect_true(any(grepl("how many samples", out2)))
  expect_true(any(grepl("what the results show", out2)))

  expect_error(tv_save(adv), "file")
})

test_that("printed advice reads cleanly", {
  pw <- format(tv_power("two_groups", delta = 5, sd = 8))
  expect_true(any(grepl("Gives an 80% chance", pw, fixed = TRUE)))
  expect_true(any(grepl("half as large: 162 samples per group", pw, fixed = TRUE)))
  expect_identical(tidyvisor:::tv_article(80), "an")
  expect_identical(tidyvisor:::tv_article(90), "a")

  kw <- format(tidyvisor(kruskal.test(count ~ spray, data = InsectSprays)))
  expect_true(any(grepl("(df = 5)", kw, fixed = TRUE)))

  ds <- format(tidyvisor(ChickWeight, question = "design", response = "weight",
                         group = "Diet", unit = "Chick", time = "Time"))
  expect_true(any(grepl("design sound", ds)))
  expect_true(any(grepl("Diet 1: 20", paste(ds, collapse = " "), fixed = TRUE)))

  pr <- format(tv_practice("plan", design = "experiment"))
  expect_true(any(grepl("good research practice", pr)))
  expect_true(any(grepl("delta = <difference to detect>", pr, fixed = TRUE)))
})
