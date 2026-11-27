# tidyvisor: advice before the analysis, interpretation after it

`tidyvisor()` is a statistical advisor shared by a family of packages.
Give it **data** and a question, and it recommends the analysis, checks
the data for the usual pitfalls, and names the plots and the code to run
([`advise()`](https://tidyvisor.in4metrix.dev/reference/advise.md)).
Give it a **result**, and it explains the numbers and the figure in
plain sentences
([`interpret()`](https://tidyvisor.in4metrix.dev/reference/interpret.md)).

The knowledge lives in the packages that do the analyses. Each one
registers an *advisor* with tidyvisor
([`register_advisor()`](https://tidyvisor.in4metrix.dev/reference/register_advisor.md)):
the questions it answers, the results it can interpret, and how to
recognise its kind of data. tidyvisor knows three advisors out of the
box:

- **tidydiversity** (community ecology): which ordination, constrained
  or unconstrained, linear or unimodal, and which test; interpretation
  of ordinations, principal response curves and variation partitioning.

- **tidymapr** (spatial ecology): species distribution models, spread of
  invasions, the spread of epidemics across a landscape, range shifts
  and spatial autocorrelation.

- **tidyepidemio** (epidemiology): outbreaks (incidence, growth, Rt),
  associations (risk, odds and rate ratios), survival, diagnostic tests,
  surveillance and causal effects.

Each is used when its package is installed;
[`advisors()`](https://tidyvisor.in4metrix.dev/reference/advisors.md)
lists them.

The advice always gives its reasons, so it can be checked and overruled:
the question, which only the analyst knows, comes first.

## Usage

``` r
tidyvisor(x, ...)
```

## Arguments

- x:

  A data frame (to be advised) or a fitted result (to be interpreted).

- ...:

  Passed to
  [`advise()`](https://tidyvisor.in4metrix.dev/reference/advise.md) or
  [`interpret()`](https://tidyvisor.in4metrix.dev/reference/interpret.md),
  and on to the advisor: for example `question`, the columns to use, or
  `abundance` and `formula` for community data.

## Value

The advisor's advice or interpretation, which prints as sentences.

## See also

[`advise()`](https://tidyvisor.in4metrix.dev/reference/advise.md),
[`interpret()`](https://tidyvisor.in4metrix.dev/reference/interpret.md),
[`advisors()`](https://tidyvisor.in4metrix.dev/reference/advisors.md),
[`register_advisor()`](https://tidyvisor.in4metrix.dev/reference/register_advisor.md)

## Examples

``` r
frogs <- tidydiversity::png_frogs

# Before: which analysis?
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

# After: what does it show?
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
#> 
#> ── After the overall test ──
#> 
#> • An unconstrained ordination describes the patterns; it has no overall test,
#>   so there is nothing to follow up with pairwise comparisons.
#> • To test whether groups of sites differ in composition, use a permutation
#>   test, beta_permanova(data, formula = ~ group), and check that the groups have
#>   similar spread with beta_dispersion(data, group = group): PERMANOVA cannot
#>   tell a difference in location from a difference in spread (Anderson 2006).
#> 
#> ── For the paper ──
#> 
#> • Results: 'The first two PCA axes explained 27.1% and 22.3% of the variation
#>   in Hellinger-transformed community composition; axis 1 separated ... from ...
#>   (describe the sites and species at each end).'
#> • Report the variation explained by each axis shown, and how many axes are
#>   worth reading (broken stick).
#> • Figure: the ordination diagram with the sites as points (coloured or shaped
#>   by group), the variables as arrows or centroids, and only the species that
#>   matter labelled:
#> • ord_plot <- ggplot2::autoplot(ord) ord_plot
#> • ggplot2::ggsave("figure1.pdf", width = 85, height = 85, units = "mm") # one
#>   journal column
#> • Figure style for journals: one column (about 85 mm) or the page (about 180
#>   mm); label only the species that matter (the strongest weights or best
#>   fitted); give the variation of each axis in its label; a colour-blind-safe
#>   palette and different symbols for groups; text at least 8 pt; vector PDF or
#>   SVG.
#> • Table: the eigenvalues and the variation explained by the first axes, and, if
#>   needed, the species scores on them.
#> • Methods: the method (PCA), the transformation (Hellinger), the scaling, the
#>   permutation scheme and number of permutations, and the software (R 4.6.2,
#>   vegan 2.7.8; citation("vegan"), citation("tidydiversity")).
```
