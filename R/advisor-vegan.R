#' Advisor for vegan: ordination and multivariate tests
#'
#' @description
#' Built-in advisor for the vegan package, for community data in the wide
#' format vegan uses (one row per site, one column per species).
#'
#' * **Before** (`question = "vegan"`): reports the number of sites and
#'   species, the share of zeros, and the length of the main gradient. From
#'   these it recommends a linear or a unimodal method, NMDS for an
#'   unconstrained view, and PERMANOVA ([vegan::adonis2()]) with its
#'   companion check of dispersion ([vegan::betadisper()]).
#'
#' **The gradient-length rule.** The gradient length is the length of the
#' longest axis of a detrended correspondence analysis ([vegan::decorana()],
#' detrending by segments, on log(y + 1) abundances or presence-absence),
#' in standard-deviation (SD) units of species turnover. This is the value
#' CANOCO reports. Over about 4 SD the species composition turns over
#' completely.
#'
#' | Gradient length | Species responses | Method |
#' |---|---|---|
#' | below 3 SD | mostly monotonic | linear: PCA, RDA (on Hellinger-transformed abundances) |
#' | 3 to 4 SD | mixed | both appropriate; tidyvisor gives RDA, with CCA as the alternative |
#' | above 4 SD | unimodal (rise and fall) | unimodal: CA, CCA |
#'
#' The rule guides; it does not decide. Hellinger-transformed RDA
#' (Legendre & Gallagher 2001) and distance-based methods (NMDS, db-RDA,
#' PERMANOVA) are valid at any gradient length.
#' * **After**: explains [vegan::metaMDS()] (stress against Clarke's
#'   benchmarks), [vegan::rda()], [vegan::cca()], [vegan::capscale()] and
#'   [vegan::dbrda()] (variance explained, adjusted R-squared, permutation
#'   tests), [vegan::adonis2()] and `anova()` tables, [vegan::betadisper()]
#'   and [vegan::envfit()].
#'
#' For long-format data, tidydiversity offers the same analyses through
#' `ord_fit()`; its advisor answers `tidyvisor(data, abundance = ...)`.
#'
#' @param x A wide data frame of sites (advice), or a vegan result
#'   (interpretation).
#' @param question The question; set by [advise()].
#' @param species Names of the species columns (default: every numeric
#'   column not in `env`).
#' @param env Names of the explanatory columns, if any.
#' @param permutations Number of permutations for the tests run while
#'   interpreting a constrained ordination.
#' @param ... Ignored.
#' @return A `tv_advice` or a `tv_interpretation` object.
#' @references
#' Anderson, M.J. (2001). A new method for non-parametric multivariate
#' analysis of variance. *Austral Ecology* 26, 32-46.
#'
#' Clarke, K.R. (1993). Non-parametric multivariate analyses of changes in
#' community structure. *Australian Journal of Ecology* 18, 117-143.
#'
#' Leps, J. & Smilauer, P. (2003). *Multivariate Analysis of Ecological
#' Data using CANOCO*. Cambridge University Press. (Second edition for
#' Canoco 5, 2014.)
#'
#' Legendre, P. & Gallagher, E.D. (2001). Ecologically meaningful
#' transformations for ordination of species data. *Oecologia* 129,
#' 271-280.
#'
#' Ter Braak, C.J.F. & Smilauer, P. (2012). *Canoco Reference Manual and
#' User's Guide: Software for Ordination (version 5.0)*. Microcomputer
#' Power, Ithaca.
#' @name vegan-advisor
#' @examplesIf rlang::is_installed("vegan")
#' data("dune", "dune.env", package = "vegan")
#' tidyvisor(cbind(dune, dune.env), question = "vegan", env = c("A1", "Management"))
#' m <- vegan::rda(vegan::decostand(dune, "hellinger") ~ A1 + Management, dune.env)
#' tidyvisor(m, permutations = 99)
NULL

# nolint start: line_length_linter. Advice sentences read better unbroken.

