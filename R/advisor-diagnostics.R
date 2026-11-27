# nolint start: line_length_linter. Advice sentences read better unbroken.

#' Check a fitted model with simulated residuals
#'
#' @description
#' Checks whether a fitted model describes the data well, using scaled
#' residuals from simulations of the fitted model (Dunn and Smyth 1996;
#' Hartig 2024, the method of the DHARMa package). For each observation the
#' observed value is placed within the values simulated from the model; if
#' the model is right these scaled residuals are uniform between 0 and 1,
#' whatever the distribution (Poisson, binomial, negative binomial, mixed
#' models). Four tests follow:
#'
#' * uniformity (Kolmogorov-Smirnov): the overall distribution is wrong;
#' * dispersion: the data vary more (or less) than the model expects;
#' * zero inflation: more zeros than the model expects (counts only);
#' * outliers: more observations outside all simulated values than chance.
#'
#' It works for any model with [stats::simulate()] and [stats::fitted()]
#' methods: `lm()`, `glm()`, `MASS::glm.nb()`, `lme4::glmer()` and
#' `glmmTMB::glmmTMB()`.
#'
#' @param model A fitted model.
#' @param nsim Number of simulations (250 is usually enough).
#' @param seed Optional random seed, set with [set.seed()] before simulating,
#'   for reproducible residuals.
#' @return A `tv_advice` object (question `"model check"`) with `checks`
#'   (each test, its p-value and what it means) and `advice`, plus
#'   `residuals`, a tibble with `observed`, `fitted` and `scaled` (the
#'   scaled residuals), for plots such as a uniform QQ plot.
#' @references Dunn, P. K. and Smyth, G. K. (1996). Randomized quantile
#'   residuals. Journal of Computational and Graphical Statistics, 5,
#'   236-244. \doi{10.1080/10618600.1996.10474708}
#'
#'   Hartig, F. (2024). DHARMa: residual diagnostics for hierarchical
#'   (multi-level / mixed) regression models. R package.
#'   <https://CRAN.R-project.org/package=DHARMa>
#' @export
#' @examples
#' # Counts with extra variation: Poisson is overdispersed
#' fit <- glm(count ~ spray, family = poisson, data = InsectSprays)
#' tv_check_model(fit, seed = 1)
tv_check_model <- function(model, nsim = 250, seed = NULL) {
  if (!is.numeric(nsim) || length(nsim) != 1 || nsim < 10) {
    cli::cli_abort("{.arg nsim} must be a number of at least 10.")
  }
  if (!is.null(seed)) set.seed(seed)
  sims <- tryCatch(stats::simulate(model, nsim = nsim),
    error = function(e) cli::cli_abort(c("Can't simulate from this model.", "x" = conditionMessage(e)))
  )
  sim <- as.matrix(as.data.frame(lapply(sims, function(s) if (is.matrix(s)) s[, 1] else as.numeric(s))))
  y <- stats::model.response(stats::model.frame(model))
  if (is.matrix(y)) y <- y[, 1]
  if (is.factor(y)) y <- as.numeric(y != levels(y)[1])
  y <- as.numeric(y)
  if (inherits(model, "glm") && stats::family(model)$family == "binomial" && any(stats::weights(model) != 1) && all(y <= 1)) {
    y <- round(y * stats::weights(model))
  }
  if (length(y) != nrow(sim)) cli::cli_abort("The response and the simulations differ in length.")
  fitted <- rowMeans(sim)
  scaled <- tv_scaled_residuals(y, sim)
  n <- length(y)
  ks <- suppressWarnings(stats::ks.test(scaled, "punif"))
  # Dispersion: variance of residuals around the simulated mean, observed vs simulated
  obs_var <- stats::var(y - fitted)
  sim_var <- apply(sim, 2, function(s) stats::var(s - fitted))
  disp_ratio <- obs_var / mean(sim_var)
  disp_p <- min(1, 2 * min(mean(sim_var >= obs_var), mean(sim_var <= obs_var)) + 1 / (nsim + 1))
  counts <- all(abs(y - round(y)) < 1e-8) && all(y >= 0)
  zero_p <- NA_real_
  zero_ratio <- NA_real_
  if (counts) {
    obs_z <- sum(y == 0)
    sim_z <- colSums(sim == 0)
    zero_ratio <- if (mean(sim_z) > 0) obs_z / mean(sim_z) else NA_real_
    zero_p <- min(1, 2 * min(mean(sim_z >= obs_z), mean(sim_z <= obs_z)) + 1 / (nsim + 1))
  }
  outside <- sum(y < apply(sim, 1, min) | y > apply(sim, 1, max))
  out_p <- stats::binom.test(outside, n, p = 2 / (nsim + 1), alternative = "greater")$p.value
  fmt_p <- function(p) if (is.na(p)) "not applicable" else if (p < 0.001) "p < 0.001" else sprintf("p = %.3f", p)
  checks <- rbind(
    tv_check("Simulations", sprintf("%d from the fitted model, %d observations", nsim, n)),
    tv_check(
      "Uniformity (KS test)", fmt_p(ks$p.value),
      if (ks$p.value < 0.05) "the residuals are not uniform: the distribution or the mean structure is wrong" else "no sign that the distribution is wrong"
    ),
    tv_check(
      "Dispersion", sprintf("ratio %s, %s", tv_num(disp_ratio), fmt_p(disp_p)),
      if (disp_p < 0.05 && disp_ratio > 1) "overdispersed: more variation than the model allows" else if (disp_p < 0.05) "underdispersed: less variation than the model allows" else "dispersion as expected"
    ),
    tv_check(
      "Zero inflation", if (is.na(zero_p)) "not applicable" else sprintf("observed/expected zeros %s, %s", tv_num(zero_ratio), fmt_p(zero_p)),
      if (!is.na(zero_p) && zero_p < 0.05 && zero_ratio > 1) "more zeros than expected" else ""
    ),
    tv_check(
      "Outliers", sprintf("%d outside all simulated values, %s", outside, fmt_p(out_p)),
      if (out_p < 0.05) "more extreme observations than chance" else ""
    )
  )
  step <- function(s, rec, why, code = "") tibble::tibble(step = s, recommendation = rec, reason = why, code = code)
  problems <- c(ks$p.value < 0.05, disp_p < 0.05, !is.na(zero_p) && zero_p < 0.05, out_p < 0.05)
  advice <- rbind(
    if (!any(problems)) step("Model", "The model passes the simulation checks", "Report that residuals were checked by simulation (DHARMa-style scaled residuals) and showed no problems; then interpret it with interpret()."),
    if (disp_p < 0.05 && disp_ratio > 1) step("Overdispersion", "Use a distribution with extra variance", "Standard errors and p-values from an overdispersed model are too small. For counts use a negative binomial (MASS::glm.nb() or glmmTMB(family = nbinom2)); for proportions a beta-binomial or an observation-level random effect.", "m2 <- MASS::glm.nb(formula(model), data = model.frame(model))"),
    if (disp_p < 0.05 && disp_ratio < 1) step("Underdispersion", "Check for too many predictors or a bounded process", "Less variation than expected makes tests conservative; it is often caused by overfitting or by counts with an upper limit. A generalised Poisson or COM-Poisson model (glmmTMB) can fit it."),
    if (!is.na(zero_p) && zero_p < 0.05 && zero_ratio > 1) step("Zero inflation", "Fit a zero-inflated or hurdle model, after fixing dispersion", "Excess zeros often disappear once overdispersion is modelled; if they remain, a zero-inflated negative binomial (glmmTMB(ziformula = ~1)) separates structural zeros.", "m3 <- glmmTMB::glmmTMB(formula(model), ziformula = ~1, family = glmmTMB::nbinom2, data = model.frame(model))"),
    if (ks$p.value < 0.05 && !(disp_p < 0.05)) step("Distribution", "Plot the scaled residuals against each predictor", "Non-uniform residuals without overdispersion point to a missing predictor, a non-linear effect (try a GAM) or the wrong link function."),
    if (out_p < 0.05) step("Outliers", "Check the outlying observations", "Look for recording errors first; never drop observations only because they are outlying. A heavier-tailed distribution may fit better."),
    step(
      "Plot", "Show the residual checks in the supplement", "A uniform QQ plot of the scaled residuals and a plot of them against the fitted values make the checks visible to reviewers.",
      "chk <- tv_check_model(model, seed = 1)\nggplot2::ggplot(chk$residuals, ggplot2::aes(sample = scaled)) +\n  ggplot2::stat_qq(distribution = stats::qunif) + ggplot2::geom_abline()"
    )
  )
  structure(list(
    question = "model check", checks = checks, advice = advice,
    residuals = tibble::tibble(observed = y, fitted = fitted, scaled = scaled),
    tests = tibble::tibble(
      test = c("uniformity", "dispersion", "zero_inflation", "outliers"),
      statistic = c(unname(ks$statistic), disp_ratio, zero_ratio, outside),
      p_value = c(ks$p.value, disp_p, zero_p, out_p)
    )
  ), class = "tv_advice")
}

