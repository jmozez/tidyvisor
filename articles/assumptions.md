# 3. Checking assumptions and choosing the test

Every classical test makes assumptions. The t-test and ANOVA assume
roughly normal data with similar spread in each group; a linear model
assumes the same of its residuals. When the assumptions fail, there is
almost always a better analysis: a transformation, a robust method, a
rank test or a model with the right family. tidyvisor checks the
assumptions, recommends the analysis they support and gives the code.

``` r

library(tidyvisor)
```

## Before the test: which test?

Give the data, the response and the grouping column. Two classic data
sets show the two ends of the scale.

### Sleep: the assumptions hold

The `sleep` data record the extra hours of sleep of 10 people under each
of two drugs.

``` r

tidyvisor(sleep, response = "extra", group = "group")
#> Registered S3 method overwritten by 'parsnip':
#>   method          from 
#>   print.nullmodel vegan
#> 
#> ── tidyvisor: which analysis? ──────────────────────────────────────────────────
#> Question: compare
#> 
#> ── What the data show ──
#> 
#> • Groups: 2 — 1 (n = 10), 2 (n = 10)
#> • Normality (Shapiro-Wilk p, per group): 1 0.41; 2 0.35 — no clear departure
#> • Skewness: 1 0.42; 2 0.28 — roughly symmetric
#> • Outliers (robust z > 3.5): 0
#> • Spread (largest SD / smallest SD): 1.12 (Fligner-Killeen p = 0.645) — similar
#>   spreads
#> • All values positive: no
#> 
#> ── Recommended ──
#> 
#> Before testing: Plot the data
#> Box plots with the points show skewness, outliers and unequal spread at a
#> glance; the checks above put numbers on them.
#> boxplot(extra ~ group, data = data); stripchart(extra ~ group, data = data, vertical = TRUE, add = TRUE, method = "jitter")
#> Test: t-test
#> The groups look close to normal with similar spread; Welch's version gives
#> almost the same answer and is safe if in doubt.
#> t.test(extra ~ group, data = data, var.equal = TRUE)
#> t.test(extra ~ group, data = data)   # Welch, the safer default
#> Alternative: Non-parametric: rank test
#> Makes no assumption about the shape of the distributions; answers whether
#> values in one group tend to be larger.
#> wilcox.test(extra ~ group, data = data, conf.int = TRUE)
#> Alternative: Robust: trimmed means
#> Resists outliers and heavy tails while still comparing a centre.
#> WRS2::yuen(extra ~ group, data = data)   # 20% trimmed means
#> Alternative: Permutation test
#> Uses only the assumption that group labels are exchangeable under no
#> difference; exact for any distribution.
#> # permutation test of the difference in means
#> obs <- diff(tapply(data$extra, data$group, mean))
#> null <- replicate(9999, diff(tapply(data$extra, sample(data$group), mean)))
#> mean(abs(c(obs, null)) >= abs(obs))
#> Interpret: Plain-language explanation of the result
#> What was tested, the effect with its interval, and what to do next.
#> tidyvisor(result)
```

Both groups look close to normal with similar spread, so the t-test is
fine; Welch’s version is shown too, as the safer default. The same
people took both drugs, so the right analysis is paired:

``` r

tidyvisor(sleep, response = "extra", group = "group", paired = "ID")
#> 
#> ── tidyvisor: which analysis? ──────────────────────────────────────────────────
#> Question: compare
#> 
#> ── What the data show ──
#> 
#> • Groups: 2 — 1 (n = 10), 2 (n = 10)
#> • Complete pairs: 10
#> • Normality (Shapiro-Wilk p, per group): differences 0.033 — at least one group
#>   departs from normality
#> • Skewness: differences 1.26 — right-skewed (long tail of large values)
#> • Outliers (robust z > 3.5): 1 — a few extreme values can dominate means and
#>   variances
#> • All values positive: no
#> 
#> ── Recommended ──
#> 
#> Before testing: Plot the data
#> Box plots with the points show skewness, outliers and unequal spread at a
#> glance; the checks above put numbers on them.
#> boxplot(extra ~ group, data = data); stripchart(extra ~ group, data = data, vertical = TRUE, add = TRUE, method = "jitter")
#> Test: Robust test on trimmed means (Yuen)
#> 1 outlier: trimming 20% from each tail keeps them from dominating, while still
#> comparing a mean-like centre (Wilcox 2017).
#> a <- with(data[data$group == "1", ], extra[order(ID)])
#> b <- with(data[data$group == "2", ], extra[order(ID)])
#> WRS2::yuend(b, a)   # trimmed mean of the differences
#> Alternative: Paired t-test
#> The classical test on the within-pair differences; fine when they are close to
#> normal or there are 30 or more pairs.
#> a <- with(data[data$group == "1", ], extra[order(ID)])
#> b <- with(data[data$group == "2", ], extra[order(ID)])
#> t.test(b, a, paired = TRUE)
#> Alternative: Non-parametric: rank test
#> Makes no assumption about the shape of the distributions; answers whether
#> values in one group tend to be larger.
#> a <- with(data[data$group == "1", ], extra[order(ID)])
#> b <- with(data[data$group == "2", ], extra[order(ID)])
#> wilcox.test(b, a, paired = TRUE, conf.int = TRUE)
#> Interpret: Plain-language explanation of the result
#> What was tested, the effect with its interval, and what to do next.
#> tidyvisor(result)
```

With `paired`, the checks are on the within-person differences. They are
right-skewed with one outlier, so tidyvisor recommends a robust test on
trimmed means, with the paired t-test and the Wilcoxon signed-rank test
as alternatives.

### Insect sprays: the assumptions fail

