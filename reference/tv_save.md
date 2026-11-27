# Save advice and interpretations to a file

tidyvisor prints its advice with the cli package. In the RStudio
console, cli writes straight to the console, so
[`capture.output()`](https://rdrr.io/r/utils/capture.output.html) and
[`sink()`](https://rdrr.io/r/base/sink.html) record nothing there.
`tv_save()` writes the advice as plain text instead, and
[`format()`](https://rdrr.io/r/base/format.html) returns it as a
character vector, one element per line.

## Usage

``` r
tv_save(..., file, append = FALSE, width = 80)

# S3 method for class 'tv_advice'
format(x, ..., width = 80)

# S3 method for class 'tv_interpretation'
format(x, ..., width = 80)
```

## Arguments

- ...:

  Objects to save, such as the results of
  [`tidyvisor()`](https://tidyvisor.in4metrix.dev/reference/tidyvisor.md).

- file:

  Path of the file to write. A file ending in `.md` gets a heading per
  object and the text in code blocks, ready for a report or a Quarto / R
  Markdown document; any other file gets plain text.

- append:

  Add to the end of `file` instead of replacing it.

- width:

  Line width of the text.

- x:

  An object printed by tidyvisor.

## Value

`tv_save()` returns `file`, invisibly.
[`format()`](https://rdrr.io/r/base/format.html) returns a character
vector.

## Details

`tv_save()` works on anything tidyvisor prints: advice from
[`tidyvisor()`](https://tidyvisor.in4metrix.dev/reference/tidyvisor.md),
[`advise()`](https://tidyvisor.in4metrix.dev/reference/advise.md),
[`tv_power()`](https://tidyvisor.in4metrix.dev/reference/power-advisor.md)
and
[`tv_practice()`](https://tidyvisor.in4metrix.dev/reference/practice-advisor.md),
interpretations from
[`interpret()`](https://tidyvisor.in4metrix.dev/reference/interpret.md),
and the advice of the packages that register an advisor (tidydiversity,
tidymapr, tidyepidemio). Give several objects to save a whole
consultation in one file.

## Examples

``` r
adv <- tv_power("two_groups", delta = 5, sd = 8)
res <- tidyvisor(lm(mpg ~ wt + hp, data = mtcars))
f <- tempfile(fileext = ".md")
tv_save(adv, res, file = f)
cat(readLines(f), sep = "\n")
#> ## `adv`
#> 
#> ```
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
#> ```
#> 
#> ## `res`
#> 
#> ```
#> ── tidyvisor: what the results show ────────────────────────────────────────────
#> 
#> ── Overview ──
#> 
#> • Linear model of mpg on 32 observations (gaussian family, identity link).
#> 
#> ── Fit ──
#> 
#> • The predictors explain 82.7% of the variance of mpg (R-squared; adjusted
#>   81.5%).
#> • Against a model with no predictors: F = 69.21 on 2 and 29 df, p < 0.001.
#> 
#> ── Effects ──
#> 
#> • wt: each one-unit increase in wt changes mpg by -3.88 (95% CI -5.17 to
#>   -2.58), p < 0.001.
#> • hp: each one-unit increase in hp changes mpg by -0.0318 (95% CI -0.0502 to
#>   -0.0133), p = 0.001.
#> • Each effect is estimated with the other predictors held fixed.
#> 
#> ── Diagnostics ──
#> 
#> • Normality of residuals (Shapiro-Wilk): W = 0.928, p = 0.034; the residuals
#>   depart from normality: look at the Q-Q plot, and consider a transformation or
#>   another family.
#> • Constant variance (Breusch-Pagan): chi-squared = 0.88 on 2 df, p = 0.644.
#> • Influence: no observation dominates the fit (largest Cook's distance 0.42,
#>   row Chrysler Imperial; values above 1 would be a concern).
#> 
#> ── What to do next ──
#> 
#> • Transform the response: the values are positive and the residuals are
#>   right-skewed, which a log scale often fixes. Refit with log(mpg) and check
#>   again; effects then multiply mpg (report exp(coefficient)). MASS::boxcox(m)
#>   shows which power suits the data (0 = log, 0.5 = square root).
#> • Or keep the original scale with a Gamma GLM and a log link, which expects the
#>   spread to grow with the mean: glm(mpg ~ wt + hp, family = Gamma(link =
#>   "log"), data = data).
#> • Rank-based or permutation alternatives make no assumption about the
#>   distribution: for one factor, kruskal.test() or wilcox.test(); for a whole
#>   model, a permutation test of each term (for example lmPerm::lmp()).
#> • After any change, check the residuals again with plot() and tidyvisor().
#> 
#> ── For the paper ──
#> 
#> • Results (strongest evidence first; each factor level is compared with the
#>   reference level):
#> • 'mpg changed by -3.88 per unit increase in wt (95% CI -5.17 to -2.58, p <
#>   0.001).'
#> • 'mpg changed by -0.0318 per unit increase in hp (95% CI -0.0502 to -0.0133, p
#>   = 0.001).'
#> • Report every term of the model, not only the significant ones, with the
#>   estimate, its 95% CI and the p-value; give n, and the fit (R-squared, or
#>   deviance explained, or the random-effect SDs for a mixed model).
#> • Figure: model predictions with their confidence band over the raw data, one
#>   panel per focal predictor:
#> • ggeffects::ggpredict(m, terms = "wt") |> plot(show_data = TRUE)
#> • ggplot2::ggsave("figure1.pdf", width = 85, height = 70, units = "mm") # one
#>   journal column
#> • Figure style for journals: show the raw data with the estimates, give n per
#>   group in the caption, label axes with units, use a colour-blind-safe palette
#>   (Okabe-Ito, viridis) and no 3D, pie or dual-axis charts; text at least 8 pt
#>   at final size; save as PDF or SVG (vector) at the journal's column width
#>   (about 85 mm single, 180 mm double), or 600 dpi for raster images.
#> • Table: one row per term with the estimate, 95% CI and p-value (and the
#>   random-effect SDs for a mixed model):
#> • gtsummary::tbl_regression(m) # or broom::tidy(m, conf.int = TRUE) for your
#>   own table
#> • Methods: the model formula, the family and link, how the model was checked,
#>   the software and packages with versions (R 4.6.2; citation("stats")), and how
#>   the predictors were chosen (before seeing the data, or how).
#> 
#> ── Reading the plots ──
#> 
#> • plot(model) shows four diagnostics: residuals against fitted values (look for
#>   curves or a funnel), the normal Q-Q plot, scale-location (spread against
#>   fitted values) and residuals against leverage (influential points).
#> • Plot each effect on the response scale, with its confidence band, rather than
#>   the coefficients alone.
#> ```
#> 

# The text as a character vector
head(format(adv))
#> [1] "── tidyvisor: how many samples? ────────────────────────────────────────────────"
#> [2] "Question: power"                                                                 
#> [3] ""                                                                                
#> [4] "── What the data show ──"                                                        
#> [5] ""                                                                                
#> [6] "• Design: two_groups"                                                            
```
