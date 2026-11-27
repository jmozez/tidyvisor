# 2. Power analysis before fieldwork

Fieldwork is expensive, and a study that is too small to detect the
effect it was designed for is wasted: a non-significant result from it
says almost nothing. A power analysis, done before the field season,
says how many samples, plots, traps or sites are needed. tidyvisor does
it for the common ecological designs and explains the answer.

``` r

library(tidyvisor)
```

Power analysis needs three things:

1.  **The effect worth detecting**: the smallest difference, ratio or
    slope that would matter biologically. It comes from the literature,
    from experience or from the question itself, not from the hope of a
    large effect.
2.  **The variability**: the standard deviation, or the dispersion of
    counts, from a pilot study or earlier work.
3.  **The power and significance level**: usually 80% (a 4-in-5 chance
    of detecting the effect if it is real) and 0.05.

## Two habitats: how many trees?

Suppose a 5 cm difference in sapling height between two habitats would
matter, and earlier surveys give a standard deviation of 8 cm.

``` r

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
```

The sensitivity rows matter as much as the answer: halving the effect
roughly quadruples the sample size, so being optimistic about the effect
is the commonest way to end up with a study that is too small.

## Counts: how many traps?

Beetle counts average 4 per pitfall trap and are overdispersed (negative
binomial size 2). To detect a 1.5-fold difference between treatments:

``` r

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
```

The calculation assumes the counts will be analysed with a negative
binomial GLM, and its code checks the answer by simulation.

## Plots nested in sites: how many sites?

Ecological samples usually come in clusters: quadrats in sites, traps in
transects. Samples within a site are alike, measured by the intra-class
correlation (ICC), so each extra sample per site adds less information
than a new site.

``` r

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
```

The design row shows the trade-off: beyond a few samples per site, only
more sites help. This is why the number of *sites* (or groups), not the
number of samples, usually limits an ecological study.

## Other designs

``` r

# Three or more treatments (one-way ANOVA)
tv_power("groups", means = c(10, 12, 14), sd = 5)$checks
#> # A tibble: 7 × 3
#>   check                          value                                   meaning
#>   <chr>                          <chr>                                   <chr>  
#> 1 Design                         groups                                  ""     
#> 2 Effect to detect               means 10, 12, 14 with SD 5.00 (Cohen's… ""     
#> 3 Power, significance level      80%, 0.05                               ""     
#> 4 Needed                         32 samples per group (96 in total)      ""     
#> 5 If the effect is half as large 122 samples per group                   ""     
#> 6 If it is twice as large        9 samples per group                     ""     
#> 7 For 90% power                  41 samples per group                    ""

# Occupancy or survival: proportions
tv_power("proportions", p1 = 0.2, p2 = 0.4)$checks
#> # A tibble: 7 × 3
#>   check                          value                               meaning
#>   <chr>                          <chr>                               <chr>  
#> 1 Design                         proportions                         ""     
#> 2 Effect to detect               0.200 against 0.400                 ""     
#> 3 Power, significance level      80%, 0.05                           ""     
#> 4 Needed                         82 samples per group (164 in total) ""     
#> 5 If the effect is half as large 294 samples per group               ""     
#> 6 If it is twice as large        23 samples per group                ""     
#> 7 For 90% power                  109 samples per group               ""

# A regression slope explaining 10% of the variation, with 3 predictors
tv_power("regression", r2 = 0.1, predictors = 3)$checks
#> # A tibble: 7 × 3
#>   check                          value                                   meaning
#>   <chr>                          <chr>                                   <chr>  
#> 1 Design                         regression                              ""     
#> 2 Effect to detect               partial R squared 0.100 with 3 predict… ""     
#> 3 Power, significance level      80%, 0.05                               ""     
#> 4 Needed                         73 observations (73 in total)           ""     
#> 5 If the effect is half as large 152 observations                        ""     
#> 6 If it is twice as large        34 observations                         ""     
#> 7 For 90% power                  97 observations                         ""

# A correlation of 0.3
tv_power("correlation", r = 0.3)$checks
#> # A tibble: 7 × 3
#>   check                          value                         meaning
#>   <chr>                          <chr>                         <chr>  
#> 1 Design                         correlation                   ""     
#> 2 Effect to detect               r = 0.300                     ""     
#> 3 Power, significance level      80%, 0.05                     ""     
#> 4 Needed                         85 observations (85 in total) ""     
#> 5 If the effect is half as large 347 observations              ""     
#> 6 If it is twice as large        20 observations               ""     
#> 7 For 90% power                  113 observations              ""

# Before-after on the same plots
tv_power("paired", delta = 2, sd = 4)$checks
#> # A tibble: 7 × 3
#>   check                          value                                   meaning
#>   <chr>                          <chr>                                   <chr>  
#> 1 Design                         paired                                  ""     
#> 2 Effect to detect               mean difference 2.00 with SD of differ… ""     
#> 3 Power, significance level      80%, 0.05                               ""     
#> 4 Needed                         34 pairs (34 in total)                  ""     
#> 5 If the effect is half as large 128 pairs                               ""     
#> 6 If it is twice as large        10 pairs                                ""     
#> 7 For 90% power                  44 pairs                                ""
```

## From pilot data

With a pilot study, tidyvisor estimates the variability from it; only
the effect has to be given. Here the `PlantGrowth` data stand in for a
pilot, and a difference of 0.5 g in dry weight is the effect of
interest:

``` r

advise(PlantGrowth, question = "power", response = "weight",
       group = "group", delta = 0.5)
#> Registered S3 method overwritten by 'parsnip':
#>   method          from 
#>   print.nullmodel vegan
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

For pilot counts, give the rate ratio; the mean and the dispersion come
from the pilot:

``` r

advise(InsectSprays, question = "power", response = "count", ratio = 1.5)$checks
#> # A tibble: 8 × 3
#>   check                          value                                   meaning
#>   <chr>                          <chr>                                   <chr>  
#> 1 From the pilot                 72 observations of count                "mean …
#> 2 Design                         counts                                  ""     
#> 3 Effect to detect               mean 9.50 against 14.2 (rate ratio 1.5… ""     
#> 4 Power, significance level      80%, 0.05                               ""     
#> 5 Needed                         54 samples per group (108 in total)     ""     
#> 6 If the effect is half as large 216 samples per group                   ""     
#> 7 If it is twice as large        14 samples per group                    ""     
#> 8 For 90% power                  72 samples per group                    ""
```

and with sites, give `site` and the ICC is estimated as well.

Do not use the pilot’s own difference as the effect: pilot effects are
noisy, and a study powered on an overestimate is too small. Use the
smallest effect that would matter.

## For mixed models and complex designs

The formulas above cover the common designs. For a generalised linear
mixed model, simulate: fit the model to pilot data, extend it to more
sites and estimate the power by refitting to simulated data, with the
`simr` package (Green and MacLeod 2016; Johnson et al. 2015). The code
is in the advice for `design = "sites"`.

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
