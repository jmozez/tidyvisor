# tidyvisor (development version)

* The vegan advisor covers the rest of CANOCO's toolkit: restricted
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
