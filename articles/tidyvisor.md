# Get started with tidyvisor

tidyvisor is a statistical advisor: the chief statistician of a study.
It advises at every stage:

| Stage | Ask | tidyvisor gives |
|----|----|----|
| Planning | `tv_practice("plan")` | good practice: question, unit of replication, randomisation, pre-registration |
| Before fieldwork | `tv_power(...)` | samples, traps or sites needed |
| With the data | `tidyvisor(data, ...)` | a data audit, the analysis, the test and the code |
| With the result | `tidyvisor(result)` | the result in plain sentences, the diagnostics and what to do next |
| Reporting | `tv_practice("report", field = ...)` | the reporting guideline and what to share |

It always gives its reasons, so its advice can be checked and overruled.

``` r

library(tidyvisor)
```

## Plan the study

``` r

tv_practice("plan", design = "experiment")
#> 
#> ── tidyvisor: good research practice ───────────────────────────────────────────
#> Question: practice
#> 
#> ── What the data show ──
#> 
#> • Stage: plan
#> • Study: experiment
#> • Field: general
#> 
#> ── Recommended ──
#> 
#> Plan: Write the question and the hypothesis before collecting data
#> A precise question decides the design, the response, the unit of replication
#> and the analysis; analyses chosen after seeing the data inflate false
#> positives.
#> Plan: Define the unit of replication
#> The unit to which a treatment is applied independently (plot, site, cage,
#> patient, school) sets the sample size. Measurements within a unit are not
#> replicates (pseudoreplication; Hurlbert 1984).
#> Plan: Run a power analysis
#> Decide the sample size from the smallest effect worth detecting, not from habit
#> or budget alone.
#> tv_power("two_groups", delta = <difference to detect>, sd = <standard deviation>)
#> Plan: Randomise, include controls and blind where possible
#> Randomising which unit gets which treatment removes systematic bias; controls
#> give the baseline; blinding observers prevents expectations from colouring
#> measurements.
#> Plan: Pre-register the study and the analysis plan
#> Recording hypotheses, design and analysis before the data exist separates
#> confirmatory from exploratory results (Nosek et al. 2018).
```

How many replicates? Suppose a difference of 5 units matters and the
standard deviation is about 8:

``` r

tv_power("two_groups", delta = 5, sd = 8)$checks
#> # A tibble: 7 × 3
#>   check                          value                                   meaning
#>   <chr>                          <chr>                                   <chr>  
#> 1 Design                         two_groups                              ""     
#> 2 Effect to detect               difference 5.00 with SD 8.00 (Cohen's … ""     
#> 3 Power, significance level      80%, 0.05                               ""     
#> 4 Needed                         42 samples per group (84 in total)      ""     
#> 5 If the effect is half as large 162 samples per group                   ""     
#> 6 If it is twice as large        12 samples per group                    ""     
#> 7 For 90% power                  55 samples per group                    ""
```

## Audit the data

Give the data, and as much of the design as you know. The `ChickWeight`
data record the weight of 50 chicks on four diets, weighed repeatedly:

``` r

tidyvisor(ChickWeight, question = "design", response = "weight",
          group = "Diet", unit = "Chick", time = "Time")
#> Registered S3 method overwritten by 'parsnip':
#>   method          from 
#>   print.nullmodel vegan
#> 
#> ── tidyvisor: is the design sound? ─────────────────────────────────────────────
#> Question: design
#> 
#> ── What the data show ──
#> 
#> • Rows and columns: 578 rows, 4 columns
#> • Missing values: none
#> • Duplicated rows: 0
#> • Response: whole numbers, large: probably a measurement rounded to whole units
#>   — If these are counts, use a Poisson or negative binomial model; if a
#>   measurement, a linear model (or Gamma for positive skewed values).
#> • Groups: 4 — 1 (220), 2 (120), 3 (120), 4 (118)
#> • Units: 50 units, 11.6 rows per unit — several measurements per unit: they are
#>   not independent
#> • Unit of replication: Chick (treatment applied to whole units) — true
#>   replicates (Chicks) per group: Diet 1: 20, Diet 2: 10, Diet 3: 10, Diet 4:
#>   10; not the number of rows
#> • Time points: 12 — repeated over time: residuals may be autocorrelated
#> 
#> ── Recommended ──
#> 
#> Design: Treat Chick as the unit of replication
#> Each Chick received one treatment, so its 11.6 measurements are
#> pseudoreplicates (Hurlbert 1984). Analyse with a random effect for Chick, or
#> average within each Chick; counting rows as replicates makes p-values far too
#> small.
#> Design: Allow for correlation over time
#> Measurements close in time are more alike; check the autocorrelation of the
#> residuals and, if needed, add a temporal correlation structure (nlme::corAR1(),
#> glmmTMB::ar1()).
#> acf(residuals(m))
#> Analysis: Mixed model
#> Chosen from the kind of response and the structure of the design; ask tidyvisor
#> for the detailed advice and the assumption checks.
#> lme4::lmer(weight ~ Diet + Time + (1 | Chick), data = data)
#> # detailed advice: tidyvisor(data, response = "weight", random = "Chick")
#> Next: Good practice for the rest of the study
#> Pre-registration, data management, effect sizes and reporting guidelines.
#> tv_practice()
```

