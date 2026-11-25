#' Save advice and interpretations to a file
#'
#' tidyvisor prints its advice with the cli package. In the RStudio console,
#' cli writes straight to the console, so `capture.output()` and `sink()`
#' record nothing there. `tv_save()` writes the advice as plain text instead,
#' and `format()` returns it as a character vector, one element per line.
#'
#' `tv_save()` works on anything tidyvisor prints: advice from
#' [tidyvisor()], [advise()], [tv_power()] and [tv_practice()],
#' interpretations from [interpret()], and the advice of the packages that
#' register an advisor (tidydiversity, tidymapr). Give several objects to
#' save a whole consultation in one file.
#'
#' @param ... Objects to save, such as the results of [tidyvisor()].
#' @param file Path of the file to write. A file ending in `.md` gets a
#'   heading per object and the text in code blocks, ready for a report or
#'   a Quarto / R Markdown document; any other file gets plain text.
#' @param append Add to the end of `file` instead of replacing it.
#' @param x An object printed by tidyvisor.
#' @param width Line width of the text.
#' @return `tv_save()` returns `file`, invisibly. `format()` returns a
#'   character vector.
#' @examples
#' adv <- tv_power("two_groups", delta = 5, sd = 8)
#' res <- tidyvisor(lm(mpg ~ wt + hp, data = mtcars))
#' f <- tempfile(fileext = ".md")
#' tv_save(adv, res, file = f)
#' cat(readLines(f), sep = "\n")
#'
#' # The text as a character vector
#' head(format(adv))
#' @export
tv_save <- function(..., file, append = FALSE, width = 80) {
  objs <- list(...)
  if (!length(objs)) cli::cli_abort("Give at least one object to save.")
  if (missing(file) || !is.character(file) || length(file) != 1) {
    cli::cli_abort("Give {.arg file}, the path of the file to write.")
  }
  exprs <- as.list(substitute(list(...)))[-1]
  labels <- vapply(exprs, function(e) paste(deparse(e, width.cutoff = 500L), collapse = " "), "")
  md <- grepl("\\.(md|qmd|rmd)$", file, ignore.case = TRUE)
  out <- unlist(lapply(seq_along(objs), function(i) {
    txt <- tv_text(objs[[i]], width = width)
    if (md) c(paste0("## `", labels[i], "`"), "", "```", txt, "```", "") else c(txt, "")
  }))
  con <- file(file, open = if (append) "ab" else "wb")
  on.exit(close(con), add = TRUE)
  writeLines(enc2utf8(out), con, useBytes = TRUE)
  invisible(file)
}

#' @rdname tv_save
#' @export
format.tv_advice <- function(x, ..., width = 80) tv_text(x, width = width)

#' @rdname tv_save
#' @export
format.tv_interpretation <- function(x, ..., width = 80) tv_text(x, width = width)

# Plain text of whatever print() shows, cli output included
tv_text <- function(x, width = 80) {
  withr_width <- options(width = width, cli.width = width)
  on.exit(options(withr_width), add = TRUE)
  cli_txt <- character()
  out_txt <- utils::capture.output(cli_txt <- cli::cli_fmt(print(x)))
  txt <- cli::ansi_strip(c(cli_txt, out_txt))
  # Drop leading blank lines that cli puts before a heading
  while (length(txt) && !nzchar(trimws(txt[1]))) txt <- txt[-1]
  txt
}
