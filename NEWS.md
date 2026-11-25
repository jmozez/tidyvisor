# tidyvisor (development version)

* Publication advice. Every interpretation of a test or a model ends with
  a section "For the paper":
  - a sentence for the Results with the numbers in the usual order
    ("count differed among levels of spray (Kruskal-Wallis rank sum test;
    H(5) = 54.7, p < 0.001)"); factor levels in words against the reference
    level, and ratios or odds ratios for log and logit models;
  - the figure to make, with `ggplot2` or `ggeffects` code that uses the
    data's own names and `ggsave()` at a journal column width, and the rules
    for journal figures (raw data shown, units, colour-blind-safe palettes,
    vector formats, text size);
  - the table to make (with `gtsummary` or `broom` code for models), and
    what the Methods must state (test or model, software and versions).
  Assumption tests are flagged as checks, not results.
* `tv_practice("report")` adds advice on figures to a journal's
  specification, lean tables, reporting each statistical result in full,
  and describing the analysis so it can be repeated.

* After an overall test, the interpretation says what to do next in a new
  section, "After the overall test":
  - significant, with three or more groups: go on to post hoc comparisons,
    with the method that suits the test (pairwise Wilcoxon or Dunn after
    Kruskal-Wallis, Games-Howell or Tukey after ANOVA, cell residuals or
    pairwise proportions after a chi-squared test) and code that uses the
    data's own column names;
  - not significant: do not test every pair, which is a search for something
    significant; report the effect size and the difference the study could
    have detected;
  - two groups: no post hoc tests are needed; report the effect size.
  For `lm()`, `glm()`, `aov()`, `lmer()`, `glmer()` and `glmmTMB()` fits,
  each factor with three or more levels is tested with `drop1()`: when it
  matters, its levels are compared with `emmeans` (Tukey, or Dunnett against
  a control), and within each level of the other factor when they interact.
* `tidyvisor()` reads an `aov()` fit as the linear model it is (it failed
  before).

* `tv_save()` writes advice and interpretations to a text or Markdown file,
  and `format()` returns them as text. In the RStudio console the advice
  could not be captured with `capture.output()` or `sink()`.
* Clearer printed advice:
  - `tv_power()`: "Needed: 42 samples per group (84 in total)", and the
    sensitivity lines read "162 samples per group"; "an 80% chance".
  - Headings name the question: "good research practice", "how many
    samples?", "is the design sound?".
  - Degrees of freedom of a test print as whole numbers (`df = 5`).
  - The design audit names each group: "Diet 1: 20, Diet 2: 10".
  - Placeholders in suggested code are marked, e.g.
    `delta = <difference to detect>`.

* Website: a full user guide in eight chapters (research practice, power,
  assumptions, regression, mixed and additive models, Bayesian models,
  community and spatial ecology, writing an advisor) and two tutorials
  that follow whole studies from the question to the report.

* tidyvisor is now a general statistical advisor for any field:
  - `tv_practice()`: good research practice for planning, data collection,
    analysis and reporting, by kind of study, with the reporting guideline
    for the field (CONSORT, STROBE, ARRIVE, PRISMA, STARD, ODMAP, TTEE).
  - `advise(data, question = "design")`: a data audit (missing values,
    duplicated rows, constant columns, numbers stored as text, the unit of
    replication and pseudoreplication, treatments confounded with time,
    unbalanced groups) with the suggested analysis. `tidyvisor()` falls
    back on it when no specialised advisor recognises the data, so it
    always answers.
* A website at <https://tidyvisor.in4metrix.dev/>, laid out like those of
  tidydiversity and tidymapr, with a Get started page and three guides:
  research practice and study design, power analysis, and assumption
  checks.
* README: installation lists tidyvisor first, then tidydiversity and
  tidymapr, saying what each does.

* Power analysis before fieldwork: `tv_power()`, or `advise(pilot,
  question = "power", ...)` with pilot data. It gives the samples, traps,
  pairs, observations or sites needed to detect a given effect, for two or
  more groups, paired designs, proportions, counts (Poisson and negative
  binomial), regression, correlation and samples nested in sites (with the
  intra-class correlation), with a sensitivity table and the code.
