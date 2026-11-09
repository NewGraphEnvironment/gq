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

# Locate a vignette SOURCE file across the layouts it actually lives in.
#
# Test for the file, never for a `vignettes/` directory. The first version of
# this walked up looking for the directory and, under R CMD check, matched an
# unrelated one further up the temp tree -- so it reported "found" and then died
# in readLines(). A directory of the right name is not evidence.
#
# Three real layouts: devtools::test() from tests/testthat/ in the source tree;
# R CMD check running from the unpacked tarball, which ships vignettes/ as well
# as inst/doc/ once vignettes are built; and the installed package, where the
# source is reachable as system.file("doc", ...).
#
# Tarball FIRST, as build_root() in test-build_hygiene.R does and for the same
# reason: `R CMD check` run from inside the repo puts gq.Rcheck/ in the repo, so
# a source-first walk reaches the real vignettes/ three levels up and the
# tarball's copy is never read. Under check the working directory is
# <pkg>.Rcheck/tests/testthat, so 00_pkg_src sits two levels up, not one. The
# single hardcoded `../00_pkg_src` this replaced never existed, and the guard
# only ran because system.file() caught it (gq#80).
#
# Returns the path AND which layout answered, so a test can assert the branch it
# expects was the one taken rather than whichever fallback happened to exist.
vignette_source <- function(file) {
  up <- c("..", "../..", "../../..")
  cand <- list(
    tarball = file.path(up, "00_pkg_src", "gq", "vignettes", file),
    source = file.path(c(up, "../../../.."), "vignettes", file),
    installed = system.file("doc", file, package = "gq")
  )
  for (layout in names(cand)) {
    p <- cand[[layout]]
    hit <- p[nzchar(p) & file.exists(p)]
    if (length(hit)) {
      return(list(path = normalizePath(hit[[1]]), layout = layout))
    }
  }
  list(path = NA_character_, layout = NA_character_)
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

# Every string constant in an expression that names a colour: a hex value or a
# name R knows (grDevices::colors()). Parsed, so comments are never read.
colour_literals <- function(expr) {
  out <- character()
  walk <- function(e) {
    if (is.character(e)) {
      out <<- c(out, e)
    } else if (is.call(e)) {
      for (i in seq_along(e)) if (!is.null(e[[i]])) walk(e[[i]])
    }
  }
  for (e in expr) walk(e)
  is_col <- grepl("^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$", out) |
    tolower(out) %in% grDevices::colors()
  unique(out[is_col])
}

# One check per vignette map. `min_drawn` is per map: the parser must be shown
# to find things (a broken matcher makes the setdiff empty and the assertion
# pass for nothing), and how many layers a map draws through the registry is a
# fact about that map. gq-intro draws three that way; streams and railway are
# coloured from registry values by hand, which drawn_keys() does not see.
legend_coverage <- function(file, chunk, min_drawn) {
  f <- vignette_source(file)$path

  # The one case where this legitimately cannot run: a build that ships no
  # vignette source at all (R CMD check --no-build-vignettes). Skip visibly
  # rather than pass quietly -- and note that the parser logic itself is still
  # covered unconditionally by the test below, so a skip here never leaves the
  # guard entirely unexercised.
  testthat::skip_if(is.na(f), "vignette source not shipped in this build")

  code <- chunk_code(readLines(f, warn = FALSE), chunk)
  expr <- parse(text = code)

  drawn <- drawn_keys(expr)
  legended <- legend_keys(expr)

  testthat::expect_gte(length(drawn), min_drawn)
  testthat::expect_gte(length(legended), min_drawn)

  missing <- setdiff(drawn, c(legended, names(legend_exempt)))
  testthat::expect_equal(missing, character(0))
  invisible(code)
}

test_that("gq-tmap-composition draws no registry layer it fails to legend", {
  legend_coverage("gq-tmap-composition.Rmd", "map-composition", min_drawn = 4)
})

test_that("gq-intro draws no registry layer it fails to legend (gq#62)", {
  code <- legend_coverage("gq-intro.Rmd", "map-intro", min_drawn = 3)

  # gq-intro's map had no registry legend and hand-typed every road, stream and
  # railway colour until gq#62. A colour typed into the chunk is one the
  # registry no longer governs. Read from the PARSED chunk, so a named colour
  # ("red") counts as well as a hex one; matching only `#rrggbb` let "white"
  # through unseen. Each allowed colour is one the registry has no entry for.
  allowed <- c(
    "#2c3e50" = "the watershed outline",
    white = "the exterior mask, the railway's dashes and the legend box",
    grey30 = "the tile credit text"
  )
  cols <- colour_literals(parse(text = code))
  expect_gt(length(cols), 0)   # premise: the reader finds colours at all
  expect_equal(setdiff(cols, names(allowed)), character(0))
})

test_that("the colour reader sees named and hex colours, not comments", {
  cols <- colour_literals(parse(text = c(
    'tm_lines(col = "red", lwd = 2)',
    '# col = "blue" in a comment',
    'tm_text("gnis_name", col = "#1A5276")'
  )))
  expect_setequal(cols, c("red", "#1A5276"))
})

test_that("under R CMD check the vignette is read from the unpacked tarball (gq#80)", {
  # The branch has to be shown to be TAKEN, not merely present. When the
  # 00_pkg_src candidate was wrong, the guard above still ran -- on the
  # installed copy -- so nothing failed and the dead line read as coverage.
  # Asserting the layout is what tells the two candidates apart.
  #
  # Keyed on testthat::is_checking() rather than on finding 00_pkg_src: a guard
  # that skips when it cannot find the tree would skip, not fail, if the search
  # and the resolver were wrong in the same way. Under check, no tree is a
  # failure.
  skip_if_not(testthat::is_checking(), "not running under R CMD check")
  # R CMD check unpacks 00_pkg_src only for a TARBALL; a check run on a source
  # directory has none, and failing there would be failing for nothing. The
  # tarball case is told apart by the installed DESCRIPTION's `Packaged:` field,
  # which R CMD build writes and a directory install lacks (measured: absent from
  # `R CMD INSTALL <dir>`, present from the built tarball).
  skip_if(is.null(utils::packageDescription("gq")[["Packaged"]]),
          "R CMD check of a source directory: no tarball unpacked")
  pkg_src <- file.path(c("..", "../..", "../../.."), "00_pkg_src", "gq")
  pkg_src <- pkg_src[dir.exists(pkg_src)]
  expect_gt(length(pkg_src), 0)
  skip_if(!length(pkg_src))  # the expectation above has already failed

  v <- vignette_source("gq-tmap-composition.Rmd")
  expect_identical(v$layout, "tarball")
  expect_true(startsWith(v$path, normalizePath(pkg_src[[1]])))
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
