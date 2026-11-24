# nolint start: line_length_linter. Tables and advice sentences read better unbroken.

#' Power analysis: how many samples, sites or groups to collect
#'
#' @description
#' Advice before fieldwork: how large a study must be to detect the effect
#' that matters, with a given power (the chance of detecting the effect if
#' it is real) and significance level.
#'
#' Give the design and the smallest effect worth detecting, from
#' biology, earlier studies or a pilot:
#'
#' | `design` | Effect to give | Answer |
#' |---|---|---|
#' | `"two_groups"` | `delta` (difference in means), `sd` | samples per group (t-test) |
#' | `"paired"` | `delta`, `sd` of the within-pair differences | pairs |
#' | `"groups"` | `means` (expected group means), `sd` | samples per group (one-way ANOVA) |
#' | `"proportions"` | `p1`, `p2` | samples per group |
#' | `"counts"` | `mean1` and `ratio` (rate ratio), `theta` (negative binomial size; `Inf` for Poisson) | samples per group |
#' | `"regression"` | `r2` (partial R squared of the predictor(s) tested), `predictors` | observations |
#' | `"correlation"` | `r` | observations |
#' | `"sites"` | `delta`, `sd`, `icc`, `per_site` | sites per group, with samples nested in sites |
#'
#' Each answer comes with a sensitivity table (the size needed for half and
#' twice the effect, and for 90% power) because the effect is never known
#' exactly, and with the code that reproduces the calculation.
#'
#' With pilot data, `advise(pilot, question = "power", response = ...,
#' group = ...)` estimates the standard deviation (and the intra-class
#' correlation when `site` is given) from the pilot and asks only for the
#' effect. Use the smallest effect of biological interest, not the pilot's
#' observed difference: pilot effects are noisy, and powering a study on an
#' overestimate leaves it too small.
#'
#' @param design The design (see the table).
#' @param delta,sd Difference in means worth detecting, and the standard
#'   deviation within groups (in the same units).
#' @param means Expected means of three or more groups.
#' @param p1,p2 Expected proportions in two groups.
#' @param mean1,ratio,theta Expected mean count in the reference group,
#'   rate ratio worth detecting, and negative binomial size (dispersion;
#'   smaller is more overdispersed; `Inf` for Poisson).
#' @param r2,predictors Partial R squared of the tested predictor(s) and
#'   the total number of predictors.
#' @param r Correlation worth detecting.
#' @param icc,per_site Intra-class correlation (share of the variance
#'   between sites) and the number of samples per site.
#' @param power Target power (default 0.8).
#' @param alpha Significance level (default 0.05).
#' @param x Pilot data (a data frame).
#' @param question Set by [advise()].
#' @param response,group,site Columns of the pilot data.
#' @param ... Passed to `tv_power()` (the effect: `delta`, `ratio`, ...).
#' @return A `tv_advice` object: `checks` (inputs and sensitivity) and
#'   `advice` (the size needed and how to collect it), and `n`, the
#'   required size.
#' @references
#' Cohen, J. (1988). *Statistical Power Analysis for the Behavioral
#' Sciences*, second edition. Lawrence Erlbaum.
#'
#' Green, P. and MacLeod, C. J. (2016). SIMR: an R package for power
#' analysis of generalized linear mixed models by simulation. *Methods in
#' Ecology and Evolution* 7, 493-498.
#'
#' Johnson, P. C. D., Barry, S. J. E., Ferguson, H. M. and Mueller, P.
#' (2015). Power analysis for generalized linear mixed models in ecology
#' and evolution. *Methods in Ecology and Evolution* 6, 133-142.
#'
#' Zhu, H. and Lakkis, H. (2014). Sample size calculation for comparing two
#' negative binomial rates. *Statistics in Medicine* 33, 376-387.
#' @name power-advisor
#' @examples
#' # Detect a 5 cm difference in tree height (SD 8 cm) between two habitats
#' tv_power("two_groups", delta = 5, sd = 8)
#'
#' # Beetle counts: mean 4 per trap, detect a 1.5-fold difference
#' tv_power("counts", mean1 = 4, ratio = 1.5, theta = 2)
#'
#' # Plots nested in sites: how many sites per treatment?
#' tv_power("sites", delta = 5, sd = 8, icc = 0.2, per_site = 5)
#'
#' # From a pilot: the SD comes from the data, the effect from biology
#' advise(PlantGrowth, question = "power", response = "weight",
#'        group = "group", delta = 0.5)
NULL

