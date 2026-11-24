#' The regression adviser: linear and generalised linear models
#'
#' @description
#' The built-in adviser for [stats::lm()] and [stats::glm()]. It is
#' registered under the name `"stats"`, so [tidyvisor()] uses it for
#' `question = "regression"` and for any fitted `lm` or `glm`.
#'
#' **Before fitting** (`tidyvisor(data, question = "regression", response =
#' "y")`), it looks at the response and the predictors and recommends a model:
#'
#' * the **family and link** from the kind of response: continuous
#'   (Gaussian), counts (Poisson, or negative binomial when overdispersed),
#'   binary (binomial, logit), proportions (binomial with the number of
#'   trials), positive and right-skewed (Gamma, log);
#' * whether counts show **overdispersion** or **more zeros** than a Poisson
#'   distribution with the same mean would give (a rough first check, before
#'   the predictors are taken into account);
#' * whether there are enough observations: about 10 to 20 per estimated
#'   parameter (Harrell 2015), and for a binary response at least 10 events of
#'   the rarer outcome per parameter (Peduzzi et al. 1996);
#' * **collinear** numeric predictors (|r| > 0.7; Dormann et al. 2013) and
#'   missing values.
#'
#' **After fitting** (`tidyvisor(model)`), it explains:
#'
#' * the fit: R-squared for `lm`, the share of deviance explained for `glm`,
#'   and the test against the null model;
#' * every coefficient on its natural scale, with a 95% confidence interval:
#'   a change per unit (identity link), a multiplicative change (log link) or
#'   an odds ratio (logit link);
#' * diagnostics: overdispersion (Pearson statistic / residual df),
#'   non-constant variance (studentised Breusch-Pagan test), non-normal
#'   residuals (Shapiro-Wilk, for Gaussian models), influential observations
#'   (Cook's distance > 1; Cook and Weisberg 1982), collinearity (variance inflation factors) and
#'   separation in binomial models.
#'
#' Confidence intervals are Wald intervals (estimate +/- critical value x
#' standard error) on the link scale, transformed to the response scale; they
#' can be optimistic in small samples, where profile intervals
#' ([stats::confint()]) are better.
#'
#' @param x A data frame (advice) or a fitted `lm` or `glm` (interpretation).
#' @param question `"regression"`.
#' @param response Name of the response column.
#' @param predictors Names of the predictor columns; default all other
#'   columns.
#' @param trials For a response of successes out of a number of trials, the
#'   name of the column holding the number of trials.
#' @param level Confidence level of the intervals.
#' @param ... Not used.
#' @return `tv_advise_regression()` returns a `tv_advice` object and
#'   `tv_interpret_regression()` a `tv_interpretation` object; both print as
#'   sentences.
#' @references
#' Cook, R. D. and Weisberg, S. (1982). Residuals and Influence in
#' Regression. Chapman and Hall.
#'
#' Dormann, C. F. et al. (2013). Collinearity: a review of methods to deal
#' with it and a simulation study evaluating their performance. Ecography,
#' 36, 27-46.
#'
#' Harrell, F. E. (2015). Regression Modeling Strategies, 2nd ed. Springer.
#'
#' Peduzzi, P., Concato, J., Kemper, E., Holford, T. R. and Feinstein, A. R.
#' (1996). A simulation study of the number of events per variable in
#' logistic regression analysis. Journal of Clinical Epidemiology, 49,
#' 1373-1379.
#'
#' Zuur, A. F., Ieno, E. N. and Elphick, C. S. (2010). A protocol for data
#' exploration to avoid common statistical problems. Methods in Ecology and
#' Evolution, 1, 3-14.
#' @name regression-advisor
#' @examples
#' # Before: which model for counts of warp breaks?
#' tidyvisor(warpbreaks, question = "regression", response = "breaks")
#'
#' # After: what does the model show?
#' m <- glm(breaks ~ wool + tension, family = poisson, data = warpbreaks)
#' tidyvisor(m)
NULL

# nolint start: line_length_linter. Advice sentences read better unbroken.

