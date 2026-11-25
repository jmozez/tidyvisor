# "For the paper": how to report a result in a publication. A sentence for
# the Results with the numbers in the usual order, the figure and the table
# to make (with code that uses the data's own names), and what the Methods
# must state.
# nolint start: line_length_linter. Advice strings read better unbroken.

tv_pub_figure_style <- paste(
  "Figure style for journals: show the raw data with the estimates, give n per group in the caption,",
  "label axes with units, use a colour-blind-safe palette (Okabe-Ito, viridis) and no 3D, pie or dual-axis charts;",
  "text at least 8 pt at final size; save as PDF or SVG (vector) at the journal's column width",
  "(about 85 mm single, 180 mm double), or 600 dpi for raster images."
)

tv_pub_save <- 'ggplot2::ggsave("figure1.pdf", width = 85, height = 70, units = "mm")   # one journal column'

# Numbers for the text: three significant figures, no trailing point
tv_pub_num <- function(x) trimws(formatC(signif(x, 3), digits = 3, format = "fg"))

tv_pub_stat <- function(x) {
  nm <- names(x$statistic) %||% ""
  df <- if (!is.null(x$parameter)) paste(tv_whole(unname(x$parameter)), collapse = ", ") else ""
  utf8 <- isTRUE(l10n_info()$`UTF-8`)
  chi <- if (utf8) "\u03c7\u00b2" else "chi-squared"
  sym <- switch(nm,
    "Kruskal-Wallis chi-squared" = "H", "X-squared" = chi, "Friedman chi-squared" = chi,
    t = "t", F = "F", W = "W", V = "V", S = "S", "Bartlett's K-squared" = if (utf8) "K\u00b2" else "K-squared",
    "med chi-squared" = chi, nm
  )
  if (!nzchar(sym)) return(tv_p(x$p.value))
  sprintf("%s%s = %s, %s", sym, if (nzchar(df)) paste0("(", df, ")") else "", tv_pub_num(unname(x$statistic)), tv_p(x$p.value))
}

tv_publication_htest <- function(x, kind, sig) {
  meth <- trimws(x$method)
  parts <- strsplit(x$data.name %||% "", " by | and ")[[1]]
  two_names <- length(parts) == 2
  y <- if (two_names) trimws(parts[1]) else "y"
  g <- if (two_names) trimws(sub(" .*$", "", parts[2])) else "group"
  stat <- tv_pub_stat(x)
  ci <- if (!is.null(x$conf.int)) sprintf("; %d%% CI %s to %s", round(100 * attr(x$conf.int, "conf.level")), tv_pub_num(x$conf.int[1]), tv_pub_num(x$conf.int[2])) else ""
  est_name <- switch(names(x$estimate)[1] %||% "", cor = "r", rho = "Spearman's rho", tau = "Kendall's tau", names(x$estimate)[1] %||% "")
  est <- if (!is.null(x$estimate) && length(x$estimate) == 1) sprintf("%s = %s%s, ", est_name, tv_pub_num(unname(x$estimate)), ci) else ""
  if (kind %in% c("normality", "spread")) {
    return(c(
      "Assumption checks are not results: state in the Methods which checks were made and what was done about them (for example 'Normality of residuals was checked with Q-Q plots; counts were log-transformed').",
      "A formal test of an assumption is rarely worth reporting on its own; the plot of the residuals is more informative."
    ))
  }
  sentence <- switch(kind,
    correlation = sprintf("Results: '%s and %s were %scorrelated (%s%s).'", y, g, if (sig) "" else "not detectably ", est, stat),
    table = sprintf("Results: 'The distribution of %s %s %s (%s).'", y, if (sig) "differed with" else "did not differ detectably with", g, stat),
    sprintf("Results: '%s %s %s (%s; %s%s).'", y, if (sig) "differed among levels of" else "did not differ detectably among levels of", g, meth, est, stat)
  )
  fig <- switch(kind,
    correlation = sprintf("ggplot2::ggplot(data, ggplot2::aes(%s, %s)) + ggplot2::geom_point(alpha = 0.7) + ggplot2::geom_smooth(method = \"lm\") + ggplot2::theme_classic(base_size = 9)", g, y),
    table = sprintf("ggplot2::ggplot(data, ggplot2::aes(%s, fill = %s)) + ggplot2::geom_bar(position = \"fill\") + ggplot2::labs(y = \"Proportion\") + ggplot2::scale_fill_viridis_d() + ggplot2::theme_classic(base_size = 9)", g, y),
    sprintf("ggplot2::ggplot(data, ggplot2::aes(%s, %s)) + ggplot2::geom_boxplot(outlier.shape = NA, width = 0.5) + ggplot2::geom_jitter(width = 0.15, alpha = 0.6) + ggplot2::theme_classic(base_size = 9)", g, y)
  )
  table <- switch(kind,
    table = "Table: the counts with row percentages, and the test statistic, df and p-value in a footnote.",
    correlation = "Table: for several pairs, a correlation matrix with n and the method named; mark adjusted p-values if many are tested.",
    sprintf("Table: one row per level of %s with n and %s; the test in a footnote, and any post hoc results as letters or a pairwise table with adjusted p-values.", g, if (kind == "rank") "the median and interquartile range" else "the mean with its SD (or 95%% CI)")
  )
  c(sentence,
    "Report the statistic with its degrees of freedom, the exact p-value (p < 0.001 below that), and the effect size with its interval; never 'p = 0.000' or 'n.s.' alone.",
    "Figure:", fig, tv_pub_save, tv_pub_figure_style,
    table,
    sprintf("Methods: name the test (%s), the software and version (R %s, citation()), any adjustment for multiple comparisons, and the significance level.", meth, paste(R.version$major, R.version$minor, sep = ".")))
}