#' @rdname power-advisor
#' @export
tv_power <- function(design = c("two_groups", "paired", "groups", "proportions", "counts",
                                "regression", "correlation", "sites"),
                     delta = NULL, sd = NULL, means = NULL, p1 = NULL, p2 = NULL,
                     mean1 = NULL, ratio = NULL, theta = Inf, r2 = NULL, predictors = 1,
                     r = NULL, icc = NULL, per_site = NULL, power = 0.8, alpha = 0.05) {
  design <- rlang::arg_match(design)
  need <- function(...) {
    a <- list(...)
    miss <- names(a)[vapply(a, is.null, TRUE)]
    if (length(miss)) cli::cli_abort("Design {.val {design}} needs {.arg {miss}}.", call = rlang::caller_env(2))
  }
  # n for a given effect multiplier and power; returns the size per unit
  # of the design (per group, pairs, observations or sites per group)
  size <- switch(design,
    two_groups = {
      need(delta = delta, sd = sd)
      function(m, pw) stats::power.t.test(delta = m * delta, sd = sd, power = pw, sig.level = alpha)$n
    },
    paired = {
      need(delta = delta, sd = sd)
      function(m, pw) stats::power.t.test(delta = m * delta, sd = sd, power = pw, sig.level = alpha, type = "paired")$n
    },
    groups = {
      need(means = means, sd = sd)
      if (length(means) < 3) cli::cli_abort("{.arg means} needs three or more groups; for two, use {.val two_groups}.")
      function(m, pw) {
        mm <- mean(means) + m * (means - mean(means))
        stats::power.anova.test(groups = length(means), between.var = stats::var(mm), within.var = sd^2, power = pw, sig.level = alpha)$n
      }
    },
    proportions = {
      need(p1 = p1, p2 = p2)
      function(m, pw) stats::power.prop.test(p1 = p1, p2 = p1 + m * (p2 - p1), power = pw, sig.level = alpha)$n
    },
    counts = {
      need(mean1 = mean1, ratio = ratio)
      function(m, pw) {
        rr <- exp(m * log(ratio))
        v <- 1 / mean1 + 1 / (mean1 * rr) + 2 / theta
        (stats::qnorm(1 - alpha / 2) + stats::qnorm(pw))^2 * v / log(rr)^2
      }
    },
    regression = {
      need(r2 = r2)
      function(m, pw) {
        f2 <- m * r2 / (1 - m * r2)
        tv_solve_n(function(n) {
          df2 <- n - predictors - 1
          stats::pf(stats::qf(1 - alpha, 1, df2), 1, df2, ncp = f2 * n, lower.tail = FALSE)
        }, pw, lower = predictors + 3)
      }
    },
    correlation = {
      need(r = r)
      function(m, pw) ((stats::qnorm(1 - alpha / 2) + stats::qnorm(pw)) / atanh(m * r))^2 + 3
    },
    sites = {
      need(delta = delta, sd = sd, icc = icc, per_site = per_site)
      function(m, pw) {
        n <- stats::power.t.test(delta = m * delta, sd = sd, power = pw, sig.level = alpha)$n
        n * (1 + (per_site - 1) * icc) / per_site
      }
    }
  )
  n <- ceiling(size(1, power))
  unit <- switch(design,
    two_groups = , groups = , proportions = , counts = "samples per group",
    paired = "pairs", regression = , correlation = "observations", sites = "sites per group"
  )
  total <- switch(design,
    two_groups = , proportions = , counts = 2 * n, groups = length(means) * n,
    sites = 2 * n * per_site, n
  )

  eff <- switch(design,
    two_groups = sprintf("difference %s with SD %s (Cohen's d = %.2f)", tv_num(delta), tv_num(sd), delta / sd),
    paired = sprintf("mean difference %s with SD of differences %s (d = %.2f)", tv_num(delta), tv_num(sd), delta / sd),
    groups = sprintf("means %s with SD %s (Cohen's f = %.2f)", paste(means, collapse = ", "), tv_num(sd), sqrt(mean((means - mean(means))^2)) / sd),
    proportions = sprintf("%s against %s", tv_num(p1), tv_num(p2)),
    counts = sprintf("mean %s against %s (rate ratio %s), %s", tv_num(mean1), tv_num(mean1 * ratio), tv_num(ratio), if (is.finite(theta)) sprintf("negative binomial size %s", tv_num(theta)) else "Poisson"),
    regression = sprintf("partial R squared %s with %d predictor%s (f2 = %.3f)", tv_num(r2), predictors, if (predictors == 1) "" else "s", r2 / (1 - r2)),
    correlation = sprintf("r = %s", tv_num(r)),
    sites = sprintf("difference %s with SD %s, intra-class correlation %s, %d samples per site", tv_num(delta), tv_num(sd), tv_num(icc), per_site)
  )
  sens <- function(m, pw) {
    v <- tryCatch(ceiling(size(m, pw)), error = function(e) NA)
    if (is.na(v)) "not reachable" else as.character(v)
  }
  checks <- rbind(
    tv_check("Design", design),
    tv_check("Effect to detect", eff),
    tv_check("Power, significance level", sprintf("%.0f%%, %s", 100 * power, alpha)),
    tv_check(sprintf("Needed: %s", unit), n, sprintf("%d in total", total)),
    tv_check("If the effect is half as large", sens(0.5, power), unit),
    tv_check("If it is twice as large", sens(2, power), unit),
    tv_check("For 90% power", sens(1, 0.9), unit)
  )

  code <- switch(design,
    two_groups = sprintf("power.t.test(delta = %s, sd = %s, power = %s, sig.level = %s)", delta, sd, power, alpha),
    paired = sprintf("power.t.test(delta = %s, sd = %s, power = %s, sig.level = %s, type = \"paired\")", delta, sd, power, alpha),
    groups = sprintf("power.anova.test(groups = %d, between.var = var(c(%s)), within.var = %s^2, power = %s)", length(means), paste(means, collapse = ", "), sd, power),
    proportions = sprintf("power.prop.test(p1 = %s, p2 = %s, power = %s, sig.level = %s)", p1, p2, power, alpha),
    counts = sprintf("# check by simulation: power for n per group\nsim <- function(n) {\n  g <- gl(2, n)\n  y <- MASS::rnegbin(2 * n, mu = %s * c(1, %s)[g], theta = %s)\n  summary(MASS::glm.nb(y ~ g))$coefficients[2, 4] < %s\n}\nmean(replicate(500, sim(%d)))", mean1, ratio, if (is.finite(theta)) theta else 1e6, alpha, n),
    regression = sprintf("# pwr::pwr.f2.test(u = 1, f2 = %.3f, power = %s)   # v + %d + 1 = n", r2 / (1 - r2), power, predictors),
    correlation = sprintf("# pwr::pwr.r.test(r = %s, power = %s)", r, power),
    sites = "# with pilot data, simulate the mixed model directly:\n# m <- lme4::lmer(y ~ treatment + (1 | site), data = pilot)\n# simr::powerCurve(simr::extend(m, along = \"site\", n = 40), along = \"site\")"
  )
  step <- function(s, rec, why, code = "") tibble::tibble(step = s, recommendation = rec, reason = why, code = code)
  advice <- rbind(
    step("Sample size", sprintf("Collect at least %d %s (%d in total)", n, unit, total),
         sprintf("Gives a %.0f%% chance of detecting %s at the %s level; with fewer, a real effect of that size will often be missed and a non-significant result will say little.", 100 * power, eff, alpha), code),
    if (design == "sites") {
      m_opts <- c(1, 2, 5, 10, 20)
      tab <- vapply(m_opts, function(k) ceiling(stats::power.t.test(delta = delta, sd = sd, power = power, sig.level = alpha)$n * (1 + (k - 1) * icc) / k), 0)
      step("Design", "Prefer more sites to more samples per site",
           sprintf("Samples within a site are correlated (ICC %s), so each extra sample per site adds less. Sites per group needed for 1, 2, 5, 10 and 20 samples per site: %s. Beyond a few samples per site, only more sites help.", tv_num(icc), paste(tab, collapse = ", ")))
    },
    if (design == "counts") step("Analysis", if (is.finite(theta)) "Negative binomial GLM" else "Poisson GLM",
                                 "The calculation assumes the counts will be analysed with a count GLM; overdispersion (small size) raises the sample size needed, so estimate it from a pilot.", ""),
    step("Before the field", "Add a margin for losses", "Traps fail, plots flood and samples are lost: collect 10-20% more than the minimum. Randomise which units get each treatment, and record the site and date of every sample.", ""),
    step("Check", "The effect size drives everything",
         "Halving the effect roughly quadruples the sample size (see the checks). Use the smallest effect that would matter biologically, from the literature or a pilot, and report the power analysis with the study.", "")
  )
  structure(list(question = "power", checks = checks, advice = advice, n = n), class = "tv_advice")
}

