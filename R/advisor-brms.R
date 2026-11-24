#' Advisor for brms: Bayesian regression and mixed models
#'
#' @description
#' Built-in advisor for [brms::brm()].
#'
#' * **Before** (`question = "bayesian"`): chooses the family from the kind
#'   of response (including `trials()` for successes out of trials, and
#'   zero-inflated families for counts with excess zeros), adds random
#'   intercepts for the grouping columns in `random`, and gives the code with
#'   weakly informative priors, a prior predictive check and a posterior
#'   predictive check.
#' * **After**: explains each population-level effect on its natural scale
#'   with its credible interval and the posterior probability of its
#'   direction; the standard deviation of each group-level effect; and the
#'   sampling diagnostics (R-hat, effective sample sizes, divergent
#'   transitions) that decide whether the posterior can be trusted at all.
#'
#' @param x A data frame (advice) or a `brmsfit` (interpretation).
#' @param question The question; set by [advise()].
#' @param response,predictors,random,trials As for [tv_advise_mixed()];
#'   `random` is optional.
#' @param level Width of the credible intervals.
#' @param ... Ignored.
#' @return A `tv_advice` or a `tv_interpretation` object.
#' @references
#' Bürkner, P.-C. (2017). brms: an R package for Bayesian multilevel models
#' using Stan. *Journal of Statistical Software* 80(1), 1-28.
#'
#' Gabry, J. et al. (2019). Visualization in Bayesian workflow. *Journal of
#' the Royal Statistical Society A* 182, 389-402.
#'
#' Vehtari, A. et al. (2021). Rank-normalization, folding, and localization:
#' an improved R-hat for assessing convergence of MCMC. *Bayesian Analysis*
#' 16, 667-718.
#' @name brms-advisor
#' @examplesIf rlang::is_installed("brms")
#' tidyvisor(mtcars, question = "bayesian", response = "am", predictors = "wt")
NULL

# nolint start: line_length_linter. Advice sentences read better unbroken.

#' @rdname brms-advisor
#' @export
tv_advise_brms <- function(x, question = "bayesian", response, predictors = NULL, random = NULL,
                           trials = NULL, ...) {
  predictors <- predictors %||% setdiff(names(x), c(response, trials, random))
  base <- tv_advise_regression(x, question = question, response = response,
                               predictors = predictors, trials = trials)
  checks <- base$checks
  for (g in random) {
    nl <- length(unique(stats::na.omit(x[[g]])))
    checks <- rbind(checks, tv_check(sprintf("Levels of %s", g), nl,
                                     if (nl < 5) "few levels: a group-level SD is weakly identified; give it an informative prior or use a fixed effect" else ""))
  }
  y <- x[[response]]
  kind <- tv_response_kind(stats::na.omit(y), trials)
  fam <- switch(kind$kind,
    binary = "bernoulli()",
    proportion = "binomial()",
    count = "poisson()",
    continuous = "gaussian()",
    if (grepl("Gamma", kind$family)) "Gamma(link = \"log\")" else "gaussian()"
  )
  if (kind$kind == "count") {
    yy <- stats::na.omit(y)
    m <- mean(yy)
    over <- m > 0 && stats::var(yy) / m > 1.5
    zi <- mean(yy == 0) > 2 * exp(-m) && mean(yy == 0) - exp(-m) > 0.1
    fam <- if (zi) "zero_inflated_negbinomial()" else if (over) "negbinomial()" else "poisson()"
  }
  lhs <- if (!is.null(trials)) sprintf("%s | trials(%s)", response, trials) else response
  rhs <- c(if (length(predictors)) predictors else "1", if (length(random)) sprintf("(1 | %s)", random))
  f <- sprintf("%s ~ %s", lhs, paste(rhs, collapse = " + "))
  pri <- if (fam == "gaussian()") "prior(normal(0, 2.5 * sd(y)), class = b)  # scale to the response" else "prior(normal(0, 1), class = b)"
  code <- paste0(
    "priors <- c(brms::", pri, ")\n",
    sprintf("m <- brms::brm(%s, family = %s, prior = priors,\n  data = data, chains = 4, cores = 4, seed = 1)", f, fam)
  )
  step <- function(s, r, why, code = "") tibble::tibble(step = s, recommendation = r, reason = why, code = code)
  advice <- rbind(
    step("Model", sprintf("Bayesian %s model with brms (%s)", if (length(random)) "multilevel" else "regression", fam),
         paste(kind$why, "Weakly informative priors keep estimates in a plausible range without dominating the data (Buerkner 2017)."), code),
    step("Before fitting", "Prior predictive check", "Simulate from the priors alone to see that they allow plausible data and rule out absurd data (Gabry et al. 2019).",
         sprintf("p <- brms::brm(%s, family = %s, prior = priors, data = data, sample_prior = \"only\")\nbrms::pp_check(p)", f, fam)),
    step("After fitting", "Check convergence, then the posterior predictive fit", "R-hat must be below 1.01 and effective sample sizes above 400 before any estimate is read (Vehtari et al. 2021).",
         "summary(m); brms::pp_check(m); brms::loo(m)"),
    step("Interpret", "Plain-language explanation of the model", "Effects with credible intervals and the probability of their direction.", "tidyvisor(m)")
  )
  structure(list(question = question, checks = checks, advice = advice), class = "tv_advice")
}

