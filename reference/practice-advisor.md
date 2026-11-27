# Research practice and study design: advice for any field

The general advice of tidyvisor, for any field and any stage of a study.

- `tv_practice()` gives a checklist of good research practice for a
  stage of the study (`"plan"`, `"collect"`, `"analyse"`, `"report"` or
  `"all"`) and a kind of study (`"experiment"`, `"observational"`,
  `"survey"`, `"monitoring"`, `"review"`), with the reporting guideline
  for the field where one exists (`field`).

- `advise(data, question = "design", ...)` audits a data set before the
  analysis: missing values, duplicated rows, constant and nearly empty
  columns, the unit of replication (pseudoreplication), treatments
  confounded with sites or time, unbalanced groups, and suggests the
  analysis for the response. It is also what
  [`advise()`](https://tidyvisor.in4metrix.dev/reference/advise.md)
  falls back on when no specialised advisor recognises the data, so
  [`tidyvisor()`](https://tidyvisor.in4metrix.dev/reference/tidyvisor.md)
  always answers.

Reporting guidelines by `field`:

|  |  |
|----|----|
| `field` | Guideline |
| `"trial"` | CONSORT 2010 (randomised trials) |
| `"epidemiology"`, `"medicine"` | STROBE (observational studies) |
| `"animal"` | ARRIVE 2.0 (animal research) |
| `"review"` | PRISMA 2020 (systematic reviews and meta-analyses) |
| `"diagnostic"` | STARD 2015 (diagnostic accuracy) |
| `"sdm"` | ODMAP (species distribution models) |
| `"ecology"` | Tools for Transparency in Ecology and Evolution (TTEE) |

## Usage

``` r
tv_practice(
  stage = c("all", "plan", "collect", "analyse", "report"),
  design = c("any", "experiment", "observational", "survey", "monitoring", "review"),
  field = NULL
)

tv_advise_design(
  x,
  question = "design",
  response = NULL,
  group = NULL,
  unit = NULL,
  time = NULL,
  ...
)
```

## Arguments

- stage:

  Stage of the study.

- design:

  Kind of study.

- field:

  Field, to name its reporting guideline (see the table); `NULL` for
  general advice.

- x:

  A data frame.

- question:

  Set by
  [`advise()`](https://tidyvisor.in4metrix.dev/reference/advise.md).

- response:

  Optional name of the response column.

- group:

  Optional name of the treatment or grouping column.

- unit:

  Optional name of the column identifying the unit the treatment was
  applied to (plot, site, cage, patient, school).

- time:

  Optional name of a time column (date, year, visit).

- ...:

  Ignored.

## Value

A `tv_advice` object.

## References

Hurlbert, S. H. (1984). Pseudoreplication and the design of ecological
field experiments. *Ecological Monographs* 54, 187-211.

Nosek, B. A., Ebersole, C. R., DeHaven, A. C. and Mellor, D. T. (2018).
The preregistration revolution. *Proceedings of the National Academy of
Sciences* 115, 2600-2606.

Wasserstein, R. L. and Lazar, N. A. (2016). The ASA statement on
p-values: context, process, and purpose. *The American Statistician* 70,
129-133.

Wilkinson, M. D. et al. (2016). The FAIR Guiding Principles for
scientific data management and stewardship. *Scientific Data* 3, 160018.

Zuur, A. F., Ieno, E. N. and Elphick, C. S. (2010). A protocol for data
exploration to avoid common statistical problems. *Methods in Ecology
and Evolution* 1, 3-14.

## Examples

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
tv_practice("report", field = "sdm")
#> 
#> ── tidyvisor: good research practice ───────────────────────────────────────────
#> Question: practice
#> 
#> ── What the data show ──
#> 
#> • Stage: report
#> • Study: any
#> • Field: sdm — ODMAP, the protocol for reporting species distribution models
#>   (Zurell et al. 2020, Ecography).
#> 
#> ── Recommended ──
#> 
#> Report: Follow the reporting guideline for the study type
#> ODMAP, the protocol for reporting species distribution models (Zurell et al.
#> 2020, Ecography).
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

# Audit a data set: here, chicks weighed repeatedly
advise(ChickWeight, question = "design", response = "weight",
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
