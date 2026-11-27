# 1. Research practice and study design

Most problems that statistics cannot fix are made before the analysis:
too few independent replicates, a treatment confounded with time, raw
data edited by hand, an analysis chosen after seeing the data. tidyvisor
gives advice for every stage of a study, in any field.

``` r

library(tidyvisor)
```

## A checklist for each stage

[`tv_practice()`](https://tidyvisor.in4metrix.dev/reference/practice-advisor.md)
gives a checklist for a stage (`"plan"`, `"collect"`, `"analyse"`,
`"report"` or `"all"`) and a kind of study (`"experiment"`,
`"observational"`, `"survey"`, `"monitoring"`, `"review"`).

``` r

tv_practice("plan", design = "observational")
#> 
#> ── tidyvisor: good research practice ───────────────────────────────────────────
#> Question: practice
#> 
#> ── What the data show ──
#> 
#> • Stage: plan
#> • Study: observational
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
#> Plan: List the confounders and measure them
#> Without randomisation, any variable that affects both the predictor and the
#> response can create or hide an effect; draw a causal diagram and measure what
#> it shows.
#> Plan: Pre-register the study and the analysis plan
#> Recording hypotheses, design and analysis before the data exist separates
#> confirmatory from exploratory results (Nosek et al. 2018).
```

``` r

tv_practice("collect")
#> 
#> ── tidyvisor: good research practice ───────────────────────────────────────────
#> Question: practice
#> 
#> ── What the data show ──
#> 
#> • Stage: collect
#> • Study: any
#> • Field: general
#> 
#> ── Recommended ──
#> 
#> Collect: Record data in a tidy table from the start
#> One row per observation, one column per variable, one value per cell; dates in
#> ISO format (YYYY-MM-DD); units in the column names or a data dictionary.
#> Collect: Keep the raw data read-only
#> Never edit raw files by hand; clean them with code, so every change is recorded
#> and can be redone.
#> Collect: Write the metadata as you go
#> Who, where (coordinates and datum), when, how, and what each column and code
#> means; without it the data cannot be reused (FAIR principles; Wilkinson et al.
#> 2016).
#> Collect: Record the unit, the site and the date of every measurement
#> These are needed for random effects, for checking temporal or spatial
#> structure, and for finding errors.
#> Collect: Back up in at least two places
#> Field data cannot be collected again.
```

``` r

tv_practice("analyse")
#> 
#> ── tidyvisor: good research practice ───────────────────────────────────────────
#> Question: practice
#> 
#> ── What the data show ──
#> 
#> • Stage: analyse
#> • Study: any
#> • Field: general
#> 
#> ── Recommended ──
#> 
#> Analyse: Explore the data before modelling
#> Plot the response and every predictor: outliers, zeros, collinearity,
#> non-linear relations and imbalance change which analysis is right (Zuur et al.
#> 2010).
#> advise(data, question = "design", response = "<response column>", group = "<group column>", unit = "<unit column>")
#> Analyse: Match the model to the response and the design
#> Counts, proportions, presence-absence and positive skewed values have their own
#> families; nested or repeated measurements need random effects.
#> tidyvisor(data, response = )
#> Analyse: Check the assumptions, then act on them
#> Residual plots and tests show whether the model fits; tidyvisor says what to do
#> when it does not.
#> tidyvisor(model)
#> Analyse: Report effect sizes with confidence intervals, not p-values alone
#> A p-value says nothing about how large or important an effect is, and p < 0.05
#> is not a measure of truth (Wasserstein and Lazar 2016).
#> Analyse: Correct for multiple comparisons and avoid data dredging
#> Many tests make some significant by chance; adjust (Holm, false discovery rate)
#> or say which analyses were exploratory.
#> Analyse: Keep the analysis in a script under version control
#> A script (with the package versions, for example from sessionInfo() or renv)
#> lets anyone, including you later, reproduce every number.
```

## Reporting guidelines by field

Most fields have a reporting guideline: a checklist of what a paper must
state so that readers can judge and repeat the work. Give `field`:

``` r

tv_practice("report", field = "sdm")$advice[1, ]
#> # A tibble: 1 × 4
#>   step   recommendation                                    reason          code 
#>   <chr>  <chr>                                             <chr>           <chr>
#> 1 Report Follow the reporting guideline for the study type ODMAP, the pro… ""
tv_practice("report", field = "animal")$advice[1, ]
#> # A tibble: 1 × 4
#>   step   recommendation                                    reason          code 
#>   <chr>  <chr>                                             <chr>           <chr>
#> 1 Report Follow the reporting guideline for the study type ARRIVE 2.0 for… ""
tv_practice("report", design = "experiment", field = "trial")$advice[1, ]
#> # A tibble: 1 × 4
#>   step   recommendation                                    reason          code 
#>   <chr>  <chr>                                             <chr>           <chr>
#> 1 Report Follow the reporting guideline for the study type CONSORT 2010 f… ""
```

| `field` | Guideline |
|----|----|
| `"trial"` | CONSORT 2010 (randomised trials) |
| `"epidemiology"`, `"medicine"` | STROBE (observational studies) |
| `"animal"` | ARRIVE 2.0 (animal research) |
| `"review"` | PRISMA 2020 (systematic reviews and meta-analyses) |
| `"diagnostic"` | STARD 2015 (diagnostic accuracy) |
| `"sdm"` | ODMAP (species distribution models) |
| `"ecology"` | Tools for Transparency in Ecology and Evolution |
| anything else | the EQUATOR Network lists the guideline for each kind of study |

## Auditing a data set

Before the analysis, `advise(data, question = "design")` audits the
data: missing values, duplicated rows, constant columns, numbers stored
as text, extreme values, and, given the design, the unit of replication
and confounding.

### Pseudoreplication

The commonest design error in field and laboratory studies is treating
repeated measurements of one unit as independent replicates (Hurlbert
1984). In `ChickWeight`, each chick received one diet and was weighed up
to 12 times: there are 50 replicates, not 578.

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

### Missing values

`airquality` has gaps in the ozone and solar radiation records. The
audit reports them and asks why they are missing before any rows are
dropped:

``` r

advise(airquality, question = "design", response = "Ozone")
#> 
#> ── tidyvisor: is the design sound? ─────────────────────────────────────────────
#> Question: design
#> 
#> ── What the data show ──
#> 
#> • Rows and columns: 153 rows, 6 columns
#> • Missing values: Ozone 24%; Solar.R 5% — more than 20% missing in some
#>   columns: ask why they are missing before dropping rows
#> • Duplicated rows: 0
#> • Response: whole numbers, large: probably a measurement rounded to whole units
#>   — If these are counts, use a Poisson or negative binomial model; if a
#>   measurement, a linear model (or Gamma for positive skewed values).
#> • Extreme values in the response: 1 — check them against the field sheets:
#>   errors or real?
#> 
#> ── Recommended ──
#> 
#> Data: Find out why values are missing
#> If missingness depends on the response or the treatment, dropping rows biases
#> the results; consider multiple imputation (mice) when values are missing at
#> random.
#> colSums(is.na(data))
#> Analysis: Regression model
#> Chosen from the kind of response and the structure of the design; ask tidyvisor
#> for the detailed advice and the assumption checks.
#> lm(Ozone ~ 1, data = data)
#> # detailed advice: tidyvisor(data, response = "Ozone")
#> Next: Good practice for the rest of the study
#> Pre-registration, data management, effect sizes and reporting guidelines.
#> tv_practice()
```

### When nothing else applies

When no specialised advisor recognises the data,
[`tidyvisor()`](https://tidyvisor.in4metrix.dev/reference/tidyvisor.md)
falls back on this audit, so it always answers:

``` r

tidyvisor(iris)$checks
#> # A tibble: 3 × 3
#>   check            value               meaning                      
#>   <chr>            <chr>               <chr>                        
#> 1 Rows and columns 150 rows, 5 columns ""                           
#> 2 Missing values   none                ""                           
#> 3 Duplicated rows  1                   "check for double data entry"
```

## References

Hurlbert, S. H. (1984). Pseudoreplication and the design of ecological
field experiments. *Ecological Monographs* 54, 187-211.

Nosek, B. A., Ebersole, C. R., DeHaven, A. C. and Mellor, D. T. (2018).
The preregistration revolution. *Proceedings of the National Academy of
Sciences* 115, 2600-2606.

Wasserstein, R. L. and Lazar, N. A. (2016). The ASA statement on
p-values: context, process, and purpose. *The American Statistician* 70,
129-133.

Wilkinson, M. D. et al. (2016). The FAIR Guiding Principles for
scientific data management and stewardship. *Scientific Data* 3, 160018.

Zuur, A. F., Ieno, E. N. and Elphick, C. S. (2010). A protocol for data
exploration to avoid common statistical problems. *Methods in Ecology
and Evolution* 1, 3-14.