#' @rdname vegan-advisor
#' @export
tv_advise_vegan <- function(x, question = "vegan", species = NULL, env = NULL, ...) {
  species <- species %||% setdiff(names(x)[vapply(x, is.numeric, TRUE)], env)
  comm <- as.matrix(x[species])
  keep <- rowSums(comm) > 0
  comm <- comm[keep, colSums(comm[keep, , drop = FALSE]) > 0, drop = FALSE]
  zeros <- mean(comm == 0)
  acc <- list(
    tv_check("Sites", nrow(comm), if (any(!keep)) sprintf("%d empty sites dropped", sum(!keep)) else ""),
    tv_check("Species", ncol(comm)),
    tv_check("Zeros", sprintf("%.0f%%", 100 * zeros), if (zeros > 0.5) "many zeros: avoid Euclidean distances on raw counts (double-zero problem); use Hellinger or Bray-Curtis" else "")
  )
  len <- tv_gradient_length(comm)
  acc[[4]] <- tv_check(
    "Gradient length (longest DCA axis, SD units)", sprintf("%.2f", len),
    tv_gradient_rule(len)
  )
  unimodal <- isTRUE(len > 4)
  step <- function(s, r, why, code = "") tibble::tibble(step = s, recommendation = r, reason = why, code = code)
  sp <- "comm <- data[species]"
  rows <- list()
  if (length(env)) {
    rhs <- paste(env, collapse = " + ")
    rows[[1]] <- if (unimodal) {
      step("Model", "Canonical correspondence analysis (CCA)", "A long gradient means species have optima along it; CCA models unimodal responses (ter Braak & Smilauer 2012).",
           sprintf("%s\nm <- vegan::cca(comm ~ %s, data = data)", sp, rhs))
    } else {
      step("Model", "Redundancy analysis (RDA) on Hellinger-transformed abundances",
           paste(if (isTRUE(len >= 3)) "With a gradient of 3 to 4 SD, linear and unimodal methods are both appropriate; CCA (vegan::cca(comm ~ ...)) is the alternative." else "A gradient shorter than 3 SD suits a linear method.",
                 "The Hellinger transformation removes the double-zero problem so RDA can be used on community data (Legendre & Gallagher 2001)."),
           sprintf("%s\nm <- vegan::rda(vegan::decostand(comm, \"hellinger\") ~ %s, data = data)", sp, rhs))
    }
    rows[[2]] <- step("Test", "Permutation tests of the model, the axes and each term", "Community data are not multivariate normal; permutations give valid p-values.",
                      "anova(m); anova(m, by = \"terms\"); vegan::RsquareAdj(m)")
    rows[[3]] <- step("Alternative", "PERMANOVA on Bray-Curtis dissimilarities", "Tests differences in composition without assuming a linear or unimodal response (Anderson 2001).",
                      sprintf("vegan::adonis2(comm ~ %s, data = data, method = \"bray\", by = \"terms\")", rhs))
    fac <- env[vapply(env, function(v) is.factor(x[[v]]) || is.character(x[[v]]), TRUE)]
    if (length(fac)) {
      rows[[4]] <- step("Check", sprintf("Compare the dispersion of the %s groups", fac[1]),
                        "PERMANOVA is sensitive to differences in spread as well as location; a significant betadisper test means a PERMANOVA difference may reflect spread.",
                        sprintf("b <- vegan::betadisper(vegan::vegdist(comm), data$%s); anova(b)", fac[1]))
    }
  } else {
    rows[[1]] <- step("Model", "Non-metric multidimensional scaling (NMDS) on Bray-Curtis", "NMDS preserves the rank order of dissimilarities and makes no assumption about species responses; check its stress.",
                      sprintf("%s\nm <- vegan::metaMDS(comm, distance = \"bray\", k = 2, trymax = 50)", sp))
    rows[[2]] <- step("Alternative", if (unimodal) "Correspondence analysis (CA)" else "PCA on Hellinger-transformed abundances", "An eigenvector method whose axes have explained variances.",
                      if (unimodal) "m2 <- vegan::cca(comm)" else "m2 <- vegan::rda(vegan::decostand(comm, \"hellinger\"))")
  }
  rows[[length(rows) + 1]] <- step("Interpret", "Plain-language explanation of the result", "Variance explained, tests and how to read the plot.", "tidyvisor(m)")
  structure(list(question = question, checks = do.call(rbind, acc), advice = do.call(rbind, rows)), class = "tv_advice")
}

