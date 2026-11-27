# Advisor for comparing groups: assumptions and what to do when they fail

Built-in advisor for comparing a numeric response between groups: the
t-test, one-way ANOVA and their alternatives in base R.

- **Before** (`question = "compare"`): checks the assumptions of the
  classical tests in each group (normality, equal spread, outliers,
  skewness, whether the spread grows with the mean) and recommends the
  test those checks support, with the code, and the alternatives:

  |  |  |
  |----|----|
  | What the checks show | Recommendation |
  | roughly normal, equal spread | Student t-test or one-way ANOVA |
  | roughly normal, unequal spread | Welch t-test or Welch ANOVA ([`oneway.test()`](https://rdrr.io/r/stats/oneway.test.html)) |
  | positive, right-skewed, spread grows with the mean | log-transform, then Welch (compares geometric means) |
  | outliers or heavy tails | robust test on trimmed means (Yuen; `WRS2`) |
  | counts with unequal spread | Poisson or negative binomial GLM |
  | otherwise non-normal, or very small groups | rank test: Wilcoxon or Kruskal-Wallis, or a permutation test |

  With `paired`, the checks are on the within-pair differences and the
  tests are their paired versions (paired t, Wilcoxon signed-rank).

- **After**: explains any classical test result (`htest`: from
  [`stats::t.test()`](https://rdrr.io/r/stats/t.test.html),
  [`stats::wilcox.test()`](https://rdrr.io/r/stats/wilcox.test.html),
  [`stats::kruskal.test()`](https://rdrr.io/r/stats/kruskal.test.html),
  [`stats::oneway.test()`](https://rdrr.io/r/stats/oneway.test.html),
  [`stats::shapiro.test()`](https://rdrr.io/r/stats/shapiro.test.html),
  [`stats::cor.test()`](https://rdrr.io/r/stats/cor.test.html),
  [`stats::chisq.test()`](https://rdrr.io/r/stats/chisq.test.html) and
  others): what was tested, the statistic, the p-value, the estimate and
  its interval, what the test does not show, and what to do next.

Assumption tests answer "can the data rule out the assumption?", not
"does the violation matter?": with large groups they flag trivial
departures, with small groups they miss large ones. The advice therefore
weighs them together with the skewness, the ratio of spreads and the
group sizes, and always says to look at the plot.

## Usage

``` r
tv_advise_compare(x, question = "compare", response, group, paired = NULL, ...)

tv_interpret_htest(x, ...)
```

## Arguments

- x:

  A data frame (advice) or an `htest` object (interpretation).

- question:

  The question; set by
  [`advise()`](https://tidyvisor.in4metrix.dev/reference/advise.md).

- response:

  Name of the numeric response column.

- group:

  Name of the grouping column (two or more groups).

- paired:

  Optional name of a column identifying the pairs (or blocks) for
  repeated measurements on the same units; two groups only.

- ...:

  Ignored.

## Value

A `tv_advice` or a `tv_interpretation` object.

## References

Delacre, M., Lakens, D. and Leys, C. (2017). Why psychologists should by
default use Welch's t-test instead of Student's t-test. *International
Review of Social Psychology* 30, 92-101.

Fagerland, M. W. (2012). t-tests, non-parametric tests, and large
studies: a paradox of statistical practice? *BMC Medical Research
Methodology* 12, 78.

O'Hara, R. B. and Kotze, D. J. (2010). Do not log-transform count data.
*Methods in Ecology and Evolution* 1, 118-122.

Wilcox, R. R. (2017). *Introduction to Robust Estimation and Hypothesis
Testing*, fourth edition. Academic Press.

## Examples

``` r
tidyvisor(InsectSprays, response = "count", group = "spray")
#> 
#> ── tidyvisor: which analysis? ──────────────────────────────────────────────────
#> Question: compare
#> 
#> ── What the data show ──
#> 
#> • Groups: 6 — A (n = 12), B (n = 12), C (n = 12), D (n = 12), E (n = 12), F (n
#>   = 12)
#> • Normality (Shapiro-Wilk p, per group): A 0.75; B 0.64; C 0.048; D 0.0027; E
#>   0.3; F 0.1 — at least one group departs from normality
#> • Skewness: A 0.27; B -0.35; C 1.13; D 1.68; E 0.05; F 0.39 — right-skewed
#>   (long tail of large values)
#> • Outliers (robust z > 3.5): 0
#> • Spread (largest SD / smallest SD): 3.59 (Fligner-Killeen p = 0.013) — unequal
#>   spreads: Student's t and the classical ANOVA are unreliable, especially with
#>   unequal group sizes
#> • Counts: non-negative whole numbers — counts have a variance that grows with
#>   the mean; a GLM for counts models that directly
#> • All values positive: no
#> 
#> ── Recommended ──
#> 
#> Before testing: Plot the data
#> Box plots with the points show skewness, outliers and unequal spread at a
#> glance; the checks above put numbers on them.
#> boxplot(count ~ spray, data = data); stripchart(count ~ spray, data = data, vertical = TRUE, add = TRUE, method = "jitter")
#> Test: GLM for counts: negative binomial
#> The response is counts whose spread differs between groups. A count GLM models
#> that directly and gives each group difference as a ratio of means; transforming
#> counts (log(y + 1)) biases the estimates (O'Hara and Kotze 2010). The variance
#> is up to 2.3 times the mean, so the negative binomial.
#> m <- MASS::glm.nb(count ~ spray, data = data)
#> anova(m, test = "Chisq"); tidyvisor(m)
#> Alternative: Non-parametric: rank test
#> Makes no assumption about the shape of the distributions; answers whether
#> values in one group tend to be larger.
#> kruskal.test(count ~ spray, data = data)
#> pairwise.wilcox.test(data$count, data$spray, p.adjust.method = "holm")
#> Alternative: Robust: trimmed means
#> Resists outliers and heavy tails while still comparing a centre.
#> WRS2::t1way(count ~ spray, data = data)   # 20% trimmed means
#> Interpret: Plain-language explanation of the result
#> What was tested, the effect with its interval, and what to do next.
#> tidyvisor(result)
tidyvisor(kruskal.test(count ~ spray, data = InsectSprays))
#> 
#> ── tidyvisor: what the results show ────────────────────────────────────────────
#> 
#> ── Overview ──
#> 
#> • Kruskal-Wallis rank sum test on count by spray.
#> 
#> ── Result ──
#> 
#> • Kruskal-Wallis chi-squared = 54.7 (df = 5), p < 0.001.
#> 
#> ── Meaning ──
#> 
#> • Values in one group tend to be larger than in another. Rank tests compare
#>   whole distributions, not means: report medians or the location shift with its
#>   interval, not a difference in means.
#> • A p-value is not the size of an effect: always report the estimate and its
#>   interval, and a non-significant result is not evidence of no difference.
#> 
#> ── After the overall test ──
#> 
#> • The overall test shows that the 6 groups are not all alike; it does not say
#>   which differ. Go on to post hoc comparisons of every pair, with p-values
#>   adjusted for the number of comparisons.
#> • Rank-based pairs (the follow-up to Kruskal-Wallis):
#>   pairwise.wilcox.test(data$count, data$spray, p.adjust.method = "holm"), or a
#>   Dunn test (FSA::dunnTest(count ~ spray, data = data, method = "holm")).
#> • Report each pair as a median difference or Hodges-Lehmann shift with its
#>   interval (wilcox.test(conf.int = TRUE)), not only adjusted p-values.
#> • Decide which pairs matter before looking: if only comparisons with a control
#>   are of interest, test those alone (Dunnett, or Holm on that smaller set);
#>   fewer comparisons keep more power.
#> 
#> ── What to do next ──
#> 
#> • For an effect size, wilcox.test(conf.int = TRUE) gives the Hodges-Lehmann
#>   shift with its interval.
#> • If the data are positive and right-skewed, a test on the log scale (or a
#>   Gamma GLM) gives a ratio of means, which is often easier to report.
#> 
#> ── For the paper ──
#> 
#> • Results: 'count differed among levels of spray (Kruskal-Wallis rank sum test;
#>   H(5) = 54.7, p < 0.001).'
#> • Report the statistic with its degrees of freedom, the exact p-value (p <
#>   0.001 below that), and the effect size with its interval; never 'p = 0.000'
#>   or 'n.s.' alone.
#> • Figure:
#> • ggplot2::ggplot(data, ggplot2::aes(spray, count)) +
#>   ggplot2::geom_boxplot(outlier.shape = NA, width = 0.5) +
#>   ggplot2::geom_jitter(width = 0.15, alpha = 0.6) +
#>   ggplot2::theme_classic(base_size = 9)
#> • ggplot2::ggsave("figure1.pdf", width = 85, height = 70, units = "mm") # one
#>   journal column
#> • Figure style for journals: show the raw data with the estimates, give n per
#>   group in the caption, label axes with units, use a colour-blind-safe palette
#>   (Okabe-Ito, viridis) and no 3D, pie or dual-axis charts; text at least 8 pt
#>   at final size; save as PDF or SVG (vector) at the journal's column width
#>   (about 85 mm single, 180 mm double), or 600 dpi for raster images.
#> • Table: one row per level of spray with n and the median and interquartile
#>   range; the test in a footnote, and any post hoc results as letters or a
#>   pairwise table with adjusted p-values.
#> • Methods: name the test (Kruskal-Wallis rank sum test), the software and
#>   version (R 4.6.2, citation()), any adjustment for multiple comparisons, and
#>   the significance level.
```
