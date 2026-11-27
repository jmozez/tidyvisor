# Advisor for vegan: ordination and multivariate tests

Built-in advisor for the vegan package, for community data in the wide
format vegan uses (one row per site, one column per species).

- **Before** (`question = "vegan"`): reports the number of sites and
  species, the share of zeros, and the length of the main gradient. From
  these it recommends a linear or a unimodal method, NMDS for an
  unconstrained view, and PERMANOVA
  ([`vegan::adonis2()`](https://vegandevs.github.io/vegan/reference/adonis.html))
  with its companion check of dispersion
  ([`vegan::betadisper()`](https://vegandevs.github.io/vegan/reference/betadisper.html)).

**The gradient-length rule.** The gradient length is the length of the
longest axis of a detrended correspondence analysis
([`vegan::decorana()`](https://vegandevs.github.io/vegan/reference/decorana.html),
detrending by segments, on log(y + 1) abundances or presence-absence),
in standard-deviation (SD) units of species turnover. This is the value
CANOCO reports. Over about 4 SD the species composition turns over
completely.

|  |  |  |
|----|----|----|
| Gradient length | Species responses | Method |
| below 3 SD | mostly monotonic | linear: PCA, RDA (on Hellinger-transformed abundances) |
| 3 to 4 SD | mixed | both appropriate; tidyvisor gives RDA, with CCA as the alternative |
| above 4 SD | unimodal (rise and fall) | unimodal: CA, CCA |

The rule guides; it does not decide. Hellinger-transformed RDA (Legendre
& Gallagher 2001) and distance-based methods (NMDS, db-RDA, PERMANOVA)
are valid at any gradient length.

- **After**: explains
  [`vegan::metaMDS()`](https://vegandevs.github.io/vegan/reference/metaMDS.html)
  (stress against Clarke's benchmarks),
  [`vegan::rda()`](https://vegandevs.github.io/vegan/reference/cca.html),
  [`vegan::cca()`](https://vegandevs.github.io/vegan/reference/cca.html),
  [`vegan::capscale()`](https://vegandevs.github.io/vegan/reference/dbrda.html)
  and
  [`vegan::dbrda()`](https://vegandevs.github.io/vegan/reference/dbrda.html)
  (variance explained, adjusted R-squared, permutation tests),
  [`vegan::adonis2()`](https://vegandevs.github.io/vegan/reference/adonis.html)
  and [`anova()`](https://rdrr.io/r/stats/anova.html) tables,
  [`vegan::betadisper()`](https://vegandevs.github.io/vegan/reference/betadisper.html)
  and
  [`vegan::envfit()`](https://vegandevs.github.io/vegan/reference/envfit.html).

For long-format data, tidydiversity offers the same analyses through
`ord_fit()`; its advisor answers `tidyvisor(data, abundance = ...)`.

## Usage

``` r
tv_advise_vegan(
  x,
  question = "vegan",
  species = NULL,
  env = NULL,
  blocks = NULL,
  time = NULL,
  lon = NULL,
  lat = NULL,
  traits = NULL,
  ...
)

tv_interpret_vegan(x, permutations = 999, ...)
```

## Arguments

- x:

  A wide data frame of sites (advice), or a vegan result
  (interpretation).

- question:

  The question; set by
  [`advise()`](https://tidyvisor.in4metrix.dev/reference/advise.md).

- species:

  Names of the species columns (default: every numeric column not in
  `env`).

- env:

  Names of the explanatory columns, if any.

- blocks:

  Name of a column of blocks: permutations are restricted to within
  blocks
  ([`tidydiversity::ord_design()`](https://tidydiversity.in4metrix.dev/reference/ord_design.html)).

- time:

  Name of a time (or transect position) column: permutations keep the
  order of the series.

- lon, lat:

  Names of coordinate columns: the advice adds variation partitioning
  between environment and space
  ([`tidymapr::geo_varpart()`](https://tidymapr.in4metrix.dev/reference/geo_varpart.html)).

- traits:

  Name of a trait table, if traits were measured: the advice adds
  trait-environment analysis (dc-CA or RLQ).

- ...:

  Ignored.

- permutations:

  Number of permutations for the tests run while interpreting a
  constrained ordination.

## Value

A `tv_advice` or a `tv_interpretation` object.

## References

Anderson, M.J. (2001). A new method for non-parametric multivariate
analysis of variance. *Austral Ecology* 26, 32-46.

Clarke, K.R. (1993). Non-parametric multivariate analyses of changes in
community structure. *Australian Journal of Ecology* 18, 117-143.

Leps, J. & Smilauer, P. (2003). *Multivariate Analysis of Ecological
Data using CANOCO*. Cambridge University Press. (Second edition for
Canoco 5, 2014.)

Legendre, P. & Gallagher, E.D. (2001). Ecologically meaningful
transformations for ordination of species data. *Oecologia* 129,
271-280.

Ter Braak, C.J.F. & Smilauer, P. (2012). *Canoco Reference Manual and
User's Guide: Software for Ordination (version 5.0)*. Microcomputer
Power, Ithaca.

## Examples

``` r
data("dune", "dune.env", package = "vegan")
tidyvisor(cbind(dune, dune.env), question = "vegan", env = c("A1", "Management"))
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
m <- vegan::rda(vegan::decostand(dune, "hellinger") ~ A1 + Management, dune.env)
tidyvisor(m, permutations = 99)
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
#> • Whole model: F = 2.35, p = 0.010 (99 permutations).
#> • A1 explains 13.0% of the variation: F = 3.17, p = 0.010.
#> • Management explains 25.6% of the variation: F = 2.08, p = 0.010.
#> 
#> ── Reading the plot ──
#> 
#> • In an RDA triplot, the angle between arrows approximates correlation; project
#>   sites or species onto an arrow to read their relation to it.
#> • Look at the axes' explained variance before reading patterns along them.
```
