# nolint start: line_length_linter. Tables and advice sentences read better unbroken.

#' Research practice and study design: advice for any field
#'
#' @description
#' The general advice of tidyvisor, for any field and any stage of a study.
#'
#' * `tv_practice()` gives a checklist of good research practice for a
#'   stage of the study (`"plan"`, `"collect"`, `"analyse"`, `"report"` or
#'   `"all"`) and a kind of study (`"experiment"`, `"observational"`,
#'   `"survey"`, `"monitoring"`, `"review"`), with the reporting guideline
#'   for the field where one exists (`field`).
#' * `advise(data, question = "design", ...)` audits a data set before the
#'   analysis: missing values, duplicated rows, constant and nearly empty
#'   columns, the unit of replication (pseudoreplication), treatments
#'   confounded with sites or time, unbalanced groups, and suggests the
#'   analysis for the response. It is also what [advise()] falls back on
#'   when no specialised advisor recognises the data, so `tidyvisor()`
#'   always answers.
#'
#' Reporting guidelines by `field`:
#'
#' | `field` | Guideline |
#' |---|---|
#' | `"trial"` | CONSORT 2010 (randomised trials) |
#' | `"epidemiology"`, `"medicine"` | STROBE (observational studies) |
#' | `"animal"` | ARRIVE 2.0 (animal research) |
#' | `"review"` | PRISMA 2020 (systematic reviews and meta-analyses) |
#' | `"diagnostic"` | STARD 2015 (diagnostic accuracy) |
#' | `"sdm"` | ODMAP (species distribution models) |
#' | `"ecology"` | Tools for Transparency in Ecology and Evolution (TTEE) |
#'
#' @param stage Stage of the study.
#' @param design Kind of study.
#' @param field Field, to name its reporting guideline (see the table);
#'   `NULL` for general advice.
#' @param x A data frame.
#' @param question Set by [advise()].
#' @param response Optional name of the response column.
#' @param group Optional name of the treatment or grouping column.
#' @param unit Optional name of the column identifying the unit the
#'   treatment was applied to (plot, site, cage, patient, school).
#' @param time Optional name of a time column (date, year, visit).
#' @param ... Ignored.
#' @return A `tv_advice` object.
#' @references
#' Hurlbert, S. H. (1984). Pseudoreplication and the design of ecological
#' field experiments. *Ecological Monographs* 54, 187-211.
#'
#' Nosek, B. A., Ebersole, C. R., DeHaven, A. C. and Mellor, D. T. (2018).
#' The preregistration revolution. *Proceedings of the National Academy of
#' Sciences* 115, 2600-2606.
#'
#' Wasserstein, R. L. and Lazar, N. A. (2016). The ASA statement on
#' p-values: context, process, and purpose. *The American Statistician* 70,
#' 129-133.
#'
#' Wilkinson, M. D. et al. (2016). The FAIR Guiding Principles for
#' scientific data management and stewardship. *Scientific Data* 3, 160018.
#'
#' Zuur, A. F., Ieno, E. N. and Elphick, C. S. (2010). A protocol for data
#' exploration to avoid common statistical problems. *Methods in Ecology
#' and Evolution* 1, 3-14.
#' @name practice-advisor
#' @examples
#' tv_practice("plan", design = "experiment")
#' tv_practice("report", field = "sdm")
#'
#' # Audit a data set: here, chicks weighed repeatedly
#' advise(ChickWeight, question = "design", response = "weight",
#'        group = "Diet", unit = "Chick", time = "Time")
NULL

