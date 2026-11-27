# 5. Mixed, additive and overdispersed models

Ecological and field data are rarely independent and rarely straight.
Measurements come in groups (plots in sites, repeated visits to the same
animal), relations curve, and counts vary more than a Poisson model
allows. tidyvisor advises on the four packages most used for these
problems.

``` r

library(tidyvisor)
```

## Grouped data: mixed models (lme4)

`sleepstudy` records the reaction time of 18 people over 10 days of
sleep deprivation. Each person is measured ten times, so the person is a
grouping factor: a random effect.

``` r

tidyvisor(lme4::sleepstudy, response = "Reaction", predictors = "Days",
          random = "Subject")
#> Registered S3 method overwritten by 'parsnip':
#>   method          from 
#>   print.nullmodel vegan
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
```

``` r

m <- lme4::lmer(Reaction ~ Days + (Days | Subject), data = lme4::sleepstudy)
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
#> • Subject: (Intercept) varies with a standard deviation of 24.7 (in units of
#>   Reaction).
#> • Subject: Days varies with a standard deviation of 5.92 (in units of
#>   Reaction).
#> • Residual standard deviation 25.6. Intra-class correlation 0.48: 48% of the
#>   variance left after the fixed effects lies between groups.
#> 
#> ── Effects ──
#> 
#> • Days: each one-unit increase in Days changes Reaction by 10.5 (95% CI 7.44 to
#>   13.5), p < 0.001.
#> • lmer() gives no p-values; those shown use the normal approximation (Wald z),
#>   which is optimistic with few groups. For small samples, use lmerTest or a
#>   parametric bootstrap.
#> • Fixed effects are for a typical group (random effects at zero), with the
#>   other predictors held fixed.
#> 
#> ── Diagnostics ──
#> 
#> • Normality of residuals (Shapiro-Wilk): W = 0.901, p < 0.001; inspect the Q-Q
#>   plot; mixed models are fairly robust to mild departures.
#> 
#> ── For the paper ──
#> 
#> • Results (strongest evidence first; each factor level is compared with the
#>   reference level):
#> • 'Reaction changed by 10.5 per unit increase in Days (95% CI 7.44 to 13.5, p <
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

The intra-class correlation says how much of the variation lies between
people rather than within them. A singular fit (a variance estimated as
zero) means the random-effect structure is too complex for the data.

## Curved relations: additive models (mgcv)

`airquality` relates ozone concentration in New York to temperature,
wind and solar radiation. Ozone does not rise in a straight line with
temperature; a generalised additive model lets the data show the shape.

``` r

aq <- na.omit(airquality)
tidyvisor(aq, response = "Ozone", predictors = c("Temp", "Wind", "Solar.R"),
          smooth = c("Temp", "Wind"))
#> 
#> ── tidyvisor: which analysis? ──────────────────────────────────────────────────
#> Question: smooth
#> 
#> ── What the data show ──
#> 
#> • Observations: 111
#> • Response: counts (non-negative integers)
#> • Variance / mean: 26.3 — above 1: overdispersed; a negative binomial model is
#>   safer than Poisson
#> • Zeros: 0% observed, 0% expected under Poisson
#> • Parameters (excluding intercept): 3
#> • Collinear predictor pairs (|r| > 0.7): none
#> • Unique values of Temp: 39
#> • Unique values of Wind: 29
#> 
#> ── Recommended ──
#> 
#> Model: Generalised additive model (mgcv, mgcv::nb())
#> Smooth functions let the data show the shape of each relation instead of
#> assuming a straight line; REML estimates the smoothness (Wood 2017).
#> m <- mgcv::gam(Ozone ~ s(Temp) + s(Wind) + Solar.R, family = mgcv::nb(), method = "REML", data = data)
#> Before fitting: Plot the response against each predictor
#> Shows non-linear relations, outliers and interactions that the model would miss
#> (Zuur et al. 2010).
#> plot(data[c("Ozone", "Temp", "Wind", "Solar.R")])
#> After fitting: Check the basis dimension and the residuals
#> A k-index well below 1 with a small p-value means a smooth needs a larger k.
#> mgcv::gam.check(m)
#> Interpret: Plain-language explanation of the model
#> Each smooth by its shape and significance, the parametric effects and
#> diagnostics.
#> tidyvisor(m); plot(m, pages = 1)
```

``` r

g <- mgcv::gam(Ozone ~ s(Temp) + s(Wind) + Solar.R, data = aq,
               family = Gamma(link = "log"), method = "REML")
