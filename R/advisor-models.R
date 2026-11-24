#' Advisers for mixed, additive and overdispersed models
#'
#' @description
#' Built-in advisers for four widely used modelling packages. Each gives
#' advice before fitting (from a data frame) and a plain-language
#' interpretation after it (from the fitted model).
#'
#' * **lme4** (`question = "mixed"`, or a `random` argument): linear and
#'   generalised linear mixed models, [lme4::lmer()], [lme4::glmer()] and
#'   [lme4::glmer.nb()]. The advice checks the grouping factors (number of
#'   levels, observations per level) and chooses the family. The
#'   interpretation reports fixed effects on their natural scale, the
#'   variance of each random effect, the intra-class correlation, and
#'   singular or non-converged fits.
#' * **glmmTMB** (`question = "zero_inflation"`): mixed models for
#'   overdispersed and zero-inflated counts with [glmmTMB::glmmTMB()]; the
#'   interpretation adds the zero-inflation part and the dispersion.
#' * **mgcv** (`question = "smooth"`, or a `smooth` argument): generalised
#'   additive models with [mgcv::gam()]. The interpretation explains each
#'   smooth by its effective degrees of freedom, checks the basis dimension
#'   (`k`) and concurvity.
#' * **aods3** (`question = "overdispersion"`): beta-binomial and negative
#'   binomial models with [aods3::aodml()] for proportions and counts more
#'   variable than the binomial or Poisson allows.
#'
#' @param x A data frame (advice) or a fitted model (interpretation).
#' @param question The question; set by [advise()].
#' @param response Name of the response column.
#' @param predictors Names of the fixed-effect predictor columns (default:
#'   all other columns except `random`, `smooth` and `trials`).
#' @param random Names of the grouping columns for random intercepts.
#' @param smooth Names of the numeric predictors to model with smooths.
#' @param trials Name of the column with the number of trials, for
#'   successes out of trials.
#' @param engine Package to fit the mixed model with, `"lme4"` or
#'   `"glmmTMB"`.
#' @param level Confidence level for the intervals.
#' @param ... Ignored.
#' @return A `tv_advice` or a `tv_interpretation` object.
#' @references
#' Bolker, B.M. et al. (2009). Generalized linear mixed models: a practical
#' guide for ecology and evolution. *Trends in Ecology & Evolution* 24,
#' 127-135.
#'
#' Brooks, M.E. et al. (2017). glmmTMB balances speed and flexibility among
#' packages for zero-inflated generalized linear mixed modeling. *The R
#' Journal* 9, 378-400.
#'
#' Harrison, X.A. et al. (2018). A brief introduction to mixed effects
#' modelling and multi-model inference in ecology. *PeerJ* 6, e4794.
#'
#' Nakagawa, S. & Schielzeth, H. (2013). A general and simple method for
#' obtaining R2 from generalized linear mixed-effects models. *Methods in
#' Ecology and Evolution* 4, 133-142.
#'
#' Wood, S.N. (2017). *Generalized Additive Models: An Introduction with R*,
#' 2nd ed. Chapman & Hall/CRC.
#'
#' Lesnoff, M. & Lancelot, R. (2012). aods3: analysis of overdispersed data
#' using S3 methods. R package.
#' @name model-advisors
#' @examplesIf rlang::is_installed("lme4")
#' tidyvisor(lme4::sleepstudy, response = "Reaction", predictors = "Days",
#'   random = "Subject")
#' m <- lme4::lmer(Reaction ~ Days + (1 | Subject), data = lme4::sleepstudy)
#' tidyvisor(m)
NULL

# nolint start: line_length_linter. Advice sentences read better unbroken.