#' @rdname practice-advisor
#' @export
tv_practice <- function(stage = c("all", "plan", "collect", "analyse", "report"),
                        design = c("any", "experiment", "observational", "survey", "monitoring", "review"),
                        field = NULL) {
  stage <- rlang::arg_match(stage)
  design <- rlang::arg_match(design)
  r <- function(st, rec, why, code = "") tibble::tibble(step = st, recommendation = rec, reason = why, code = code)
  plan <- rbind(
    r("Plan", "Write the question and the hypothesis before collecting data", "A precise question decides the design, the response, the unit of replication and the analysis; analyses chosen after seeing the data inflate false positives."),
    r("Plan", "Define the unit of replication", "The unit to which a treatment is applied independently (plot, site, cage, patient, school) sets the sample size. Measurements within a unit are not replicates (pseudoreplication; Hurlbert 1984)."),
    r("Plan", "Run a power analysis", "Decide the sample size from the smallest effect worth detecting, not from habit or budget alone.", "tv_power(\"two_groups\", delta = <difference to detect>, sd = <standard deviation>)"),
    if (design %in% c("any", "experiment")) r("Plan", "Randomise, include controls and blind where possible", "Randomising which unit gets which treatment removes systematic bias; controls give the baseline; blinding observers prevents expectations from colouring measurements."),
    if (design %in% c("any", "observational", "monitoring", "survey")) r("Plan", "List the confounders and measure them", "Without randomisation, any variable that affects both the predictor and the response can create or hide an effect; draw a causal diagram and measure what it shows."),
    if (design %in% c("any", "survey")) r("Plan", "Use probability sampling and pilot the instrument", "A random or stratified sample lets results generalise to the population; a pilot finds unclear questions and estimates the variability for the power analysis."),
    if (design %in% c("any", "monitoring")) r("Plan", "Fix the protocol and keep it fixed", "Changes in method, effort or observer over time look like trends; when a change cannot be avoided, overlap the old and new methods."),
    if (design %in% c("any", "review")) r("Plan", "Register the protocol and define the search", "A registered protocol (for example in PROSPERO or OSF) with fixed inclusion criteria and search strings prevents selective inclusion."),
    r("Plan", "Pre-register the study and the analysis plan", "Recording hypotheses, design and analysis before the data exist separates confirmatory from exploratory results (Nosek et al. 2018).")
  )
  collect <- rbind(
    r("Collect", "Record data in a tidy table from the start", "One row per observation, one column per variable, one value per cell; dates in ISO format (YYYY-MM-DD); units in the column names or a data dictionary."),
    r("Collect", "Keep the raw data read-only", "Never edit raw files by hand; clean them with code, so every change is recorded and can be redone."),
    r("Collect", "Write the metadata as you go", "Who, where (coordinates and datum), when, how, and what each column and code means; without it the data cannot be reused (FAIR principles; Wilkinson et al. 2016)."),
    r("Collect", "Record the unit, the site and the date of every measurement", "These are needed for random effects, for checking temporal or spatial structure, and for finding errors."),
    r("Collect", "Back up in at least two places", "Field data cannot be collected again.")
  )
  analyse <- rbind(
    r("Analyse", "Explore the data before modelling", "Plot the response and every predictor: outliers, zeros, collinearity, non-linear relations and imbalance change which analysis is right (Zuur et al. 2010).", "advise(data, question = \"design\", response = \"<response column>\", group = \"<group column>\", unit = \"<unit column>\")"),
    r("Analyse", "Match the model to the response and the design", "Counts, proportions, presence-absence and positive skewed values have their own families; nested or repeated measurements need random effects.", "tidyvisor(data, response = )"),
    r("Analyse", "Check the assumptions, then act on them", "Residual plots and tests show whether the model fits; tidyvisor says what to do when it does not.", "tidyvisor(model)"),
    r("Analyse", "Report effect sizes with confidence intervals, not p-values alone", "A p-value says nothing about how large or important an effect is, and p < 0.05 is not a measure of truth (Wasserstein and Lazar 2016)."),
    r("Analyse", "Correct for multiple comparisons and avoid data dredging", "Many tests make some significant by chance; adjust (Holm, false discovery rate) or say which analyses were exploratory."),
    r("Analyse", "Keep the analysis in a script under version control", "A script (with the package versions, for example from sessionInfo() or renv) lets anyone, including you later, reproduce every number.")
  )
  report <- rbind(
    r("Report", "Follow the reporting guideline for the study type", tv_guideline(field, design)),
    r("Report", "Report everything that was done", "All measured variables, all analyses run, exclusions and why, and deviations from the pre-registered plan; non-significant results too."),
    r("Report", "Share the data and the code", "Deposit them in a repository with a DOI (Dryad, Zenodo, OSF, Figshare) under an open licence, with the metadata."),
    r("Report", "Show the data in the figures", "Plot the raw points with the estimates and intervals, not bars alone; give the sample size of each group.")
  )
  advice <- switch(stage,
    plan = plan, collect = collect, analyse = analyse, report = report,
    all = rbind(plan, collect, analyse, report)
  )
  checks <- rbind(
    tv_check("Stage", stage),
    tv_check("Study", design),
    tv_check("Field", field %||% "general", if (!is.null(field)) tv_guideline(field, design) else "")
  )
  structure(list(question = "practice", checks = checks, advice = advice), class = "tv_advice")
}