tidyvisor(g)
#> 
#> ── tidyvisor: what the results show ────────────────────────────────────────────
#> 
#> ── Overview ──
#> 
#> • Generalised additive model of Ozone on 111 observations (Gamma family, log
#>   link), smoothness by REML.
#> 
#> ── Fit ──
#> 
#> • The model explains 68.9% of the deviance (adjusted R-squared 0.66).
#> 
#> ── Smooths ──
#> 
#> • s(Temp): effective degrees of freedom 3.05 (clearly non-linear), p < 0.001.
#> • s(Wind): effective degrees of freedom 2.44 (gently curved), p < 0.001.
#> • The edf measures wiggliness: 1 is a straight line, larger values more complex
#>   curves. Read the shape from plot(m), not from a coefficient.
#> 
#> ── Parametric effects ──
#> 
#> • Solar.R: each one-unit increase in Solar.R multiplies the expected Ozone by
#>   1.00 (+0%; 95% CI 1.00 to 1.00), p < 0.001.
#> • Effects on the log or logit scale are multiplicative: they combine by
#>   multiplying, and a factor of 1 means no effect.
#> 
#> ── Diagnostics ──
#> 
#> • Basis dimension: k may be too small for s(Wind) (k-index below 1, small
#>   p-value); refit with a larger k and see whether the edf rises.
#> 
#> ── Reading the plots ──
#> 
#> • plot(m, pages = 1, shade = TRUE) draws each smooth with its confidence band
#>   on the link scale; where the band includes zero across the range, the effect
#>   is weak.
#> • mgcv::gam.check(m) draws residual plots and reports the basis checks.
```

An effective degrees of freedom near 1 means a smooth is nearly a
straight line; larger values mean more curvature. The basis check warns
when `k` is too small to capture the shape.

## Overdispersed and zero-inflated counts (glmmTMB)

When counts have more zeros than a Poisson or negative binomial model
predicts, some zeros may be structural (the species cannot occur there)
rather than chance. glmmTMB fits zero-inflated models with random
effects.

``` r

tidyvisor(glmmTMB::Salamanders, question = "zero_inflation",
          response = "count", predictors = c("mined", "spp"), random = "site")
#> 
#> ── tidyvisor: which analysis? ──────────────────────────────────────────────────
#> Question: zero_inflation
#> 
#> ── What the data show ──
#> 
#> • Observations: 644
#> • Response: counts (non-negative integers)
#> • Variance / mean: 5.3 — above 1: overdispersed; a negative binomial model is
#>   safer than Poisson
#> • Zeros: 60% observed, 27% expected under Poisson — more zeros than expected:
#>   check a zero-inflated or hurdle model after fitting
#> • Parameters (excluding intercept): 7
#> • Levels of site: 23 (observations per level: 28 to 28, median 28)
#> 
#> ── Recommended ──
#> 
#> Model: Generalised linear mixed model (glmmTMB, nbinom2, zero-inflated)
#> Observations in the same group are not independent; random intercepts for site
#> account for it. The data have more zeros than a count distribution predicts, so
#> a zero-inflation part is added (Brooks et al. 2017). The counts are
#> overdispersed, so the negative binomial (nbinom2) is used.
#> m <- glmmTMB::glmmTMB(count ~ mined + spp + (1 | site), ziformula = ~1, family = nbinom2, data = data)
#> Random slopes: Consider a random slope for a predictor that varies within
#> groups
#> If the effect of a predictor differs among groups, a random intercept alone
#> makes its p-value too small.
#> (1 + mined | site)
#> Before fitting: Plot the response against each predictor
#> Shows non-linear relations, outliers and interactions that the model would miss
#> (Zuur et al. 2010).
#> plot(data[c("count", "mined", "spp")])
#> After fitting: Check the residuals
#> Residual plots show non-linearity, unequal variance and influential points;
#> tidyvisor reports the tests.
#> plot(m)   # or performance::check_model(m)
#> Interpret: Plain-language explanation of the model
#> Fixed effects on the scale of the response, random-effect variances and
#> diagnostics.
#> tidyvisor(m)
```

``` r

z <- glmmTMB::glmmTMB(count ~ mined + (1 | site), ziformula = ~ mined,
                      family = glmmTMB::nbinom2, data = glmmTMB::Salamanders)