#' @rdname model-advisors
#' @export
tv_advise_mixed <- function(x, question = "mixed", response, predictors = NULL, random,
                            trials = NULL, engine = c("lme4", "glmmTMB"), ...) {
  engine <- match.arg(engine)
  if (missing(random) || !is.character(random) || !all(random %in% names(x))) {
    cli::cli_abort("Give {.arg random}, the name{?s} of the grouping column{?s} for random effects.")
  }
  predictors <- predictors %||% setdiff(names(x), c(response, trials, random))
  base <- tv_advise_regression(x, question = question, response = response,
                               predictors = predictors, trials = trials)
  d <- x[stats::complete.cases(x[unique(c(response, predictors, trials, random))]), , drop = FALSE]
  checks <- base$checks
  few <- character()
  for (g in random) {
    tb <- table(d[[g]])
    nl <- length(tb)
    if (nl < 5) few <- c(few, g)
    checks <- rbind(checks, tv_check(
      sprintf("Levels of %s", g),
      sprintf("%d (observations per level: %d to %d, median %g)", nl, min(tb), max(tb), stats::median(tb)),
      if (nl < 5) "fewer than 5 levels: its variance cannot be estimated well; treat it as a fixed effect instead" else ""
    ))
  }

  y <- d[[response]]
  kind <- tv_response_kind(y, trials)
  zeros <- FALSE
  overd <- FALSE
  if (kind$kind == "count") {
    m <- mean(y)
    overd <- m > 0 && stats::var(y) / m > 1.5
    zeros <- mean(y == 0) > 2 * exp(-m) && mean(y == 0) - exp(-m) > 0.1
  }
  if (engine == "lme4" && zeros) engine <- "glmmTMB"
  fam <- kind$family
  lhs <- if (!is.null(trials)) sprintf("cbind(%s, %s - %s)", response, trials, response) else response
  fixed <- if (length(predictors)) paste(predictors, collapse = " + ") else "1"
  f <- sprintf("%s ~ %s + %s", lhs, fixed, paste0("(1 | ", random, ")", collapse = " + "))

  if (engine == "glmmTMB") {
    tfam <- if (kind$kind == "count") {
      if (overd) "nbinom2" else "poisson"
    } else {
      fam
    }
    code <- sprintf("m <- glmmTMB::glmmTMB(%s,%s family = %s, data = data)", f, if (zeros) " ziformula = ~1," else "", tfam)
    what <- sprintf("Generalised linear mixed model (glmmTMB, %s%s)", tfam, if (zeros) ", zero-inflated" else "")
    why <- paste(
      "Observations in the same group are not independent; random intercepts for", paste(random, collapse = " and "),
      "account for it.", if (zeros) "The data have more zeros than a count distribution predicts, so a zero-inflation part is added (Brooks et al. 2017)." else "",
      if (overd) "The counts are overdispersed, so the negative binomial (nbinom2) is used." else ""
    )
  } else {
    code <- if (fam == "gaussian") {
      sprintf("m <- lme4::lmer(%s, data = data)", f)
    } else if (kind$kind == "count" && overd) {
      sprintf("m <- lme4::glmer.nb(%s, data = data)", f)
    } else {
      sprintf("m <- lme4::glmer(%s, family = %s, data = data)", f, fam)
    }
    what <- if (fam == "gaussian") "Linear mixed model (lme4::lmer)" else "Generalised linear mixed model (lme4)"
    why <- paste(
      "Observations in the same group are not independent; random intercepts for", paste(random, collapse = " and "),
      "account for it and let the results generalise to other groups (Bolker et al. 2009).",
      if (kind$kind == "count" && overd) "The counts are overdispersed, so the negative binomial is used." else ""
    )
  }
  step <- function(s, r, why, code = "") tibble::tibble(step = s, recommendation = r, reason = why, code = code)
  advice <- rbind(
    step("Model", what, trimws(gsub(" +", " ", why)), code),
    if (length(few)) step("Grouping", sprintf("Use %s as fixed effects", paste(few, collapse = ", ")), "A random effect needs at least 5 levels to estimate its variance (Harrison et al. 2018).", ""),
    step("Random slopes", "Consider a random slope for a predictor that varies within groups", "If the effect of a predictor differs among groups, a random intercept alone makes its p-value too small.",
         if (length(predictors)) sprintf("(1 + %s | %s)", predictors[1], random[1]) else ""),
    base$advice[base$advice$step %in% c("Before fitting", "After fitting"), ],
    step("Interpret", "Plain-language explanation of the model", "Fixed effects on the scale of the response, random-effect variances and diagnostics.", "tidyvisor(m)")
  )
  structure(list(question = question, checks = checks, advice = advice), class = "tv_advice")
}

