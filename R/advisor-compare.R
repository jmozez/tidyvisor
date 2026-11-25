# nolint start: line_length_linter. Tables and advice sentences read better unbroken.

#' Advisor for comparing groups: assumptions and what to do when they fail
#'
#' @description
#' Built-in advisor for comparing a numeric response between groups: the
#' t-test, one-way ANOVA and their alternatives in base R.
#'
#' * **Before** (`question = "compare"`): checks the assumptions of the
#'   classical tests in each group (normality, equal spread, outliers,
#'   skewness, whether the spread grows with the mean) and recommends the
#'   test those checks support, with the code, and the alternatives:
#'
#'   | What the checks show | Recommendation |
#'   |---|---|
#'   | roughly normal, equal spread | Student t-test or one-way ANOVA |
#'   | roughly normal, unequal spread | Welch t-test or Welch ANOVA (`oneway.test()`) |
#'   | positive, right-skewed, spread grows with the mean | log-transform, then Welch (compares geometric means) |
#'   | outliers or heavy tails | robust test on trimmed means (Yuen; `WRS2`) |
#'   | counts with unequal spread | Poisson or negative binomial GLM |
#'   | otherwise non-normal, or very small groups | rank test: Wilcoxon or Kruskal-Wallis, or a permutation test |
#'
#'   With `paired`, the checks are on the within-pair differences and the
#'   tests are their paired versions (paired t, Wilcoxon signed-rank).
#' * **After**: explains any classical test result (`htest`: from
#'   [stats::t.test()], [stats::wilcox.test()], [stats::kruskal.test()],
#'   [stats::oneway.test()], [stats::shapiro.test()], [stats::cor.test()],
#'   [stats::chisq.test()] and others): what was tested, the statistic, the
#'   p-value, the estimate and its interval, what the test does not show,
#'   and what to do next.
#'
#' Assumption tests answer "can the data rule out the assumption?", not
#' "does the violation matter?": with large groups they flag trivial
#' departures, with small groups they miss large ones. The advice therefore
#' weighs them together with the skewness, the ratio of spreads and the
#' group sizes, and always says to look at the plot.
#'
#' @param x A data frame (advice) or an `htest` object (interpretation).
#' @param question The question; set by [advise()].
#' @param response Name of the numeric response column.
#' @param group Name of the grouping column (two or more groups).
#' @param paired Optional name of a column identifying the pairs (or
#'   blocks) for repeated measurements on the same units; two groups only.
#' @param ... Ignored.
#' @return A `tv_advice` or a `tv_interpretation` object.
#' @references
#' Delacre, M., Lakens, D. and Leys, C. (2017). Why psychologists should by
#' default use Welch's t-test instead of Student's t-test. *International
#' Review of Social Psychology* 30, 92-101.
#'
#' Fagerland, M. W. (2012). t-tests, non-parametric tests, and large
#' studies: a paradox of statistical practice? *BMC Medical Research
#' Methodology* 12, 78.
#'
#' O'Hara, R. B. and Kotze, D. J. (2010). Do not log-transform count data.
#' *Methods in Ecology and Evolution* 1, 118-122.
#'
#' Wilcox, R. R. (2017). *Introduction to Robust Estimation and Hypothesis
#' Testing*, fourth edition. Academic Press.
#' @name compare-advisor
#' @examples
#' tidyvisor(InsectSprays, response = "count", group = "spray")
#' tidyvisor(kruskal.test(count ~ spray, data = InsectSprays))
NULL

