# Every registry layer a vignette DRAWS must also appear in its legend.
#
# gq#61 shipped a map whose most prominent feature -- a 397-feature red habitat
# network -- was styled from the registry and absent from the legend, while the
# prose beneath described its widths and dashes. Nothing caught it, because
# building a legend from a layer list answers "did I list my layers", which
# always says yes.
#
# This reads the vignette source rather than a second hand-maintained list. A
# list maintained beside the first one drifts from it, which is the failure
# being guarded against.

vignette_dir <- function() {
  # devtools::test() runs from tests/testthat/; R CMD check runs the same tests
  # from the unpacked source, so walk up looking for the directory rather than
  # hardcoding a depth.
  for (up in c("..", "../..", "../../..", "../../../..")) {
    p <- file.path(up, "vignettes")
    if (dir.exists(p)) return(normalizePath(p))
  }
  NA_character_
}

# Parse the vignette's R with R's own parser rather than with regexes.
#
# The first draft matched patterns against the raw file and was wrong twice
# over: it read `gq_tmap_style(reg, "name")` out of a markdown code span in the
# closing prose and counted it as a drawn layer, and its legend matcher latched
# onto the words "gq_tmap_legend(" inside a comment, sweeping up the comment's
# prose as layer keys. parse() sees neither -- comments are dropped and prose is
# never in a chunk.
# Scoped to ONE named chunk, not the whole file. The vignette also demonstrates
# gq_tmap_style() in a teaching chunk and styles a layer for the keymap inset;
# neither is drawn on the main map, so a whole-file scan reports layers that are
# correctly absent from the legend.
chunk_code <- function(src, chunk) {
  open <- grep(paste0("^```\\{r ", chunk, "[,}]"), src)
  if (length(open) != 1L) {
    stop("expected exactly one '", chunk, "' chunk, found ", length(open),
         ". If it was renamed, this guard is no longer reading the map -- ",
         "update the name rather than letting it check nothing.",
         call. = FALSE)
  }
  close <- grep("^```\\s*$", src)
  end <- close[close > open][1]
  src[(open + 1):(end - 1)]
}

# Walk an expression tree, returning every call to `fn`.
calls_to <- function(expr, fn) {
  found <- list()
  walk <- function(e) {
    if (is.call(e)) {
      if (identical(e[[1]], as.name(fn))) found[[length(found) + 1L]] <<- e
      for (i in seq_along(e)) if (!is.null(e[[i]])) walk(e[[i]])
    }
  }
  for (e in expr) walk(e)
  found
}

# Argument names of a call, as a character vector the same length as the
# argument list. names() is NULL when nothing is named, and `NULL == ""` is
# logical(0) -- which silently subsets a list to nothing rather than keeping
# everything. That zero-length recycling made the first version of this parser
# find only the calls that happened to carry a `field =` argument.
arg_names <- function(a) {
  nm <- names(a)
  if (is.null(nm)) rep("", length(a)) else nm
}

# Registry keys the vignette hands to a style resolver, i.e. layers it draws.
drawn_keys <- function(expr) {
  cl <- calls_to(expr, "gq_tmap_style")
  keys <- vapply(cl, function(e) {
    a <- as.list(e)[-1]
    positional <- a[arg_names(a) == ""]
    v <- Filter(is.character, positional)   # `reg` is a symbol; the key is not
    if (length(v)) as.character(v[[1]]) else NA_character_
  }, character(1))
  unique(stats::na.omit(keys))
}

# Registry keys the vignette hands to gq_tmap_legend() -- the character values
# of its `layers` argument, wherever they sit in the c(...) vector.
legend_keys <- function(expr) {
  cl <- calls_to(expr, "gq_tmap_legend")
  unique(unlist(lapply(cl, function(e) {
    a <- as.list(e)[-1]
    a <- a[!arg_names(a) %in% c("present", "reg")]
    vecs <- Filter(function(x) is.call(x) && identical(x[[1]], as.name("c")), a)
    unlist(lapply(vecs, function(v) {
      vals <- as.list(v)[-1]
      as.character(unlist(Filter(is.character, vals)))
    }))
  })))
}

# A drawn layer may one day be legitimately absent from the legend -- an
# inset-only fill, say. Each exemption needs a REASON: an ignored entry without
# one is a backlog note pretending to be a decision, and gets re-litigated at
# every review.
#
# EMPTY IS THE CORRECT STATE, and it is load-bearing. The first draft of this
# file listed all nine drawn layers here with the reason "drawn and legended",
# which exempts everything and makes the assertion below incapable of ever
# failing. A guard that cannot go red is decoration; only add a name here when a
# layer genuinely should not be legended, and say why.
legend_exempt <- character(0)

test_that("gq-tmap-composition draws no registry layer it fails to legend", {
  vd <- vignette_dir()
  # Assert the premise. If the source cannot be found this test must fail, not
  # skip -- a coverage guard that silently checks nothing is worse than none.
  expect_false(is.na(vd))

  f <- file.path(vd, "gq-tmap-composition.Rmd")
  expect_true(file.exists(f))
  code <- chunk_code(readLines(f, warn = FALSE), "map-composition")
  expr <- parse(text = code)

  drawn <- drawn_keys(expr)
  legended <- legend_keys(expr)

  # The parser must actually be finding things; a broken regex would make the
  # setdiff empty and the assertion pass for nothing.
  expect_gt(length(drawn), 3)
  expect_gt(length(legended), 3)

  missing <- setdiff(drawn, c(legended, names(legend_exempt)))
  expect_equal(missing, character(0))
})

test_that("the coverage guard actually fires on an unlegended layer", {
  # Restore the bug: a layer that is drawn and not listed. Without this the test
  # above is indistinguishable from one whose regexes match nothing.
  expr <- parse(text = c(
    'do.call(tm_lines, gq_tmap_style(reg, "streams_salmon"))',
    '# a comment naming gq_tmap_legend( and gq_tmap_style(reg, "decoy")',
    'do.call(tm_dots, gq_tmap_style(reg, "a_layer_nobody_legended"))',
    "leg <- gq_tmap_legend(",
    "  reg,",
    '  c("Stream" = "streams_salmon"),',
    '  present = list(roads_dra = "RH1")',
    ")"
  ))
  drawn <- drawn_keys(expr)
  legended <- legend_keys(expr)

  # The decoy proves comments are not being read as code, which the first draft
  # of this parser did.
  expect_false("decoy" %in% drawn)
  # `present` values are arguments, not layer keys.
  expect_false("RH1" %in% legended)

  expect_true("a_layer_nobody_legended" %in% drawn)
  expect_true("streams_salmon" %in% legended)
  expect_equal(setdiff(drawn, legended), "a_layer_nobody_legended")
})