tv_advise_glmmtmb <- function(x, question = "zero_inflation", ...) {
  tv_advise_mixed(x, question = question, ..., engine = "glmmTMB")
}

#' @rdname model-advisors
#' @export
tv_advise_gam <- function(x, question = "smooth", response, predictors = NULL, smooth = NULL,
                          random = NULL, trials = NULL, ...) {
  predictors <- predictors %||% setdiff(names(x), c(response, trials, random))
  num <- predictors[vapply(predictors, function(p) is.numeric(x[[p]]), TRUE)]
  smooth <- smooth %||% num
  base <- tv_advise_regression(x, question = question, response = response,
                               predictors = predictors, trials = trials)
  checks <- base$checks
  k_txt <- character()
  for (v in smooth) {
    u <- length(unique(stats::na.omit(x[[v]])))
    k <- min(10, u - 1)
    k_txt <- c(k_txt, if (u < 10) sprintf("s(%s, k = %d)", v, max(3, k)) else sprintf("s(%s)", v))
    checks <- rbind(checks, tv_check(
      sprintf("Unique values of %s", v), u,
      if (u < 10) "few distinct values: lower the basis dimension k (at most the number of values minus 1)" else ""
    ))
  }
  lin <- setdiff(predictors, smooth)
  re <- if (length(random)) sprintf("s(%s, bs = \"re\")", random)
  rhs <- paste(c(k_txt, lin, re), collapse = " + ")
  kind <- tv_response_kind(x[[response]], trials)
  fam <- if (grepl("glm.nb", base$advice$code[1])) "mgcv::nb()" else kind$family
  lhs <- if (!is.null(trials)) sprintf("cbind(%s, %s - %s)", response, trials, response) else response
  code <- sprintf("m <- mgcv::gam(%s ~ %s, family = %s, method = \"REML\", data = data)", lhs, if (nzchar(rhs)) rhs else "1", fam)
  step <- function(s, r, why, code = "") tibble::tibble(step = s, recommendation = r, reason = why, code = code)
  advice <- rbind(
    step("Model", sprintf("Generalised additive model (mgcv, %s)", fam),
         "Smooth functions let the data show the shape of each relation instead of assuming a straight line; REML estimates the smoothness (Wood 2017).", code),
    base$advice[base$advice$step == "Before fitting", ],
    step("After fitting", "Check the basis dimension and the residuals", "A k-index well below 1 with a small p-value means a smooth needs a larger k.", "mgcv::gam.check(m)"),
    step("Interpret", "Plain-language explanation of the model", "Each smooth by its shape and significance, the parametric effects and diagnostics.", "tidyvisor(m); plot(m, pages = 1)")
  )
  structure(list(question = question, checks = checks, advice = advice), class = "tv_advice")
}

