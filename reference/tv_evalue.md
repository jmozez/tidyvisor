# E-value: how strong would unmeasured confounding have to be?

For an observational study, the E-value (VanderWeele and Ding 2017) is
the minimum strength of association, on the risk ratio scale, that an
unmeasured confounder would need with both the exposure and the outcome
to fully explain away the observed association. A small E-value (near 1)
means weak confounding could explain the result; a large one means only
strong confounding could. The E-value for the confidence limit closest
to 1 says how much confounding would make the interval include 1.

Odds ratios and hazard ratios for a common outcome (more than about 15%)
are first converted to approximate risk ratios with the square-root
transformation and that of VanderWeele (2020); a standardised mean
difference `d` with \\RR \approx \exp(0.91 d)\\.

## Usage

``` r
tv_evalue(
  estimate,
  lower = NULL,
  upper = NULL,
  type = c("rr", "or", "hr", "smd"),
  rare = FALSE
)
```

## Arguments

- estimate:

  The point estimate (a ratio, or a standardised mean difference for
  `type = "smd"`).

- lower, upper:

  Confidence limits (optional).

- type:

  `"rr"` (risk or rate ratio), `"or"` (odds ratio), `"hr"` (hazard
  ratio) or `"smd"` (standardised mean difference).

- rare:

  For odds and hazard ratios: is the outcome rare (under about 15%)?
  Then the ratio approximates a risk ratio and is used as is.

## Value

A `tv_advice` object (question `"confounding"`) with the E-values in
`checks` and an interpretation in `advice`, plus `evalue` (point) and
`evalue_ci`.

## References

VanderWeele, T. J. and Ding, P. (2017). Sensitivity analysis in
observational research: introducing the E-value. Annals of Internal
Medicine, 167, 268-274.
[doi:10.7326/M16-2607](https://doi.org/10.7326/M16-2607)

VanderWeele, T. J. (2020). Optimal approximate conversions of odds
ratios and hazard ratios to risk ratios. Biometrics, 76, 746-752.
[doi:10.1111/biom.13197](https://doi.org/10.1111/biom.13197)

## Examples

``` r
# Risk ratio 3.9 (95% CI 1.8 to 8.7) for an exposure in a cohort study
tv_evalue(3.9, 1.8, 8.7)
#> 
#> ── tidyvisor: could confounding explain it? ────────────────────────────────────
#> Question: confounding
#> 
#> ── What the data show ──
#> 
#> • Estimate: 3.90 (1.80 to 8.70) — used as given
#> • E-value for the estimate: 7.26 — risk ratio a confounder would need with both
#>   exposure and outcome to explain the estimate away
#> • E-value for the confidence limit: 3.00 — to move the interval to include no
#>   effect
#> 
#> ── Recommended ──
#> 
#> Interpretation: Only strong unmeasured confounding could explain this
#> association
#> An unmeasured confounder associated with both the exposure and the outcome by a
#> risk ratio of 7.26 each, above the measured covariates, could explain away the
#> estimate; weaker confounding could not. A risk ratio of 3.00 each would be
#> enough to make the confidence interval include 1.
#> Compare: Compare the E-value with known confounders
#> Set the E-value against the strength of measured covariates (their risk ratios
#> with exposure and outcome): if no plausible unmeasured factor is that strong,
#> the conclusion is robust.
#> For the paper: Report the E-value with the estimate
#> For example: "The observed risk ratio of 3.90 could be explained away by an
#> unmeasured confounder associated with both exposure and outcome by a risk ratio
#> of 7.26 each, above the measured confounders, but weaker confounding could not
#> (VanderWeele and Ding 2017)."

# Odds ratio for a common outcome
tv_evalue(1.6, 1.1, 2.3, type = "or")
#> 
#> ── tidyvisor: could confounding explain it? ────────────────────────────────────
#> Question: confounding
#> 
#> ── What the data show ──
#> 
#> • Estimate: 1.60 (1.10 to 2.30) — converted with RR = sqrt(OR) (common outcome)
#> • E-value for the estimate: 1.84 — risk ratio a confounder would need with both
#>   exposure and outcome to explain the estimate away
#> • E-value for the confidence limit: 1.28 — to move the interval to include no
#>   effect
#> 
#> ── Recommended ──
#> 
#> Interpretation: Moderate unmeasured confounding could explain this association
#> An unmeasured confounder associated with both the exposure and the outcome by a
#> risk ratio of 1.84 each, above the measured covariates, could explain away the
#> estimate; weaker confounding could not. A risk ratio of 1.28 each would be
#> enough to make the confidence interval include 1.
#> Compare: Compare the E-value with known confounders
#> Set the E-value against the strength of measured covariates (their risk ratios
#> with exposure and outcome): if no plausible unmeasured factor is that strong,
#> the conclusion is robust.
#> For the paper: Report the E-value with the estimate
#> For example: "The observed risk ratio of 1.26 could be explained away by an
#> unmeasured confounder associated with both exposure and outcome by a risk ratio
#> of 1.84 each, above the measured confounders, but weaker confounding could not
#> (VanderWeele and Ding 2017)."
```
