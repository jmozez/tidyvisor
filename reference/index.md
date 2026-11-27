# Package index

## The advisor

- [`tidyvisor()`](https://tidyvisor.in4metrix.dev/reference/tidyvisor.md)
  : tidyvisor: advice before the analysis, interpretation after it
- [`advise()`](https://tidyvisor.in4metrix.dev/reference/advise.md) :
  Advice on which analysis to run
- [`interpret()`](https://tidyvisor.in4metrix.dev/reference/interpret.md)
  : Plain-language interpretation of a fitted result
- [`tv_save()`](https://tidyvisor.in4metrix.dev/reference/tv_save.md)
  [`format(`*`<tv_advice>`*`)`](https://tidyvisor.in4metrix.dev/reference/tv_save.md)
  [`format(`*`<tv_interpretation>`*`)`](https://tidyvisor.in4metrix.dev/reference/tv_save.md)
  : Save advice and interpretations to a file

## Research practice, design and power

- [`tv_practice()`](https://tidyvisor.in4metrix.dev/reference/practice-advisor.md)
  [`tv_advise_design()`](https://tidyvisor.in4metrix.dev/reference/practice-advisor.md)
  : Research practice and study design: advice for any field
- [`tv_power()`](https://tidyvisor.in4metrix.dev/reference/power-advisor.md)
  [`tv_advise_power()`](https://tidyvisor.in4metrix.dev/reference/power-advisor.md)
  : Power analysis: how many samples, sites or groups to collect

## Statistical models and tests

- [`tv_advise_regression()`](https://tidyvisor.in4metrix.dev/reference/regression-advisor.md)
  [`tv_interpret_regression()`](https://tidyvisor.in4metrix.dev/reference/regression-advisor.md)
  : The regression advisor: linear and generalised linear models
- [`tv_advise_compare()`](https://tidyvisor.in4metrix.dev/reference/compare-advisor.md)
  [`tv_interpret_htest()`](https://tidyvisor.in4metrix.dev/reference/compare-advisor.md)
  : Advisor for comparing groups: assumptions and what to do when they
  fail
- [`tv_advise_mixed()`](https://tidyvisor.in4metrix.dev/reference/model-advisors.md)
  [`tv_advise_gam()`](https://tidyvisor.in4metrix.dev/reference/model-advisors.md)
  [`tv_advise_aod()`](https://tidyvisor.in4metrix.dev/reference/model-advisors.md)
  [`tv_interpret_mixed()`](https://tidyvisor.in4metrix.dev/reference/model-advisors.md)
  [`tv_interpret_gam()`](https://tidyvisor.in4metrix.dev/reference/model-advisors.md)
  [`tv_interpret_aod()`](https://tidyvisor.in4metrix.dev/reference/model-advisors.md)
  : Advisors for mixed, additive and overdispersed models
- [`tv_advise_brms()`](https://tidyvisor.in4metrix.dev/reference/brms-advisor.md)
  [`tv_interpret_brms()`](https://tidyvisor.in4metrix.dev/reference/brms-advisor.md)
  : Advisor for brms: Bayesian regression and mixed models

## Model checks, equivalence and confounding

- [`tv_check_model()`](https://tidyvisor.in4metrix.dev/reference/tv_check_model.md)
  : Check a fitted model with simulated residuals
- [`tv_equivalence()`](https://tidyvisor.in4metrix.dev/reference/tv_equivalence.md)
  : Equivalence test: is the difference small enough to ignore?
- [`tv_evalue()`](https://tidyvisor.in4metrix.dev/reference/tv_evalue.md)
  : E-value: how strong would unmeasured confounding have to be?

## Community ecology

- [`tv_advise_vegan()`](https://tidyvisor.in4metrix.dev/reference/vegan-advisor.md)
  [`tv_interpret_vegan()`](https://tidyvisor.in4metrix.dev/reference/vegan-advisor.md)
  : Advisor for vegan: ordination and multivariate tests

## Advisors from other packages

- [`advisors()`](https://tidyvisor.in4metrix.dev/reference/advisors.md)
  : List the available advisors
- [`register_advisor()`](https://tidyvisor.in4metrix.dev/reference/register_advisor.md)
  : Register an advisor with tidyvisor