#' @rdname model-advisors
#' @export
tv_advise_aod <- function(x, question = "overdispersion", response, predictors = NULL,
                          trials = NULL, ...) {
  predictors <- predictors %||% setdiff(names(x), c(response, trials))
  base <- tv_advise_regression(x, question = question, response = response,
                               predictors = predictors, trials = trials)
  y <- x[[response]]
  kind <- tv_response_kind(y, trials)
  rhs <- if (length(predictors)) paste(predictors, collapse = " + ") else "1"
  checks <- base$checks
  if (kind$kind == "proportion") {
    p <- y / x[[trials]]
    ok <- is.finite(p)
    fit <- stats::glm(stats::reformulate(if (length(predictors)) predictors else "1", "cbind(y, n - y)"),
                      family = stats::binomial, data = cbind(x[ok, predictors, drop = FALSE], y = y[ok], n = x[[trials]][ok]))
    phi <- sum(stats::residuals(fit, type = "pearson")^2) / fit$df.residual
    checks <- rbind(checks, tv_check("Binomial dispersion (Pearson / df)", sprintf("%.2f", phi),
                                     if (phi > 1.5) "above 1: the proportions vary more than the binomial allows" else "close to 1: a plain binomial glm may be enough"))
    code <- sprintf("m <- aods3::aodml(cbind(%s, %s - %s) ~ %s, family = \"bb\", data = data)", response, trials, response, rhs)
    what <- "Beta-binomial model (aods3::aodml, family = \"bb\")"
    why <- "When proportions vary more among units than the binomial predicts, the beta-binomial estimates the extra variation (phi) and gives honest standard errors."
  } else if (kind$kind == "count") {
    code <- sprintf("m <- aods3::aodml(%s ~ %s, family = \"nb\", data = data)", response, rhs)
    what <- "Negative binomial model (aods3::aodml, family = \"nb\")"
    why <- "Counts more variable than the Poisson are modelled with a negative binomial whose extra variation (phi) is estimated."
  } else {
    cli::cli_abort("The overdispersion adviser needs counts, or successes out of {.arg trials}.")
  }
  step <- function(s, r, why, code = "") tibble::tibble(step = s, recommendation = r, reason = why, code = code)
  advice <- rbind(
    step("Model", what, why, code),
    base$advice[base$advice$step == "Before fitting", ],
    step("Interpret", "Plain-language explanation of the model", "Effects on the odds or rate scale and the size of the overdispersion.", "tidyvisor(m)")
  )
  structure(list(question = question, checks = checks, advice = advice), class = "tv_advice")
}

# ---- Interpretation ----

