# Advisor for brms: Bayesian regression and mixed models

Built-in advisor for
[`brms::brm()`](https://paulbuerkner.com/brms/reference/brm.html).

- **Before** (`question = "bayesian"`): chooses the family from the kind
  of response (including `trials()` for successes out of trials, and
  zero-inflated families for counts with excess zeros), adds random
  intercepts for the grouping columns in `random`, and gives the code
  with weakly informative priors, a prior predictive check and a
  posterior predictive check.

- **After**: explains each population-level effect on its natural scale
  with its credible interval and the posterior probability of its
  direction; the standard deviation of each group-level effect; and the
  sampling diagnostics (R-hat, effective sample sizes, divergent
  transitions) that decide whether the posterior can be trusted at all.

## Usage

``` r
tv_advise_brms(
  x,
  question = "bayesian",
  response,
  predictors = NULL,
  random = NULL,
  trials = NULL,
  ...
)

tv_interpret_brms(x, level = 0.95, ...)
```

## Arguments

- x:

  A data frame (advice) or a `brmsfit` (interpretation).

- question:

  The question; set by
  [`advise()`](https://tidyvisor.in4metrix.dev/reference/advise.md).

- response, predictors, random, trials:

  As for
  [`tv_advise_mixed()`](https://tidyvisor.in4metrix.dev/reference/model-advisors.md);
  `random` is optional.

- ...:

  Ignored.

- level:

  Width of the credible intervals.

## Value

A `tv_advice` or a `tv_interpretation` object.

## References

Bürkner, P.-C. (2017). brms: an R package for Bayesian multilevel models
using Stan. *Journal of Statistical Software* 80(1), 1-28.

Gabry, J. et al. (2019). Visualization in Bayesian workflow. *Journal of
the Royal Statistical Society A* 182, 389-402.

Vehtari, A. et al. (2021). Rank-normalization, folding, and
localization: an improved R-hat for assessing convergence of MCMC.
*Bayesian Analysis* 16, 667-718.

## Examples

``` r
tidyvisor(mtcars, question = "bayesian", response = "am", predictors = "wt")
#> 
#> ── tidyvisor: which analysis? ──────────────────────────────────────────────────
#> Question: bayesian
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
#> Model: Bayesian regression model with brms (bernoulli())
#> A yes/no response is binomial; the logit link gives effects as odds ratios.
#> Weakly informative priors keep estimates in a plausible range without
#> dominating the data (Buerkner 2017).
#> priors <- c(brms::prior(normal(0, 1), class = b))
#> m <- brms::brm(am ~ wt, family = bernoulli(), prior = priors,
#>   data = data, chains = 4, cores = 4, seed = 1)
#> Before fitting: Prior predictive check
#> Simulate from the priors alone to see that they allow plausible data and rule
#> out absurd data (Gabry et al. 2019).
#> p <- brms::brm(am ~ wt, family = bernoulli(), prior = priors, data = data, sample_prior = "only")
#> brms::pp_check(p)
#> After fitting: Check convergence, then the posterior predictive fit
#> R-hat must be below 1.01 and effective sample sizes above 400 before any
#> estimate is read (Vehtari et al. 2021).
#> summary(m); brms::pp_check(m); brms::loo(m)
#> Interpret: Plain-language explanation of the model
#> Effects with credible intervals and the probability of their direction.
#> tidyvisor(m)
```
