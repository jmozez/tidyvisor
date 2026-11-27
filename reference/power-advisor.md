# Power analysis: how many samples, sites or groups to collect

Advice before fieldwork: how large a study must be to detect the effect
that matters, with a given power (the chance of detecting the effect if
it is real) and significance level.

Give the design and the smallest effect worth detecting, from biology,
earlier studies or a pilot:

|  |  |  |
|----|----|----|
| `design` | Effect to give | Answer |
| `"two_groups"` | `delta` (difference in means), `sd` | samples per group (t-test) |
| `"paired"` | `delta`, `sd` of the within-pair differences | pairs |
| `"groups"` | `means` (expected group means), `sd` | samples per group (one-way ANOVA) |
| `"proportions"` | `p1`, `p2` | samples per group |
| `"counts"` | `mean1` and `ratio` (rate ratio), `theta` (negative binomial size; `Inf` for Poisson) | samples per group |
| `"regression"` | `r2` (partial R squared of the predictor(s) tested), `predictors` | observations |
| `"correlation"` | `r` | observations |
| `"sites"` | `delta`, `sd`, `icc`, `per_site` | sites per group, with samples nested in sites |

Each answer comes with a sensitivity table (the size needed for half and
twice the effect, and for 90% power) because the effect is never known
exactly, and with the code that reproduces the calculation.

With pilot data,
`advise(pilot, question = "power", response = ..., group = ...)`
estimates the standard deviation (and the intra-class correlation when
`site` is given) from the pilot and asks only for the effect. Use the
smallest effect of biological interest, not the pilot's observed
difference: pilot effects are noisy, and powering a study on an
overestimate leaves it too small.

## Usage

``` r
tv_power(
  design = c("two_groups", "paired", "groups", "proportions", "counts", "regression",
    "correlation", "sites"),
  delta = NULL,
  sd = NULL,
  means = NULL,
  p1 = NULL,
  p2 = NULL,
  mean1 = NULL,
  ratio = NULL,
  theta = Inf,
  r2 = NULL,
  predictors = 1,
  r = NULL,
  icc = NULL,
  per_site = NULL,
  power = 0.8,
  alpha = 0.05
)

tv_advise_power(
  x,
  question = "power",
  response,
  group = NULL,
  site = NULL,
  ...
)
```

## Arguments

- design:

  The design (see the table).

- delta, sd:

  Difference in means worth detecting, and the standard deviation within
  groups (in the same units).

- means:

  Expected means of three or more groups.

- p1, p2:

  Expected proportions in two groups.

- mean1, ratio, theta:

  Expected mean count in the reference group, rate ratio worth
  detecting, and negative binomial size (dispersion; smaller is more
  overdispersed; `Inf` for Poisson).

- r2, predictors:

  Partial R squared of the tested predictor(s) and the total number of
  predictors.

- r:

  Correlation worth detecting.

- icc, per_site:

  Intra-class correlation (share of the variance between sites) and the
  number of samples per site.

- power:

  Target power (default 0.8).

- alpha:

  Significance level (default 0.05).

- x:

  Pilot data (a data frame).