#' @rdname regression-advisor
#' @export
tv_advise_regression <- function(x, question = "regression", response, predictors = NULL,
                                 trials = NULL, ...) {
  if (missing(response) || !rlang::is_string(response) || !response %in% names(x)) {
    cli::cli_abort("Give {.arg response}, the name of the response column.")
  }
  predictors <- predictors %||% setdiff(names(x), c(response, trials))
  miss <- setdiff(predictors, names(x))
  if (length(miss)) cli::cli_abort("Unknown predictor column{?s}: {.field {miss}}.")
  cols <- unique(c(response, predictors, trials))
  cc <- stats::complete.cases(x[cols])
  d <- x[cc, cols, drop = FALSE]
  n <- nrow(d)
  y <- d[[response]]

  acc <- new.env()
  acc$checks <- list(tv_check("Observations", n))
  add <- function(check, value, meaning = "") {
    acc$checks[[length(acc$checks) + 1]] <- tv_check(check, value, meaning)
  }
  if (any(!cc)) {
    add("Rows with missing values", sum(!cc), "dropped; check that they are missing at random")
  }

  # ---- Kind of response -> family ----
  kind <- tv_response_kind(y, trials)
  add("Response", kind$label)
  fam <- kind$family
  why <- kind$why
  if (kind$kind == "count") {
    m <- mean(y)
    ratio <- if (m > 0) stats::var(y) / m else NA
    zero_obs <- mean(y == 0)
    zero_exp <- exp(-m)
    add(
      "Variance / mean", sprintf("%.1f", ratio),
      if (is.finite(ratio) && ratio > 1.5) "above 1: overdispersed; a negative binomial model is safer than Poisson" else "close to 1: Poisson is plausible"
    )
    add(
      "Zeros", sprintf("%.0f%% observed, %.0f%% expected under Poisson", 100 * zero_obs, 100 * zero_exp),
      if (zero_obs > 2 * zero_exp && zero_obs - zero_exp > 0.1) "more zeros than expected: check a zero-inflated or hurdle model after fitting" else ""
    )
    if (is.finite(ratio) && ratio > 1.5) {
      fam <- "MASS::glm.nb()"
      why <- "Counts whose variance exceeds the mean (overdispersion) make Poisson standard errors too small; the negative binomial estimates the extra variance."
    }
  }

  # ---- Size of the data for the number of parameters ----
  rhs <- if (length(predictors)) paste(predictors, collapse = " + ") else "1"
  mm <- stats::model.matrix(stats::reformulate(if (length(predictors)) predictors else "1"), d)
  k <- ncol(mm) - 1
  add(
    "Parameters (excluding intercept)", k,
    if (k > 0 && n / k < 10) "fewer than 10 observations per parameter: the model is likely overfitted; drop or combine predictors" else ""
  )
  if (kind$kind == "binary") {
    ev <- min(table(tv_as_binary(y)))
    add(
      "Events of the rarer outcome", ev,
      if (k > 0 && ev / k < 10) "fewer than 10 per parameter: estimates are biased and unstable (Peduzzi et al. 1996)" else ""
    )
  }

  # ---- Collinearity ----
  num <- predictors[vapply(predictors, function(p) is.numeric(d[[p]]), TRUE)]
  if (length(num) >= 2) {
    r <- stats::cor(d[num])
    r[upper.tri(r, diag = TRUE)] <- NA
    hi <- which(abs(r) > 0.7, arr.ind = TRUE)
    add(
      "Collinear predictor pairs (|r| > 0.7)",
      if (nrow(hi)) paste(sprintf("%s-%s (%.2f)", rownames(r)[hi[, 1]], colnames(r)[hi[, 2]], r[hi]), collapse = "; ") else "none",
      if (nrow(hi)) "their effects cannot be separated: keep one of each pair, or combine them" else ""
    )
  }

  # ---- The advice ----
  lhs <- if (!is.null(trials)) sprintf("cbind(%s, %s - %s)", response, trials, response) else response
  f <- paste(lhs, "~", rhs)
  code <- if (fam == "MASS::glm.nb()") {
    sprintf("m <- MASS::glm.nb(%s, data = data)", f)
  } else if (fam == "gaussian") {
    sprintf("m <- lm(%s, data = data)", f)
  } else {
    sprintf("m <- glm(%s, family = %s, data = data)", f, fam)
  }
  step <- function(s, r, why, code = "") tibble::tibble(step = s, recommendation = r, reason = why, code = code)
  advice <- rbind(
    step("Model", if (fam == "gaussian") "Linear model" else paste("Generalised linear model:", fam), why, code),
    step(
      "Before fitting", "Plot the response against each predictor",
      "Shows non-linear relations, outliers and interactions that the model would miss (Zuur et al. 2010).",
      sprintf("plot(data[c(%s)])", paste0('"', c(response, utils::head(predictors, 5)), '"', collapse = ", "))
    ),
    step(
      "After fitting", "Check the residuals",
      "Residual plots show non-linearity, unequal variance and influential points; tidyvisor reports the tests.",
      "plot(m)   # or performance::check_model(m)"
    ),
    step("Interpret", "Plain-language explanation of the model", "Effects on the scale of the response, the fit and the diagnostics.", "tidyvisor(m)")
  )
  structure(list(question = question, checks = do.call(rbind, acc$checks), advice = advice), class = "tv_advice")
}