#' @rdname compare-advisor
#' @export
tv_advise_compare <- function(x, question = "compare", response, group, paired = NULL, ...) {
  for (a in c(response, group, paired)) {
    if (!a %in% names(x)) cli::cli_abort("Unknown column {.field {a}}.")
  }
  cols <- c(response, group, paired)
  d <- x[stats::complete.cases(x[cols]), cols, drop = FALSE]
  y <- d[[response]]
  if (!is.numeric(y)) cli::cli_abort("{.arg response} must be numeric; for counts of categories use a chi-squared test.")
  g <- droplevels(factor(d[[group]]))
  k <- nlevels(g)
  if (k < 2) cli::cli_abort("{.arg group} needs at least two groups.")
  if (!is.null(paired) && k != 2) cli::cli_abort("{.arg paired} works with two groups; for more, use a mixed model ({.code question = \"mixed\"}).")

  acc <- new.env()
  acc$checks <- list(tv_check("Groups", k, paste(sprintf("%s (n = %d)", levels(g), tabulate(g)), collapse = ", ")))
  add <- function(check, value, meaning = "") {
    acc$checks[[length(acc$checks) + 1]] <- tv_check(check, value, meaning)
  }

  # The data the assumptions are about: residuals from the group means, or
  # within-pair differences
  if (!is.null(paired)) {
    w <- stats::reshape(data.frame(id = d[[paired]], g = g, y = y), idvar = "id", timevar = "g", direction = "wide")
    w <- w[stats::complete.cases(w), ]
    dif <- w[[3]] - w[[2]]
    add("Complete pairs", length(dif), if (length(dif) < nrow(d) / 2) "units measured in only one group are dropped" else "")
    res <- dif - mean(dif)
    groups <- list(differences = dif)
  } else {
    res <- y - stats::ave(y, g)
    groups <- split(y, g)
  }
  nmin <- min(lengths(groups))
  small <- nmin < 10

  # Normality: per group (or of the differences), Shapiro-Wilk, with skewness
  sw <- vapply(groups, function(v) if (length(v) >= 3 && length(v) <= 5000 && stats::var(v) > 0) stats::shapiro.test(v)$p.value else NA_real_, 0)
  sk <- vapply(groups, tv_skew, 0)
  nonnormal <- any(sw < 0.05, na.rm = TRUE) || any(abs(sk) > 1)
  add(
    "Normality (Shapiro-Wilk p, per group)",
    paste(sprintf("%s %s", names(sw), ifelse(is.na(sw), "NA", formatC(sw, digits = 2, format = "g"))), collapse = "; "),
    if (nonnormal) "at least one group departs from normality" else "no clear departure"
  )
  add(
    "Skewness", paste(sprintf("%s %.2f", names(sk), sk), collapse = "; "),
    if (any(sk > 1)) "right-skewed (long tail of large values)" else if (any(sk < -1)) "left-skewed" else "roughly symmetric"
  )

  # Outliers: robust z-score (median and MAD) of the residuals
  mad <- stats::mad(res)
  rz <- if (mad > 0) abs(res - stats::median(res)) / mad else rep(0, length(res))
  nout <- sum(rz > 3.5)
  add("Outliers (robust z > 3.5)", nout, if (nout) "a few extreme values can dominate means and variances" else "")

  # Equal spread and whether the spread grows with the mean
  hetero <- FALSE
  mean_var <- FALSE
  if (is.null(paired)) {
    sds <- vapply(groups, stats::sd, 0)
    ratio <- max(sds) / min(sds)
    fl <- stats::fligner.test(y, g)$p.value
    hetero <- ratio > 2 || fl < 0.05
    add(
      "Spread (largest SD / smallest SD)", sprintf("%.2f (Fligner-Killeen %s)", ratio, tv_p(fl)),
      if (hetero) "unequal spreads: Student's t and the classical ANOVA are unreliable, especially with unequal group sizes" else "similar spreads"
    )
    if (k >= 2 && all(y > 0)) {
      mns <- vapply(groups, mean, 0)
      mean_var <- isTRUE(k >= 3 && stats::cor(mns, sds) > 0.6) || isTRUE(k == 2 && sds[which.max(mns)] > 1.5 * sds[which.min(mns)])
    }
  }
  positive <- all(y > 0)
  counts <- all(y >= 0) && all(y == round(y))
  if (counts) add("Counts", "non-negative whole numbers", "counts have a variance that grows with the mean; a GLM for counts models that directly")
  add("All values positive", if (positive) "yes" else "no", if (positive && (any(sk > 1) || mean_var)) "a log transformation is possible" else "")

  # ---- Choose ----
  f <- sprintf("%s ~ %s", response, group)
  two <- k == 2
  student <- if (two) sprintf("t.test(%s, data = data, var.equal = TRUE)", f) else sprintf("summary(aov(%s, data = data))", f)
  welch <- if (two) sprintf("t.test(%s, data = data)", f) else sprintf("oneway.test(%s, data = data)", f)
  rank <- if (two) sprintf("wilcox.test(%s, data = data, conf.int = TRUE)", f) else sprintf("kruskal.test(%s, data = data)\npairwise.wilcox.test(data$%s, data$%s, p.adjust.method = \"holm\")", f, response, group)
  logt <- if (two) sprintf("t.test(log(%s) ~ %s, data = data)   # exp() of the difference = ratio of geometric means", response, group) else sprintf("oneway.test(log(%s) ~ %s, data = data)", response, group)
  robust <- if (two) sprintf("WRS2::yuen(%s, data = data)   # 20%% trimmed means", f) else sprintf("WRS2::t1way(%s, data = data)   # 20%% trimmed means", f)
  perm <- sprintf("# permutation test of the difference in means\nobs <- diff(tapply(data$%s, data$%s, mean))\nnull <- replicate(9999, diff(tapply(data$%s, sample(data$%s), mean)))\nmean(abs(c(obs, null)) >= abs(obs))", response, group, response, group)
  if (!is.null(paired)) {
    lv <- levels(g)
    prep <- sprintf("a <- with(data[data$%s == \"%s\", ], %s[order(%s)])\nb <- with(data[data$%s == \"%s\", ], %s[order(%s)])\n",
                    group, lv[1], response, paired, group, lv[2], response, paired)
    student <- paste0(prep, "t.test(b, a, paired = TRUE)")
    welch <- student
    rank <- paste0(prep, "wilcox.test(b, a, paired = TRUE, conf.int = TRUE)")
    logt <- paste0(prep, "t.test(log(b), log(a), paired = TRUE)")
    robust <- paste0(prep, "WRS2::yuend(b, a)   # trimmed mean of the differences")
  }

  step <- function(s, r, why, code = "") tibble::tibble(step = s, recommendation = r, reason = why, code = code)
  name <- function(a, b) if (!is.null(paired)) a else if (two) a else b
  main <- if (counts && is.null(paired) && (nonnormal || hetero || mean_var)) {
    vm <- vapply(groups, function(v) if (mean(v) > 0) stats::var(v) / mean(v) else NA_real_, 0)
    nb <- isTRUE(max(vm, na.rm = TRUE) > 1.5)
    step("Test", paste("GLM for counts:", if (nb) "negative binomial" else "Poisson"),
         sprintf("The response is counts whose spread differs between groups. A count GLM models that directly and gives each group difference as a ratio of means; transforming counts (log(y + 1)) biases the estimates (O'Hara and Kotze 2010).%s", if (nb) sprintf(" The variance is up to %.1f times the mean, so the negative binomial.", max(vm, na.rm = TRUE)) else ""),
         if (nb) sprintf("m <- MASS::glm.nb(%s, data = data)\nanova(m, test = \"Chisq\"); tidyvisor(m)", f) else sprintf("m <- glm(%s, family = poisson, data = data)\nanova(m, test = \"Chisq\"); tidyvisor(m)", f))
  } else if (nout > 0 && !(positive && any(sk > 1))) {
    step("Test", "Robust test on trimmed means (Yuen)", sprintf("%d outlier%s: trimming 20%% from each tail keeps them from dominating, while still comparing a mean-like centre (Wilcox 2017).", nout, if (nout == 1) "" else "s"), robust)
  } else if (nonnormal && positive && (any(sk > 1) || mean_var)) {
    step("Test", paste("Log-transform, then", name("the Welch t-test", "Welch's ANOVA")), "Positive, right-skewed values whose spread grows with the mean are usually close to normal with equal spread on the log scale; the result is then a ratio of geometric means, which is easy to report.", logt)
  } else if (nonnormal && small) {
    step("Test", name("Wilcoxon test", "Kruskal-Wallis test, then pairwise Wilcoxon tests (Holm)"), "Non-normal data in small groups: the t-test and ANOVA cannot rely on the central limit theorem, and rank tests make no assumption about the shape. They compare distributions (whether values in one group tend to be larger), not means.", rank)
  } else if (hetero || !is.null(paired)) {
    step("Test", if (!is.null(paired)) "Paired t-test" else name("Welch t-test", "Welch's ANOVA (oneway.test)"), if (!is.null(paired)) "Each unit is its own control; the test is on the within-pair differences, which look close enough to normal." else "Welch's test does not assume equal spreads and loses almost nothing when they are equal, so it is the safer default (Delacre et al. 2017).", welch)
  } else if (nonnormal) {
    step("Test", name("Welch t-test", "Welch's ANOVA (oneway.test)"), sprintf("The groups depart from normality, but with at least %d values each the means are close to normal (central limit theorem), so the test on means remains valid; check the result with a rank test (Fagerland 2012).", nmin), welch)
  } else {
    step("Test", name("t-test", "One-way ANOVA"), "The groups look close to normal with similar spread; Welch's version gives almost the same answer and is safe if in doubt.", paste0(student, "\n", welch, "   # Welch, the safer default"))
  }

  alts <- list(
    if (!is.null(paired)) step("Alternative", "Paired t-test", "The classical test on the within-pair differences; fine when they are close to normal or there are 30 or more pairs.", student),
    step("Alternative", "Non-parametric: rank test", "Makes no assumption about the shape of the distributions; answers whether values in one group tend to be larger.", rank),
    step("Alternative", "Robust: trimmed means", "Resists outliers and heavy tails while still comparing a centre.", robust),
    if (positive && is.null(paired)) step("Alternative", "Transform: log scale", "For positive, right-skewed data; compares geometric means (ratios).", logt),
    if (is.null(paired) && two) step("Alternative", "Permutation test", "Uses only the assumption that group labels are exchangeable under no difference; exact for any distribution.", perm),
    if (is.null(paired) && !two && !counts) step("Alternative", "Model with the right family", "Counts: Poisson or negative binomial GLM; positive skewed values: Gamma GLM with a log link. Estimates the effect directly on the scale of the data.", sprintf("glm(%s, family = Gamma(link = \"log\"), data = data)", f))
  )
  alts <- Filter(Negate(is.null), alts)
  # do not offer the main test again as an alternative
  alts <- Filter(function(a) a$code != main$code, alts)
  advice <- rbind(
    step("Before testing", "Plot the data", "Box plots with the points show skewness, outliers and unequal spread at a glance; the checks above put numbers on them.", sprintf("boxplot(%s, data = data); stripchart(%s, data = data, vertical = TRUE, add = TRUE, method = \"jitter\")", f, f)),
    main,
    do.call(rbind, alts),
    step("Interpret", "Plain-language explanation of the result", "What was tested, the effect with its interval, and what to do next.", "tidyvisor(result)")
  )
  structure(list(question = question, checks = do.call(rbind, acc$checks), advice = advice), class = "tv_advice")
}

