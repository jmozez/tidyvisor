# 4. Regression and generalised linear models

A regression model explains a response by one or more predictors. The
first decision is the **family**: the kind of variation the response
has. A linear model assumes a continuous response with constant, normal
scatter. Counts, proportions and yes/no outcomes break those assumptions
and have their own generalised linear models (GLMs).

``` r

library(tidyvisor)
```

## Before fitting: which model?

Give the data and the name of the response; tidyvisor looks at the
response and the predictors and recommends the model.

### A continuous response

Fuel consumption of 32 cars (`mtcars`) against weight and power:

``` r

tidyvisor(mtcars, response = "mpg", predictors = c("wt", "hp"))
#> Registered S3 method overwritten by 'parsnip':
#>   method          from 
#>   print.nullmodel vegan
#> 
#> ── tidyvisor: which analysis? ──────────────────────────────────────────────────
#> Question: regression
#> 
#> ── What the data show ──
#> 
#> • Observations: 32
#> • Response: continuous
#> • Parameters (excluding intercept): 2
#> • Collinear predictor pairs (|r| > 0.7): none
#> 
#> ── Recommended ──
#> 
#> Model: Linear model
#> A continuous, roughly symmetric response suits a linear model; check the
#> residuals after fitting.
#> m <- lm(mpg ~ wt + hp, data = data)
#> Before fitting: Plot the response against each predictor
#> Shows non-linear relations, outliers and interactions that the model would miss
#> (Zuur et al. 2010).
#> plot(data[c("mpg", "wt", "hp")])
#> After fitting: Check the residuals
#> Residual plots show non-linearity, unequal variance and influential points;
#> tidyvisor reports the tests.
#> plot(m)   # or performance::check_model(m)
#> Interpret: Plain-language explanation of the model
#> Effects on the scale of the response, the fit and the diagnostics.
#> tidyvisor(m)
```

### Counts

Counts of warp breaks in wool (`warpbreaks`) by wool type and tension.
tidyvisor compares the variance of the counts with their mean: Poisson
models assume they are equal, and when the variance is much larger
(overdispersion) a negative binomial model is safer.

``` r

tidyvisor(warpbreaks, response = "breaks", predictors = c("wool", "tension"))
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
```

### A binary outcome

Whether a car has a manual gearbox (`am`, 0 or 1) against its weight. A
binary response needs a logistic regression, and the rarer outcome
limits how many predictors the data can support (about ten events per
parameter).

``` r

tidyvisor(mtcars, response = "am", predictors = "wt")
#> 
#> ── tidyvisor: which analysis? ──────────────────────────────────────────────────
#> Question: regression
#> 
#> ── What the data show ──
#> 
#> • Observations: 32
#> • Response: binary (two outcomes)
#> • Parameters (excluding intercept): 1
#> • Events of the rarer outcome: 13
#> 
#> ── Recommended ──
#> 
#> Model: Generalised linear model: binomial
#> A yes/no response is binomial; the logit link gives effects as odds ratios.
#> m <- glm(am ~ wt, family = binomial, data = data)
#> Before fitting: Plot the response against each predictor
#> Shows non-linear relations, outliers and interactions that the model would miss
#> (Zuur et al. 2010).
#> plot(data[c("am", "wt")])
#> After fitting: Check the residuals
#> Residual plots show non-linearity, unequal variance and influential points;
#> tidyvisor reports the tests.
#> plot(m)   # or performance::check_model(m)
#> Interpret: Plain-language explanation of the model
#> Effects on the scale of the response, the fit and the diagnostics.
#> tidyvisor(m)
```

## After fitting: what does the model say?