#' @rdname regression-advisor
#' @export
tv_interpret_regression <- function(x, level = 0.95, ...) {
  is_glm <- inherits(x, "glm")
  fam <- if (is_glm) stats::family(x) else stats::gaussian()
  link <- fam$link
  n <- stats::nobs(x)
  yname <- deparse(stats::formula(x)[[2]])
  # the outcome whose odds a logistic model describes
  odds_of <- yname
  if (is_glm && fam$family == "binomial") {
    yv <- stats::model.response(stats::model.frame(x))
    odds_of <- tv_odds_of(yv, yname)
  }
  est_disp <- !fam$family %in% c("poisson", "binomial")
  sm <- summary(x)
  s <- list()

  s$Overview <- sprintf(
    "%s of %s on %d observations (%s family, %s link).",
    if (is_glm) "Generalised linear model" else "Linear model", yname, n, fam$family, link
  )

  # ---- Fit ----
  if (!is_glm) {
    fs <- sm$fstatistic
    fit <- c(
      sprintf("The predictors explain %.1f%% of the variance of %s (R-squared; adjusted %.1f%%).", 100 * sm$r.squared, yname, 100 * sm$adj.r.squared),
      if (!is.null(fs)) {
        p <- stats::pf(fs[1], fs[2], fs[3], lower.tail = FALSE)
        sprintf("Against a model with no predictors: F = %.2f on %d and %d df, %s.", fs[1], fs[2], fs[3], tv_p(p))
      }
    )
  } else {
    d2 <- 1 - x$deviance / x$null.deviance
    ddf <- x$df.null - x$df.residual
    fit <- sprintf("The predictors explain %.1f%% of the deviance (the GLM analogue of R-squared).", 100 * d2)
    if (ddf > 0) {
      if (est_disp) {
        phi <- sum(stats::residuals(x, type = "pearson")^2) / x$df.residual
        fstat <- ((x$null.deviance - x$deviance) / ddf) / phi
        p <- stats::pf(fstat, ddf, x$df.residual, lower.tail = FALSE)
        fit <- c(fit, sprintf("Against a model with no predictors: F = %.2f on %d and %d df, %s.", fstat, ddf, x$df.residual, tv_p(p)))
      } else {
        chi <- x$null.deviance - x$deviance
        p <- stats::pchisq(chi, ddf, lower.tail = FALSE)
        fit <- c(fit, sprintf("Against a model with no predictors: likelihood-ratio chi-squared = %.1f on %d df, %s.", chi, ddf, tv_p(p)))
      }
    }
  }
  s$Fit <- fit

  # ---- Coefficients on the response scale ----
  cf <- stats::coef(sm)
  cf <- cf[rownames(cf) != "(Intercept)", , drop = FALSE]
  crit <- if (!is_glm || est_disp) stats::qt(1 - (1 - level) / 2, stats::df.residual(x)) else stats::qnorm(1 - (1 - level) / 2)
  e <- tv_effects(cf, crit, link, yname, odds_of, x$xlevels, level)
  tab <- e$table
  if (length(e$sentences)) {
    s$Effects <- c(e$sentences, "Each effect is estimated with the other predictors held fixed.")
  }

  # ---- Diagnostics ----
  diag <- character()
  if (is_glm && fam$family %in% c("poisson", "binomial")) {
    binary <- fam$family == "binomial" && all(stats::weights(x, "prior") == 1) && all(x$y %in% c(0, 1))
    if (!binary && x$df.residual > 0) {
      phi <- sum(stats::residuals(x, type = "pearson")^2) / x$df.residual
      diag <- c(diag, if (phi > 1.5) {
        sprintf("Overdispersion: Pearson statistic / residual df = %.2f (expected about 1). Standard errors and p-values are too small; refit with %s.", phi, if (fam$family == "poisson") "a negative binomial model (MASS::glm.nb()) or family = quasipoisson" else "family = quasibinomial")
      } else {
        sprintf("Dispersion: Pearson statistic / residual df = %.2f, consistent with the %s assumption.", phi, fam$family)
      })
    }
    if (fam$family == "binomial") {
      fv <- stats::fitted(x)
      if (any(fv < 1e-8 | fv > 1 - 1e-8) || any(abs(stats::coef(x)) > 10, na.rm = TRUE)) {
        diag <- c(diag, "Separation: some fitted probabilities are 0 or 1, so some coefficients and their standard errors are unreliable; consider a penalised (Firth) logistic regression.")
      }
    }
  }
  if (!is_glm || fam$family == "gaussian") {
    r <- stats::residuals(x)
    if (n >= 3 && n <= 5000) {
      sw <- stats::shapiro.test(r)
      diag <- c(diag, sprintf(
        "Normality of residuals (Shapiro-Wilk): W = %.3f, %s%s", sw$statistic, tv_p(sw$p.value),
        if (sw$p.value < 0.05) "; the residuals depart from normality: look at the Q-Q plot, and consider a transformation or another family." else "."
      ))
    }
    bp <- tv_breusch_pagan(x)
    if (!is.null(bp)) {
      diag <- c(diag, sprintf(
        "Constant variance (Breusch-Pagan): chi-squared = %.2f on %d df, %s%s", bp$stat, bp$df, tv_p(bp$p),
        if (bp$p < 0.05) "; the spread of the residuals changes with the fitted values: consider a log or Gamma model, or robust standard errors." else "."
      ))
    }
  }
  cd <- stats::cooks.distance(x)
  cd <- cd[is.finite(cd)]
  if (length(cd)) {
    top <- max(cd)
    diag <- c(diag, if (top > 1) {
      sprintf("Influence: row %s has Cook's distance %.2f (above 1), so it alone changes the fit noticeably; refit without it to see whether the conclusions hold.", names(which.max(cd)), top)
    } else {
      sprintf("Influence: no observation dominates the fit (largest Cook's distance %.2f, row %s; values above 1 would be a concern).", top, names(which.max(cd)))
    })
  }
  vif <- tv_vif(x)
  if (length(vif) && max(vif) > 5) {
    diag <- c(diag, sprintf(
      "Collinearity: variance inflation factor of %s is %.1f (above 5); its effect is hard to separate from the others.",
      names(which.max(vif)), max(vif)
    ))
  }
  s$Diagnostics <- if (length(diag)) diag else "No problems found by the checks run."

  s$`Reading the plots` <- c(
    "plot(model) shows four diagnostics: residuals against fitted values (look for curves or a funnel), the normal Q-Q plot, scale-location (spread against fitted values) and residuals against leverage (influential points).",
    "Plot each effect on the response scale, with its confidence band, rather than the coefficients alone."
  )
  structure(list(sections = s, tables = list(coefficients = tab)), class = "tv_interpretation")
}