# For a fitted model with a coefficient table `tab` (term, estimate,
# lower, upper, p.value).
tv_publication_model <- function(m, tab, link = "identity", yname = "y", mixed = FALSE) {
  ratio <- link %in% c("log", "logit")
  what <- switch(link, log = "multiplied by", logit = "multiplied the odds by", "changed by")
  tab <- tab[is.finite(tab$p.value), , drop = FALSE]
  top <- utils::head(tab[order(tab$p.value), , drop = FALSE], 3)
  xl <- tryCatch(if (inherits(m, "lm")) m$xlevels else tv_model_xlevels(m), error = function(e) list())
  lev <- unlist(lapply(names(xl), function(f) {
    v <- all.vars(str2lang(f))
    lab <- if (length(v) == 1) v else f
    stats::setNames(sprintf("%s = %s|%s = %s", lab, xl[[f]][-1], lab, xl[[f]][1]), paste0(f, xl[[f]][-1]))
  }))
  sents <- vapply(seq_len(nrow(top)), function(i) {
    r <- top[i, ]
    e <- c(r$estimate, r$lower, r$upper)
    if (ratio) e <- exp(e)
    ci <- sprintf("95%% CI %s to %s, %s", tv_pub_num(e[2]), tv_pub_num(e[3]), tv_p(r$p.value))
    if (r$term %in% names(lev)) {
      ab <- strsplit(lev[[r$term]], "|", fixed = TRUE)[[1]]
      if (link == "logit") {
        sprintf("'The odds of %s were %s times as high for %s as for %s (%s).'", yname, tv_pub_num(e[1]), ab[1], ab[2], ci)
      } else if (ratio) {
        sprintf("'%s was %s times as high for %s as for %s (%s).'", yname, tv_pub_num(e[1]), ab[1], ab[2], ci)
      } else {
        sprintf("'%s was %s %s for %s than for %s (%s).'", yname, tv_pub_num(abs(e[1])), if (e[1] >= 0) "higher" else "lower", ab[1], ab[2], ci)
      }
    } else {
      if (link == "logit") {
        sprintf("'The odds of %s were multiplied by %s per unit increase in %s (%s).'", yname, tv_pub_num(e[1]), r$term, ci)
      } else {
        sprintf("'%s %s %s per unit increase in %s (%s).'", yname, what, tv_pub_num(e[1]), r$term, ci)
      }
    }
  }, "")
  vars <- tryCatch({
    tl <- attr(stats::terms(stats::formula(m)), "term.labels")
    tl[!grepl("|", tl, fixed = TRUE) & !grepl(":", tl, fixed = TRUE)]
  }, error = function(e) character())
  focal <- if (length(vars)) all.vars(str2lang(vars[1]))[1] else "x"
  expo <- if (ratio) ", exponentiate = TRUE" else ""
  c(
    if (length(sents)) c("Results (strongest evidence first; each factor level is compared with the reference level):", sents),
    if (ratio) sprintf("The model is on the %s scale, so effects are reported as %s (exponentiated coefficients) with their intervals.", link, if (link == "log") "ratios of means" else "odds ratios"),
    "Report every term of the model, not only the significant ones, with the estimate, its 95% CI and the p-value; give n, and the fit (R-squared, or deviance explained, or the random-effect SDs for a mixed model).",
    "Figure: model predictions with their confidence band over the raw data, one panel per focal predictor:",
    sprintf("ggeffects::ggpredict(m, terms = \"%s\") |> plot(show_data = TRUE)", focal),
    tv_pub_save, tv_pub_figure_style,
    "Table: one row per term with the estimate, 95% CI and p-value (and the random-effect SDs for a mixed model):",
    sprintf("gtsummary::tbl_regression(m%s)   # or broom%s::tidy(m, conf.int = TRUE%s) for your own table", expo, if (mixed) ".mixed" else "", expo),
    sprintf("Methods: the model formula, the family and link, how the model was checked, the software and packages with versions (R %s; citation(\"%s\")), and how the predictors were chosen (before seeing the data, or how).", paste(R.version$major, R.version$minor, sep = "."), if (mixed) if (inherits(m, "glmmTMB")) "glmmTMB" else "lme4" else "stats")
  )
}
# nolint end