tidyvisor(z)
#> 
#> ── tidyvisor: what the results show ────────────────────────────────────────────
#> 
#> ── Overview ──
#> 
#> • Generalised linear mixed model of count on 644 observations in 23 levels of
#>   site (nbinom2 family, log link), fitted with glmmTMB.
#> 
#> ── Random effects ──
#> 
#> • site: (Intercept) varies with a standard deviation of 0.366 on the log scale.
#> 
#> ── Effects ──
#> 
#> • minedno: mined = no (compared with mined = yes) multiplies the expected count
#>   by 4.34 (+334%; 95% CI 2.14 to 8.81), p < 0.001.
#> • Effects on the log or logit scale are multiplicative: they combine by
#>   multiplying, and a factor of 1 means no effect.
#> • Fixed effects are for a typical group (random effects at zero), with the
#>   other predictors held fixed.
#> 
#> ── Diagnostics ──
#> 
#> • Zero-inflation: for a typical observation, the probability of an extra
#>   (structural) zero is 56%.
#> 
#> ── For the paper ──
#> 
#> • Results (strongest evidence first; each factor level is compared with the
#>   reference level):
#> • 'count was 4.34 times as high for mined = no as for mined = yes (95% CI 2.14
#>   to 8.81, p < 0.001).'
#> • The model is on the log scale, so effects are reported as ratios of means
#>   (exponentiated coefficients) with their intervals.
#> • Report every term of the model, not only the significant ones, with the
#>   estimate, its 95% CI and the p-value; give n, and the fit (R-squared, or
#>   deviance explained, or the random-effect SDs for a mixed model).
#> • Figure: model predictions with their confidence band over the raw data, one
#>   panel per focal predictor:
#> • ggeffects::ggpredict(m, terms = "mined") |> plot(show_data = TRUE)
#> • ggplot2::ggsave("figure1.pdf", width = 85, height = 70, units = "mm") # one
#>   journal column
#> • Figure style for journals: show the raw data with the estimates, give n per
#>   group in the caption, label axes with units, use a colour-blind-safe palette
#>   (Okabe-Ito, viridis) and no 3D, pie or dual-axis charts; text at least 8 pt
#>   at final size; save as PDF or SVG (vector) at the journal's column width
#>   (about 85 mm single, 180 mm double), or 600 dpi for raster images.
#> • Table: one row per term with the estimate, 95% CI and p-value (and the
#>   random-effect SDs for a mixed model):
#> • gtsummary::tbl_regression(m, exponentiate = TRUE) # or broom.mixed::tidy(m,
#>   conf.int = TRUE, exponentiate = TRUE) for your own table
#> • Methods: the model formula, the family and link, how the model was checked,
#>   the software and packages with versions (R 4.6.2; citation("glmmTMB")), and
#>   how the predictors were chosen (before seeing the data, or how).
#> 
#> ── Reading the plots ──
#> 
#> • Plot residuals against fitted values (look for curves or a funnel) and a Q-Q
#>   plot of the random effects (lattice::qqmath(lme4::ranef(m))).
#> • For generalised models, simulated residuals (DHARMa::simulateResiduals(m))
#>   are easier to read than raw residuals.
```

## Overdispersed proportions (aods3)

Proportions out of a known number of trials (germinated seeds out of
seeds sown, infected hosts out of hosts examined) are often more
variable than the binomial allows. The beta-binomial model of aods3
estimates the extra variation.

``` r

data(orob2, package = "aods3")
tidyvisor(orob2, question = "overdispersion", response = "m",
          predictors = c("seed", "root"), trials = "n")
#> 
#> ── tidyvisor: which analysis? ──────────────────────────────────────────────────
#> Question: overdispersion
#> 
#> ── What the data show ──
#> 
#> • Observations: 21
#> • Response: successes out of a number of trials
#> • Parameters (excluding intercept): 2
#> • Binomial dispersion (Pearson / df): 2.13 — above 1: the proportions vary more
#>   than the binomial allows
#> 
#> ── Recommended ──
#> 
#> Model: Beta-binomial model (aods3::aodml, family = "bb")
#> When proportions vary more among units than the binomial predicts, the
#> beta-binomial estimates the extra variation (phi) and gives honest standard
#> errors.
#> m <- aods3::aodml(cbind(m, n - m) ~ seed + root, family = "bb", data = data)
#> Before fitting: Plot the response against each predictor
#> Shows non-linear relations, outliers and interactions that the model would miss
#> (Zuur et al. 2010).
#> plot(data[c("m", "seed", "root")])
#> Interpret: Plain-language explanation of the model
#> Effects on the odds or rate scale and the size of the overdispersion.
#> tidyvisor(m)
```

## How to read the advice

- **Random or fixed?** A grouping factor is a random effect when its
  levels are a sample from a larger population (sites, people, years)
  and there are at least five or six of them; with fewer, estimate it as
  a fixed effect.
- **The unit of replication.** A treatment applied to whole sites is
  tested against the variation between sites, not between plots within
  sites. Random effects make that explicit.
- **Overdispersion is not a nuisance.** It usually signals an unmeasured
  variable or clustering. Model it, then ask what causes it.

## References

Bates, D., Mächler, M., Bolker, B. and Walker, S. (2015). Fitting linear
mixed-effects models using lme4. *Journal of Statistical Software*
67(1), 1-48.

Brooks, M. E. et al. (2017). glmmTMB balances speed and flexibility
among packages for zero-inflated generalized linear mixed modeling. *The
R Journal* 9, 378-400.

Wood, S. N. (2017). *Generalized Additive Models: An Introduction with
R*, second edition. Chapman and Hall/CRC.