Pass the fitted model to
[`tidyvisor()`](https://tidyvisor.in4metrix.dev/reference/tidyvisor.md).
Effects are given on the scale of the response: changes for linear
models, rate ratios for counts with a log link, odds ratios for logistic
regression. The diagnostics check the assumptions, and “What to do next”
lists the remedies for those that fail.

``` r

m <- lm(mpg ~ wt + hp, data = mtcars)
tidyvisor(m)
#> 
#> ── tidyvisor: what the results show ────────────────────────────────────────────
#> 
#> ── Overview ──
#> 
#> • Linear model of mpg on 32 observations (gaussian family, identity link).
#> 
#> ── Fit ──
#> 
#> • The predictors explain 82.7% of the variance of mpg (R-squared; adjusted
#>   81.5%).
#> • Against a model with no predictors: F = 69.21 on 2 and 29 df, p < 0.001.
#> 
#> ── Effects ──
#> 
#> • wt: each one-unit increase in wt changes mpg by -3.88 (95% CI -5.17 to
#>   -2.58), p < 0.001.
#> • hp: each one-unit increase in hp changes mpg by -0.0318 (95% CI -0.0502 to
#>   -0.0133), p = 0.001.
#> • Each effect is estimated with the other predictors held fixed.
#> 
#> ── Diagnostics ──
#> 
#> • Normality of residuals (Shapiro-Wilk): W = 0.928, p = 0.034; the residuals
#>   depart from normality: look at the Q-Q plot, and consider a transformation or
#>   another family.
#> • Constant variance (Breusch-Pagan): chi-squared = 0.88 on 2 df, p = 0.644.
#> • Influence: no observation dominates the fit (largest Cook's distance 0.42,
#>   row Chrysler Imperial; values above 1 would be a concern).
#> 
#> ── What to do next ──
#> 
#> • Transform the response: the values are positive and the residuals are
#>   right-skewed, which a log scale often fixes. Refit with log(mpg) and check
#>   again; effects then multiply mpg (report exp(coefficient)). MASS::boxcox(m)
#>   shows which power suits the data (0 = log, 0.5 = square root).
#> • Or keep the original scale with a Gamma GLM and a log link, which expects the
#>   spread to grow with the mean: glm(mpg ~ wt + hp, family = Gamma(link =
#>   "log"), data = data).
#> • Rank-based or permutation alternatives make no assumption about the
#>   distribution: for one factor, kruskal.test() or wilcox.test(); for a whole
#>   model, a permutation test of each term (for example lmPerm::lmp()).
#> • After any change, check the residuals again with plot() and tidyvisor().
#> 
#> ── For the paper ──
#> 
#> • Results (strongest evidence first; each factor level is compared with the
#>   reference level):
#> • 'mpg changed by -3.88 per unit increase in wt (95% CI -5.17 to -2.58, p <
#>   0.001).'
#> • 'mpg changed by -0.0318 per unit increase in hp (95% CI -0.0502 to -0.0133, p
#>   = 0.001).'
#> • Report every term of the model, not only the significant ones, with the
#>   estimate, its 95% CI and the p-value; give n, and the fit (R-squared, or
#>   deviance explained, or the random-effect SDs for a mixed model).
#> • Figure: model predictions with their confidence band over the raw data, one
#>   panel per focal predictor:
#> • ggeffects::ggpredict(m, terms = "wt") |> plot(show_data = TRUE)
#> • ggplot2::ggsave("figure1.pdf", width = 85, height = 70, units = "mm") # one
#>   journal column
#> • Figure style for journals: show the raw data with the estimates, give n per
#>   group in the caption, label axes with units, use a colour-blind-safe palette
#>   (Okabe-Ito, viridis) and no 3D, pie or dual-axis charts; text at least 8 pt
#>   at final size; save as PDF or SVG (vector) at the journal's column width
#>   (about 85 mm single, 180 mm double), or 600 dpi for raster images.
#> • Table: one row per term with the estimate, 95% CI and p-value (and the
#>   random-effect SDs for a mixed model):
#> • gtsummary::tbl_regression(m) # or broom::tidy(m, conf.int = TRUE) for your
#>   own table
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

``` r

nb <- MASS::glm.nb(breaks ~ wool + tension, data = warpbreaks)
tidyvisor(nb)
#> 
#> ── tidyvisor: what the results show ────────────────────────────────────────────
#> 
#> ── Overview ──
#> 
#> • Generalised linear model of breaks on 54 observations (Negative
#>   Binomial(9.9444) family, log link).
#> 
#> ── Fit ──
#> 
#> • The predictors explain 28.8% of the deviance (the GLM analogue of R-squared).
#> • Against a model with no predictors: F = 6.75 on 3 and 50 df, p < 0.001.
#> 
#> ── Effects ──
#> 
#> • woolB: wool = B (compared with wool = A) multiplies the expected breaks by
#>   0.830 (-17%; 95% CI 0.678 to 1.02), p = 0.065.
#> • tensionM: tension = M (compared with tension = L) multiplies the expected
#>   breaks by 0.741 (-26%; 95% CI 0.581 to 0.947), p = 0.014.
#> • tensionH: tension = H (compared with tension = L) multiplies the expected
#>   breaks by 0.600 (-40%; 95% CI 0.468 to 0.769), p < 0.001.
#> • Effects on the log or logit scale are multiplicative: they combine by
#>   multiplying, and a factor of 1 means no effect.
#> • Each effect is estimated with the other predictors held fixed.
#> 
#> ── Diagnostics ──
#> 
#> • Influence: no observation dominates the fit (largest Cook's distance 0.11,
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
#> • 'breaks was 0.6 times as high for tension = H as for tension = L (95% CI
#>   0.468 to 0.769, p < 0.001).'
#> • 'breaks was 0.741 times as high for tension = M as for tension = L (95% CI
#>   0.581 to 0.947, p = 0.014).'
#> • 'breaks was 0.83 times as high for wool = B as for wool = A (95% CI 0.678 to
#>   1.02, p = 0.065).'
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

``` r

lg <- glm(am ~ wt, family = binomial, data = mtcars)
tidyvisor(lg)
#> 
#> ── tidyvisor: what the results show ────────────────────────────────────────────
#> 
#> ── Overview ──
#> 
#> • Generalised linear model of am on 32 observations (binomial family, logit
#>   link).
#> 
#> ── Fit ──
#> 
#> • The predictors explain 55.6% of the deviance (the GLM analogue of R-squared).
#> • Against a model with no predictors: likelihood-ratio chi-squared = 24.1 on 1
#>   df, p < 0.001.
#> 
#> ── Effects ──
#> 
#> • wt: each one-unit increase in wt multiplies the odds of am = 1 by 0.0179
#>   (odds ratio; 95% CI 0.00107 to 0.299), p = 0.005.
#> • Effects on the log or logit scale are multiplicative: they combine by
#>   multiplying, and a factor of 1 means no effect.
#> • Each effect is estimated with the other predictors held fixed.
#> 
#> ── Diagnostics ──
#> 
#> • Separation: some fitted probabilities are 0 or 1, so some coefficients and
#>   their standard errors are unreliable; consider a penalised (Firth) logistic
#>   regression.
#> • Influence: no observation dominates the fit (largest Cook's distance 0.62,
#>   row Toyota Corona; values above 1 would be a concern).
#> 
#> ── For the paper ──
#> 
#> • Results (strongest evidence first; each factor level is compared with the
#>   reference level):
#> • 'The odds of am were multiplied by 0.0179 per unit increase in wt (95% CI
#>   0.00107 to 0.299, p = 0.005).'
#> • The model is on the logit scale, so effects are reported as odds ratios
#>   (exponentiated coefficients) with their intervals.
#> • Report every term of the model, not only the significant ones, with the
#>   estimate, its 95% CI and the p-value; give n, and the fit (R-squared, or
#>   deviance explained, or the random-effect SDs for a mixed model).
#> • Figure: model predictions with their confidence band over the raw data, one
#>   panel per focal predictor:
#> • ggeffects::ggpredict(m, terms = "wt") |> plot(show_data = TRUE)
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

## How to read the advice

- **Family.** The family follows the response: gaussian for continuous
  values, Poisson or negative binomial for counts, binomial for
  proportions and yes/no outcomes, Gamma for positive skewed values.
  Transforming counts and proportions to fit a linear model is rarely
  better than the right GLM.
- **Observations per parameter.** With fewer than about ten observations
  (or rare-outcome events) per estimated coefficient, models overfit:
  they describe the sample well and new data badly. Drop or combine
  predictors.
- **Collinearity.** Strongly correlated predictors share their effect;
  their separate coefficients are unstable. The variance inflation
  factor (above 5) flags them.
- **Effects are conditional.** Each coefficient is the effect with the
  other predictors held fixed; adding or removing predictors changes it.

## References

Zuur, A. F., Ieno, E. N. and Elphick, C. S. (2010). A protocol for data
exploration to avoid common statistical problems. *Methods in Ecology
and Evolution* 1, 3-14.

O’Hara, R. B. and Kotze, D. J. (2010). Do not log-transform count data.
*Methods in Ecology and Evolution* 1, 118-122.

Peduzzi, P., Concato, J., Kemper, E., Holford, T. R. and Feinstein, A.
R. (1996). A simulation study of the number of events per variable in
logistic regression analysis. *Journal of Clinical Epidemiology* 49,
1373-1379.