# ---- Helpers ----

tv_check <- function(check, value, meaning = "") {
  tibble::tibble(check = check, value = as.character(value), meaning = meaning)
}

tv_as_binary <- function(y) {
  if (is.logical(y)) y else if (is.numeric(y)) y == max(y) else factor(y)
}

tv_response_kind <- function(y, trials) {
  if (!is.null(trials)) {
    return(list(
      kind = "proportion", label = "successes out of a number of trials", family = "binomial",
      why = "Successes out of a known number of trials are binomial; give both counts so each proportion is weighted by its number of trials."
    ))
  }
  vals <- unique(y)
  two <- length(vals) == 2
  is_binary <- is.logical(y) || ((is.factor(y) || is.character(y)) && two) ||
    (is.numeric(y) && two && all(vals %in% c(0, 1)))
  if (is_binary) {
    return(list(
      kind = "binary", label = "binary (two outcomes)", family = "binomial",
      why = "A yes/no response is binomial; the logit link gives effects as odds ratios."
    ))
  }
  if (!is.numeric(y)) {
    cli::cli_abort("The response must be numeric, logical or have two levels; it has {length(vals)} levels.")
  }
  if (all(y >= 0) && all(y == round(y))) {
    return(list(
      kind = "count", label = "counts (non-negative integers)", family = "poisson",
      why = "Counts are discrete and their variance grows with the mean; a Poisson model with a log link fits both, where a linear model on raw counts does not."
    ))
  }
  if (all(y >= 0 & y <= 1)) {
    return(list(
      kind = "proportion", label = "proportions between 0 and 1", family = "binomial",
      why = "Proportions are bounded by 0 and 1. If they come from counts, give the number of trials (argument trials); otherwise consider beta regression."
    ))
  }
  skew <- mean((y - mean(y))^3) / stats::sd(y)^3
  if (all(y > 0) && skew > 1) {
    return(list(
      kind = "positive", label = sprintf("positive and right-skewed (skewness %.1f)", skew),
      family = 'Gamma(link = "log")',
      why = "Positive, right-skewed values usually have a spread that grows with the mean; a Gamma model with a log link fits that without transforming the response."
    ))
  }
  list(
    kind = "continuous", label = "continuous", family = "gaussian",
    why = "A continuous, roughly symmetric response suits a linear model; check the residuals after fitting."
  )
}

