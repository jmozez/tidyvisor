# Advisors for mixed, additive and overdispersed models

Built-in advisors for four widely used modelling packages. Each gives
advice before fitting (from a data frame) and a plain-language
interpretation after it (from the fitted model).

- **lme4** (`question = "mixed"`, or a `random` argument): linear and
  generalised linear mixed models,
  [`lme4::lmer()`](https://rdrr.io/pkg/lme4/man/lmer.html),
  [`lme4::glmer()`](https://rdrr.io/pkg/lme4/man/glmer.html) and
  [`lme4::glmer.nb()`](https://rdrr.io/pkg/lme4/man/glmer.nb.html). The
  advice checks the grouping factors (number of levels, observations per
  level) and chooses the family. The interpretation reports fixed
  effects on their natural scale, the variance of each random effect,
  the intra-class correlation, and singular or non-converged fits.

- **glmmTMB** (`question = "zero_inflation"`): mixed models for
  overdispersed and zero-inflated counts with
  [`glmmTMB::glmmTMB()`](https://rdrr.io/pkg/glmmTMB/man/glmmTMB.html);
  the interpretation adds the zero-inflation part and the dispersion.

- **mgcv** (`question = "smooth"`, or a `smooth` argument): generalised
  additive models with
  [`mgcv::gam()`](https://rdrr.io/pkg/mgcv/man/gam.html). The
  interpretation explains each smooth by its effective degrees of
  freedom, checks the basis dimension (`k`) and concurvity.

- **aods3** (`question = "overdispersion"`): beta-binomial and negative
  binomial models with
  [`aods3::aodml()`](https://rdrr.io/pkg/aods3/man/aodml.html) for
  proportions and counts more variable than the binomial or Poisson
  allows.

## Usage

``` r
tv_advise_mixed(
  x,
  question = "mixed",
  response,
  predictors = NULL,
  random,
  trials = NULL,
  engine = c("lme4", "glmmTMB"),
  ...
)

tv_advise_gam(
  x,
  question = "smooth",
  response,
  predictors = NULL,
  smooth = NULL,
  random = NULL,
  trials = NULL,
  ...
)

tv_advise_aod(
  x,
  question = "overdispersion",
  response,
  predictors = NULL,
  trials = NULL,
  ...
)

tv_interpret_mixed(x, level = 0.95, ...)

tv_interpret_gam(x, level = 0.95, ...)

tv_interpret_aod(x, level = 0.95, ...)
```

## Arguments

- x:

  A data frame (advice) or a fitted model (interpretation).

- question:

  The question; set by
  [`advise()`](https://tidyvisor.in4metrix.dev/reference/advise.md).

- response:

  Name of the response column.

- predictors:

  Names of the fixed-effect predictor columns (default: all other
  columns except `random`, `smooth` and `trials`).

- random:

  Names of the grouping columns for random intercepts.

- trials:

  Name of the column with the number of trials, for successes out of
  trials.

- engine:

  Package to fit the mixed model with, `"lme4"` or `"glmmTMB"`.

- ...:

  Ignored.

- smooth:

  Names of the numeric predictors to model with smooths.

- level:

  Confidence level for the intervals.

## Value

A `tv_advice` or a `tv_interpretation` object.

## References

Bolker, B.M. et al. (2009). Generalized linear mixed models: a practical
guide for ecology and evolution. *Trends in Ecology & Evolution* 24,
127-135.

Brooks, M.E. et al. (2017). glmmTMB balances speed and flexibility among
packages for zero-inflated generalized linear mixed modeling. *The R
Journal* 9, 378-400.

Harrison, X.A. et al. (2018). A brief introduction to mixed effects
modelling and multi-model inference in ecology. *PeerJ* 6, e4794.

Nakagawa, S. & Schielzeth, H. (2013). A general and simple method for
obtaining R2 from generalized linear mixed-effects models. *Methods in
Ecology and Evolution* 4, 133-142.

Wood, S.N. (2017). *Generalized Additive Models: An Introduction with
R*, 2nd ed. Chapman & Hall/CRC.

Lesnoff, M. & Lancelot, R. (2012). aods3: analysis of overdispersed data
using S3 methods. R package.

## Examples

``` r
tidyvisor(lme4::sleepstudy, response = "Reaction", predictors = "Days",
  random = "Subject")
#> 
#> ── tidyvisor: which analysis? ──────────────────────────────────────────────────
#> Question: mixed
#> 
#> ── What the data show ──
#> 
#> • Observations: 180
#> • Response: continuous
#> • Parameters (excluding intercept): 1
#> • Levels of Subject: 18 (observations per level: 10 to 10, median 10)
#> 
#> ── Recommended ──
#> 
#> Model: Linear mixed model (lme4::lmer)
#> Observations in the same group are not independent; random intercepts for
#> Subject account for it and let the results generalise to other groups (Bolker
#> et al. 2009).
#> m <- lme4::lmer(Reaction ~ Days + (1 | Subject), data = data)
#> Random slopes: Consider a random slope for a predictor that varies within
#> groups
#> If the effect of a predictor differs among groups, a random intercept alone
#> makes its p-value too small.
#> (1 + Days | Subject)
#> Before fitting: Plot the response against each predictor
#> Shows non-linear relations, outliers and interactions that the model would miss
#> (Zuur et al. 2010).
#> plot(data[c("Reaction", "Days")])
#> After fitting: Check the residuals
#> Residual plots show non-linearity, unequal variance and influential points;
#> tidyvisor reports the tests.
#> plot(m)   # or performance::check_model(m)
#> Interpret: Plain-language explanation of the model
#> Fixed effects on the scale of the response, random-effect variances and
#> diagnostics.
#> tidyvisor(m)
m <- lme4::lmer(Reaction ~ Days + (1 | Subject), data = lme4::sleepstudy)
tidyvisor(m)
#> 
#> ── tidyvisor: what the results show ────────────────────────────────────────────
#> 
#> ── Overview ──
#> 
#> • Linear mixed model of Reaction on 180 observations in 18 levels of Subject
#>   (gaussian family, identity link), fitted with lme4.
#> 
#> ── Random effects ──
#> 
#> • Subject: (Intercept) varies with a standard deviation of 37.1 (in units of
#>   Reaction).
#> • Residual standard deviation 31.0. Intra-class correlation 0.59: 59% of the
#>   variance left after the fixed effects lies between groups.
#> 
#> ── Effects ──
#> 
#> • Days: each one-unit increase in Days changes Reaction by 10.5 (95% CI 8.89 to
#>   12.0), p < 0.001.
#> • lmer() gives no p-values; those shown use the normal approximation (Wald z),
#>   which is optimistic with few groups. For small samples, use lmerTest or a
#>   parametric bootstrap.
#> • Fixed effects are for a typical group (random effects at zero), with the
#>   other predictors held fixed.
#> 
#> ── Diagnostics ──
#> 
#> • Normality of residuals (Shapiro-Wilk): W = 0.975, p = 0.003; inspect the Q-Q
#>   plot; mixed models are fairly robust to mild departures.
#> 
#> ── For the paper ──
#> 
#> • Results (strongest evidence first; each factor level is compared with the
#>   reference level):
#> • 'Reaction changed by 10.5 per unit increase in Days (95% CI 8.89 to 12, p <
#>   0.001).'
#> • Report every term of the model, not only the significant ones, with the
#>   estimate, its 95% CI and the p-value; give n, and the fit (R-squared, or
#>   deviance explained, or the random-effect SDs for a mixed model).
#> • Figure: model predictions with their confidence band over the raw data, one
#>   panel per focal predictor:
#> • ggeffects::ggpredict(m, terms = "Days") |> plot(show_data = TRUE)
#> • ggplot2::ggsave("figure1.pdf", width = 85, height = 70, units = "mm") # one
#>   journal column
#> • Figure style for journals: show the raw data with the estimates, give n per
#>   group in the caption, label axes with units, use a colour-blind-safe palette
#>   (Okabe-Ito, viridis) and no 3D, pie or dual-axis charts; text at least 8 pt
#>   at final size; save as PDF or SVG (vector) at the journal's column width
#>   (about 85 mm single, 180 mm double), or 600 dpi for raster images.
#> • Table: one row per term with the estimate, 95% CI and p-value (and the
#>   random-effect SDs for a mixed model):
#> • gtsummary::tbl_regression(m) # or broom.mixed::tidy(m, conf.int = TRUE) for
#>   your own table
#> • Methods: the model formula, the family and link, how the model was checked,
#>   the software and packages with versions (R 4.6.2; citation("lme4")), and how
#>   the predictors were chosen (before seeing the data, or how).
#> 
#> ── Reading the plots ──
#> 
#> • Plot residuals against fitted values (look for curves or a funnel) and a Q-Q
#>   plot of the random effects (lattice::qqmath(lme4::ranef(m))).
#> • For generalised models, simulated residuals (DHARMa::simulateResiduals(m))
#>   are easier to read than raw residuals.
```
