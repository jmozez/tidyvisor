#' Register an adviser with tidyvisor
#'
#' @description
#' A package that wants [tidyvisor()] to advise on its analyses and interpret
#' its results registers an *adviser*, usually from its `.onLoad()`:
#'
#' ```r
#' .onLoad <- function(libname, pkgname) {
#'   if (requireNamespace("tidyvisor", quietly = TRUE)) {
#'     tidyvisor::register_advisor(
#'       package   = pkgname,
#'       questions = c("explore", "explain"),
#'       classes   = c("mypkg_fit"),
#'       advise    = function(x, ...) my_advise(x, ...),
#'       interpret = function(x, ...) my_interpret(x, ...),
#'       claims    = function(x, args) "abundance" %in% args
#'     )
#'   }
#' }
#' ```
#'
#' Registering again under the same `package` replaces the earlier adviser,
#' so a package's own registration takes precedence over the built-in one.
#'
#' @param package Name of the package that provides the adviser.
#' @param questions The questions it answers (used by [advise()] with
#'   `question = "..."`).
#' @param classes Classes of the results it can interpret.
#' @param advise,interpret Functions `function(x, ...)` returning the advice
#'   or the interpretation, or names of functions exported by `package`.
#' @param claims A function `function(x, args)` returning `TRUE` when a data
#'   frame `x`, given with arguments named `args`, is this adviser's kind of
#'   data (used by [advise()] with `question = "auto"`). It must not evaluate
#'   the arguments, which may be bare column names.
#' @param title A short description shown by [advisors()].
#' @return The registry entry, invisibly.
#' @export
register_advisor <- function(package, questions, classes, advise, interpret,
                             claims = function(x, args) FALSE, title = package) {
  stopifnot(
    rlang::is_string(package), is.character(questions), is.character(classes),
    is.function(claims)
  )
  entry <- list(
    package = package, title = title, questions = questions, classes = classes,
    advise = advise, interpret = interpret, claims = claims
  )
  tv_env$advisors[[package]] <- entry
  invisible(entry)
}

#' List the available advisers
#'
#' @return A tibble with one row per adviser: `package`, `title`, whether the
#'   package is `installed`, its `questions` and the result `classes` it can
#'   interpret.
#' @export
#' @examples
#' advisors()
advisors <- function() {
  regs <- tv_env$advisors
  tibble::tibble(
    package = names(regs),
    title = vapply(regs, `[[`, "", "title"),
    installed = vapply(names(regs), function(p) requireNamespace(p, quietly = TRUE), TRUE),
    questions = unname(lapply(regs, `[[`, "questions")),
    classes = unname(lapply(regs, `[[`, "classes"))
  )
}

tv_env <- new.env(parent = emptyenv())
tv_env$advisors <- list()

# Advisers whose package is installed. Loading a package lets it replace the
# built-in adviser with its own registration.
tv_registry <- function() {
  regs <- tv_env$advisors
  ok <- vapply(names(regs), function(p) requireNamespace(p, quietly = TRUE), TRUE)
  tv_env$advisors[ok]
}

# Built-in advisers: regression with lm() and glm(), lme4, glmmTMB, mgcv,
# aods3, vegan and brms, and the two companion
# packages through the functions they already export (tidydiversity and
# tidymapr 0.3.0 and later).
tv_register_builtin <- function() {
  register_advisor(
    package = "stats",
    title = "Regression: linear and generalised linear models",
    questions = "regression",
    classes = c("glm", "lm"),
    advise = tv_advise_regression,
    interpret = tv_interpret_regression,
    claims = function(x, args) "response" %in% args && !any(c("random", "smooth") %in% args)
  )
  register_advisor(
    package = "lme4",
    title = "Mixed models: lmer() and glmer()",
    questions = "mixed",
    classes = "merMod",
    advise = tv_advise_mixed,
    interpret = tv_interpret_mixed,
    claims = function(x, args) "random" %in% args && !"smooth" %in% args
  )
  register_advisor(
    package = "glmmTMB",
    title = "Mixed models for overdispersed and zero-inflated data: glmmTMB()",
    questions = "zero_inflation",
    classes = "glmmTMB",
    advise = tv_advise_glmmtmb,
    interpret = tv_interpret_mixed
  )
  register_advisor(
    package = "mgcv",
    title = "Additive models with smooth effects: gam()",
    questions = "smooth",
    classes = "gam",
    advise = tv_advise_gam,
    interpret = tv_interpret_gam,
    claims = function(x, args) "smooth" %in% args
  )
  register_advisor(
    package = "aods3",
    title = "Overdispersed proportions and counts: aodml()",
    questions = "overdispersion",
    classes = c("aodml", "aodql"),
    advise = tv_advise_aod,
    interpret = tv_interpret_aod
  )
  register_advisor(
    package = "vegan",
    title = "Community ordination and multivariate tests: rda(), cca(), metaMDS(), adonis2()",
    questions = "vegan",
    classes = c("metaMDS", "cca", "anova.cca", "betadisper", "envfit"),
    advise = tv_advise_vegan,
    interpret = tv_interpret_vegan
  )
  register_advisor(
    package = "brms",
    title = "Bayesian regression and multilevel models: brm()",
    questions = "bayesian",
    classes = "brmsfit",
    advise = tv_advise_brms,
    interpret = tv_interpret_brms
  )
  register_advisor(
    package = "tidydiversity",
    title = "Community ecology: ordination and its tests",
    questions = c("explore", "explain", "groups", "time", "partition"),
    classes = c("td_ordination", "td_prc", "td_varpart"),
    advise = "ord_advise",
    interpret = "ord_interpret",
    claims = function(x, args) any(c("abundance", "formula", "treatment") %in% args)
  )
  register_advisor(
    package = "tidymapr",
    title = "Spatial ecology: distributions, spread, epidemics, range shifts",
    questions = c("distribution", "spread", "epidemic", "range_shift", "autocorrelation"),
    classes = c(
      "tmr_epi_growth", "tmr_spread_rate", "tmr_epidemic", "tmr_shift_ensemble",
      "tmr_sdm_ensemble", "tmr_sdm_integrated", "tmr_geo_moran"
    ),
    advise = "tmr_advise",
    interpret = "tmr_interpret",
    claims = function(x, args) {
      # community data (often with coordinates too) belong to tidydiversity
      if (any(c("abundance", "formula", "treatment") %in% args)) {
        return(FALSE)
      }
      nm <- tolower(names(x))
      any(c("date", "cases", "lon", "lat", "longitude", "latitude", "presence") %in% c(nm, args))
    }
  )
}
