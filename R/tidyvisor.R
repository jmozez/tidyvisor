#' tidyvisor: advice before the analysis, interpretation after it
#'
#' @description
#' `tidyvisor()` is a statistical advisor shared by a family of packages. Give
#' it **data** and a question, and it recommends the analysis, checks the data
#' for the usual pitfalls, and names the plots and the code to run
#' ([advise()]). Give it a **result**, and it explains the numbers and the
#' figure in plain sentences ([interpret()]).
#'
#' The knowledge lives in the packages that do the analyses. Each one
#' registers an *advisor* with tidyvisor ([register_advisor()]): the questions
#' it answers, the results it can interpret, and how to recognise its kind of
#' data. tidyvisor knows three advisors out of the box:
#'
#' * **tidydiversity** (community ecology): which ordination, constrained or
#'   unconstrained, linear or unimodal, and which test; interpretation of
#'   ordinations, principal response curves and variation partitioning.
#' * **tidymapr** (spatial ecology): species distribution models, spread of
#'   invasions, the spread of epidemics across a landscape, range shifts and
#'   spatial autocorrelation.
#' * **tidyepidemio** (epidemiology): outbreaks (incidence, growth, Rt),
#'   associations (risk, odds and rate ratios), survival, diagnostic tests,
#'   surveillance and causal effects.
#'
#' Each is used when its package is installed; [advisors()] lists them.
#'
#' The advice always gives its reasons, so it can be checked and overruled:
#' the question, which only the analyst knows, comes first.
#'
#' @param x A data frame (to be advised) or a fitted result (to be
#'   interpreted).
#' @param ... Passed to [advise()] or [interpret()], and on to the advisor:
#'   for example `question`, the columns to use, or `abundance` and `formula`
#'   for community data.
#' @return The advisor's advice or interpretation, which prints as sentences.
#' @seealso [advise()], [interpret()], [advisors()], [register_advisor()]
#' @export
#' @examplesIf rlang::is_installed(c("tidydiversity", "vegan"))
#' frogs <- tidydiversity::png_frogs
#'
#' # Before: which analysis?
#' tidyvisor(frogs, abundance = abundance)
#'
#' # After: what does it show?
#' ord <- tidydiversity::ord_fit(frogs,
#'   abundance = abundance, method = "pca", transform = "hellinger"
#' )
#' tidyvisor(ord)
tidyvisor <- function(x, ...) {
  # some results are data frames too (an adonis2 table), so check the
  # classes the advisors interpret first
  known <- unlist(lapply(tv_registry(), `[[`, "classes"))
  if (is.data.frame(x) && !inherits(x, known)) advise(x, ...) else interpret(x, ...)
}

#' Advice on which analysis to run
#'
#' `advise()` finds the advisor for a data frame and a question, and returns
#' its advice: what the data show, the analysis to run and why, the test, the
#' plots, and the code.
#'
#' The advisor is chosen by `question`. With `question = "auto"` (the
#' default), each installed advisor is asked whether the data and the
#' arguments look like its kind: community data given with `abundance` or a
#' `formula` belong to tidydiversity, records with coordinates to tidymapr,
#' and case counts, exposures and outcomes to tidyepidemio. When more than one
#' advisor claims the data, give `question`.
#'
#' @param x A data frame.
#' @param question What is asked, or `"auto"`. [advisors()] lists the
#'   questions of each advisor.
#' @param ... Passed to the advisor.
#' @return The advisor's advice.
#' @export
#' @examplesIf rlang::is_installed("tidymapr")
#' cases <- data.frame(
#'   week = seq(as.Date("2024-01-01"), by = "week", length.out = 12),
#'   n = c(2, 3, 5, 4, 9, 12, 15, 24, 30, 41, 60, 77)
#' )
#' advise(cases, question = "epidemic", date = "week", cases = "n")
advise <- function(x, question = "auto", ...) {
  if (!is.data.frame(x)) {
    cli::cli_abort(c(
      "{.fn advise} needs a data frame.",
      i = "To explain a fitted result, use {.fn interpret}."
    ))
  }
  regs <- tv_registry()
  if (!identical(question, "auto")) {
    hit <- Filter(function(r) question %in% r$questions, regs)
    if (!length(hit)) tv_abort_question(question, regs)
    return(tv_call(hit[[1]], "advise", x, question = question, ...))
  }
  dots <- ...names()
  hit <- Filter(function(r) isTRUE(r$claims(x, dots)), regs)
  if (length(hit) == 1) {
    return(tv_call(hit[[1]], "advise", x, ...))
  }
  if (length(hit) > 1) {
    cli::cli_abort(c(
      "More than one advisor recognises these data: {.pkg {vapply(hit, `[[`, '', 'package')}}.",
      i = "Give {.arg question} to choose; {.fn advisors} lists the questions."
    ))
  }
  # No specialised advisor recognises the data: the general advisor audits
  # them and suggests where to go next, so tidyvisor always answers.
  tv_advise_design(x, question = "design", ...)
}

#' Plain-language interpretation of a fitted result
#'
#' `interpret()` finds the advisor that knows the class of `x` and returns its
#' interpretation: the numbers in sentences, what the tests say, and how to
#' read the figure.
#'
#' @param x A fitted result, such as an ordination from
#'   `tidydiversity::ord_fit()` or a growth rate from
#'   `tidymapr::epi_growth_rate()`.
#' @param ... Passed to the advisor (for example `permutations`).
#' @return The advisor's interpretation.
#' @export
#' @examplesIf rlang::is_installed("tidymapr")
#' cases <- data.frame(
#'   week = seq(as.Date("2024-01-01"), by = "week", length.out = 12),
#'   n = c(2, 3, 5, 4, 9, 12, 15, 24, 30, 41, 60, 77)
#' )
#' g <- tidymapr::epi_growth_rate(cases, date = week, cases = n, unit = "week")
#' interpret(g)
interpret <- function(x, ...) {
  regs <- tv_registry()
  # the advisor for the most specific class wins (a gam is also a glm)
  cls <- if (isS4(x)) methods::is(x) else class(x)
  rank <- vapply(regs, function(r) suppressWarnings(min(match(r$classes, cls), na.rm = TRUE)), 0)
  hit <- regs[is.finite(rank)][order(rank[is.finite(rank)])]
  if (!length(hit)) {
    cli::cli_abort(c(
      "No advisor knows how to interpret an object of class {.cls {class(x)}}.",
      i = if (length(regs)) {
        "Advisors available: {.pkg {vapply(regs, `[[`, '', 'package')}}; see {.fn advisors}."
      } else {
        "No advisor is available: install tidydiversity or tidymapr."
      }
    ))
  }
  tv_call(hit[[1]], "interpret", x, ...)
}

tv_abort_question <- function(question, regs, call = rlang::caller_env()) {
  qs <- unlist(lapply(regs, function(r) {
    paste0(r$package, ": ", paste(r$questions, collapse = ", "))
  }))
  cli::cli_abort(c(
    if (identical(question, "auto")) {
      "No advisor recognises these data."
    } else {
      "No advisor answers the question {.val {question}}."
    },
    i = if (length(qs)) {
      "Questions available:"
    } else {
      "No advisor is available: install tidydiversity or tidymapr."
    },
    stats::setNames(qs, rep("*", length(qs)))
  ), call = call)
}

# Call an advisor's advise or interpret function, loading its package on
# first use.
tv_call <- function(reg, what, x, ...) {
  fun <- reg[[what]]
  if (is.character(fun)) fun <- getExportedValue(reg$package, fun)
  fun(x, ...)
}