#' @rdname model-advisors
#' @export
tv_interpret_mixed <- function(x, level = 0.95, ...) {
  tmb <- inherits(x, "glmmTMB")
  fam <- stats::family(x)
  famname <- fam$family
  link <- fam$link
  mf <- stats::model.frame(x)
  yname <- deparse(stats::formula(x)[[2]])
  n <- stats::nobs(x)
  if (tmb) {
    vc <- glmmTMB::VarCorr(x)$cond
    re_sd <- unlist(lapply(names(vc), function(g) stats::setNames(attr(vc[[g]], "stddev"), paste(g, names(attr(vc[[g]], "stddev")), sep = ": "))))
    groups <- vapply(names(vc), function(g) length(unique(mf[[g]])), 1L)
    cf <- summary(x)$coefficients$cond
  } else {
    vc <- as.data.frame(lme4::VarCorr(x))
    vc <- vc[is.na(vc$var2), ]
    resid <- vc$grp == "Residual"
    re_sd <- stats::setNames(vc$sdcor[!resid], paste(vc$grp[!resid], vc$var1[!resid], sep = ": "))
    groups <- lme4::ngrps(x)
    cf <- stats::coef(summary(x))
  }
  gauss <- famname == "gaussian"
  s <- list()
  s$Overview <- sprintf(
    "%s mixed model of %s on %d observations in %s (%s family, %s link), fitted with %s.",
    if (gauss) "Linear" else "Generalised linear", yname, n,
    paste(sprintf("%d levels of %s", groups, names(groups)), collapse = " and "),
    famname, link, if (tmb) "glmmTMB" else "lme4"
  )

  # ---- Random effects ----
  rs <- sprintf("%s varies with a standard deviation of %s%s.", names(re_sd), tv_num(re_sd),
                if (link == "identity") sprintf(" (in units of %s)", yname) else sprintf(" on the %s scale", link))
  sig <- if (gauss) stats::sigma(x) else NA
  int <- grepl("\\(Intercept\\)$", names(re_sd))
  if (gauss && any(int)) {
    icc <- sum(re_sd[int]^2) / (sum(re_sd[int]^2) + sig^2)
    rs <- c(rs, sprintf("Residual standard deviation %s. Intra-class correlation %.2f: %.0f%% of the variance left after the fixed effects lies between groups.", tv_num(sig), icc, 100 * icc))
  } else if (link == "logit" && any(int)) {
    icc <- sum(re_sd[int]^2) / (sum(re_sd[int]^2) + pi^2 / 3)
    rs <- c(rs, sprintf("Intra-class correlation on the latent scale %.2f (residual variance pi^2/3 for the logit link).", icc))
  }
  s$`Random effects` <- rs

  # ---- Fixed effects ----
  crit <- stats::qnorm(1 - (1 - level) / 2)
  odds_of <- if (famname == "binomial") tv_odds_of(mf[[1]], yname) else yname
  e <- tv_effects(cf, crit, link, yname, odds_of, tv_xlevels(mf), level)
  if (length(e$sentences)) {
    s$Effects <- c(
      e$sentences,
      if (ncol(cf) < 4) "lmer() gives no p-values; those shown use the normal approximation (Wald z), which is optimistic with few groups. For small samples, use lmerTest or a parametric bootstrap.",
      "Fixed effects are for a typical group (random effects at zero), with the other predictors held fixed."
    )
  }

  # ---- Diagnostics ----
  diag <- character()
  if (tmb) {
    if (!isTRUE(x$sdr$pdHess)) diag <- c(diag, "Convergence: the Hessian is not positive definite, so the fit is unreliable; simplify the model (fewer random effects or zero-inflation terms) or rescale predictors.")
    if (any(re_sd < 1e-4)) diag <- c(diag, sprintf("Singular fit: the variance of %s is estimated as zero; drop that random effect.", names(re_sd)[re_sd < 1e-4][1]))
  } else {
    if (lme4::isSingular(x)) diag <- c(diag, "Singular fit: a random-effect variance is (nearly) zero or correlations are +/-1; the random structure is too complex for the data, so simplify it.")
    msg <- x@optinfo$conv$lme4$messages
    if (length(msg)) diag <- c(diag, sprintf("Convergence warning: %s. Rescale predictors or try another optimiser (lme4::allFit()).", msg[1]))
  }
  if (any(groups < 5)) {
    diag <- c(diag, sprintf("Few levels: %s has %d levels, too few to estimate its variance well; consider a fixed effect.", names(groups)[which.min(groups)], min(groups)))
  }
  if (famname %in% c("poisson", "binomial")) {
    rdf <- stats::df.residual(x)
    phi <- sum(stats::residuals(x, type = "pearson")^2) / rdf
    binary <- famname == "binomial" && is.null(dim(mf[[1]])) && length(unique(mf[[1]])) <= 2
    if (!binary && is.finite(phi)) {
      diag <- c(diag, if (phi > 1.5) {
        sprintf("Overdispersion: Pearson statistic / residual df = %.2f; add an observation-level random effect or use a negative binomial (%s).", phi, if (famname == "poisson") "glmer.nb() or glmmTMB(family = nbinom2)" else "glmmTMB(family = betabinomial)")
      } else {
        sprintf("Dispersion: Pearson statistic / residual df = %.2f, consistent with the %s.", phi, famname)
      })
    }
  }
  if (famname %in% c("poisson", "nbinom2")) {
    mu <- stats::fitted(x)
    y <- mf[[1]]
    p0 <- if (famname == "poisson") stats::dpois(0, mu) else stats::dnbinom(0, size = stats::sigma(x), mu = mu)
    zi <- tmb && !identical(deparse(x$modelInfo$allForm$ziformula), "~0")
    if (!zi && mean(y == 0) > 1.2 * mean(p0) && mean(y == 0) - mean(p0) > 0.05) {
      diag <- c(diag, sprintf("Zeros: %.0f%% observed, %.0f%% expected from the model; consider a zero-inflated model (glmmTMB with ziformula = ~1).", 100 * mean(y == 0), 100 * mean(p0)))
    }
  }
  if (tmb && !identical(deparse(x$modelInfo$allForm$ziformula), "~0")) {
    zc <- summary(x)$coefficients$zi
    if (!is.null(zc) && "(Intercept)" %in% rownames(zc)) {
      diag <- c(diag, sprintf("Zero-inflation: for a typical observation, the probability of an extra (structural) zero is %.0f%%.", 100 * stats::plogis(zc["(Intercept)", 1])))
    }
  }
  if (gauss) {
    r <- stats::residuals(x)
    if (length(r) >= 3 && length(r) <= 5000) {
      sw <- stats::shapiro.test(r)
      diag <- c(diag, sprintf("Normality of residuals (Shapiro-Wilk): W = %.3f, %s%s", sw$statistic, tv_p(sw$p.value),
                              if (sw$p.value < 0.05) "; inspect the Q-Q plot; mixed models are fairly robust to mild departures." else "."))
    }
  }
  s$Diagnostics <- if (length(diag)) diag else "No problems found by the checks run."
  s$`Reading the plots` <- c(
    "Plot residuals against fitted values (look for curves or a funnel) and a Q-Q plot of the random effects (lattice::qqmath(lme4::ranef(m))).",
    "For generalised models, simulated residuals (DHARMa::simulateResiduals(m)) are easier to read than raw residuals."
  )
  structure(list(sections = s, tables = list(coefficients = e$table, random = tibble::tibble(term = names(re_sd), sd = unname(re_sd)))), class = "tv_interpretation")
}

