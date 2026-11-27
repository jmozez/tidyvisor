# Check a fitted model with simulated residuals

Checks whether a fitted model describes the data well, using scaled
residuals from simulations of the fitted model (Dunn and Smyth 1996;
Hartig 2024, the method of the DHARMa package). For each observation the
observed value is placed within the values simulated from the model; if
the model is right these scaled residuals are uniform between 0 and 1,
whatever the distribution (Poisson, binomial, negative binomial, mixed
models). Four tests follow:

- uniformity (Kolmogorov-Smirnov): the overall distribution is wrong;

- dispersion: the data vary more (or less) than the model expects;

- zero inflation: more zeros than the model expects (counts only);

- outliers: more observations outside all simulated values than chance.

It works for any model with
[`stats::simulate()`](https://rdrr.io/r/stats/simulate.html) and
[`stats::fitted()`](https://rdrr.io/r/stats/fitted.values.html) methods:
[`lm()`](https://rdrr.io/r/stats/lm.html),
[`glm()`](https://rdrr.io/r/stats/glm.html),
[`MASS::glm.nb()`](https://rdrr.io/pkg/MASS/man/glm.nb.html),
[`lme4::glmer()`](https://rdrr.io/pkg/lme4/man/glmer.html) and
[`glmmTMB::glmmTMB()`](https://rdrr.io/pkg/glmmTMB/man/glmmTMB.html).

## Usage

``` r
tv_check_model(model, nsim = 250, seed = NULL)
```

## Arguments

- model:

  A fitted model.

- nsim:

  Number of simulations (250 is usually enough).

- seed:

  Optional random seed, set with
  [`set.seed()`](https://rdrr.io/r/base/Random.html) before simulating,
  for reproducible residuals.

## Value

A `tv_advice` object (question `"model check"`) with `checks` (each
test, its p-value and what it means) and `advice`, plus `residuals`, a
tibble with `observed`, `fitted` and `scaled` (the scaled residuals),
for plots such as a uniform QQ plot.

## References

Dunn, P. K. and Smyth, G. K. (1996). Randomized quantile residuals.
Journal of Computational and Graphical Statistics, 5, 236-244.
[doi:10.1080/10618600.1996.10474708](https://doi.org/10.1080/10618600.1996.10474708)

Hartig, F. (2024). DHARMa: residual diagnostics for hierarchical
(multi-level / mixed) regression models. R package.
<https://CRAN.R-project.org/package=DHARMa>

## Examples

``` r
# Counts with extra variation: Poisson is overdispersed
fit <- glm(count ~ spray, family = poisson, data = InsectSprays)
tv_check_model(fit, seed = 1)
#> 
#> ── tidyvisor: does the model fit? ──────────────────────────────────────────────
#> Question: model check
#> 
#> ── What the data show ──
#> 
#> • Simulations: 250 from the fitted model, 72 observations
#> • Uniformity (KS test): p = 0.756 — no sign that the distribution is wrong
#> • Dispersion: ratio 1.51, p = 0.028 — overdispersed: more variation than the
#>   model allows
#> • Zero inflation: observed/expected zeros 1.03, p = 1.000
#> • Outliers: 1 outside all simulated values, p = 0.438
#> 
#> ── Recommended ──
#> 
#> Overdispersion: Use a distribution with extra variance
#> Standard errors and p-values from an overdispersed model are too small. For
#> counts use a negative binomial (MASS::glm.nb() or glmmTMB(family = nbinom2));
#> for proportions a beta-binomial or an observation-level random effect.
#> m2 <- MASS::glm.nb(formula(model), data = model.frame(model))
#> Plot: Show the residual checks in the supplement
#> A uniform QQ plot of the scaled residuals and a plot of them against the fitted
#> values make the checks visible to reviewers.
#> chk <- tv_check_model(model, seed = 1)
#> ggplot2::ggplot(chk$residuals, ggplot2::aes(sample = scaled)) +
#>   ggplot2::stat_qq(distribution = stats::qunif) + ggplot2::geom_abline()
```