- question:

  Set by
  [`advise()`](https://tidyvisor.in4metrix.dev/reference/advise.md).

- response, group, site:

  Columns of the pilot data.

- ...:

  Passed to `tv_power()` (the effect: `delta`, `ratio`, ...).

## Value

A `tv_advice` object: `checks` (inputs and sensitivity) and `advice`
(the size needed and how to collect it), and `n`, the required size.

## References

Cohen, J. (1988). *Statistical Power Analysis for the Behavioral
Sciences*, second edition. Lawrence Erlbaum.

Green, P. and MacLeod, C. J. (2016). SIMR: an R package for power
analysis of generalized linear mixed models by simulation. *Methods in
Ecology and Evolution* 7, 493-498.

Johnson, P. C. D., Barry, S. J. E., Ferguson, H. M. and Mueller, P.
(2015). Power analysis for generalized linear mixed models in ecology
and evolution. *Methods in Ecology and Evolution* 6, 133-142.

Zhu, H. and Lakkis, H. (2014). Sample size calculation for comparing two
negative binomial rates. *Statistics in Medicine* 33, 376-387.

## Examples

``` r
# Detect a 5 cm difference in tree height (SD 8 cm) between two habitats
tv_power("two_groups", delta = 5, sd = 8)
#> 
#> ── tidyvisor: how many samples? ────────────────────────────────────────────────
#> Question: power
#> 
#> ── What the data show ──
#> 
#> • Design: two_groups
#> • Effect to detect: difference 5.00 with SD 8.00 (Cohen's d = 0.62)
#> • Power, significance level: 80%, 0.05
#> • Needed: 42 samples per group (84 in total)
#> • If the effect is half as large: 162 samples per group
#> • If it is twice as large: 12 samples per group
#> • For 90% power: 55 samples per group
#> 
#> ── Recommended ──
#> 
#> Sample size: Collect at least 42 samples per group (84 in total)
#> Gives an 80% chance of detecting difference 5.00 with SD 8.00 (Cohen's d =
#> 0.62) at the 0.05 level; with fewer, a real effect of that size will often be
#> missed and a non-significant result will say little.
#> power.t.test(delta = 5, sd = 8, power = 0.8, sig.level = 0.05)
#> Before the field: Add a margin for losses
#> Traps fail, plots flood and samples are lost: collect 10-20% more than the
#> minimum. Randomise which units get each treatment, and record the site and date
#> of every sample.
#> Check: The effect size drives everything
#> Halving the effect roughly quadruples the sample size (see the checks). Use the
#> smallest effect that would matter biologically, from the literature or a pilot,
#> and report the power analysis with the study.

# Beetle counts: mean 4 per trap, detect a 1.5-fold difference
tv_power("counts", mean1 = 4, ratio = 1.5, theta = 2)
#> 
#> ── tidyvisor: how many samples? ────────────────────────────────────────────────
#> Question: power
#> 
#> ── What the data show ──
#> 
#> • Design: counts
#> • Effect to detect: mean 4.00 against 6.00 (rate ratio 1.50), negative binomial
#>   size 2.00
#> • Power, significance level: 80%, 0.05
#> • Needed: 68 samples per group (136 in total)
#> • If the effect is half as large: 278 samples per group
#> • If it is twice as large: 17 samples per group
#> • For 90% power: 91 samples per group
#> 
#> ── Recommended ──
#> 
#> Sample size: Collect at least 68 samples per group (136 in total)
#> Gives an 80% chance of detecting mean 4.00 against 6.00 (rate ratio 1.50),
#> negative binomial size 2.00 at the 0.05 level; with fewer, a real effect of
#> that size will often be missed and a non-significant result will say little.
#> # check by simulation: power for n per group
#> sim <- function(n) {
#>   g <- gl(2, n)
#>   y <- MASS::rnegbin(2 * n, mu = 4 * c(1, 1.5)[g], theta = 2)
#>   summary(MASS::glm.nb(y ~ g))$coefficients[2, 4] < 0.05
#> }
#> mean(replicate(500, sim(68)))
#> Analysis: Negative binomial GLM
#> The calculation assumes the counts will be analysed with a count GLM;
#> overdispersion (small size) raises the sample size needed, so estimate it from
#> a pilot.
#> Before the field: Add a margin for losses
#> Traps fail, plots flood and samples are lost: collect 10-20% more than the
#> minimum. Randomise which units get each treatment, and record the site and date
#> of every sample.
#> Check: The effect size drives everything
#> Halving the effect roughly quadruples the sample size (see the checks). Use the
#> smallest effect that would matter biologically, from the literature or a pilot,
#> and report the power analysis with the study.

# Plots nested in sites: how many sites per treatment?
tv_power("sites", delta = 5, sd = 8, icc = 0.2, per_site = 5)
#> 
#> ── tidyvisor: how many samples? ────────────────────────────────────────────────
#> Question: power
#> 
#> ── What the data show ──
#> 
#> • Design: sites
#> • Effect to detect: difference 5.00 with SD 8.00, intra-class correlation
#>   0.200, 5 samples per site
#> • Power, significance level: 80%, 0.05
#> • Needed: 15 sites per group (150 in total)
#> • If the effect is half as large: 59 sites per group
#> • If it is twice as large: 4 sites per group
#> • For 90% power: 20 sites per group
#> 
#> ── Recommended ──
#> 
#> Sample size: Collect at least 15 sites per group (150 in total)
#> Gives an 80% chance of detecting difference 5.00 with SD 8.00, intra-class
#> correlation 0.200, 5 samples per site at the 0.05 level; with fewer, a real
#> effect of that size will often be missed and a non-significant result will say
#> little.
#> # with pilot data, simulate the mixed model directly:
#> # m <- lme4::lmer(y ~ treatment + (1 | site), data = pilot)
#> # simr::powerCurve(simr::extend(m, along = "site", n = 40), along = "site")
#> Design: Prefer more sites to more samples per site
#> Samples within a site are correlated (ICC 0.200), so each extra sample per site
#> adds less. Sites per group needed for 1, 2, 5, 10 and 20 samples per site: 42,
#> 25, 15, 12, 10. Beyond a few samples per site, only more sites help.
#> Before the field: Add a margin for losses
#> Traps fail, plots flood and samples are lost: collect 10-20% more than the
#> minimum. Randomise which units get each treatment, and record the site and date
#> of every sample.
#> Check: The effect size drives everything
#> Halving the effect roughly quadruples the sample size (see the checks). Use the
#> smallest effect that would matter biologically, from the literature or a pilot,
#> and report the power analysis with the study.

# From a pilot: the SD comes from the data, the effect from biology
advise(PlantGrowth, question = "power", response = "weight",
       group = "group", delta = 0.5)
#> 
#> ── tidyvisor: how many samples? ────────────────────────────────────────────────
#> Question: power
#> 
#> ── What the data show ──
#> 
#> • From the pilot: 30 observations of weight — within-group SD 0.623
#> • Design: two_groups
#> • Effect to detect: difference 0.500 with SD 0.623 (Cohen's d = 0.80)
#> • Power, significance level: 80%, 0.05
#> • Needed: 26 samples per group (52 in total)
#> • If the effect is half as large: 99 samples per group
#> • If it is twice as large: 8 samples per group
#> • For 90% power: 34 samples per group
#> 
#> ── Recommended ──
#> 
#> Sample size: Collect at least 26 samples per group (52 in total)
#> Gives an 80% chance of detecting difference 0.500 with SD 0.623 (Cohen's d =
#> 0.80) at the 0.05 level; with fewer, a real effect of that size will often be
#> missed and a non-significant result will say little.
#> power.t.test(delta = 0.5, sd = 0.623374627271536, power = 0.8, sig.level = 0.05)
#> Before the field: Add a margin for losses
#> Traps fail, plots flood and samples are lost: collect 10-20% more than the
#> minimum. Randomise which units get each treatment, and record the site and date
#> of every sample.
#> Check: The effect size drives everything
#> Halving the effect roughly quadruples the sample size (see the checks). Use the
#> smallest effect that would matter biologically, from the literature or a pilot,
#> and report the power analysis with the study.
```