#' @rdname vegan-advisor
#' @export
tv_interpret_vegan <- function(x, permutations = 999, ...) {
  s <- list()
  if (inherits(x, "metaMDS")) {
    st <- x$stress
    s$Overview <- sprintf("NMDS in %d dimensions on %s dissimilarities.", x$ndim, x$distance)
    s$Fit <- c(
      sprintf("Stress %.3f: %s (Clarke 1993: below 0.05 excellent, below 0.1 good, below 0.2 usable, above 0.2 close to arbitrary).", st,
              if (st < 0.05) "an excellent representation" else if (st < 0.1) "a good representation" else if (st < 0.2) "usable, but do not over-interpret fine detail" else "the configuration is unreliable; increase k or use another method"),
      if (!isTRUE(x$converged)) "The solution did not converge: rerun with larger trymax, or start from this solution (previous.best = m)."
    )
    s$`Reading the plot` <- c(
      "Distances between sites show how different their composition is; the axes have no units and their orientation is arbitrary.",
      "Use vegan::stressplot(m) to check the fit, and vegan::envfit(m, env) to relate the axes to explanatory variables."
    )
  } else if (inherits(x, "cca")) {
    method <- class(x)[1]
    tot <- x$tot.chi
    con <- if (!is.null(x$CCA)) x$CCA$tot.chi else 0
    lab <- switch(method, rda = "Redundancy analysis (RDA)", cca = "Canonical correspondence analysis (CCA)", capscale = "Distance-based RDA (capscale)", dbrda = "Distance-based RDA (dbrda)", method)
    if (is.null(x$CCA)) {
      ev <- x$CA$eig
      s$Overview <- sprintf("Unconstrained ordination (%s) of %d sites.", if (method == "rda") "PCA" else "CA", nrow(x$CA$u))
      s$Fit <- sprintf("The first two axes show %.1f%% and %.1f%% of the total %s.", 100 * ev[1] / tot, 100 * ev[2] / tot, if (method == "rda") "variance" else "inertia")
    } else {
      r2 <- tryCatch(vegan::RsquareAdj(x), error = function(e) NULL)
      s$Overview <- sprintf("%s of %d sites with %d constraining degrees of freedom.", lab, nrow(x$CCA$u), x$CCA$rank)
      s$Fit <- c(
        sprintf("The explanatory variables account for %.1f%% of the total %s%s.", 100 * con / tot, if (method == "cca") "inertia" else "variance",
                if (!is.null(r2) && is.finite(r2$adj.r.squared)) sprintf(" (adjusted R-squared %.1f%%, corrected for the number of variables)", 100 * r2$adj.r.squared) else ""),
        sprintf("The first constrained axis shows %.1f%% of the total.", 100 * x$CCA$eig[1] / tot)
      )
      if (permutations > 0) {
        a <- vegan::anova.cca(x, permutations = permutations)
        bt <- vegan::anova.cca(x, by = "terms", permutations = permutations)
        s$Tests <- c(
          sprintf("Whole model: F = %.2f, %s (%d permutations).", a$F[1], tv_p(a$`Pr(>F)`[1]), permutations),
          tv_anova_rows(bt, "explains")
        )
      }
    }
    s$`Reading the plot` <- c(
      if (method == "cca") "In a CCA triplot, species near a site are abundant there; arrows point to increasing values of the variables, and centroids mark factor levels." else "In an RDA triplot, the angle between arrows approximates correlation; project sites or species onto an arrow to read their relation to it.",
      "Look at the axes' explained variance before reading patterns along them."
    )
  } else if (inherits(x, "anova.cca")) {
    s$Overview <- "Permutation test table (adonis2 or anova of a constrained ordination)."
    s$Tests <- tv_anova_rows(x, "explains")
    s$Note <- "A significant PERMANOVA term can reflect a difference in location (centroid), in spread, or both: check with vegan::betadisper()."
  } else if (inherits(x, "betadisper")) {
    a <- stats::anova(x)
    md <- tapply(x$distances, x$group, mean)
    type <- attr(x, "type") %||% "centroid"
    s$Overview <- sprintf("Multivariate dispersion of %d groups (distance to the group %s).", length(md), type)
    s$Dispersion <- c(
      sprintf("Mean distance to the %s: %s.", type, paste(sprintf("%s %.3f", names(md), md), collapse = ", ")),
      sprintf("Test of equal dispersion: F = %.2f on %d and %d df, %s%s", a$`F value`[1], a$Df[1], a$Df[2], tv_p(a$`Pr(>F)`[1]),
              if (a$`Pr(>F)`[1] < 0.05) "; the groups differ in spread, so a PERMANOVA difference may be partly or wholly due to spread." else "; no evidence that the groups differ in spread, so a PERMANOVA difference reflects location."),
      "The F test is parametric; vegan::permutest(b) gives a permutation p-value."
    )
  } else if (inherits(x, "envfit")) {
    s$Overview <- "Fit of explanatory variables onto an ordination (envfit)."
    v <- x$vectors
    f <- x$factors
    s$Vectors <- if (!is.null(v)) sprintf("%s: r-squared %.2f with the ordination, %s.", names(v$r), v$r, vapply(v$pvals, tv_p, "")) else NULL
    s$Factors <- if (!is.null(f)) sprintf("%s: r-squared %.2f, %s.", names(f$r), f$r, vapply(f$pvals, tv_p, "")) else NULL
    s$Note <- "envfit is a post hoc fit onto fixed axes: it shows association, not how much of the composition the variables explain (use a constrained ordination for that)."
  }
  structure(list(sections = s, tables = list()), class = "tv_interpretation")
}

