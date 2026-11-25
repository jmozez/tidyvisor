
# tidyvisor <img src="man/figures/logo.png" align="right" height="139" alt="tidyvisor hex logo" />

<!-- badges: start -->

[![R-CMD-check](https://github.com/jmozez/tidyvisor/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/jmozez/tidyvisor/actions/workflows/R-CMD-check.yaml)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**tidyvisor** is a chief statistician for R. It advises at every stage
of a study, in any field:

| Stage                  | Ask                               | tidyvisor gives                                                                                                                                    |
|------------------------|-----------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| Planning               | `tv_practice("plan")`             | good research practice: the question, the unit of replication, randomisation, controls, pre-registration                                           |
| Before fieldwork       | `tv_power()`                      | the samples, traps, plots or sites needed to detect the effect that matters                                                                        |
| With the data          | `tidyvisor(data, ...)`            | a data audit (missing values, pseudoreplication, confounding), the analysis, the test, the plots and the code; what to do when assumptions fail    |
| With the result        | `tidyvisor(result)`               | the numbers in plain sentences, the diagnostics and what to do next                                                                                |
| After the overall test | `tidyvisor(result)`               | whether to go on to post hoc comparisons and which ones (Tukey, Games-Howell, Dunn, `emmeans`), or, when the result is not significant, why not to |
| Writing the paper      | `tidyvisor(result)`               | a sentence for the Results with the numbers in the usual order, the figure and the table to make (with code), and what the Methods must state      |
| Reporting              | `tv_practice("report", field = )` | the reporting guideline for the field, journal-ready figures and tables, and what to share                                                         |

It always gives its reasons, so its advice can be checked and overruled.
The question, which only you know, comes first. Website:
<https://tidyvisor.in4metrix.dev/>.

## One advisor, many packages

The knowledge lives in the packages that do the analyses. Each registers
an *advisor* with tidyvisor, and one `tidyvisor()` serves them all:

| Package | Field | Advises on |
|---|---|---|
| [tidydiversity](https://tidydiversity.in4metrix.dev/) | Community ecology | Which ordination: unconstrained or constrained, linear or unimodal; which test; ordinations, principal response curves and variation partitioning; canonical variate analysis, trait-environment analyses (dc-CA, RLQ) and co-correspondence analysis |
| [tidymapr](https://tidymapr.in4metrix.dev/) | Spatial ecology | Species distribution models, the spread of invasions, the spread of epidemics across a landscape, range shifts, spatial autocorrelation, variation partitioning between environment and space |
| [tidyepidemio](https://jmozez.github.io/tidyepidemio/) | Epidemiology | Outbreaks (incidence, growth, Rt, nowcasting), associations (risk, odds and rate ratios, Mantel-Haenszel), survival, diagnostic tests, surveillance, causal effects (g-computation, weighting) |

Other packages can join with `register_advisor()`.

## Installation

Install tidyvisor first, then the two companion packages whose advisors
it uses:

``` r
# install.packages("remotes")

# 1. tidyvisor: the statistical advisor (study design, power, assumptions,
#    which analysis, and plain-language interpretation of results)
remotes::install_github("jmozez/tidyvisor")

# 2. tidydiversity: community ecology (taxonomic, phylogenetic and
#    functional diversity, beta diversity, ordination and multivariate tests)
remotes::install_github("jmozez/tidydiversity")

# 3. tidymapr: spatial ecology (maps, species distributions, the spread of
#    invasions and epidemics, range shifts, spatial autocorrelation)
remotes::install_github("jmozez/tidymapr")
```

tidyvisor works on its own; the companion packages add their advisors
when installed.

## Plan the study and audit the data

``` r
library(tidyvisor)
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

``` r
tidyvisor(ChickWeight, question = "design", response = "weight",
          group = "Diet", unit = "Chick", time = "Time")
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

## Before the analysis: which analysis?

Community data, with abundances and a question about site variables, go
to the tidydiversity advisor:

``` r
frogs <- tidydiversity::png_frogs
tidyvisor(frogs, abundance = abundance)
#> 
#> ── tidyvisor: what are the main patterns? ──────────────────────────────────────
#> Question: explore
#> 
#> ── What the data show ──
#> 
#> • Sites: 8 — few sites: tests have little power
#> • Species: 55
#> • Data: abundances
#> • Zeros: 79% — many zeros: shared absences must not make sites similar
#>   (Hellinger or Bray-Curtis)
#> • Species in one site only: 51% — many rare species: they add noise; consider
#>   removing or down-weighting
#> • Gradient length (DCA axis 1, SD units): 11.56 — above 4 SD: long; species
#>   rise and fall along the gradient; unimodal methods (CA, CCA)
#> • Site variables (model terms): 0
#> 
#> ── Recommended ──
#> 
#> Approach: Unconstrained (indirect) ordination
#> Branch: ordination (a picture, no test). You want to describe the main patterns
#> of composition, not test their causes.
#> Method: CA, or NMDS
#> Gradient length 11.6 SD; NMDS on bray dissimilarity suits any data.
#> ord_fit(data, abundance = abundance, method = "ca", transform = "none")
#> ord_fit(data, abundance = abundance, method = "nmds", distance = "bray")
#> Interpret: Fit site variables afterwards (arrows, contours, centroids)
#> Fitted variables are a post hoc interpretation of the axes; their permutation
#> p-values are descriptive.
#> autoplot(ord, surface = <numeric variable>)
#> Check: Scree diagram (PCA, CA) or Shepard diagram and stress (NMDS)
#> How many axes are worth reading, and how faithful the diagram is.
#> autoplot(ord, type = "scree")   # or type = "shepard"
#> Plots: Biplot with numeric variables as contours or symbol size, factors as
#> centroids; scree or Shepard inset; stability ellipses
#> Contours show non-linear change that an arrow hides; the inset shows how
#> faithful the diagram is; ellipses show which sites are placed firmly.
#> autoplot(ord, surface = <numeric>, colour = <factor>, inset = "scree")   # "shepard" for NMDS
#> autoplot(ord, type = "gradient", path = <numeric>)
#> autoplot(ord, type = "stability")
#> Interpret: Plain-language explanation of the tables and the diagram
#> Variation explained, tests, directions of variables, groups, species at each
#> end of the axes, and how to read the plot.
#> ord_interpret(ord)
```

Case counts and a question about an epidemic go to the tidymapr advisor:

``` r
cases <- data.frame(
  week = seq(as.Date("2024-01-01"), by = "week", length.out = 12),
  n = c(2, 3, 5, 4, 9, 12, 15, 24, 30, 41, 60, 77)
)
tidyvisor(cases, question = "epidemic", date = "week", cases = "n")
#> 
#> ── tidyvisor: how fast is the epidemic growing? ────────────────────────────────
#> Question: epidemic
#> 
#> ── What the data show ──
#> 
#> • Records: 12
#> • Time points: 12
#> • Dispersion about the trend (Pearson): 0.1 — close to Poisson
#> 
#> ── Recommended ──
#> 
#> Approach: Exponential growth rate from a log-linear count model
#> Early in an outbreak cases grow exponentially; the slope of log cases on time
#> is the growth rate r.
#> Method: Poisson generalised linear model over the exponential phase
#> Choose a window where the log counts rise in a straight line; later, control
#> and depletion bend the curve.
#> g <- epi_growth_rate(data, date = week, cases = n, family = "poisson", window = c(<start>, <end>))
#> Reproduction number: Convert r to R with the generation interval
#> R depends on r and on the mean and standard deviation of the generation
#> interval (Wallinga and Lipsitch 2007); take these from the literature for the
#> pathogen.
#> epi_growth_rate(..., generation_mean = <mean>, generation_sd = <sd>)
#> Spatial spread: Simulate spread across hosts with a dispersal kernel
#> To ask where an infection could go, combine host density, transmission and a
#> dispersal kernel.
#> geo_epidemic_simulate(hosts, init_inf, beta = <beta>, gamma = <gamma>, dispersal_mean = <km>)
#> Plots: Observed counts with the fitted curve and its confidence band, on a log
#> scale
#> On a log scale exponential growth is a straight line, so departures from it are
#> easy to see.
#> plot(g)
#> Interpret: Plain-language explanation of the estimates
#> tidyvisor(g)
```

## After the analysis: what does it show?

``` r
ord <- tidydiversity::ord_fit(frogs,
  abundance = abundance, method = "pca", transform = "hellinger"
)
tidyvisor(ord)
#> 
#> ── tidyvisor: what the results show ────────────────────────────────────────────
#> 
#> ── Overview ──
#> 
#> • A principal component analysis (PCA) of 8 sites and 55 species
#>   (Hellinger-transformed): an unconstrained ordination, describing the main
#>   patterns of composition.
#> 
#> ── Variation ──
#> 
#> • The first two axes hold 27.1% and 22.3% of the variation (49.4% together).
#> • No axis holds more than expected by chance (broken stick): the structure is
#>   weak.
#> 
#> ── Species ──
#> 
#> • Axis 1 (PC1) runs from FR01, FR25, FR23 (negative end) to FR36, FR34, FR12
#>   (positive end).
#> • Axis 2 (PC2) runs from FR16, FR29, FR05 (negative end) to FR36, FR01, FR34
#>   (positive end).
#> 
#> ── Reading the diagram ──
#> 
#> • Sites (circles) close together have similar species composition.
#> • With species scaling, the angles between species (and between species and
#>   variable arrows) approximate their correlations; distances between sites are
#>   only approximate.
```

## After the overall test, and for the paper

Every interpretation of a test or a model ends with two sections. *After
the overall test* says whether to go on to post hoc comparisons: with a
significant result and three or more groups, which comparisons suit the
test, with code that uses your column names; with a non-significant
result, not to test every pair. *For the paper* gives a sentence for the
Results, the figure and the table to make, with code, and what the
Methods must state.

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
#>   version (R 4.3.3, citation()), any adjustment for multiple comparisons, and
#>   the significance level.
```

For models, each factor with three or more levels is tested; when it
matters, its levels are compared with `emmeans`, and the effects are
written out in words against the reference level:

``` r
tidyvisor(glm(count ~ spray, family = poisson, data = InsectSprays))
#> 
#> ── tidyvisor: what the results show ────────────────────────────────────────────
#> 
#> ── Overview ──
#> 
#> • Generalised linear model of count on 72 observations (poisson family, log
#>   link).
#> 
#> ── Fit ──
#> 
#> • The predictors explain 76.0% of the deviance (the GLM analogue of R-squared).
#> • Against a model with no predictors: likelihood-ratio chi-squared = 310.7 on 5
#>   df, p < 0.001.
#> 
#> ── Effects ──
#> 
#> • sprayB: spray = B (compared with spray = A) multiplies the expected count by
#>   1.06 (+6%; 95% CI 0.860 to 1.30), p = 0.597.
#> • sprayC: spray = C (compared with spray = A) multiplies the expected count by
#>   0.144 (-86%; 95% CI 0.0945 to 0.218), p < 0.001.
#> • sprayD: spray = D (compared with spray = A) multiplies the expected count by
#>   0.339 (-66%; 95% CI 0.252 to 0.456), p < 0.001.
#> • sprayE: spray = E (compared with spray = A) multiplies the expected count by
#>   0.241 (-76%; 95% CI 0.172 to 0.338), p < 0.001.
#> • sprayF: spray = F (compared with spray = A) multiplies the expected count by
#>   1.15 (+15%; 95% CI 0.938 to 1.41), p = 0.179.
#> • Effects on the log or logit scale are multiplicative: they combine by
#>   multiplying, and a factor of 1 means no effect.
#> • Each effect is estimated with the other predictors held fixed.
#> 
#> ── Diagnostics ──
#> 
#> • Overdispersion: Pearson statistic / residual df = 1.51 (expected about 1).
#>   Standard errors and p-values are too small; refit with a negative binomial
#>   model (MASS::glm.nb()) or family = quasipoisson.
#> • Influence: no observation dominates the fit (largest Cook's distance 0.19,
#>   row 27; values above 1 would be a concern).
#> 
#> ── After the overall test ──
#> 
#> • spray (6 levels) has an overall effect (p < 0.001): the levels are not all
#>   alike. Go on to post hoc comparisons of every pair, adjusted for the number
#>   of comparisons; the coefficients above only compare each level with the
#>   reference level A.
#> • emmeans::emmeans(m, pairwise ~ spray, type = "response") # Tukey-adjusted
#>   pairs, with intervals
#> • If only comparisons with a control matter, decide so before looking and use
#>   emmeans::emmeans(m, trt.vs.ctrl ~ spray, type = "response") (Dunnett; the
#>   first level, A, is the control), which keeps more power.
#> 
#> ── For the paper ──
#> 
#> • Results (strongest evidence first; each factor level is compared with the
#>   reference level):
#> • 'count was 0.144 times as high for spray = C as for spray = A (95% CI 0.0945
#>   to 0.218, p < 0.001).'
#> • 'count was 0.241 times as high for spray = E as for spray = A (95% CI 0.172
#>   to 0.338, p < 0.001).'
#> • 'count was 0.339 times as high for spray = D as for spray = A (95% CI 0.252
#>   to 0.456, p < 0.001).'
#> • The model is on the log scale, so effects are reported as ratios of means
#>   (exponentiated coefficients) with their intervals.
#> • Report every term of the model, not only the significant ones, with the
#>   estimate, its 95% CI and the p-value; give n, and the fit (R-squared, or
#>   deviance explained, or the random-effect SDs for a mixed model).
#> • Figure: model predictions with their confidence band over the raw data, one
#>   panel per focal predictor:
#> • ggeffects::ggpredict(m, terms = "spray") |> plot(show_data = TRUE)
#> • ggplot2::ggsave("figure1.pdf", width = 85, height = 70, units = "mm") # one
#>   journal column
#> • Figure style for journals: show the raw data with the estimates, give n per
#>   group in the caption, label axes with units, use a colour-blind-safe palette
#>   (Okabe-Ito, viridis) and no 3D, pie or dual-axis charts; text at least 8 pt
#>   at final size; save as PDF or SVG (vector) at the journal's column width
#>   (about 85 mm single, 180 mm double), or 600 dpi for raster images.
#> • Table: one row per term with the estimate, 95% CI and p-value (and the
#>   random-effect SDs for a mixed model):
#> • gtsummary::tbl_regression(m, exponentiate = TRUE) # or broom::tidy(m,
#>   conf.int = TRUE, exponentiate = TRUE) for your own table
#> • Methods: the model formula, the family and link, how the model was checked,
#>   the software and packages with versions (R 4.3.3; citation("stats")), and how
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

`tv_practice("report")` lists the rules for publication: figures at the
journal’s width with the raw data, units and colour-blind-safe palettes;
lean tables; each statistical result in full; and Methods that can be
repeated.

## Statistical models

Besides the ecology packages, tidyvisor advises on widely used models.
Give data with a `question` (or the argument shown), or give it the
fitted model.

| Package | Question or argument                                                               | Fitted classes                                                                     | What it adds                                                                                                                                                                                                                                                   |
|---------|------------------------------------------------------------------------------------|------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| stats   | `"regression"`, `response`                                                         | `lm`, `glm`                                                                        | family from the response, overdispersion, effects as changes, rate or odds ratios; when assumptions fail, what to do next (transform, Gamma GLM, robust standard errors, robust regression)                                                                    |
| stats   | `"compare"`, `response` and `group` (`paired`)                                     | `htest` (t-test, Wilcoxon, Kruskal-Wallis, Shapiro-Wilk, correlation, chi-squared) | assumption checks per group and the test they support: t-test, Welch, log scale, trimmed means, rank or permutation test, count GLM; what to do next after any test                                                                                            |
| stats   | `"design"`, `"practice"`, or `tv_practice()`; also the fallback for any data frame |                                                                                    | data audit (missing values, duplicates, pseudoreplication, confounding with time), the analysis for the response; good practice for planning, data collection, analysis and reporting, with the reporting guideline for the field                              |
| stats   | `"power"`, or `tv_power()`                                                         |                                                                                    | samples, traps or sites needed before fieldwork: two groups, paired, several groups, proportions, counts, regression, correlation, sites with nested samples; from pilot data or given effects                                                                 |
| lme4    | `"mixed"`, `random`                                                                | `lmerMod`, `glmerMod`                                                              | grouping-factor checks, random-effect SDs, intra-class correlation, singular fits                                                                                                                                                                              |
| glmmTMB | `"zero_inflation"`                                                                 | `glmmTMB`                                                                          | negative binomial and zero-inflated mixed models, structural zeros                                                                                                                                                                                             |
| mgcv    | `"smooth"`, `smooth`                                                               | `gam`                                                                              | smooths by effective degrees of freedom, basis (`k`) and concurvity checks                                                                                                                                                                                     |
| vegan   | `"vegan"`                                                                          | `metaMDS`, `rda`, `cca`, `capscale`, `dbrda`, `adonis2`, `betadisper`, `envfit`    | RDA or CCA from the gradient length (the CANOCO rule: below 3 SD linear, above 4 SD unimodal), NMDS stress, permutation tests, dispersion; with `blocks`, `time`, `lon`/`lat` or `traits`, restricted permutations, CVA, spatial partitioning and dc-CA or RLQ |
| brms    | `"bayesian"`                                                                       | `brmsfit`                                                                          | priors and predictive checks, credible intervals, probability of direction, R-hat, ESS, divergences                                                                                                                                                            |
| aods3   | `"overdispersion"`                                                                 | `aodml`, `aodql`                                                                   | beta-binomial and negative binomial models, the overdispersion parameter                                                                                                                                                                                       |

``` r
tidyvisor(lme4::sleepstudy, response = "Reaction", predictors = "Days", random = "Subject")
m <- lme4::lmer(Reaction ~ Days + (1 | Subject), data = lme4::sleepstudy)
tidyvisor(m)
```

## Saving the advice

In the RStudio console the advice is written straight to the screen, so
`capture.output()` and `sink()` cannot record it. `tv_save()` writes one
or more pieces of advice to a file: a `.md` file gets a heading for
each, ready for a report or a Quarto document; any other file gets plain
text. `format()` returns the advice as text.

``` r
plan <- tv_power("two_groups", delta = 5, sd = 8)
fit <- tidyvisor(lm(mpg ~ wt + hp, data = mtcars))
tv_save(plan, fit, file = "advice.md")
tv_save(tidyvisor(InsectSprays, response = "count", group = "spray"),
        file = "advice.md", append = TRUE)
```

## Which advisors are there?

``` r
advisors()
#> # A tibble: 9 x 5
#>   package       title                                installed questions classes
#>   <chr>         <chr>                                <lgl>     <list>    <list> 
#> 1 stats         General statistics: study design an~ TRUE      <chr [5]> <chr>  
#> 2 lme4          Mixed models: lmer() and glmer()     TRUE      <chr [1]> <chr>  
#> 3 glmmTMB       Mixed models for overdispersed and ~ TRUE      <chr [1]> <chr>  
#> 4 mgcv          Additive models with smooth effects~ TRUE      <chr [1]> <chr>  
#> 5 aods3         Overdispersed proportions and count~ TRUE      <chr [1]> <chr>  
#> 6 vegan         Community ordination and multivaria~ TRUE      <chr [1]> <chr>  
#> 7 brms          Bayesian regression and multilevel ~ TRUE      <chr [1]> <chr>  
#> 8 tidydiversity Community ecology: ordination and i~ TRUE      <chr [5]> <chr>  
#> 9 tidymapr      Spatial ecology: distributions, spr~ TRUE      <chr [5]> <chr>
```

## Citation

Please cite tidyvisor as described in `citation("tidyvisor")` and
[`CITATION.cff`](CITATION.cff).
