# tidyvisor 0.2.0

* New built-in adviser for linear and generalised linear models
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

* First release. tidyvisor is the statistical adviser shared by tidydiversity
  and tidymapr, moved into a package of its own so that one `tidyvisor()`
  serves both, whichever is loaded.
* `tidyvisor()` advises on data (`advise()`) and interprets fitted results
  (`interpret()`).
* `register_advisor()` lets any package add an adviser; `advisors()` lists
  them. Advisers for tidydiversity (community ecology) and tidymapr (spatial
  ecology) are built in and used when those packages are installed.