The audit finds the unit of replication (the chick, not the row), the
repeated measurements over time, and suggests a mixed model.

With no question at all, tidyvisor audits whatever it is given:

``` r

tidyvisor(airquality)$checks
#> # A tibble: 3 × 3
#>   check            value                 meaning                                
#>   <chr>            <chr>                 <chr>                                  
#> 1 Rows and columns 153 rows, 6 columns   ""                                     
#> 2 Missing values   Ozone 24%; Solar.R 5% "more than 20% missing in some columns…
#> 3 Duplicated rows  0                     ""
```

## Choose the analysis and check its assumptions

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

## Explain the result

``` r

m <- lm(mpg ~ wt + hp, data = mtcars)
tidyvisor(m)
#> 
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
```

## After the overall test

A significant test with three or more groups says that the groups are
not all alike, not which differ. tidyvisor says whether to go on to post
hoc comparisons, which ones suit the test, and, when the result is not
significant, why not to test every pair.

``` r

kw <- kruskal.test(count ~ spray, data = InsectSprays)
tidyvisor(kw)$sections$`After the overall test`
#> [1] "The overall test shows that the 6 groups are not all alike; it does not say which differ. Go on to post hoc comparisons of every pair, with p-values adjusted for the number of comparisons."                
#> [2] "Rank-based pairs (the follow-up to Kruskal-Wallis): pairwise.wilcox.test(data$count, data$spray, p.adjust.method = \"holm\"), or a Dunn test (FSA::dunnTest(count ~ spray, data = data, method = \"holm\"))."
#> [3] "Report each pair as a median difference or Hodges-Lehmann shift with its interval (wilcox.test(conf.int = TRUE)), not only adjusted p-values."                                                               
#> [4] "Decide which pairs matter before looking: if only comparisons with a control are of interest, test those alone (Dunnett, or Holm on that smaller set); fewer comparisons keep more power."
```

## Write it up for the paper

Each interpretation ends with a sentence for the Results, the figure and
the table to make (with code that uses your column names and saves the
figure at a journal’s column width), and what the Methods must state.

``` r

tidyvisor(kw)$sections$`For the paper`
#> [1] "Results: 'count differed among levels of spray (Kruskal-Wallis rank sum test; H(5) = 54.7, p < 0.001).'"                                                                                                                                                                                                                                                                         
#> [2] "Report the statistic with its degrees of freedom, the exact p-value (p < 0.001 below that), and the effect size with its interval; never 'p = 0.000' or 'n.s.' alone."                                                                                                                                                                                                           
#> [3] "Figure:"                                                                                                                                                                                                                                                                                                                                                                         
#> [4] "ggplot2::ggplot(data, ggplot2::aes(spray, count)) + ggplot2::geom_boxplot(outlier.shape = NA, width = 0.5) + ggplot2::geom_jitter(width = 0.15, alpha = 0.6) + ggplot2::theme_classic(base_size = 9)"                                                                                                                                                                            
#> [5] "ggplot2::ggsave(\"figure1.pdf\", width = 85, height = 70, units = \"mm\")   # one journal column"                                                                                                                                                                                                                                                                                
#> [6] "Figure style for journals: show the raw data with the estimates, give n per group in the caption, label axes with units, use a colour-blind-safe palette (Okabe-Ito, viridis) and no 3D, pie or dual-axis charts; text at least 8 pt at final size; save as PDF or SVG (vector) at the journal's column width (about 85 mm single, 180 mm double), or 600 dpi for raster images."
#> [7] "Table: one row per level of spray with n and the median and interquartile range; the test in a footnote, and any post hoc results as letters or a pairwise table with adjusted p-values."                                                                                                                                                                                        
#> [8] "Methods: name the test (Kruskal-Wallis rank sum test), the software and version (R 4.6.2, citation()), any adjustment for multiple comparisons, and the significance level."
```

