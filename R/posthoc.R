# Advice after an overall test: go on to post hoc comparisons only when the
# overall result is significant and there are three or more groups; with
# two groups, report the effect; when it is not significant, stop and say
# why fishing among pairs is not allowed.
# nolint start: line_length_linter. Advice strings read better unbroken.

tv_no_posthoc <- c(
  "Do not go on to pairwise (post hoc) comparisons: with no overall difference, testing every pair is a search for something significant, and any 'difference' it finds is likely to be a false positive.",
  "Report the overall test with an effect size and its interval, and say what size of difference the study could have detected (tv_power()); a non-significant result is not evidence that the groups are the same."
)

# For a test result (class htest). `y` and `g` are the response and the
# grouping names from data.name ("count by spray"); `k` the number of groups.
tv_posthoc_htest <- function(x, kind, sig, alpha = 0.05) {
  meth <- trimws(x$method)
  parts <- strsplit(x$data.name %||% "", " by | and ")[[1]]
  y <- if (length(parts) == 2) trimws(parts[1]) else "y"
  g <- if (length(parts) == 2) trimws(sub(" .*$", "", parts[2])) else "group"
  df1 <- if (!is.null(x$parameter)) unname(x$parameter[1]) else NA
  kruskal <- grepl("Kruskal", meth)
  oneway <- grepl("One-way|oneway", meth, ignore.case = TRUE)
  friedman <- grepl("Friedman", meth)
  k <- if (is.finite(df1)) round(df1) + 1 else NA
  if ((kruskal || oneway) && isTRUE(k == 2)) kind <- if (kruskal) "rank" else "welch"
  if ((kruskal || oneway || friedman) && !isTRUE(k == 2)) {
    groups <- if (is.na(k)) "the groups" else sprintf("the %d groups", k)
    if (!sig) return(c(sprintf("The overall test finds no difference among %s (p = %s at the %s level).", groups, format(signif(x$p.value, 2)), alpha), tv_no_posthoc))
    intro <- sprintf("The overall test shows that %s are not all alike; it does not say which differ. Go on to post hoc comparisons of every pair, with p-values adjusted for the number of comparisons.", groups)
    how <- if (kruskal) {
      c(sprintf("Rank-based pairs (the follow-up to Kruskal-Wallis): pairwise.wilcox.test(data$%s, data$%s, p.adjust.method = \"holm\"), or a Dunn test (FSA::dunnTest(%s ~ %s, data = data, method = \"holm\")).", y, g, y, g),
        "Report each pair as a median difference or Hodges-Lehmann shift with its interval (wilcox.test(conf.int = TRUE)), not only adjusted p-values.")
    } else if (friedman) {
      c(sprintf("Paired rank pairs: pairwise.wilcox.test(%s, %s, paired = TRUE, p.adjust.method = \"holm\") (data in the same block order in every group).", y, g))
    } else {
      c(sprintf("Unequal spreads (Welch ANOVA): pairwise.t.test(data$%s, data$%s, pool.sd = FALSE, p.adjust.method = \"holm\"), or Games-Howell (rstatix::games_howell_test(data, %s ~ %s)).", y, g, y, g),
        sprintf("Equal spreads: TukeyHSD(aov(%s ~ %s, data = data)), which gives each difference in means with its family-wise interval.", y, g))
    }
    return(c(intro, how, "Decide which pairs matter before looking: if only comparisons with a control are of interest, test those alone (Dunnett, or Holm on that smaller set); fewer comparisons keep more power."))
  }
  if (kind %in% c("welch", "student", "rank")) {
    return(c(
      "Only two groups are compared, so no post hoc tests are needed: this test already says whether they differ.",
      if (sig) "Report the size of the difference with its interval (shown above), and a standardised effect size if readers expect one (Cohen's d for means; the rank-biserial correlation for a rank test)." else tv_no_posthoc[2]
    ))
  }
  if (kind == "table") {
    dims <- if (!is.null(x$observed)) dim(as.matrix(x$observed)) else c(NA, NA)
    big <- all(is.finite(dims)) && max(dims) > 2
    if (!sig) return(c("The overall test finds no association.", tv_no_posthoc))
    if (!big) return("A 2 x 2 table has a single comparison: report the difference in proportions, or the odds ratio, with its interval (prop.test(), fisher.test()).")
    return(c(
      "The table as a whole shows an association; it does not say which categories drive it. Go on to post hoc comparisons:",
      "Cells: standardised residuals (chisq.test(...)$stdres); beyond +/-2 (or a Bonferroni-adjusted limit for many cells) mark the cells that drive the result.",
      "Pairs of groups: pairwise.prop.test(successes, totals, p.adjust.method = \"holm\") for a 2-column table, or chi-squared tests on 2 x 2 sub-tables with adjusted p-values."
    ))
  }
  NULL
}

