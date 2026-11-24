
# tidyvisor <img src="man/figures/logo.png" align="right" height="139" alt="tidyvisor hex logo" />

<!-- badges: start -->

[![R-CMD-check](https://github.com/jmozez/tidyvisor/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/jmozez/tidyvisor/actions/workflows/R-CMD-check.yaml)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**tidyvisor** is a statistical adviser for ecological analyses. Before
an analysis, give it your data and your question: it checks the data for
the usual pitfalls and recommends the analysis, the test and the plots,
with the code to run. After the analysis, give it the result: it
explains the numbers and the figure in plain sentences.

It always gives its reasons, so its advice can be checked and overruled.
The question, which only you know, comes first.

## One adviser, many packages

The knowledge lives in the packages that do the analyses. Each registers
an *adviser* with tidyvisor, and one `tidyvisor()` serves them all:

| Package                                               | Field             | Advises on                                                                                                                                        |
|-------------------------------------------------------|-------------------|---------------------------------------------------------------------------------------------------------------------------------------------------|
| [tidydiversity](https://tidydiversity.in4metrix.dev/) | Community ecology | Which ordination: unconstrained or constrained, linear or unimodal; which test; ordinations, principal response curves and variation partitioning |
| [tidymapr](https://tidymapr.in4metrix.dev/)           | Spatial ecology   | Species distribution models, the spread of invasions, epidemic growth and R, range shifts, spatial autocorrelation                                |

Other packages can join with `register_advisor()`.

## Installation

``` r
# install.packages("remotes")
remotes::install_github("jmozez/tidyvisor")

# and the packages it advises on
remotes::install_github("jmozez/tidydiversity")
remotes::install_github("jmozez/tidymapr")
```

## Before the analysis: which analysis?

Community data, with abundances and a question about site variables, go
to the tidydiversity adviser:

``` r
library(tidyvisor)
frogs <- tidydiversity::png_frogs
tidyvisor(frogs, abundance = abundance)
#> 
#> ── tidyvisor: which analysis? ──────────────────────────────────────────────────
#> Question: explore
#> 
#> ── What the data show ──
#> 
#> • Sites: "8" — few sites: tests have little power
#> • Species: "55"
#> • Data: "abundances"
#> • Zeros: "79%" — many zeros: shared absences must not make sites similar
#>   (Hellinger or Bray-Curtis)
#> • Species in one site only: "51%" — many rare species: they add noise; consider
#>   removing or down-weighting
#> • Gradient length (DCA axis 1, SD units): "11.56" — long: species rise and fall
#>   along the gradient; unimodal methods (CA, CCA)
#> • Site variables (model terms): "0"
#> 
#> ── Recommended ──
#> 
#> Approach: Unconstrained (indirect) ordination
#> You want to describe the main patterns of composition, not test their causes.
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

Case counts and a question about an epidemic go to the tidymapr adviser:

``` r
cases <- data.frame(
  week = seq(as.Date("2024-01-01"), by = "week", length.out = 12),
  n = c(2, 3, 5, 4, 9, 12, 15, 24, 30, 41, 60, 77)
)
tidyvisor(cases, question = "epidemic", date = "week", cases = "n")
#> 
#> ── tidyvisor: which analysis? ──────────────────────────────────────────────────
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

## Statistical models

Besides the ecology packages, tidyvisor advises on widely used models. Give
data with a `question` (or the argument shown), or give it the fitted model.

| Package | Question or argument | Fitted classes | What it adds |
|---|---|---|---|
| stats | `"regression"`, `response` | `lm`, `glm` | family from the response, overdispersion, effects as changes, rate or odds ratios |
| lme4 | `"mixed"`, `random` | `lmerMod`, `glmerMod` | grouping-factor checks, random-effect SDs, intra-class correlation, singular fits |
| glmmTMB | `"zero_inflation"` | `glmmTMB` | negative binomial and zero-inflated mixed models, structural zeros |
| mgcv | `"smooth"`, `smooth` | `gam` | smooths by effective degrees of freedom, basis (`k`) and concurvity checks |
| aods3 | `"overdispersion"` | `aodml`, `aodql` | beta-binomial and negative binomial models, the overdispersion parameter |

```r
tidyvisor(lme4::sleepstudy, response = "Reaction", predictors = "Days", random = "Subject")
m <- lme4::lmer(Reaction ~ Days + (1 | Subject), data = lme4::sleepstudy)
tidyvisor(m)
```

## Which advisers are there?

``` r
advisors()
#> # A tibble: 2 × 5
#>   package       title                                installed questions classes
#>   <chr>         <chr>                                <lgl>     <list>    <list> 
#> 1 tidydiversity Community ecology: ordination and i… TRUE      <chr [5]> <chr>  
#> 2 tidymapr      Spatial ecology: distributions, spr… TRUE      <chr [5]> <chr>
```

## Citation

Please cite tidyvisor as described in `citation("tidyvisor")` and
[`CITATION.cff`](CITATION.cff).