#' @rdname compare-advisor
#' @export
tv_interpret_htest <- function(x, ...) {
  meth <- trimws(x$method)
  p <- x$p.value
  sig <- !is.null(p) && !is.na(p) && p < 0.05
  s <- list()
  s$Overview <- sprintf("%s on %s.", meth, x$data.name)
  stat <- if (!is.null(x$statistic)) {
    sprintf("%s = %s%s", names(x$statistic), tv_num(unname(x$statistic)),
            if (!is.null(x$parameter)) paste0(" (", paste(sprintf("%s = %s", names(x$parameter), tv_whole(unname(x$parameter))), collapse = ", "), ")") else "")
  } else {
    ""
  }
  res <- sprintf("%s, %s.", stat, tv_p(p))
  if (!is.null(x$estimate)) {
    est <- paste(sprintf("%s = %s", names(x$estimate), tv_num(unname(x$estimate))), collapse = "; ")
    res <- c(res, sprintf("Estimate: %s%s.", est,
                          if (!is.null(x$conf.int)) sprintf(", %d%% confidence interval %s to %s", round(100 * attr(x$conf.int, "conf.level")), tv_num(x$conf.int[1]), tv_num(x$conf.int[2])) else ""))
  }
  s$Result <- res

  kind <- tv_htest_kind(meth)
  s$Meaning <- switch(kind,
    normality = if (sig) "The data depart from normality. With large samples this flags even small departures; look at the Q-Q plot before acting." else "No evidence against normality; with small samples the test has little power, so this does not prove the data are normal.",
    spread = if (sig) "The groups differ in spread. Tests that assume equal variances (Student's t, classical ANOVA) are unreliable here." else "No evidence that the spreads differ.",
    welch = if (sig) "The group means differ; the estimate and interval give how much. Welch's test does not assume equal spreads." else "No evidence that the means differ; the interval shows which differences the data cannot rule out.",
    student = if (sig) "The group means differ. This version assumes equal spreads in the groups." else "No evidence that the means differ. This version assumes equal spreads in the groups.",
    rank = if (sig) "Values in one group tend to be larger than in another. Rank tests compare whole distributions, not means: report medians or the location shift with its interval, not a difference in means." else "No evidence that values in one group tend to be larger than in another.",
    correlation = if (sig) "The two variables are associated; the estimate gives the strength and direction. Correlation does not show which causes which." else "No evidence of an association; the interval shows how strong an association the data cannot rule out.",
    table = if (sig) "The proportions differ between categories (or the variables are not independent). Look at the standardised residuals to see which cells drive it." else "No evidence that the proportions differ.",
    if (sig) "The test rejects its null hypothesis at the 5% level." else "The test does not reject its null hypothesis at the 5% level."
  )
  if (!is.null(p) && !is.na(p)) {
    s$Meaning <- c(s$Meaning, "A p-value is not the size of an effect: always report the estimate and its interval, and a non-significant result is not evidence of no difference.")
  }

  s$`What to do next` <- switch(kind,
    normality = if (sig) c(
      "Positive, right-skewed data: try a log transformation (or find the best power with MASS::boxcox()), then test again on the new scale.",
      "Outliers or heavy tails: use a robust method (trimmed means with WRS2::yuen() or WRS2::t1way(); MASS::rlm() for regression).",
      "Otherwise, or with small groups: a rank test (wilcox.test(), kruskal.test()) or a permutation test.",
      "With 30 or more values per group, tests on means are usually still valid (central limit theorem); check the conclusion with a rank test."
    ) else "Go ahead with the test on means; Welch's version is the safer default.",
    spread = if (sig) c(
      "Use Welch's tests: t.test() (Welch by default) or oneway.test(var.equal = FALSE).",
      "If the spread grows with the mean and the values are positive, a log transformation or a Gamma GLM with a log link may fix both the spread and the skewness."
    ) else "Either Student's or Welch's test is fine; Welch's costs almost nothing when spreads are equal.",
    welch = , student = c(
      "Check the assumptions on the residuals: shapiro.test() per group and a box plot; for unequal spread use Welch (the default of t.test()).",
      if (grepl("ANOVA|one-way|oneway", meth, ignore.case = TRUE) && sig) "Which groups differ: TukeyHSD(aov(...)) for equal spreads, or pairwise.t.test(pool.sd = FALSE, p.adjust.method = \"holm\") for unequal spreads.",
      "If the residuals are skewed or have outliers, compare with a rank test (wilcox.test(), kruskal.test()) or a robust test on trimmed means (WRS2)."
    ),
    rank = c(
      if (grepl("Kruskal", meth) && sig) "Which groups differ: pairwise.wilcox.test(y, group, p.adjust.method = \"holm\") or a Dunn test.",
      "For an effect size, wilcox.test(conf.int = TRUE) gives the Hodges-Lehmann shift with its interval.",
      "If the data are positive and right-skewed, a test on the log scale (or a Gamma GLM) gives a ratio of means, which is often easier to report."
    ),
    correlation = c(
      "Plot the two variables: a single outlier or a curve can drive or hide a correlation.",
      if (grepl("Pearson", meth)) "For curved but monotonic relations or outliers, use method = \"spearman\" (ranks) or \"kendall\"." else "Spearman and Kendall correlations measure monotonic association and resist outliers.",
      "To estimate how one variable changes with the other, fit a regression and use tidyvisor() on it."
    ),
    table = c(
      "Standardised residuals: chisq.test(...)$stdres; cells beyond +/-2 drive the result.",
      "With expected counts below 5, use fisher.test() or chisq.test(simulate.p.value = TRUE)."
    ),
    "Report the estimate and its interval as well as the p-value."
  )
  structure(list(sections = s, tables = list()), class = "tv_interpretation")
}

# nolint end

tv_htest_kind <- function(meth) {
  if (grepl("Shapiro|normality|Anderson|Lilliefors", meth)) "normality"
  else if (grepl("Bartlett|Fligner|Levene|F test to compare two variances", meth)) "spread"
  else if (grepl("Welch|not assuming equal", meth)) "welch"
  else if (grepl("t-test|equal variances", meth)) "student"
  else if (grepl("Wilcoxon|Kruskal|Mann|Friedman", meth)) "rank"
  else if (grepl("correlation", meth)) "correlation"
  else if (grepl("Chi-squared|Fisher|chi-square", meth)) "table"
  else "other"
}

tv_skew <- function(v) {
  v <- v[is.finite(v)]
  if (length(v) < 3 || stats::sd(v) == 0) return(0)
  mean((v - mean(v))^3) / stats::sd(v)^3
}
