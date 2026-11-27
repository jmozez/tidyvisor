# 6. Bayesian models

A Bayesian model combines the data with prior knowledge and gives the
whole distribution of each effect: its most likely value, a credible
interval that contains it with a stated probability, and the probability
that it is positive or negative. tidyvisor advises on models fitted with
brms, which writes and runs the Stan code.

``` r

library(tidyvisor)
```

## Before fitting

``` r

tidyvisor(lme4::sleepstudy, question = "bayesian", response = "Reaction",
          predictors = "Days", random = "Subject")
#> Registered S3 method overwritten by 'parsnip':
#>   method          from 
#>   print.nullmodel vegan
#> 
#> ── tidyvisor: which analysis? ──────────────────────────────────────────────────
#> Question: bayesian
#> 
#> ── What the data show ──
#> 
#> • Observations: 180
#> • Response: continuous
#> • Parameters (excluding intercept): 1
#> • Levels of Subject: 18
#> 
#> ── Recommended ──
#> 
#> Model: Bayesian multilevel model with brms (gaussian())
#> A continuous, roughly symmetric response suits a linear model; check the
#> residuals after fitting. Weakly informative priors keep estimates in a
#> plausible range without dominating the data (Buerkner 2017).
#> priors <- c(brms::prior(normal(0, 2.5 * sd(y)), class = b)  # scale to the response)
#> m <- brms::brm(Reaction ~ Days + (1 | Subject), family = gaussian(), prior = priors,
#>   data = data, chains = 4, cores = 4, seed = 1)
#> Before fitting: Prior predictive check
#> Simulate from the priors alone to see that they allow plausible data and rule
#> out absurd data (Gabry et al. 2019).
#> p <- brms::brm(Reaction ~ Days + (1 | Subject), family = gaussian(), prior = priors, data = data, sample_prior = "only")
#> brms::pp_check(p)
#> After fitting: Check convergence, then the posterior predictive fit
#> R-hat must be below 1.01 and effective sample sizes above 400 before any
#> estimate is read (Vehtari et al. 2021).
#> summary(m); brms::pp_check(m); brms::loo(m)
#> Interpret: Plain-language explanation of the model
#> Effects with credible intervals and the probability of their direction.
#> tidyvisor(m)
```

The advice gives the family, weakly informative priors and two checks:

- a **prior predictive check**, which simulates data from the priors
  alone: plausible priors produce plausible data;
- a **posterior predictive check**, which compares data simulated from
  the fitted model with the observed data.

## After fitting

Fitting a brms model compiles a Stan program, which takes a minute or
two, so the code below is shown but not run on this page.

``` r

m <- brms::brm(Reaction ~ Days + (1 | Subject), data = lme4::sleepstudy,
               chains = 4, cores = 4, seed = 1)
tidyvisor(m)
```

The interpretation reports, for each effect, the posterior mean, its
credible interval and the probability of its direction, followed by the
diagnostics that decide whether the posterior can be trusted at all:

| Diagnostic | Should be | If not |
|----|----|----|
| R-hat | below 1.01 | the chains disagree: run longer or reparameterise |
| Effective sample size | above 400 | interval limits are imprecise: more iterations |
| Divergent transitions | none | the sampler missed part of the posterior: raise `adapt_delta` |

## How to read the advice

- **A credible interval is a probability statement about the effect**,
  given the model and priors; a confidence interval is not.
- **Priors matter most with few data.** Report them, and check that the
  conclusions hold with wider priors.
- **Diagnostics first.** Never read estimates from chains that have not
  converged.

## References

Bürkner, P.-C. (2017). brms: an R package for Bayesian multilevel models
using Stan. *Journal of Statistical Software* 80(1), 1-28.

Gabry, J., Simpson, D., Vehtari, A., Betancourt, M. and Gelman, A.
(2019). Visualization in Bayesian workflow. *Journal of the Royal
Statistical Society A* 182, 389-402.

Vehtari, A., Gelman, A., Simpson, D., Carpenter, B. and Bürkner, P.-C.
(2021). Rank-normalization, folding, and localization: an improved R-hat
for assessing convergence of MCMC. *Bayesian Analysis* 16, 667-718.