* Two guides: checking assumptions and choosing the test, and power
  analysis before fieldwork.

* Assumption checks and what to do when they fail:
  - New group-comparison advice (`question = "compare"`, or give
    `response` and `group`, with `paired` for repeated measurements). It
    checks normality, skewness, outliers, equal spread and whether the
    spread grows with the mean, then recommends the test those checks
    support: Student or Welch t-test and ANOVA, a log scale, trimmed means
    (Yuen), a rank test (Wilcoxon, Kruskal-Wallis), a permutation test, or
    a Poisson or negative binomial GLM for counts. The alternatives come
    with their code.
  - `tidyvisor()` now explains any classical test result (`htest`): the
    statistic, p-value, estimate and interval, what the test does not show,
    and what to do next.
  - The interpretation of a linear model ends with "What to do next": a log
    or Box-Cox transformation, a Gamma GLM, robust standard errors, robust
    regression (`MASS::rlm()`), a count GLM, or rank and permutation
    alternatives, depending on which checks failed.

* The vegan advisor covers the rest of the CANOCO toolkit: restricted
  permutations for blocks (`blocks`) and time series (`time`), canonical
  variate analysis for groups of sites, variation partitioning between
  environment and space (`lon`, `lat`; `tidymapr::geo_varpart()`), and
  trait-environment analysis with dc-CA or RLQ (`traits`).

# tidyvisor 0.2.0

* New built-in advisors for six modelling packages, each with advice before
  fitting and an interpretation after it:
  - lme4 (`question = "mixed"`, or give `random`): checks the grouping
    factors, chooses `lmer()`, `glmer()` or `glmer.nb()`, and explains fixed
    effects, random-effect standard deviations, the intra-class correlation,
    singular fits and convergence.
  - glmmTMB (`question = "zero_inflation"`): negative binomial and
    zero-inflated mixed models, with the probability of a structural zero.
  - mgcv (`question = "smooth"`, or give `smooth`): additive models, each
    smooth explained by its effective degrees of freedom, with basis (`k`)
    and concurvity checks.
  - vegan (`question = "vegan"`): chooses RDA or CCA from the gradient
    length, NMDS, PERMANOVA and its dispersion check; explains `metaMDS()`
    stress, constrained ordinations with permutation tests, `adonis2()`,
    `betadisper()` and `envfit()`.
  - brms (`question = "bayesian"`): family, weakly informative priors, prior
    and posterior predictive checks; explains effects with credible
    intervals and the probability of their direction, group-level standard
    deviations, and R-hat, effective sample size and divergences.
  - aods3 (`question = "overdispersion"`): beta-binomial and negative
    binomial models, with the overdispersion parameter explained.
* `tidyvisor()` sends results that are also data frames (an `adonis2()`
  table) to `interpret()`.
* `interpret()` uses the advisor for the most specific class, so a `gam`
  (which is also a `glm`) goes to the mgcv advisor.
* New built-in advisor for linear and generalised linear models
  (`question = "regression"`, and any fitted `lm` or `glm`). Before fitting,
  it chooses the family and link from the kind of response (continuous,
  counts, binary, proportions, positive and skewed), checks counts for
  overdispersion and excess zeros, the number of observations and events per
  parameter, collinear predictors and missing values, and gives the model
  code. After fitting, it reports the fit, each effect on its natural scale
  (change per unit, rate ratio or odds ratio) with confidence intervals, and
  diagnostics: overdispersion, non-constant variance, non-normal residuals,
  influential observations, collinearity and separation.

# tidyvisor 0.1.0

* First release. tidyvisor is the statistical advisor shared by tidydiversity
  and tidymapr, moved into a package of its own so that one `tidyvisor()`
  serves both, whichever is loaded.
* `tidyvisor()` advises on data (`advise()`) and interprets fitted results
  (`interpret()`).
* `register_advisor()` lets any package add an advisor; `advisors()` lists
  them. Advisors for tidydiversity (community ecology) and tidymapr (spatial
  ecology) are built in and used when those packages are installed.
