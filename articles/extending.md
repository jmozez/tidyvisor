# 8. Writing your own advisor

tidyvisor is a registry. Each **advisor** belongs to a package and has:

- the **questions** it answers (`"regression"`, `"explore"`,
  `"epidemic"`);
- the **classes** of results it can explain (`"lm"`, `"td_ordination"`);
- an **advise** function, which takes data and returns advice;
- an **interpret** function, which takes a result and returns an
  explanation;
- a **claims** function, which recognises its kind of data from the
  arguments given, so
  [`tidyvisor()`](https://tidyvisor.in4metrix.dev/reference/tidyvisor.md)
  can choose without a question.

``` r

library(tidyvisor)
advisors()
#> Registered S3 method overwritten by 'parsnip':
#>   method          from 
#>   print.nullmodel vegan
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

## How tidyvisor chooses

- **A result** (a fitted model or test) goes to the advisor whose class
  matches most specifically: a `gam` is also a `glm`, and the mgcv
  advisor wins.
- **Data with a question** go to the advisor that answers the question.
- **Data without a question** go to the advisor whose `claims` function
  recognises them (for example `abundance =` for community data). If
  none does, the general advisor audits the data and suggests where to
  go.

## Registering an advisor

A package registers its advisor when it is loaded:

``` r

.onLoad <- function(libname, pkgname) {
  if (requireNamespace("tidyvisor", quietly = TRUE)) {
    tidyvisor::register_advisor(
      package   = pkgname,
      title     = "Growth curves",
      questions = "growth",
      classes   = "mypkg_growth",
      advise    = "my_advise",     # exported functions of the package
      interpret = "my_interpret",
      claims    = function(x, args) "age" %in% args
    )
  }
}
```

The advise function returns a `tv_advice` object, a list with
`question`, `checks` (a table of check, value and meaning) and `advice`
(a table of step, recommendation, reason and code). The interpret
function returns a `tv_interpretation`, a list of named `sections` of
sentences and optional `tables`. tidyvisor prints both in the same
format whatever the advisor.

## A minimal example

An advisor needs a package name that is installed (here `utils`,
standing in for your package), a question, and the two functions:

``` r

register_advisor(
  package = "utils",
  title = "Demo: always plot the data first",
  questions = "first_look",
  classes = "demo_result",
  advise = function(x, question = "first_look", ...) {
    structure(list(
      question = question,
      checks = tibble::tibble(check = "Rows", value = as.character(nrow(x)), meaning = ""),
      advice = tibble::tibble(
        step = "Plot", recommendation = "Plot every variable before any model",
        reason = "Outliers, zeros and curves show up in plots, not in summaries.",
        code = "pairs(data)"
      )
    ), class = "tv_advice")
  },
  interpret = function(x, ...) {
    structure(list(sections = list(Overview = "A demo result."), tables = list()),
              class = "tv_interpretation")
  }
)
advise(cars, question = "first_look")
#> 
#> ── tidyvisor: which analysis? ──────────────────────────────────────────────────
#> Question: first_look
#> 
#> ── What the data show ──
#> 
#> • Rows: 50
#> 
#> ── Recommended ──
#> 
#> Plot: Plot every variable before any model
#> Outliers, zeros and curves show up in plots, not in summaries.
#> pairs(data)
tidyvisor(structure(list(), class = "demo_result"))
#> 
#> ── tidyvisor: what the results show ────────────────────────────────────────────
#> 
#> ── Overview ──
#> 
#> • A demo result.
```

Advice should always give its **reasons**, so users can check and
overrule it, and its **code**, so they can run it.