#' @rdname model-advisors
#' @export
tv_interpret_gam <- function(x, level = 0.95, ...) {
  sm <- summary(x)
  fam <- x$family
  link <- fam$link
  yname <- deparse(stats::formula(x)[[2]])
  s <- list()
  s$Overview <- sprintf("Generalised additive model of %s on %d observations (%s family, %s link), smoothness by %s.",
                        yname, sm$n, fam$family, link, x$method)
  s$Fit <- sprintf("The model explains %.1f%% of the deviance (adjusted R-squared %.2f).", 100 * sm$dev.expl, sm$r.sq)

  st <- sm$s.table
  if (!is.null(st) && nrow(st)) {
    sm_txt <- vapply(seq_len(nrow(st)), function(i) {
      edf <- st[i, "edf"]
      p <- st[i, ncol(st)]
      shape <- if (edf < 1.1) "close to a straight line" else if (edf < 2.5) "gently curved" else "clearly non-linear"
      sprintf("%s: effective degrees of freedom %.2f (%s), %s%s.", rownames(st)[i], edf, shape, tv_p(p),
              if (p >= 0.05) "; no clear effect" else "")
    }, "")
    s$Smooths <- c(sm_txt, "The edf measures wiggliness: 1 is a straight line, larger values more complex curves. Read the shape from plot(m), not from a coefficient.")
  }
  pt <- sm$p.table
  crit <- stats::qnorm(1 - (1 - level) / 2)
  mf <- stats::model.frame(x)
  odds_of <- if (fam$family == "binomial") tv_odds_of(mf[[1]], yname) else yname
  e <- tv_effects(pt, crit, link, yname, odds_of, tv_xlevels(mf), level)
  if (length(e$sentences)) s$`Parametric effects` <- e$sentences

  diag <- character()
  kc <- tryCatch(mgcv::k.check(x), error = function(e) NULL)
  if (!is.null(kc) && nrow(kc)) {
    bad <- rownames(kc)[kc[, "k-index"] < 1 & kc[, "p-value"] < 0.05]
    diag <- c(diag, if (length(bad)) {
      sprintf("Basis dimension: k may be too small for %s (k-index below 1, small p-value); refit with a larger k and see whether the edf rises.", paste(bad, collapse = ", "))
    } else {
      "Basis dimension: k is large enough for every smooth (mgcv::k.check())."
    })
  }
  if (nrow(st %||% matrix(nrow = 0, ncol = 1)) > 1) {
    cc <- tryCatch(mgcv::concurvity(x, full = TRUE), error = function(e) NULL)
    if (!is.null(cc)) {
      worst <- cc["worst", -1, drop = TRUE]
      if (any(worst > 0.8)) {
        diag <- c(diag, sprintf("Concurvity: %s is largely a smooth function of the other terms (%.2f); its shape is poorly separated from theirs.", names(worst)[which.max(worst)], max(worst)))
      }
    }
  }
  if (fam$family %in% c("poisson", "binomial") && x$df.residual > 0) {
    phi <- sum(stats::residuals(x, type = "pearson")^2) / x$df.residual
    binary <- fam$family == "binomial" && all(x$y %in% c(0, 1)) && all(x$prior.weights == 1)
    if (!binary && phi > 1.5) diag <- c(diag, sprintf("Overdispersion: Pearson statistic / residual df = %.2f; use family = %s.", phi, if (fam$family == "poisson") "nb()" else "quasibinomial()"))
  }
  s$Diagnostics <- if (length(diag)) diag else "No problems found by the checks run."
  s$`Reading the plots` <- c(
    "plot(m, pages = 1, shade = TRUE) draws each smooth with its confidence band on the link scale; where the band includes zero across the range, the effect is weak.",
    "mgcv::gam.check(m) draws residual plots and reports the basis checks."
  )
  structure(list(sections = s, tables = list(coefficients = e$table, smooths = st)), class = "tv_interpretation")
}