# Randomised probability integral transform of y within its simulations.
tv_scaled_residuals <- function(y, sim) {
  nsim <- ncol(sim)
  below <- rowSums(sim < y)
  equal <- rowSums(sim == y)
  (below + stats::runif(length(y)) * (equal + 1)) / (nsim + 1)
}

#' E-value: how strong would unmeasured confounding have to be?
#'
#' @description
#' For an observational study, the E-value (VanderWeele and Ding 2017) is
#' the minimum strength of association, on the risk ratio scale, that an
#' unmeasured confounder would need with both the exposure and the outcome
#' to fully explain away the observed association. A small E-value (near 1)
#' means weak confounding could explain the result; a large one means only
#' strong confounding could. The E-value for the confidence limit closest
#' to 1 says how much confounding would make the interval include 1.
#'
#' Odds ratios and hazard ratios for a common outcome (more than about 15%)
#' are first converted to approximate risk ratios with the square-root
#' transformation and that of VanderWeele (2020); a standardised mean
#' difference `d` with \eqn{RR \approx \exp(0.91 d)}.
#'
#' @param estimate The point estimate (a ratio, or a standardised mean
#'   difference for `type = "smd"`).
#' @param lower,upper Confidence limits (optional).
#' @param type `"rr"` (risk or rate ratio), `"or"` (odds ratio), `"hr"`
#'   (hazard ratio) or `"smd"` (standardised mean difference).
#' @param rare For odds and hazard ratios: is the outcome rare (under about
#'   15%)? Then the ratio approximates a risk ratio and is used as is.
#' @return A `tv_advice` object (question `"confounding"`) with the
#'   E-values in `checks` and an interpretation in `advice`, plus
#'   `evalue` (point) and `evalue_ci`.
#' @references VanderWeele, T. J. and Ding, P. (2017). Sensitivity analysis
#'   in observational research: introducing the E-value. Annals of Internal
#'   Medicine, 167, 268-274. \doi{10.7326/M16-2607}
#'
#'   VanderWeele, T. J. (2020). Optimal approximate conversions of odds
#'   ratios and hazard ratios to risk ratios. Biometrics, 76, 746-752.
#'   \doi{10.1111/biom.13197}
#' @export
#' @examples
#' # Risk ratio 3.9 (95% CI 1.8 to 8.7) for an exposure in a cohort study
#' tv_evalue(3.9, 1.8, 8.7)
#'
#' # Odds ratio for a common outcome
#' tv_evalue(1.6, 1.1, 2.3, type = "or")
tv_evalue <- function(estimate, lower = NULL, upper = NULL,
                      type = c("rr", "or", "hr", "smd"), rare = FALSE) {
  type <- rlang::arg_match(type)
  chk <- function(x, nm) {
    if (!is.null(x) && (!is.numeric(x) || length(x) != 1 || is.na(x) || (type != "smd" && x <= 0))) {
      cli::cli_abort("{.arg {nm}} must be a single {if (type == 'smd') 'number' else 'positive ratio'}.")
    }
  }
  chk(estimate, "estimate")
  chk(lower, "lower")
  chk(upper, "upper")
  to_rr <- function(x) {
    if (is.null(x)) {
      return(NULL)
    }
    switch(type,
      rr = x,
      or = if (rare) x else sqrt(x),
      hr = if (rare) x else (1 - 0.5^sqrt(x)) / (1 - 0.5^sqrt(1 / x)),
      smd = exp(0.91 * x)
    )
  }
  rr <- to_rr(estimate)
  lo <- to_rr(lower)
  hi <- to_rr(upper)
  ev <- tv_evalue_rr(rr)
  ev_ci <- NA_real_
  if (!is.null(lo) && !is.null(hi)) {
    if (lo > hi) cli::cli_abort("{.arg lower} must not exceed {.arg upper}.")
    ev_ci <- if (lo <= 1 && hi >= 1) 1 else if (rr > 1) tv_evalue_rr(lo) else tv_evalue_rr(hi)
  }
  conv <- switch(type,
    rr = "used as given",
    or = if (rare) "rare outcome: odds ratio used as a risk ratio" else "converted with RR = sqrt(OR) (common outcome)",
    hr = if (rare) "rare outcome: hazard ratio used as a risk ratio" else "converted as in VanderWeele (2020) (common outcome)",
    smd = "converted with RR = exp(0.91 d)"
  )
  checks <- rbind(
    tv_check("Estimate", paste0(tv_num(estimate), if (!is.null(lower) && !is.null(upper)) sprintf(" (%s to %s)", tv_num(lower), tv_num(upper)) else ""), conv),
    tv_check("E-value for the estimate", tv_num(ev), "risk ratio a confounder would need with both exposure and outcome to explain the estimate away"),
    if (!is.na(ev_ci)) tv_check("E-value for the confidence limit", tv_num(ev_ci), if (ev_ci == 1) "the interval already includes no effect" else "to move the interval to include no effect")
  )
  strength <- if (ev >= 3) "only strong" else if (ev >= 1.5) "moderate" else "weak"
  step <- function(s, rec, why, code = "") tibble::tibble(step = s, recommendation = rec, reason = why, code = code)
  advice <- rbind(
    step(
      "Interpretation", sprintf("%s unmeasured confounding could explain this association", paste0(toupper(substring(strength, 1, 1)), substring(strength, 2))),
      sprintf(
        "An unmeasured confounder associated with both the exposure and the outcome by a risk ratio of %s each, above the measured covariates, could explain away the estimate; weaker confounding could not.%s", tv_num(ev),
        if (!is.na(ev_ci) && ev_ci > 1) sprintf(" A risk ratio of %s each would be enough to make the confidence interval include 1.", tv_num(ev_ci)) else ""
      )
    ),
    step("Compare", "Compare the E-value with known confounders", "Set the E-value against the strength of measured covariates (their risk ratios with exposure and outcome): if no plausible unmeasured factor is that strong, the conclusion is robust."),
    step("For the paper", "Report the E-value with the estimate", sprintf("For example: \"The observed risk ratio of %s could be explained away by an unmeasured confounder associated with both exposure and outcome by a risk ratio of %s each, above the measured confounders, but weaker confounding could not (VanderWeele and Ding 2017).\"", tv_num(rr), tv_num(ev)))
  )
  structure(list(question = "confounding", checks = checks, advice = advice, evalue = ev, evalue_ci = ev_ci), class = "tv_advice")
}