tv_guideline <- function(field, design) {
  key <- tolower(field %||% "")
  if (key %in% c("trial", "clinical", "rct") || design == "experiment" && key %in% c("medicine", "health")) {
    "CONSORT 2010 for randomised trials (consort-spirit.org)."
  } else if (key %in% c("epidemiology", "medicine", "health", "public health")) {
    "STROBE for observational studies (strobe-statement.org)."
  } else if (key %in% c("animal", "veterinary", "laboratory animals")) {
    "ARRIVE 2.0 for research with animals (arriveguidelines.org)."
  } else if (key %in% c("review", "meta-analysis", "systematic review") || design == "review") {
    "PRISMA 2020 for systematic reviews and meta-analyses (prisma-statement.org)."
  } else if (key %in% c("diagnostic", "diagnostics")) {
    "STARD 2015 for studies of diagnostic accuracy."
  } else if (key %in% c("sdm", "species distribution", "niche")) {
    "ODMAP, the protocol for reporting species distribution models (Zurell et al. 2020, Ecography)."
  } else if (key %in% c("ecology", "evolution", "conservation")) {
    "The Tools for Transparency in Ecology and Evolution (TTEE) checklist; ODMAP for species distribution models."
  } else {
    "The EQUATOR Network (equator-network.org) lists the reporting guideline for each kind of study."
  }
}

