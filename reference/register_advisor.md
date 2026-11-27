# Register an advisor with tidyvisor

A package that wants
[`tidyvisor()`](https://tidyvisor.in4metrix.dev/reference/tidyvisor.md)
to advise on its analyses and interpret its results registers an
*advisor*, usually from its `.onLoad()`:

    .onLoad <- function(libname, pkgname) {
      if (requireNamespace("tidyvisor", quietly = TRUE)) {
        tidyvisor::register_advisor(
          package   = pkgname,
          questions = c("explore", "explain"),
          classes   = c("mypkg_fit"),
          advise    = function(x, ...) my_advise(x, ...),
          interpret = function(x, ...) my_interpret(x, ...),
          claims    = function(x, args) "abundance" %in% args
        )
      }
    }

Registering again under the same `package` replaces the earlier advisor,
so a package's own registration takes precedence over the built-in one.

## Usage

``` r
register_advisor(
  package,
  questions,
  classes,
  advise,
  interpret,
  claims = function(x, args) FALSE,
  title = package
)
```

## Arguments

- package:

  Name of the package that provides the advisor.

- questions:

  The questions it answers (used by
  [`advise()`](https://tidyvisor.in4metrix.dev/reference/advise.md) with
  `question = "..."`).

- classes:

  Classes of the results it can interpret.

- advise, interpret:

  Functions `function(x, ...)` returning the advice or the
  interpretation, or names of functions exported by `package`.

- claims:

  A function `function(x, args)` returning `TRUE` when a data frame `x`,
  given with arguments named `args`, is this advisor's kind of data
  (used by
  [`advise()`](https://tidyvisor.in4metrix.dev/reference/advise.md) with
  `question = "auto"`). It must not evaluate the arguments, which may be
  bare column names.

- title:

  A short description shown by
  [`advisors()`](https://tidyvisor.in4metrix.dev/reference/advisors.md).

## Value

The registry entry, invisibly.