#' @rdname brms-advisor
#' @export
tv_interpret_brms <- function(x, level = 0.95, ...) {
  a <- (1 - level) / 2
  fe <- brms::fixef(x, probs = c(a, 1 - a))
  fam <- stats::family(x)
  link <- fam$link
  yname <- all.vars(x$formula$formula)[1]
  dat <- x$data
  xl <- tv_xlevels(dat)
  lvl <- round(100 * level)
  s <- list()
  ng <- if (length(x$ranef$group)) vapply(unique(x$ranef$group), function(g) length(unique(dat[[g]])), 1L) else integer()
  s$Overview <- sprintf(
    "Bayesian %s model of %s on %d observations%s (%s family, %s link), %d chains of %d post-warm-up draws.",
    if (length(ng)) "multilevel" else "regression", yname, nrow(dat),
    if (length(ng)) paste0(" in ", paste(sprintf("%d levels of %s", ng, names(ng)), collapse = " and ")) else "",
    fam$family, link, x$fit@sim$chains, (x$fit@sim$iter - x$fit@sim$warmup) %/% x$fit@sim$thin
  )

  # ---- Population-level effects ----
  draws <- posterior::as_draws_df(x)
  odds_of <- if (fam$family %in% c("bernoulli", "binomial")) tv_success_name(deparse(x$formula$formula[[2]])) else yname
  eff <- character()
  tab <- list()
  for (term in setdiff(rownames(fe), "Intercept")) {
    b <- fe[term, 1]
    lo <- fe[term, 3]
    hi <- fe[term, 4]
    d <- draws[[paste0("b_", term)]]
    pdir <- if (b >= 0) mean(d > 0) else mean(d < 0)
    fac <- names(xl)[startsWith(term, names(xl))]
    what <- if (length(fac)) {
      sprintf("%s = %s (compared with %s = %s)", fac[1], substring(term, nchar(fac[1]) + 1), fac[1], xl[[fac[1]]][1])
    } else {
      sprintf("each one-unit increase in %s", term)
    }
    dir <- if (b >= 0) "an increase" else "a decrease"
    eff <- c(eff, switch(link,
      identity = sprintf("%s: %s changes %s by %s (%d%% credible interval %s to %s); probability of %s %.0f%%.", term, what, yname, tv_num(b), lvl, tv_num(lo), tv_num(hi), dir, 100 * pdir),
      log = sprintf("%s: %s multiplies the expected %s by %s (%s; %d%% credible interval %s to %s); probability of %s %.0f%%.", term, what, yname, tv_num(exp(b)), tv_pct(exp(b)), lvl, tv_num(exp(lo)), tv_num(exp(hi)), dir, 100 * pdir),
      logit = sprintf("%s: %s multiplies the odds of %s by %s (odds ratio; %d%% credible interval %s to %s); probability of %s %.0f%%.", term, what, odds_of, tv_num(exp(b)), lvl, tv_num(exp(lo)), tv_num(exp(hi)), dir, 100 * pdir),
      sprintf("%s: coefficient %s on the %s scale (%d%% credible interval %s to %s); probability of %s %.0f%%.", term, tv_num(b), link, lvl, tv_num(lo), tv_num(hi), dir, 100 * pdir)
    ))
    tab[[term]] <- tibble::tibble(term = term, estimate = b, est_error = fe[term, 2], lower = lo, upper = hi, prob_direction = pdir)
  }
  if (length(eff)) {
    s$Effects <- c(
      eff,
      "Estimates are posterior means; the credible interval contains the effect with the stated probability, given the model and priors.",
      if (link %in% c("log", "logit")) "Effects on the log or logit scale are multiplicative: a factor of 1 means no effect."
    )
  }

  # ---- Group-level effects ----
  vc <- brms::VarCorr(x, probs = c(a, 1 - a))
  re <- character()
  for (g in names(vc)) {
    sdm <- vc[[g]]$sd
    if (is.null(sdm)) next
    for (r in rownames(sdm)) {
      re <- c(re, sprintf("%s: %s varies among groups with a standard deviation of %s (%d%% credible interval %s to %s)%s.", g, r, tv_num(sdm[r, 1]), lvl, tv_num(sdm[r, 3]), tv_num(sdm[r, 4]),
                          if (g == "residual__") "" else if (link == "identity") "" else sprintf(" on the %s scale", link)))
    }
  }
  if (length(re)) s$`Group-level effects` <- re

  # ---- Sampling diagnostics ----
  sm <- summary(x)
  pars <- rbind(sm$fixed, if (length(sm$random)) do.call(rbind, sm$random), sm$spec_pars)
  diag <- character()
  rh <- max(pars$Rhat, na.rm = TRUE)
  ess <- min(c(pars$Bulk_ESS, pars$Tail_ESS), na.rm = TRUE)
  diag <- c(diag, if (rh > 1.01) {
    sprintf("R-hat: up to %.3f (should be below 1.01): the chains disagree, so the posterior is not yet reliable; run longer chains or reparameterise before reading the estimates.", rh)
  } else {
    sprintf("R-hat: at most %.3f, below 1.01: the chains agree.", rh)
  })
  diag <- c(diag, if (ess < 400) {
    sprintf("Effective sample size: as low as %.0f (should exceed 400): means and especially interval limits are imprecise; increase iter.", ess)
  } else {
    sprintf("Effective sample size: at least %.0f, enough for stable estimates and intervals.", ess)
  })
  np <- brms::nuts_params(x)
  ndiv <- sum(np$Value[np$Parameter == "divergent__"])
  if (ndiv > 0) {
    diag <- c(diag, sprintf("Divergent transitions: %d. The sampler missed part of the posterior; raise adapt_delta (control = list(adapt_delta = 0.99)) or reparameterise.", ndiv))
  }
  s$`Sampling diagnostics` <- diag
  s$`Next steps` <- c(
    "brms::pp_check(m) compares data simulated from the model with the observed data; systematic differences show where the model fails.",
    "brms::loo(m) estimates out-of-sample fit for comparing models; plot(brms::conditional_effects(m)) shows each effect on the response scale."
  )
  structure(list(sections = s, tables = list(coefficients = do.call(rbind, tab))), class = "tv_interpretation")
}

# nolint end
