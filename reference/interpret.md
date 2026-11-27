# Plain-language interpretation of a fitted result

`interpret()` finds the advisor that knows the class of `x` and returns
its interpretation: the numbers in sentences, what the tests say, and
how to read the figure.

## Usage

``` r
interpret(x, ...)
```

## Arguments

- x:

  A fitted result, such as an ordination from
  [`tidydiversity::ord_fit()`](https://tidydiversity.in4metrix.dev/reference/ord_fit.html)
  or a growth rate from
  [`tidymapr::epi_growth_rate()`](https://tidymapr.in4metrix.dev/reference/epi_growth_rate.html).

- ...:

  Passed to the advisor (for example `permutations`).

## Value

The advisor's interpretation.

## Examples

``` r
cases <- data.frame(
  week = seq(as.Date("2024-01-01"), by = "week", length.out = 12),
  n = c(2, 3, 5, 4, 9, 12, 15, 24, 30, 41, 60, 77)
)
g <- tidymapr::epi_growth_rate(cases, date = week, cases = n, unit = "week")
interpret(g)
#> 
#> ── tidyvisor: what the results show ────────────────────────────────────────────
#> 
#> ── Overview ──
#> 
#> • Exponential growth fitted to 12 weeks of counts with a Poisson model.
#> 
#> ── Growth ──
#> 
#> • Cases change by 38.2% per week (growth rate r = 0.324, 95% CI 0.277 to
#>   0.370).
#> • The epidemic is growing: cases double every 2.1 weeks (1.9 to 2.5).
#> 
#> ── Reading the plot ──
#> 
#> • Points are the observed counts; the line is the fitted exponential curve and
#>   the band its confidence interval, computed on the log scale and
#>   back-transformed.
#> • On a log scale the curve is straight; counts bending below it late in the
#>   window suggest control measures or depletion of susceptibles.
#> 
#> ── After the overall test ──
#> 
#> • To compare growth between places or periods, fit each and compare the rates
#>   with their intervals, or fit one model with an interaction of time and place;
#>   do not compare doubling times by eye.
#> 
#> ── For the paper ──
#> 
#> • Results: 'Cases grew by 38.2% per week (growth rate r = 0.324, 95% CI 0.277
#>   to 0.370), doubling every 2.1 weeks (1.9 to 2.5).'
#> • Figure: the counts with the fitted curve and its confidence band, on a log
#>   scale:
#> • p <- plot(g)
#> • geo_save(p, "figure1.pdf", width = 180, height = 100) # full page width, in
#>   mm
#> • Table: the growth rate, doubling time and R, each with its interval.
#> • Methods: the Poisson model, the window of exponential growth and how it was
#>   chosen, the generation interval (mean and SD) and its source for R (Wallinga
#>   and Lipsitch 2007), and the software (R 4.6.2; citation("tidymapr")).
```
