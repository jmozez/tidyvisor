# The regression advisor: linear and generalised linear models

The built-in advisor for
[`stats::lm()`](https://rdrr.io/r/stats/lm.html) and
[`stats::glm()`](https://rdrr.io/r/stats/glm.html). It is registered
under the name `"stats"`, so
[`tidyvisor()`](https://tidyvisor.in4metrix.dev/reference/tidyvisor.md)
uses it for `question = "regression"` and for any fitted `lm` or `glm`.

**Before fitting**
(`tidyvisor(data, question = "regression", response = "y")`), it looks
at the response and the predictors and recommends a model:

- the **family and link** from the kind of response: continuous
  (Gaussian), counts (Poisson, or negative binomial when overdispersed),
  binary (binomial, logit), proportions (binomial with the number of
  trials), positive and right-skewed (Gamma, log);

- whether counts show **overdispersion** or **more zeros** than a
  Poisson distribution with the same mean would give (a rough first
  check, before the predictors are taken into account);

- whether there are enough observations: about 10 to 20 per estimated
  parameter (Harrell 2015), and for a binary response at least 10 events
  of the rarer outcome per parameter (Peduzzi et al. 1996);

- **collinear** numeric predictors (\|r\| \> 0.7; Dormann et al. 2013)
  and missing values.

**After fitting** (`tidyvisor(model)`), it explains:

- the fit: R-squared for `lm`, the share of deviance explained for
  `glm`, and the test against the null model;

- every coefficient on its natural scale, with a 95% confidence
  interval: a change per unit (identity link), a multiplicative change
  (log link) or an odds ratio (logit link);

- diagnostics: overdispersion (Pearson statistic / residual df),
  non-constant variance (studentised Breusch-Pagan test), non-normal
  residuals (Shapiro-Wilk, for Gaussian models), influential
  observations (Cook's distance \> 1; Cook and Weisberg 1982),
  collinearity (variance inflation factors) and separation in binomial
  models.

Confidence intervals are Wald intervals (estimate +/- critical value x
standard error) on the link scale, transformed to the response scale;
they can be optimistic in small samples, where profile intervals
([`stats::confint()`](https://rdrr.io/r/stats/confint.html)) are better.

## Usage

``` r
tv_advise_regression(
  x,
  question = "regression",
  response,
  predictors = NULL,
  trials = NULL,
  ...
)

tv_interpret_regression(x, level = 0.95, ...)
```

## Arguments

- x:

  A data frame (advice) or a fitted `lm` or `glm` (interpretation).

- question:

  `"regression"`.

- response:

  Name of the response column.

- predictors:

  Names of the predictor columns; default all other columns.

- trials:

  For a response of successes out of a number of trials, the name of the
  column holding the number of trials.

- ...:

  Not used.

- level:

  Confidence level of the intervals.

## Value

`tv_advise_regression()` returns a `tv_advice` object and
`tv_interpret_regression()` a `tv_interpretation` object; both print as
sentences.

## References

Cook, R. D. and Weisberg, S. (1982). Residuals and Influence in
Regression. Chapman and Hall.

Dormann, C. F. et al. (2013). Collinearity: a review of methods to deal
with it and a simulation study evaluating their performance. Ecography,
36, 27-46.

Harrell, F. E. (2015). Regression Modeling Strategies, 2nd ed. Springer.

Peduzzi, P., Concato, J., Kemper, E., Holford, T. R. and Feinstein, A.
R. (1996). A simulation study of the number of events per variable in
logistic regression analysis. Journal of Clinical Epidemiology, 49,
1373-1379.

Zuur, A. F., Ieno, E. N. and Elphick, C. S. (2010). A protocol for data
exploration to avoid common statistical problems. Methods in Ecology and
Evolution, 1, 3-14.

## Examples

``` r
# Before: which model for counts of warp breaks?
tidyvisor(warpbreaks, question = "regression", response = "breaks")
#> 
#> ── tidyvisor: which analysis? ──────────────────────────────────────────────────
#> Question: regression
#> 
#> ── What the data show ──
#> 
#> • Observations: 54
#> • Response: counts (non-negative integers)
#> • Variance / mean: 6.2 — above 1: overdispersed; a negative binomial model is
#>   safer than Poisson
#> • Zeros: 0% observed, 0% expected under Poisson
#> • Parameters (excluding intercept): 3
#> 
#> ── Recommended ──
#> 
#> Model: Generalised linear model: MASS::glm.nb()
#> Counts whose variance exceeds the mean (overdispersion) make Poisson standard
#> errors too small; the negative binomial estimates the extra variance.
#> m <- MASS::glm.nb(breaks ~ wool + tension, data = data)
#> Before fitting: Plot the response against each predictor
#> Shows non-linear relations, outliers and interactions that the model would miss
#> (Zuur et al. 2010).
#> plot(data[c("breaks", "wool", "tension")])
#> After fitting: Check the residuals
#> Residual plots show non-linearity, unequal variance and influential points;
#> tidyvisor reports the tests.
#> plot(m)   # or performance::check_model(m)
#> Interpret: Plain-language explanation of the model
#> Effects on the scale of the response, the fit and the diagnostics.
#> tidyvisor(m)

# After: what does the model show?
m <- glm(breaks ~ wool + tension, family = poisson, data = warpbreaks)
tidyvisor(m)
#> 
#> ── tidyvisor: what the results show ────────────────────────────────────────────
#> 
#> ── Overview ──
#> 
#> • Generalised linear model of breaks on 54 observations (poisson family, log
#>   link).
#> 
#> ── Fit ──
#> 
#> • The predictors explain 29.2% of the deviance (the GLM analogue of R-squared).
#> • Against a model with no predictors: likelihood-ratio chi-squared = 87.0 on 3
#>   df, p < 0.001.
#> 
#> ── Effects ──
#> 
#> • woolB: wool = B (compared with wool = A) multiplies the expected breaks by
#>   0.814 (-19%; 95% CI 0.736 to 0.900), p < 0.001.
#> • tensionM: tension = M (compared with tension = L) multiplies the expected
#>   breaks by 0.725 (-27%; 95% CI 0.644 to 0.816), p < 0.001.
#> • tensionH: tension = H (compared with tension = L) multiplies the expected
#>   breaks by 0.595 (-40%; 95% CI 0.525 to 0.675), p < 0.001.
#> • Effects on the log or logit scale are multiplicative: they combine by
#>   multiplying, and a factor of 1 means no effect.
#> • Each effect is estimated with the other predictors held fixed.
#> 
#> ── Diagnostics ──
#> 
#> • Overdispersion: Pearson statistic / residual df = 4.26 (expected about 1).
#>   Standard errors and p-values are too small; refit with a negative binomial
#>   model (MASS::glm.nb()) or family = quasipoisson.
#> • Influence: no observation dominates the fit (largest Cook's distance 0.55,
#>   row 5; values above 1 would be a concern).
#> 
#> ── After the overall test ──
#> 
#> • tension (3 levels) has an overall effect (p < 0.001): the levels are not all
#>   alike. Go on to post hoc comparisons of every pair, adjusted for the number
#>   of comparisons; the coefficients above only compare each level with the
#>   reference level L.
#> • emmeans::emmeans(m, pairwise ~ tension, type = "response") # Tukey-adjusted
#>   pairs, with intervals
#> • If only comparisons with a control matter, decide so before looking and use
#>   emmeans::emmeans(m, trt.vs.ctrl ~ tension, type = "response") (Dunnett; the
#>   first level, L, is the control), which keeps more power.
#> 
#> ── For the paper ──
#> 
#> • Results (strongest evidence first; each factor level is compared with the
#>   reference level):
#> • 'breaks was 0.595 times as high for tension = H as for tension = L (95% CI
#>   0.525 to 0.675, p < 0.001).'
#> • 'breaks was 0.725 times as high for tension = M as for tension = L (95% CI
#>   0.644 to 0.816, p < 0.001).'
#> • 'breaks was 0.814 times as high for wool = B as for wool = A (95% CI 0.736 to
#>   0.9, p < 0.001).'
#> • The model is on the log scale, so effects are reported as ratios of means
#>   (exponentiated coefficients) with their intervals.
#> • Report every term of the model, not only the significant ones, with the
#>   estimate, its 95% CI and the p-value; give n, and the fit (R-squared, or
#>   deviance explained, or the random-effect SDs for a mixed model).
#> • Figure: model predictions with their confidence band over the raw data, one
#>   panel per focal predictor:
#> • ggeffects::ggpredict(m, terms = "wool") |> plot(show_data = TRUE)
#> • ggplot2::ggsave("figure1.pdf", width = 85, height = 70, units = "mm") # one
#>   journal column
#> • Figure style for journals: show the raw data with the estimates, give n per
#>   group in the caption, label axes with units, use a colour-blind-safe palette
#>   (Okabe-Ito, viridis) and no 3D, pie or dual-axis charts; text at least 8 pt
#>   at final size; save as PDF or SVG (vector) at the journal's column width
#>   (about 85 mm single, 180 mm double), or 600 dpi for raster images.
#> • Table: one row per term with the estimate, 95% CI and p-value (and the
#>   random-effect SDs for a mixed model):
#> • gtsummary::tbl_regression(m, exponentiate = TRUE) # or broom::tidy(m,
#>   conf.int = TRUE, exponentiate = TRUE) for your own table
#> • Methods: the model formula, the family and link, how the model was checked,
#>   the software and packages with versions (R 4.6.2; citation("stats")), and how
#>   the predictors were chosen (before seeing the data, or how).
#> 
#> ── Reading the plots ──
#> 
#> • plot(model) shows four diagnostics: residuals against fitted values (look for
#>   curves or a funnel), the normal Q-Q plot, scale-location (spread against
#>   fitted values) and residuals against leverage (influential points).
#> • Plot each effect on the response scale, with its confidence band, rather than
#>   the coefficients alone.
```
