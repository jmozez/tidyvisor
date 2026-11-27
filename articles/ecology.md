# 7. Community and spatial ecology

The knowledge for specialised fields lives in the packages that do the
analyses. Each registers an advisor with tidyvisor, so one
[`tidyvisor()`](https://tidyvisor.in4metrix.dev/reference/tidyvisor.md)
serves them all:

- [tidydiversity](https://tidydiversity.in4metrix.dev/): community
  ecology (diversity, ordination and multivariate tests);
- [tidymapr](https://tidymapr.in4metrix.dev/): spatial ecology (species
  distributions, the spread of invasions and epidemics, range shifts,
  spatial autocorrelation);
- the built-in vegan advisor, for analyses run directly in vegan.

``` r

library(tidyvisor)
```

## Community data: which ordination?

The dune meadow data pair species cover in 20 plots with the soil and
management of each plot. Give the species and the site variables;
tidyvisor measures the gradient length and follows the CANOCO rule:
below 3 standard deviations a linear method (PCA, RDA), above 4 a
unimodal one (CA, CCA), and either in between.

``` r

data(dune, dune.env, package = "vegan")
d <- cbind(dune, dune.env)
tidyvisor(d, question = "vegan", species = names(dune),
          env = c("A1", "Management"))
#> Registered S3 method overwritten by 'parsnip':
#>   method          from 
#>   print.nullmodel vegan
#> 
#> ── tidyvisor: which analysis? ──────────────────────────────────────────────────
#> Question: vegan
#> 
#> ── What the data show ──
#> 
#> • Sites: 20
#> • Species: 30
#> • Zeros: 67% — many zeros: avoid Euclidean distances on raw counts (double-zero
#>   problem); use Hellinger or Bray-Curtis
#> • Gradient length (longest DCA axis, SD units): 3.52 — between 3 and 4 SD:
#>   intermediate; linear and unimodal methods are both appropriate
#> 
#> ── Recommended ──
#> 
#> Model: Redundancy analysis (RDA) on Hellinger-transformed abundances
#> Branch: constrained ordination (a picture of the gradients your variables
#> explain, tested by permutation). With a gradient of 3 to 4 SD, linear and
#> unimodal methods are both appropriate; CCA (vegan::cca(comm ~ ...)) is the
#> alternative. The Hellinger transformation removes the double-zero problem so
#> RDA can be used on community data (Legendre & Gallagher 2001).
#> comm <- data[species]
#> m <- vegan::rda(vegan::decostand(comm, "hellinger") ~ A1 + Management, data = data)
#> Test: Permutation tests of the model, the axes and each term
#> Community data are not multivariate normal; permutations give valid p-values.
#> anova(m); anova(m, by = "terms"); vegan::RsquareAdj(m)
#> Alternative: PERMANOVA on Bray-Curtis dissimilarities
#> Branch: multivariate test (a p-value, no picture). Tests differences in
#> composition without assuming a linear or unimodal response (Anderson 2001).
#> vegan::adonis2(comm ~ A1 + Management, data = data, method = "bray", by = "terms")
#> Check: Compare the dispersion of the Management groups
#> PERMANOVA is sensitive to differences in spread as well as location; a
#> significant betadisper test means a PERMANOVA difference may reflect spread.
#> b <- vegan::betadisper(vegan::vegdist(comm), data$Management); anova(b)
#> Groups: To find the species combinations that best separate the Management
#> groups: canonical variate analysis
#> CVA (discriminant analysis) maximises the separation between predefined groups;
#> it needs fewer species than sites, so use a few species or the first PCA axes.
#> tidydiversity::ord_cva(data, abundance = abundance, group = "Management")
#> Interpret: Plain-language explanation of the result
#> Variance explained, tests and how to read the plot.
#> tidyvisor(m)
```

The result of the analysis can be explained in turn:

``` r

r <- vegan::rda(vegan::decostand(dune, "hellinger") ~ A1 + Management,
                data = dune.env)
tidyvisor(r)
#> 
#> ── tidyvisor: what the results show ────────────────────────────────────────────
#> 
#> ── Overview ──
#> 
#> • Redundancy analysis (RDA) of 20 sites with 4 constraining degrees of freedom.
#> 
#> ── Fit ──
#> 
#> • The explanatory variables account for 38.6% of the total variance (adjusted
#>   R-squared 22.2%, corrected for the number of variables).
#> • The first constrained axis shows 17.5% of the total.
#> 
#> ── Tests ──
#> 
#> • Whole model: F = 2.35, p = 0.002 (999 permutations).
#> • A1 explains 13.0% of the variation: F = 3.17, p = 0.004.
#> • Management explains 25.6% of the variation: F = 2.08, p = 0.008.
#> 
#> ── Reading the plot ──
#> 
#> • In an RDA triplot, the angle between arrows approximates correlation; project
#>   sites or species onto an arrow to read their relation to it.
#> • Look at the axes' explained variance before reading patterns along them.
```

## With tidydiversity

For data in the tidy long format of tidydiversity (one row per site and
species), the tidydiversity advisor chooses between unconstrained and
constrained ordination, tests and diagrams. Frogs along Mount Wilhelm,
Papua New Guinea:

``` r

tidyvisor(tidydiversity::png_frogs, abundance = abundance)
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

## With tidymapr

Case counts over time go to the tidymapr advisor, which recommends the
growth-rate model and the conversion to a reproduction number:

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
#> • Locations: none — case counts over time without places: tidyepidemio covers
#>   outbreak statistics (incidence, Rt, nowcasting); tidymapr adds the spatial
#>   side
#> 
#> ── Recommended ──
#> 
#> Outbreak statistics: Incidence, growth, Rt and nowcasting with tidyepidemio
#> Without locations this is an outbreak-statistics question; the tidyepidemio
#> package has the full toolkit, and tidyvisor hands these data to it.
#> tidyvisor(data, question = "outbreak", time = <date column>, cases = <count column>)
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

tidymapr also advises on species distribution models (`presence`), range
shifts, the spread of invasions and spatial autocorrelation;
[`advisors()`](https://tidyvisor.in4metrix.dev/reference/advisors.md)
lists every question.

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

## References

Legendre, P. and Gallagher, E. D. (2001). Ecologically meaningful
transformations for ordination of species data. *Oecologia* 129,
271-280.

ter Braak, C. J. F. and Šmilauer, P. (2018). *Canoco reference manual
and user’s guide: software for ordination (version 5.10)*. Microcomputer
Power, Ithaca.