# Studentised Breusch-Pagan test (Koenker): n * R^2 of the squared residuals
# regressed on the model matrix
tv_breusch_pagan <- function(m) {
  mm <- stats::model.matrix(m)
  if (ncol(mm) < 2) {
    return(NULL)
  }
  e2 <- stats::residuals(m)^2
  aux <- stats::lm.fit(mm, e2)
  r2 <- 1 - sum(aux$residuals^2) / sum((e2 - mean(e2))^2)
  stat <- length(e2) * r2
  df <- ncol(mm) - 1
  list(stat = stat, df = df, p = stats::pchisq(stat, df, lower.tail = FALSE))
}

# Variance inflation factors from the model matrix (one per column)
tv_vif <- function(m) {
  mm <- stats::model.matrix(m)
  mm <- mm[, colnames(mm) != "(Intercept)", drop = FALSE]
  if (ncol(mm) < 2) {
    return(numeric())
  }
  v <- vapply(seq_len(ncol(mm)), function(j) {
    fit <- stats::lm.fit(cbind(1, mm[, -j, drop = FALSE]), mm[, j])
    r2 <- 1 - sum(fit$residuals^2) / sum((mm[, j] - mean(mm[, j]))^2)
    1 / (1 - r2)
  }, 1)
  stats::setNames(v, colnames(mm))
}

tv_p <- function(p) if (is.na(p)) "p = NA" else if (p < 0.001) "p < 0.001" else sprintf("p = %.3f", p)
tv_num <- function(x) formatC(x, digits = 3, format = "fg", flag = "#")
tv_pct <- function(r) sprintf("%+.0f%%", 100 * (r - 1))

# ---- Printing ----

#' @export
print.tv_advice <- function(x, ...) {
  cli::cli_h1("tidyvisor: which analysis?")
  cli::cli_text("Question: {.strong {x$question}}")
  cli::cli_h2("What the data show")
  for (i in seq_len(nrow(x$checks))) {
    r <- x$checks[i, ]
    note <- if (nzchar(r$meaning)) paste0(": ", r$meaning) else ""
    cli::cli_bullets(c("*" = gsub("([{}])", "\\1\\1", paste0(r$check, ": ", r$value, note))))
  }
  cli::cli_h2("Recommended")
  for (i in seq_len(nrow(x$advice))) {
    r <- x$advice[i, ]
    cli::cli_text("{.strong {r$step}}: {r$recommendation}")
    if (nzchar(r$reason)) cli::cli_text("  {.emph {r$reason}}")
    if (nzchar(r$code)) cli::cli_code(strsplit(r$code, "\n")[[1]])
  }
  invisible(x)
}