#' @rdname practice-advisor
#' @export
tv_advise_design <- function(x, question = "design", response = NULL, group = NULL, unit = NULL,
                             time = NULL, ...) {
  for (a in c(response, group, unit, time)) {
    if (!a %in% names(x)) cli::cli_abort("Unknown column {.field {a}}.")
  }
  x <- as.data.frame(x)
  n <- nrow(x)
  acc <- new.env()
  acc$checks <- list(tv_check("Rows and columns", sprintf("%d rows, %d columns", n, ncol(x))))
  add <- function(check, value, meaning = "") {
    acc$checks[[length(acc$checks) + 1]] <- tv_check(check, value, meaning)
  }
  acc$todo <- list()
  todo <- function(s, rec, why, code = "") {
    acc$todo[[length(acc$todo) + 1]] <- tibble::tibble(step = s, recommendation = rec, reason = why, code = code)
  }

  # ---- Data quality ----
  miss <- vapply(x, function(v) mean(is.na(v)), 0)
  if (any(miss > 0)) {
    worst <- utils::head(sort(miss[miss > 0], decreasing = TRUE), 5)
    add("Missing values", paste(sprintf("%s %.0f%%", names(worst), 100 * worst), collapse = "; "),
        if (any(miss > 0.2)) "more than 20% missing in some columns: ask why they are missing before dropping rows" else "complete-case analysis drops these rows")
    if (any(miss > 0.05)) todo("Data", "Find out why values are missing", "If missingness depends on the response or the treatment, dropping rows biases the results; consider multiple imputation (mice) when values are missing at random.", "colSums(is.na(data))")
  } else {
    add("Missing values", "none")
  }
  dup <- sum(duplicated(x))
  add("Duplicated rows", dup, if (dup) "check for double data entry" else "")
  const <- names(x)[vapply(x, function(v) length(unique(stats::na.omit(v))) <= 1, TRUE)]
  if (length(const)) add("Constant columns", paste(const, collapse = ", "), "carry no information; drop them")
  chr_num <- names(x)[vapply(x, function(v) is.character(v) && mean(!is.na(suppressWarnings(as.numeric(v[!is.na(v)])))) > 0.9, TRUE)]
  if (length(chr_num)) add("Numbers stored as text", paste(chr_num, collapse = ", "), "a few non-numeric entries (\"<1\", \"NA \", commas) turn a column into text; fix them in the cleaning script")

  # ---- Response ----
  if (!is.null(response)) {
    y <- x[[response]]
    kind <- if (is.numeric(y)) tv_design_kind(stats::na.omit(y)) else list(label = "categorical", family = "binomial", why = "")
    add("Response", kind$label, kind$why %||% "")
    if (is.numeric(y)) {
      yy <- stats::na.omit(y)
      mad <- stats::mad(yy)
      nout <- if (mad > 0) sum(abs(yy - stats::median(yy)) / mad > 5) else 0
      if (nout) add("Extreme values in the response", nout, "check them against the field sheets: errors or real?")
    }
  }

  # ---- Replication and confounding ----
  if (!is.null(group)) {
    g <- factor(x[[group]])
    tab <- table(g)
    add("Groups", nlevels(g), paste(sprintf("%s (%d)", names(tab), as.integer(tab)), collapse = ", "))
    if (max(tab) > 2 * min(tab)) add("Balance", "unbalanced", "unequal group sizes: use Welch-type tests or models, and type II/III tests in ANOVA tables")
  }
  nested <- FALSE
  if (!is.null(unit)) {
    u <- factor(x[[unit]])
    nu <- nlevels(u)
    per <- n / nu
    add("Units", sprintf("%d units, %.1f rows per unit", nu, per), if (per > 1) "several measurements per unit: they are not independent" else "")
    if (per > 1) nested <- TRUE
    if (!is.null(group)) {
      g_per_u <- tapply(as.character(x[[group]]), u, function(v) length(unique(v)))
      if (all(g_per_u == 1)) {
        reps <- tapply(as.character(u), x[[group]], function(v) length(unique(v)))
        add("Unit of replication", sprintf("%s (treatment applied to whole units)", unit),
            sprintf("true replicates (%ss) per group: %s; not the number of rows", unit, paste(sprintf("%s %s: %d", group, names(reps), as.integer(reps)), collapse = ", ")))
        if (per > 1) {
          todo("Design", sprintf("Treat %s as the unit of replication", unit),
               sprintf("Each %s received one treatment, so its %.1f measurements are pseudoreplicates (Hurlbert 1984). Analyse with a random effect for %s, or average within each %s; counting rows as replicates makes p-values far too small.", unit, per, unit, unit),
               "")
        }
        if (min(reps) < 3) todo("Design", "Too few independent replicates", sprintf("A group has only %d %s(s); the treatment effect cannot be separated from differences between units. More units, not more measurements per unit, are needed.", min(reps), unit))
      } else {
        add("Unit of replication", sprintf("treatments vary within %s", unit), "a blocked or repeated-measures design: include the unit as a random effect (or block)")
      }
    }
  }
  if (!is.null(time)) {
    tt <- x[[time]]
    add("Time points", length(unique(stats::na.omit(tt))), "repeated over time: residuals may be autocorrelated")
    todo("Design", "Allow for correlation over time", "Measurements close in time are more alike; check the autocorrelation of the residuals and, if needed, add a temporal correlation structure (nlme::corAR1(), glmmTMB::ar1()).", "acf(residuals(m))")
    if (!is.null(group)) {
      cross <- table(x[[time]], x[[group]])
      if (all(rowSums(cross > 0) == 1)) {
        add("Confounding", sprintf("%s and %s", group, time), "each time point has only one group: the treatment effect cannot be separated from the time effect")
        todo("Design", "Treatment confounded with time", sprintf("Every %s value belongs to a single %s, so any difference could be caused by the timing (season, weather, observer) rather than the treatment. Interleave treatments in time in future work and say so in the report.", time, group))
      }
    }
  }

  # ---- Suggested analysis ----
  if (!is.null(response) && is.numeric(x[[response]])) {
    fam <- tv_design_kind(stats::na.omit(x[[response]]))$family
    rhs <- c(group, if (!is.null(time)) time)
    rhs <- if (length(rhs)) paste(rhs, collapse = " + ") else "1"
    f <- sprintf("%s ~ %s%s", response, rhs, if (nested) sprintf(" + (1 | %s)", unit) else "")
    code <- if (nested) {
      if (fam == "gaussian") sprintf("lme4::lmer(%s, data = data)", f) else sprintf("lme4::glmer(%s, family = %s, data = data)", f, fam)
    } else if (fam == "gaussian") {
      sprintf("lm(%s, data = data)", f)
    } else {
      sprintf("glm(%s, family = %s, data = data)", f, fam)
    }
    todo("Analysis", sprintf("%s%s", if (nested) "Mixed model" else "Regression model", if (fam == "gaussian") "" else sprintf(" (%s family)", fam)),
         "Chosen from the kind of response and the structure of the design; ask tidyvisor for the detailed advice and the assumption checks.",
         paste0(code, "\n# detailed advice: tidyvisor(data, response = \"", response, "\"", if (nested) paste0(", random = \"", unit, "\"") else "", ")"))
  }
  todo("Next", "Good practice for the rest of the study", "Pre-registration, data management, effect sizes and reporting guidelines.", "tv_practice()")
  advice <- do.call(rbind, acc$todo)
  structure(list(question = "design", checks = do.call(rbind, acc$checks), advice = advice), class = "tv_advice")
}

# Kind of response for the audit. Whole numbers are counts only when they
# look like counts (zeros or small values); larger whole numbers are more
# often measurements rounded to a unit (grams, cm, days).
tv_design_kind <- function(y) {
  k <- tv_response_kind(y, NULL)
  if (identical(k$kind, "count") && !(any(y == 0) || stats::median(y) <= 30)) {
    k <- list(kind = "continuous", family = "gaussian", label = "whole numbers, large: probably a measurement rounded to whole units",
              why = "If these are counts, use a Poisson or negative binomial model; if a measurement, a linear model (or Gamma for positive skewed values).")
  }
  k
}

# nolint end
