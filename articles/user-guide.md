# User guide

tidyvisor is a statistical advisor: the chief statistician of a study.
You give it your data and your question, or a fitted result; it gives
advice, the reasons for it and the code to run. This guide explains how
to use it at every stage of a study, and what its advice means.

Each chapter follows the same plan:

1.  **The question** the chapter answers, and when it arises.
2.  **Code** to copy into R, run on data sets that come with R or with
    the companion packages, so every example works as printed.
3.  **The advice** tidyvisor gives, exactly as it prints it.
4.  **How to read it**: what each check means, and what the advice does
    not decide for you.

| Chapter | You will learn | Main functions |
|----|----|----|
| [1. Research practice and study design](https://tidyvisor.in4metrix.dev/articles/practice.md) | Good practice at each stage of a study; the unit of replication and pseudoreplication; auditing a data set; reporting guidelines by field | [`tv_practice()`](https://tidyvisor.in4metrix.dev/reference/practice-advisor.md), `advise(question = "design")` |
| [2. Power analysis before fieldwork](https://tidyvisor.in4metrix.dev/articles/power.md) | How many samples, traps or sites; effect size, variability and power; nested designs and the intra-class correlation; pilot data | [`tv_power()`](https://tidyvisor.in4metrix.dev/reference/power-advisor.md), `advise(question = "power")` |
| [3. Checking assumptions and choosing the test](https://tidyvisor.in4metrix.dev/articles/assumptions.md) | Normality, equal spread, outliers; t-test, Welch, rank, robust and permutation tests; what to do when assumptions fail | `tidyvisor(data, response, group)`, `tidyvisor(test)` |
| [4. Regression and generalised linear models](https://tidyvisor.in4metrix.dev/articles/regression.md) | Choosing the family from the response; counts, proportions and binary outcomes; effects as rate and odds ratios; diagnostics | `tidyvisor(data, response)`, `tidyvisor(lm/glm)` |
| [5. Mixed, additive and overdispersed models](https://tidyvisor.in4metrix.dev/articles/mixed.md) | Random effects, grouping factors and the intra-class correlation; smooth effects; zero inflation and overdispersion | lme4, mgcv, glmmTMB, aods3 advisors |
| [6. Bayesian models](https://tidyvisor.in4metrix.dev/articles/bayesian.md) | Priors, prior and posterior predictive checks; credible intervals; R-hat, effective sample size and divergences | brms advisor |
| [7. Community and spatial ecology](https://tidyvisor.in4metrix.dev/articles/ecology.md) | Which ordination and which test; gradient length; species distributions, invasions and epidemics | vegan, tidydiversity and tidymapr advisors |
| [8. Writing your own advisor](https://tidyvisor.in4metrix.dev/articles/extending.md) | How the advisors work; registering one for your own package | [`register_advisor()`](https://tidyvisor.in4metrix.dev/reference/register_advisor.md), [`advisors()`](https://tidyvisor.in4metrix.dev/reference/advisors.md) |

**Where to start.** Planning a study: Chapters 1 and 2. Data in hand:
Chapters 1 and 3, then 4 or 5 for the model. A fitted model whose output
you want explained: pass it to
[`tidyvisor()`](https://tidyvisor.in4metrix.dev/reference/tidyvisor.md)
and read the chapter for its kind of model.

**Worked examples.** The
[tutorials](https://tidyvisor.in4metrix.dev/articles/tutorials.md)
follow whole studies from the question to the report.

**The rule behind the advice.** tidyvisor always gives its reasons, so
the advice can be checked and overruled. It knows the statistics; you
know the biology, the design and the question. Where they disagree, the
question wins.

**How to cite.** Run `citation("tidyvisor")` in R.
