# Equivalence test: is the difference small enough to ignore?

A non-significant test does not show that two groups are the same. An
equivalence test does: with two one-sided tests (TOST; Schuirmann 1987,
Lakens 2017) it tests whether the difference in means lies inside the
bounds `low` and `high`, the smallest differences that would matter.
Equivalence is declared when both one-sided tests are significant, which
is the same as the 90% confidence interval (for `alpha = 0.05`) lying
inside the bounds. Uses Welch's t-test, or the paired or one-sample
t-test.

## Usage

``` r
tv_equivalence(x, y = NULL, low, high, paired = FALSE, alpha = 0.05)
```

## Arguments

- x, y:

  Numeric samples (`y = NULL` for one sample or paired differences
  already taken).

- low, high:

  Equivalence bounds for the difference (`x - y`), in the units of the
  data, from the smallest effect of interest.

- paired:

  Paired samples?

- alpha:

  Significance level of each one-sided test.

## Value

A `tv_advice` object (question `"equivalence"`) with the difference, the
confidence interval, the two one-sided tests and the ordinary test in
`checks`, the conclusion in `advice`, and `result`, a one-row tibble
with `estimate`, `lower`, `upper`, `p_lower`, `p_upper`, `p_tost` and
`equivalent`.

## References

Schuirmann, D. J. (1987). A comparison of the two one-sided tests
procedure and the power approach for assessing the equivalence of
average bioavailability. Journal of Pharmacokinetics and
Biopharmaceutics, 15, 657-680.
[doi:10.1007/BF01068419](https://doi.org/10.1007/BF01068419)

Lakens, D. (2017). Equivalence tests: a practical primer for t tests,
correlations, and meta-analyses. Social Psychological and Personality
Science, 8, 355-362.
[doi:10.1177/1948550617697177](https://doi.org/10.1177/1948550617697177)

## Examples

``` r
# Is sleep gain under the two drugs within 0.5 hours?
tv_equivalence(sleep$extra[1:10], sleep$extra[11:20], low = -0.5, high = 0.5, paired = TRUE)
#> 
#> ── tidyvisor: is the difference negligible? ────────────────────────────────────
#> Question: equivalence
#> 
#> ── What the data show ──
#> 
#> • Difference: -1.58 (90% CI -2.29 to -0.867) — bounds -0.500 to 0.500
#> • Test against the lower bound: t(9) = -2.78, p = 0.989
#> • Test against the upper bound: t(9) = -5.35, p < 0.001
#> • Ordinary test of no difference: t(9) = -4.06, p = 0.003
#> 
#> ── Recommended ──
#> 
#> Conclusion: Different: the difference is significant and not shown to be
#> negligible
#> Equivalence needs both one-sided tests to be significant (TOST p = 0.989); the
#> 90% confidence interval must lie inside -0.500 to 0.500.
#> Bounds: Justify the bounds before seeing the data
#> The bounds must come from the smallest effect that matters (biology, regulation
#> or earlier studies), set in advance; bounds chosen after the analysis make the
#> test meaningless.
#> For the paper: Report both tests
#> For example: "The difference was -1.58 (90% CI -2.29 to -0.867); equivalence
#> within -0.500 to 0.500 was not supported (TOST, p = 0.989)."
```
