# Advice on which analysis to run

`advise()` finds the advisor for a data frame and a question, and
returns its advice: what the data show, the analysis to run and why, the
test, the plots, and the code.

## Usage

``` r
advise(x, question = "auto", ...)
```

## Arguments

- x:

  A data frame.

- question:

  What is asked, or `"auto"`.
  [`advisors()`](https://tidyvisor.in4metrix.dev/reference/advisors.md)
  lists the questions of each advisor.

- ...:

  Passed to the advisor.

## Value

The advisor's advice.

## Details

The advisor is chosen by `question`. With `question = "auto"` (the
default), each installed advisor is asked whether the data and the
arguments look like its kind: community data given with `abundance` or a
`formula` belong to tidydiversity, records with coordinates to tidymapr,
and case counts, exposures and outcomes to tidyepidemio. When more than
one advisor claims the data, give `question`.

## Examples

``` r
cases <- data.frame(
  week = seq(as.Date("2024-01-01"), by = "week", length.out = 12),
  n = c(2, 3, 5, 4, 9, 12, 15, 24, 30, 41, 60, 77)
)
advise(cases, question = "epidemic", date = "week", cases = "n")
#> Registered S3 method overwritten by 'parsnip':
#>   method          from 
#>   print.nullmodel vegan
#> 
#> ── tidyvisor: how fast is the epidemic growing? ────────────────────────────────
#> Question: epidemic
#> 
#> ── What the data show ──
#> 
#> • Records: 12
#> • Time points: 12
#> • Dispersion about the trend (Pearson): 0.1 — close to Poisson
#> • Locations: none — case counts over time without places: tidyepidemio covers
#>   outbreak statistics (incidence, Rt, nowcasting); tidymapr adds the spatial
#>   side
#> 
#> ── Recommended ──
#> 
#> Outbreak statistics: Incidence, growth, Rt and nowcasting with tidyepidemio
#> Without locations this is an outbreak-statistics question; the tidyepidemio
#> package has the full toolkit, and tidyvisor hands these data to it.
#> tidyvisor(data, question = "outbreak", time = <date column>, cases = <count column>)
#> Approach: Exponential growth rate from a log-linear count model
#> Early in an outbreak cases grow exponentially; the slope of log cases on time
#> is the growth rate r.
#> Method: Poisson generalised linear model over the exponential phase
#> Choose a window where the log counts rise in a straight line; later, control
#> and depletion bend the curve.
#> g <- epi_growth_rate(data, date = week, cases = n, family = "poisson", window = c(<start>, <end>))
#> Reproduction number: Convert r to R with the generation interval
#> R depends on r and on the mean and standard deviation of the generation
#> interval (Wallinga and Lipsitch 2007); take these from the literature for the
#> pathogen.
#> epi_growth_rate(..., generation_mean = <mean>, generation_sd = <sd>)
#> Spatial spread: Simulate spread across hosts with a dispersal kernel
#> To ask where an infection could go, combine host density, transmission and a
#> dispersal kernel.
#> geo_epidemic_simulate(hosts, init_inf, beta = <beta>, gamma = <gamma>, dispersal_mean = <km>)
#> Plots: Observed counts with the fitted curve and its confidence band, on a log
#> scale
#> On a log scale exponential growth is a straight line, so departures from it are
#> easy to see.
#> plot(g)
#> Interpret: Plain-language explanation of the estimates
#> tidyvisor(g)
```
