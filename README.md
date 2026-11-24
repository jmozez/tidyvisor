
# tidyvisor <img src="man/figures/logo.png" align="right" height="139" alt="tidyvisor hex logo" />

<!-- badges: start -->

[![R-CMD-check](https://github.com/jmozez/tidyvisor/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/jmozez/tidyvisor/actions/workflows/R-CMD-check.yaml)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**tidyvisor** is a chief statistician for R. It advises at every stage
of a study, in any field:

| Stage            | Ask                               | tidyvisor gives                                                                                                                                 |
|------------------|-----------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------|
| Planning         | `tv_practice("plan")`             | good research practice: the question, the unit of replication, randomisation, controls, pre-registration                                        |
| Before fieldwork | `tv_power()`                      | the samples, traps, plots or sites needed to detect the effect that matters                                                                     |
| With the data    | `tidyvisor(data, ...)`            | a data audit (missing values, pseudoreplication, confounding), the analysis, the test, the plots and the code; what to do when assumptions fail |
| With the result  | `tidyvisor(result)`               | the numbers in plain sentences, the diagnostics and what to do next                                                                             |
| Reporting        | `tv_practice("report", field = )` | the reporting guideline for the field and what to share                                                                                         |

It always gives its reasons, so its advice can be checked and overruled.
The question, which only you know, comes first. Website:
<https://tidyvisor.in4metrix.dev/>.

## One advisor, many packages

The knowledge lives in the packages that do the analyses. Each registers
an *advisor* with tidyvisor, and one `tidyvisor()` serves them all:

| Package                                               | Field             | Advises on                                                                                                                                                                                                                                            |
|-------------------------------------------------------|-------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [tidydiversity](https://tidydiversity.in4metrix.dev/) | Community ecology | Which ordination: unconstrained or constrained, linear or unimodal; which test; ordinations, principal response curves and variation partitioning; canonical variate analysis, trait-environment analyses (dc-CA, RLQ) and co-correspondence analysis |
| [tidymapr](https://tidymapr.in4metrix.dev/)           | Spatial ecology   | Species distribution models, the spread of invasions, epidemic growth and R, range shifts, spatial autocorrelation, variation partitioning between environment and space                                                                              |

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
#> -- tidyvisor: which analysis? --------------------------------------------------
#> Question: practice
#> 
#> -- What the data show --
#> 
#> * Stage: plan
#> * Study: experiment
#> * Field: general
#> 
#> -- Recommended --
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
#> tv_power("two_groups", delta = , sd = )
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
#> -- tidyvisor: which analysis? --------------------------------------------------
#> Question: design
#> 
#> -- What the data show --
#> 
#> * Rows and columns: 578 rows, 4 columns
#> * Missing values: none
#> * Duplicated rows: 0
#> * Response: whole numbers, large: probably a measurement rounded to whole
#>   units: If these are counts, use a Poisson or negative binomial model; if a
#>   measurement, a linear model (or Gamma for positive skewed values).
#> * Groups: 4: 1 (220), 2 (120), 3 (120), 4 (118)
#> * Units: 50 units, 11.6 rows per unit: several measurements per unit: they are
#>   not independent
#> * Unit of replication: Chick (treatment applied to whole units): true
#>   replicates per group: 1 20, 2 10, 3 10, 4 10, not the number of rows
#> * Time points: 12: repeated over time: residuals may be autocorrelated
#> 
#> -- Recommended --
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
#> -- tidyvisor: which analysis? --------------------------------------------------
#> Question: explore
#> 
#> -- What the data show --
#> 
#> * Sites: "8" — few sites: tests have little power
#> * Species: "55"
#> * Data: "abundances"
#> * Zeros: "79%" — many zeros: shared absences must not make sites similar
#>   (Hellinger or Bray-Curtis)
#> * Species in one site only: "51%" — many rare species: they add noise; consider
#>   removing or down-weighting
#> * Gradient length (DCA axis 1, SD units): "11.56" — above 4 SD: long; species
#>   rise and fall along the gradient; unimodal methods (CA, CCA)
#> * Site variables (model terms): "0"
#> 
#> -- Recommended --
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
#> -- tidyvisor: which analysis? --------------------------------------------------
#> Question: epidemic
#> 
#> -- What the data show --
#> 
#> * Records: 12
#> * Time points: 12
#> * Dispersion about the trend (Pearson): 0.1 — close to Poisson
#> 
#> -- Recommended --
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
#> -- tidyvisor: what the results show --------------------------------------------
#> 
#> -- Overview --
#> 
#> * A principal component analysis (PCA) of 8 sites and 55 species
#>   (Hellinger-transformed): an unconstrained ordination, describing the main
#>   patterns of composition.
#> 
#> -- Variation --
#> 
#> * The first two axes hold 27.1% and 22.3% of the variation (49.4% together).
#> * No axis holds more than expected by chance (broken stick): the structure is
#>   weak.
#> 
#> -- Species --
#> 
#> * Axis 1 (PC1) runs from FR01, FR25, FR23 (negative end) to FR36, FR34, FR12
#>   (positive end).
#> * Axis 2 (PC2) runs from FR16, FR29, FR05 (negative end) to FR36, FR01, FR34
#>   (positive end).
#> 
#> -- Reading the diagram --
#> 
#> * Sites (circles) close together have similar species composition.
#> * With species scaling, the angles between species (and between species and
#>   variable arrows) approximate their correlations; distances between sites are
#>   only approximate.
```

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