tv_evalue_rr <- function(rr) {
  if (rr < 1) rr <- 1 / rr
  rr + sqrt(rr * (rr - 1))
}

#' Equivalence test: is the difference small enough to ignore?
#'
#' @description
#' A non-significant test does not show that two groups are the same. An
#' equivalence test does: with two one-sided tests (TOST; Schuirmann 1987,
#' Lakens 2017) it tests whether the difference in means lies inside the
#' bounds `low` and `high`, the smallest differences that would matter.
#' Equivalence is declared when both one-sided tests are significant,
#' which is the same as the 90% confidence interval (for `alpha = 0.05`)
#' lying inside the bounds. Uses Welch's t-test, or the paired or
#' one-sample t-test.
#'
#' @param x,y Numeric samples (`y = NULL` for one sample or paired
#'   differences already taken).
#' @param low,high Equivalence bounds for the difference (`x - y`), in the
#'   units of the data, from the smallest effect of interest.
#' @param paired Paired samples?
#' @param alpha Significance level of each one-sided test.
#' @return A `tv_advice` object (question `"equivalence"`) with the
#'   difference, the confidence interval, the two one-sided tests and the
#'   ordinary test in `checks`, the conclusion in `advice`, and `result`, a
#'   one-row tibble with `estimate`, `lower`, `upper`, `p_lower`,
#'   `p_upper`, `p_tost` and `equivalent`.
#' @references Schuirmann, D. J. (1987). A comparison of the two one-sided
#'   tests procedure and the power approach for assessing the equivalence
#'   of average bioavailability. Journal of Pharmacokinetics and
#'   Biopharmaceutics, 15, 657-680. \doi{10.1007/BF01068419}
#'
#'   Lakens, D. (2017). Equivalence tests: a practical primer for t tests,
#'   correlations, and meta-analyses. Social Psychological and Personality
#'   Science, 8, 355-362. \doi{10.1177/1948550617697177}
#' @export
#' @examples
#' # Is sleep gain under the two drugs within 0.5 hours?
#' tv_equivalence(sleep$extra[1:10], sleep$extra[11:20], low = -0.5, high = 0.5, paired = TRUE)
tv_equivalence <- function(x, y = NULL, low, high, paired = FALSE, alpha = 0.05) {
  if (!is.numeric(x) || length(x) < 2) cli::cli_abort("{.arg x} must be numeric with at least two values.")
  if (!is.numeric(low) || !is.numeric(high) || length(low) != 1 || length(high) != 1 || low >= high) {
    cli::cli_abort("{.arg low} must be a number below {.arg high}.")
  }
  if (!is.numeric(alpha) || length(alpha) != 1 || alpha <= 0 || alpha >= 0.5) {
    cli::cli_abort("{.arg alpha} must be between 0 and 0.5.")
  }
  tt <- function(mu, alt) {
    if (is.null(y)) {
      stats::t.test(x, mu = mu, alternative = alt)
    } else {
      stats::t.test(x, y, mu = mu, paired = paired, alternative = alt)
    }
  }
  t_lo <- tt(low, "greater")
  t_hi <- tt(high, "less")
  two <- tt(0, "two.sided")
  ci <- if (is.null(y)) {
    stats::t.test(x, conf.level = 1 - 2 * alpha)$conf.int
  } else {
    stats::t.test(x, y, paired = paired, conf.level = 1 - 2 * alpha)$conf.int
  }
  est <- if (is.null(y)) mean(x) else if (paired) mean(x - y) else mean(x) - mean(y)
  p_tost <- max(t_lo$p.value, t_hi$p.value)
  eq <- p_tost < alpha
  sig <- two$p.value < alpha
  fmt_p <- function(p) if (p < 0.001) "p < 0.001" else sprintf("p = %.3f", p)
  lvl <- round(100 * (1 - 2 * alpha))
  checks <- rbind(
    tv_check("Difference", sprintf("%s (%d%% CI %s to %s)", tv_num(est), lvl, tv_num(ci[1]), tv_num(ci[2])), sprintf("bounds %s to %s", tv_num(low), tv_num(high))),
    tv_check("Test against the lower bound", sprintf("t(%s) = %s, %s", tv_whole(t_lo$parameter), tv_num(t_lo$statistic), fmt_p(t_lo$p.value))),
    tv_check("Test against the upper bound", sprintf("t(%s) = %s, %s", tv_whole(t_hi$parameter), tv_num(t_hi$statistic), fmt_p(t_hi$p.value))),
    tv_check("Ordinary test of no difference", sprintf("t(%s) = %s, %s", tv_whole(two$parameter), tv_num(two$statistic), fmt_p(two$p.value)))
  )
  verdict <- if (eq && !sig) {
    "Equivalent: the difference is within the bounds and not significant"
  } else if (eq && sig) {
    "Equivalent but different: a real difference too small to matter"
  } else if (!eq && sig) {
    "Different: the difference is significant and not shown to be negligible"
  } else {
    "Inconclusive: neither equivalence nor a difference is shown"
  }
  step <- function(s, rec, why, code = "") tibble::tibble(step = s, recommendation = rec, reason = why, code = code)
  advice <- rbind(
    step("Conclusion", verdict, sprintf("Equivalence needs both one-sided tests to be significant (TOST %s); the %d%% confidence interval must lie inside %s to %s.", fmt_p(p_tost), lvl, tv_num(low), tv_num(high))),
    if (!eq && !sig) step("Next", "Collect more data or justify wider bounds", "An inconclusive result is common in small studies; the interval is too wide to say either way. Do not report it as 'no difference'."),
    step("Bounds", "Justify the bounds before seeing the data", "The bounds must come from the smallest effect that matters (biology, regulation or earlier studies), set in advance; bounds chosen after the analysis make the test meaningless."),
    step("For the paper", "Report both tests", sprintf("For example: \"The difference was %s (%d%% CI %s to %s); equivalence within %s to %s was %s (TOST, %s).\"", tv_num(est), lvl, tv_num(ci[1]), tv_num(ci[2]), tv_num(low), tv_num(high), if (eq) "supported" else "not supported", fmt_p(p_tost)))
  )
  structure(list(
    question = "equivalence", checks = checks, advice = advice,
    result = tibble::tibble(
      estimate = est, lower = ci[1], upper = ci[2], p_lower = t_lo$p.value,
      p_upper = t_hi$p.value, p_tost = p_tost, equivalent = eq
    )
  ), class = "tv_advice")
}

# nolint end