# For a fitted model: for each factor with three or more levels, test the
# term (drop1) and say whether to compare its levels, with emmeans code.
tv_posthoc_model <- function(m, alpha = 0.05) {
  xl <- tryCatch(if (inherits(m, "lm")) m$xlevels else tv_model_xlevels(m), error = function(e) list())
  facs <- names(xl)[vapply(xl, length, 1L) >= 3]
  if (!length(facs)) return(NULL)
  test <- if (inherits(m, "glm") && stats::family(m)$family %in% c("poisson", "binomial")) "Chisq" else if (inherits(m, "lm")) "F" else "Chisq"
  d1 <- tryCatch(suppressWarnings(stats::drop1(m, test = test)), error = function(e) NULL)
  if (is.null(d1)) return(NULL)
  pcol <- grep("^Pr\\(", names(d1), value = TRUE)[1]
  if (is.na(pcol)) return(NULL)
  terms <- rownames(d1)
  pv <- stats::setNames(d1[[pcol]], terms)
  resp <- if (inherits(m, "glm") || inherits(m, "glmerMod") || inherits(m, "glmmTMB")) ", type = \"response\"" else ""
  out <- character()
  bare <- function(t) {
    v <- all.vars(str2lang(t))
    if (length(v) == 1) v else t
  }
  for (f in facs) {
    fv <- bare(f)
    inter <- terms[vapply(strsplit(terms, ":", fixed = TRUE), function(p) length(p) > 1 && f %in% p, TRUE)]
    inter_sig <- inter[is.finite(pv[inter]) & pv[inter] < alpha]
    if (length(inter_sig)) {
      other <- setdiff(strsplit(inter_sig[1], ":")[[1]], f)
      out <- c(
        out,
        sprintf("%s interacts with %s (%s, %s): its effect depends on %s, so compare the levels of %s within each level of %s, not averaged over them.", f, paste(other, collapse = " and "), inter_sig[1], tv_p(pv[inter_sig[1]]), paste(other, collapse = " and "), f, paste(other, collapse = " and ")),
        sprintf("emmeans::emmeans(m, pairwise ~ %s | %s%s)   # Tukey-adjusted pairs within each level", fv, paste(vapply(other, bare, ""), collapse = " + "), resp)
      )
      next
    }
    if (!f %in% terms || !is.finite(pv[f])) {
      out <- c(out, sprintf("%s has %d levels, but its overall test could not be separated from the interactions it is in; remove non-significant interactions first, then test it.", f, length(xl[[f]])))
      next
    }
    if (pv[f] < alpha) {
      out <- c(
        out,
        sprintf("%s (%d levels) has an overall effect (%s): the levels are not all alike. Go on to post hoc comparisons of every pair, adjusted for the number of comparisons; the coefficients above only compare each level with the reference level %s.", f, length(xl[[f]]), tv_p(pv[f]), xl[[f]][1]),
        sprintf("emmeans::emmeans(m, pairwise ~ %s%s)   # Tukey-adjusted pairs, with intervals", fv, resp),
        sprintf("If only comparisons with a control matter, decide so before looking and use emmeans::emmeans(m, trt.vs.ctrl ~ %s%s) (Dunnett; the first level, %s, is the control), which keeps more power.", fv, resp, xl[[f]][1])
      )
    } else {
      out <- c(out, sprintf("%s (%d levels) has no overall effect (%s): do not go on to pairwise comparisons of its levels, which would be a search for something significant. Report the overall test and the estimates with their intervals.", f, length(xl[[f]]), tv_p(pv[f])))
    }
  }
  out
}

# Levels of the factors among the fixed effects (random-effect grouping
# columns such as (1 | site) are left out)
tv_model_xlevels <- function(m) {
  tl <- attr(stats::terms(stats::formula(m)), "term.labels")
  tl <- tl[!grepl("|", tl, fixed = TRUE)]
  fixed <- unique(unlist(lapply(tl, function(t) all.vars(str2lang(t)))))
  mf <- stats::model.frame(m)
  keep <- intersect(fixed, names(mf))
  keep <- keep[vapply(mf[keep], function(v) is.factor(v) || is.character(v), TRUE)]
  lapply(mf[keep], function(v) levels(factor(v)))
}
# nolint end