#' @rdname power-advisor
#' @export
tv_advise_power <- function(x, question = "power", response, group = NULL, site = NULL, ...) {
  if (missing(response) || !response %in% names(x)) cli::cli_abort("Give {.arg response}, the pilot's response column.")
  dots <- list(...)
  y <- x[[response]]
  ok <- is.finite(y)
  if (!is.null(group)) {
    g <- droplevels(factor(x[[group]][ok]))
    yy <- y[ok]
    sd_w <- sqrt(sum(tapply(yy, g, function(v) sum((v - mean(v))^2))) / (length(yy) - nlevels(g)))
  } else {
    sd_w <- stats::sd(y[ok])
  }
  counts <- all(y[ok] >= 0) && all(y[ok] == round(y[ok]))
  if (counts && is.null(dots$delta) && !is.null(dots$ratio)) {
    m <- mean(y[ok])
    v <- stats::var(y[ok])
    th <- if (v > m) m^2 / (v - m) else Inf
    args <- utils::modifyList(list(design = "counts", mean1 = m, theta = th), dots)
  } else if (!is.null(site)) {
    s <- factor(x[[site]][ok])
    yy <- y[ok]
    # one-way ANOVA estimator of the intra-class correlation
    k0 <- mean(table(s))
    a <- stats::anova(stats::lm(yy ~ s))
    icc <- max(0, (a[1, 3] - a[2, 3]) / (a[1, 3] + (k0 - 1) * a[2, 3]))
    args <- utils::modifyList(list(design = "sites", sd = sqrt(a[2, 3] + max(0, (a[1, 3] - a[2, 3]) / k0)), icc = icc, per_site = round(k0)), dots)
  } else {
    args <- utils::modifyList(list(design = if (!is.null(group) && nlevels(g) > 2 && !is.null(dots$means)) "groups" else "two_groups", sd = sd_w), dots)
  }
  if (is.null(args$delta) && is.null(args$ratio) && is.null(args$means) && is.null(args$r2) && is.null(args$r)) {
    cli::cli_abort(c(
      "Give the effect worth detecting, for example {.code delta = } (difference in means) or {.code ratio = } (for counts).",
      i = "The pilot gives the spread (SD {tv_num(sd_w)}); the effect should come from biology, not from the pilot's own difference, which is noisy."
    ))
  }
  out <- do.call(tv_power, args)
  out$checks <- rbind(tv_check("From the pilot", sprintf("%d observations of %s", sum(ok), response),
                               if (identical(args$design, "counts")) sprintf("mean %s, negative binomial size %s", tv_num(args$mean1), tv_num(args$theta)) else if (identical(args$design, "sites")) sprintf("SD %s, intra-class correlation %s", tv_num(args$sd), tv_num(args$icc)) else sprintf("within-group SD %s", tv_num(args$sd))),
                      out$checks)
  out
}

# nolint end

tv_solve_n <- function(pw_fun, target, lower = 4, upper = 1e6) {
  if (pw_fun(upper) < target) stop("not reachable")
  stats::uniroot(function(n) pw_fun(n) - target, c(lower, upper))$root
}