`InsectSprays` counts insects on plots treated with six sprays.

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
```

The checks show what a box plot would: two groups are right-skewed, the
spreads differ more than threefold, and the response is counts. An ANOVA
on these data would be unreliable. A log transformation is the textbook
fix, but counts with zeros need `log(y + 1)`, which biases the estimates
(O’Hara and Kotze 2010); a count GLM models the variance growing with
the mean directly, so tidyvisor recommends a negative binomial GLM. A
rank test (Kruskal-Wallis) and a robust test are listed as alternatives.

### What the checks mean

| Check | What it detects | Remedy |
|----|----|----|
| Shapiro-Wilk per group, skewness | non-normal data | log scale for positive right-skewed data; rank or permutation test; with 30 or more per group, tests on means usually still hold |
| SD ratio, Fligner-Killeen test | unequal spread | Welch’s tests; a log scale or Gamma GLM if the spread grows with the mean |
| Robust z above 3.5 | outliers | trimmed means (Yuen), robust regression |
| Whole numbers from 0 | counts | Poisson or negative binomial GLM |

Assumption tests answer “can the data rule out the assumption?”, not
“does the violation matter?”. With large samples they flag trivial
departures, with small ones they miss serious ones. tidyvisor therefore
weighs them together with skewness, the ratio of spreads and group
sizes, and always starts with “plot the data”.

## After the test: what does it say, and what next?

Any classical test result can be explained:

``` r

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

``` r

tidyvisor(shapiro.test(InsectSprays$count))
#> 
#> ── tidyvisor: what the results show ────────────────────────────────────────────
#> 
#> ── Overview ──
#> 
#> • Shapiro-Wilk normality test on InsectSprays$count.
#> 
#> ── Result ──
#> 
#> • W = 0.922, p < 0.001.
#> 
#> ── Meaning ──
#> 
#> • The data depart from normality. With large samples this flags even small
#>   departures; look at the Q-Q plot before acting.
#> • A p-value is not the size of an effect: always report the estimate and its
#>   interval, and a non-significant result is not evidence of no difference.
#> 
#> ── What to do next ──
#> 
#> • Positive, right-skewed data: try a log transformation (or find the best power
#>   with MASS::boxcox()), then test again on the new scale.
#> • Outliers or heavy tails: use a robust method (trimmed means with WRS2::yuen()
#>   or WRS2::t1way(); MASS::rlm() for regression).
#> • Otherwise, or with small groups: a rank test (wilcox.test(), kruskal.test())
#>   or a permutation test.
#> • With 30 or more values per group, tests on means are usually still valid
#>   (central limit theorem); check the conclusion with a rank test.
#> 
#> ── For the paper ──
#> 
#> • Assumption checks are not results: state in the Methods which checks were
#>   made and what was done about them (for example 'Normality of residuals was
#>   checked with Q-Q plots; counts were log-transformed').
#> • A formal test of an assumption is rarely worth reporting on its own; the plot
#>   of the residuals is more informative.
```

## After a model: what to do when the residuals fail

For a linear model, the interpretation ends with what to do next, chosen
by the checks that failed. Here a model of the insect counts:

``` r

m <- lm(count ~ spray, data = InsectSprays)
tidyvisor(m)$sections[["What to do next"]]
#> [1] "count is counts: fit a Poisson or negative binomial GLM instead of a linear model (glm(..., family = poisson) or MASS::glm.nb()); it models the variance growing with the mean. Avoid log(y + 1), which biases the estimates (O'Hara and Kotze 2010)."
#> [2] "After any change, check the residuals again with plot() and tidyvisor()."
```

and a positive, right-skewed response whose spread grows with the mean,
for which a log scale or a Gamma GLM is the remedy:

``` r

set.seed(2)
d <- data.frame(x = runif(80, 1, 10))
d$y <- exp(0.3 * d$x + rnorm(80, 0, 0.6))
tidyvisor(lm(y ~ x, data = d))$sections[["What to do next"]]
#> [1] "Transform the response: the values are positive and the residuals are right-skewed with a spread that grows with the fitted values, which a log scale often fixes. Refit with log(y) and check again; effects then multiply y (report exp(coefficient)). MASS::boxcox(m) shows which power suits the data (0 = log, 0.5 = square root)."
#> [2] "Or keep the original scale with a Gamma GLM and a log link, which expects the spread to grow with the mean: glm(y ~ x, family = Gamma(link = \"log\"), data = data)."                                                                                                                                                                   
#> [3] "Keep the model but make the standard errors robust to unequal variance: lmtest::coeftest(m, vcov = sandwich::vcovHC(m, type = \"HC3\")). Or model the variance with weights (nlme::gls(..., weights = varPower()))."                                                                                                                    
#> [4] "Rank-based or permutation alternatives make no assumption about the distribution: for one factor, kruskal.test() or wilcox.test(); for a whole model, a permutation test of each term (for example lmPerm::lmp())."                                                                                                                     
#> [5] "After any change, check the residuals again with plot() and tidyvisor()."
```

## References

Delacre, M., Lakens, D. and Leys, C. (2017). Why psychologists should by
default use Welch’s t-test instead of Student’s t-test. *International
Review of Social Psychology* 30, 92-101.

Fagerland, M. W. (2012). t-tests, non-parametric tests, and large
studies: a paradox of statistical practice? *BMC Medical Research
Methodology* 12, 78.

O’Hara, R. B. and Kotze, D. J. (2010). Do not log-transform count data.
*Methods in Ecology and Evolution* 1, 118-122.

Wilcox, R. R. (2017). *Introduction to Robust Estimation and Hypothesis
Testing*, fourth edition. Academic Press.