# Length of the main gradient as CANOCO reports it: the longest of the four
# DCA axes (detrending by segments, rescaled to SD units of species
# turnover), on log(y + 1) abundances or on presence-absence data.
tv_gradient_length <- function(comm) {
  y <- if (all(comm %in% c(0, 1))) comm else log1p(comm)
  dca <- tryCatch(suppressWarnings(vegan::decorana(y)), error = function(e) NULL)
  if (is.null(dca)) {
    return(NA_real_)
  }
  sc <- vegan::scores(dca, display = "sites", choices = 1:4)
  max(apply(sc, 2, function(a) diff(range(a))))
}

# The rule of Leps & Smilauer (2003) and ter Braak & Smilauer (2012), in words
tv_gradient_rule <- function(len) {
  if (is.na(len)) {
    "could not be measured"
  } else if (len < 3) {
    "below 3 SD: short; most species change monotonically, so use a linear method (PCA, RDA; on Hellinger-transformed abundances)"
  } else if (len > 4) {
    "above 4 SD: long; species rise and fall along it, so use a unimodal method (CA, CCA)"
  } else {
    "between 3 and 4 SD: intermediate; linear and unimodal methods are both appropriate"
  }
}

# Sentences for the rows of an anova.cca table (adonis2 or anova.cca)
tv_anova_rows <- function(tb, verb) {
  rows <- setdiff(rownames(tb), c("Residual", "Total"))
  ss <- intersect(c("SumOfSqs", "Variance", "ChiSquare", "Inertia"), names(tb))[1]
  tot <- if (!is.na(ss)) sum(tb[[ss]][rownames(tb) != "Total"]) else NA
  vapply(rows, function(r) {
    r2 <- if ("R2" %in% names(tb)) tb[r, "R2"] else if (is.finite(tot)) tb[r, ss] / tot else NA
    sprintf("%s %s%s: F = %.2f, %s.", r, verb, if (is.finite(r2)) sprintf(" %.1f%% of the variation", 100 * r2) else "", tb[r, "F"], tv_p(tb[r, "Pr(>F)"]))
  }, "", USE.NAMES = FALSE)
}

# nolint end
