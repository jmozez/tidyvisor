# List the available advisors

List the available advisors

## Usage

``` r
advisors()
```

## Value

A tibble with one row per advisor: `package`, `title`, whether the
package is `installed`, its `questions` and the result `classes` it can
interpret.

## Examples

``` r
advisors()
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