#' @rdname model-advisors
#' @export
tv_interpret_aod <- function(x, level = 0.95, ...) {
  sm <- summary(x)
  famname <- x$family
  link <- if (famname == "bb") "logit" else "log"
  yname <- deparse(x$formula[[2]])
  n <- nrow(x$dat)
  s <- list()
  s$Overview <- sprintf("%s model of %s on %d observations (aods3::%s).",
                        if (famname == "bb") "Beta-binomial" else "Negative binomial", yname, n, class(x)[1])
  cf <- sm$BCoef
  crit <- stats::qnorm(1 - (1 - level) / 2)
  mf <- x$dat
  xl <- lapply(Filter(function(v) is.factor(v) || is.character(v), mf), function(v) levels(as.factor(v)))
  e <- tv_effects(as.matrix(cf), crit, link, yname, if (famname == "bb") tv_success_name(yname) else yname, xl, level)
  if (length(e$sentences)) s$Effects <- e$sentences
  phi <- sm$Phi
  ph <- if (!is.null(phi) && nrow(phi)) phi[1, ] else NULL
  s$Overdispersion <- if (!is.null(ph)) {
    est <- ph[[1]]
    se <- if (length(ph) > 1) ph[[2]] else NA
    c(
      sprintf("phi = %s%s.", tv_num(est), if (is.finite(se)) sprintf(" (standard error %s)", tv_num(se)) else ""),
      if (famname == "bb") "phi is the correlation of outcomes within a unit: 0 means plain binomial variation; larger values mean the proportions vary more among units." else "phi is the extra variance: the variance is mu + phi * mu^2; 0 means Poisson variation.",
      if (is.finite(se) && est - crit * se > 0) "The interval for phi excludes 0: the overdispersion is real, and a plain binomial or Poisson model would understate the uncertainty." else "The interval for phi includes 0: the data are consistent with no overdispersion."
    )
  }
  s$Fit <- sprintf("Log-likelihood %.2f on %d parameters.", x$logL, x$nbpar)
  structure(list(sections = s, tables = list(coefficients = e$table)), class = "tv_interpretation")
}

# nolint end