#' @export
print.tv_interpretation <- function(x, ...) {
  cli::cli_h1("tidyvisor: what the results show")
  for (nm in names(x$sections)) {
    cli::cli_h2(nm)
    for (line in x$sections[[nm]]) cli::cli_bullets(c("*" = gsub("([{}])", "\\1\\1", line)))
  }
  invisible(x)
}
# Sentences for fixed effects. `cf` has columns estimate, std. error, statistic
# and p-value (the layout of coef(summary()) for lm, glm, glmer, glmmTMB, gam).
tv_effects <- function(cf, crit, link, yname, odds_of, xlevels, level) {
  cf <- cf[rownames(cf) != "(Intercept)", , drop = FALSE]
  lvl <- round(100 * level)
  factor_terms <- names(xlevels)
  eff <- character()
  tab <- list()
  for (term in rownames(cf)) {
    b <- cf[term, 1]
    se <- cf[term, 2]
    p <- if (ncol(cf) >= 4) cf[term, 4] else 2 * stats::pnorm(-abs(b / se))
    lo <- b - crit * se
    hi <- b + crit * se
    fac <- factor_terms[startsWith(term, factor_terms)]
    what <- if (length(fac)) {
      sprintf("%s = %s (compared with %s = %s)", fac[1], substring(term, nchar(fac[1]) + 1), fac[1], xlevels[[fac[1]]][1])
    } else {
      sprintf("each one-unit increase in %s", term)
    }
    sentence <- switch(link,
      identity = sprintf("%s: %s changes %s by %s (%d%% CI %s to %s), %s.", term, what, yname, tv_num(b), lvl, tv_num(lo), tv_num(hi), tv_p(p)),
      log = sprintf("%s: %s multiplies the expected %s by %s (%s; %d%% CI %s to %s), %s.", term, what, yname, tv_num(exp(b)), tv_pct(exp(b)), lvl, tv_num(exp(lo)), tv_num(exp(hi)), tv_p(p)),
      logit = sprintf("%s: %s multiplies the odds of %s by %s (odds ratio; %d%% CI %s to %s), %s.", term, what, odds_of, tv_num(exp(b)), lvl, tv_num(exp(lo)), tv_num(exp(hi)), tv_p(p)),
      sprintf("%s: coefficient %s on the %s scale (%d%% CI %s to %s), %s.", term, tv_num(b), link, lvl, tv_num(lo), tv_num(hi), tv_p(p))
    )
    eff <- c(eff, sentence)
    tab[[term]] <- tibble::tibble(term = term, estimate = b, std_error = se, lower = lo, upper = hi, p.value = p)
  }
  if (length(eff) && link %in% c("log", "logit")) {
    eff <- c(eff, "Effects on the log or logit scale are multiplicative: they combine by multiplying, and a factor of 1 means no effect.")
  }
  list(sentences = eff, table = do.call(rbind, tab))
}

# Outcome named in odds ratios of a binomial model
tv_odds_of <- function(yv, yname) {
  if (is.factor(yv)) {
    sprintf("%s = %s", yname, levels(yv)[2])
  } else if (is.logical(yv)) {
    sprintf("%s = TRUE", yname)
  } else if (is.null(dim(yv))) {
    sprintf("%s = 1", yname)
  } else {
    tv_success_name(yname)
  }
}

# The success column of a cbind(successes, failures) response
tv_success_name <- function(yname) {
  if (startsWith(yname, "cbind(")) sub("^cbind\\(\\s*([^,]+),.*$", "\\1", yname) else sprintf("success in %s", yname)
}

# Levels of the factor predictors in a model frame
tv_xlevels <- function(mf) {
  f <- mf[-1][vapply(mf[-1], function(v) is.factor(v) || is.character(v), TRUE)]
  lapply(f, function(v) levels(as.factor(v)))
}

# nolint end