The rules for publication, from figures to the software citation, are in
the reporting stage of
[`tv_practice()`](https://tidyvisor.in4metrix.dev/reference/practice-advisor.md):

``` r

tv_practice("report")
#> 
#> ── tidyvisor: good research practice ───────────────────────────────────────────
#> Question: practice
#> 
#> ── What the data show ──
#> 
#> • Stage: report
#> • Study: any
#> • Field: general
#> 
#> ── Recommended ──
#> 
#> Report: Follow the reporting guideline for the study type
#> The EQUATOR Network (equator-network.org) lists the reporting guideline for
#> each kind of study.
#> Report: Report everything that was done
#> All measured variables, all analyses run, exclusions and why, and deviations
#> from the pre-registered plan; non-significant results too.
#> Report: Share the data and the code
#> Deposit them in a repository with a DOI (Dryad, Zenodo, OSF, Figshare) under an
#> open licence, with the metadata.
#> Report: Show the data in the figures
#> Plot the raw points with the estimates and intervals, not bars alone ('dynamite
#> plots' hide the data); give the sample size of each group, and say in the
#> caption what the error bars are (SD, SE or 95% CI).
#> Report: Make figures to the journal's specification
#> Width of one column (about 85 mm) or the page (about 180 mm); text at least 8
#> pt at that size; axis labels with units; a colour-blind-safe palette
#> (Okabe-Ito, viridis), never red against green; no 3D, pie or dual-axis charts;
#> vector PDF or SVG, or 600 dpi for raster images.
#> ggplot2::ggsave("figure1.pdf", width = 85, height = 70, units = "mm")
#> Report: Keep tables lean and consistent
#> Only the numbers a reader needs: estimates with 95% CI, n, and test results;
#> the same number of decimals within a column (two or three significant figures);
#> units in the column headers; horizontal rules only; abbreviations explained in
#> a footnote.
#> gtsummary::tbl_regression(m)   # or flextable / gt for your own table
#> Report: Report each statistical result in full
#> The test, the statistic with its degrees of freedom, the exact p-value (p <
#> 0.001 below that; never p = 0.000), and the effect size with its 95% CI, e.g.
#> 'H(5) = 54.7, p < 0.001'. Say how multiple comparisons were adjusted, and give
#> non-significant results the same way.
#> Report: Describe the analysis so it can be repeated
#> Methods: each model's formula, family and link; random effects; how assumptions
#> were checked and what was done when they failed; how predictors were chosen;
#> the software and package versions, cited.
#> citation(); sessionInfo()   # or grateful::cite_packages()
```

## Save the advice

Keep the advice with the analysis:
[`tv_save()`](https://tidyvisor.in4metrix.dev/reference/tv_save.md)
writes it to a file, a heading for each piece in a `.md` file, plain
text otherwise. It works in the RStudio console, where
[`capture.output()`](https://rdrr.io/r/utils/capture.output.html) and
[`sink()`](https://rdrr.io/r/base/sink.html) record nothing, and on the
advice of the companion packages too.
[`format()`](https://rdrr.io/r/base/format.html) returns the advice as
text.

``` r

f <- tempfile(fileext = ".md")
tv_save(tv_power("two_groups", delta = 5, sd = 8), file = f)
head(readLines(f), 12)
```

    #>  [1] "## `tv_power(\"two_groups\", delta = 5, sd = 8)`"                                
    #>  [2] ""                                                                                
    #>  [3] "```"                                                                             
    #>  [4] "── tidyvisor: how many samples? ────────────────────────────────────────────────"
    #>  [5] "Question: power"                                                                 
    #>  [6] ""                                                                                
    #>  [7] "── What the data show ──"                                                        
    #>  [8] ""                                                                                
    #>  [9] "• Design: two_groups"                                                            
    #> [10] "• Effect to detect: difference 5.00 with SD 8.00 (Cohen's d = 0.62)"             
    #> [11] "• Power, significance level: 80%, 0.05"                                          
    #> [12] "• Needed: 42 samples per group (84 in total)"

## Advisors from the companion packages

The same
[`tidyvisor()`](https://tidyvisor.in4metrix.dev/reference/tidyvisor.md)
serves the companion packages, which register their own advisors when
installed: [tidydiversity](https://tidydiversity.in4metrix.dev/) for
community ecology (diversity, ordination, multivariate tests) and
[tidymapr](https://tidymapr.in4metrix.dev/) for spatial ecology (species
distributions, invasions, the spread of epidemics, range shifts) and
[tidyepidemio](https://tidyepidemio.in4metrix.dev/) for epidemiology
(outbreaks, associations, survival, diagnostic tests, surveillance,
causal effects).
[`advisors()`](https://tidyvisor.in4metrix.dev/reference/advisors.md)
lists what is available:

``` r

advisors()
#> # A tibble: 10 × 5
#>    package       title                               installed questions classes
#>    <chr>         <chr>                               <lgl>     <list>    <list> 
#>  1 stats         General statistics: study design a… TRUE      <chr [5]> <chr>  
#>  2 lme4          Mixed models: lmer() and glmer()    TRUE      <chr [1]> <chr>  
#>  3 glmmTMB       Mixed models for overdispersed and… TRUE      <chr [1]> <chr>  
#>  4 mgcv          Additive models with smooth effect… TRUE      <chr [1]> <chr>  
#>  5 aods3         Overdispersed proportions and coun… TRUE      <chr [1]> <chr>  
#>  6 vegan         Community ordination and multivari… TRUE      <chr [1]> <chr>  
#>  7 brms          Bayesian regression and multilevel… TRUE      <chr [1]> <chr>  
#>  8 tidydiversity Community ecology: ordination and … TRUE      <chr [5]> <chr>  
#>  9 tidymapr      Spatial ecology: distributions, sp… TRUE      <chr [5]> <chr>  
#> 10 tidyepidemio  Epidemiology: outbreaks, associati… TRUE      <chr [6]> <chr>
```
