# Every QML in the corpus is consistent with its own field roster (gq#86 tier 1).
#
# The byte-identity check in test-gq_style_qml.R catches gq falling behind rfp.
# It cannot catch a file both stores agree on, and bcfishobs shipped references
# to a column its table no longer has with that check green. This one needs no
# database: it holds each file's field references to the roster the same file
# declares in <fieldConfiguration>.
#
# WHICH references, measured over the corpus on 2026-11-05 (gq#100):
#
# * Tags that configure one field -- <alias>, <default>, <constraint>,
#   <constraintExpression>, <attributeEditorField> -- name a roster field in
#   every file. Those are held to the roster, and a miss fails.
#
# * <editable>, <labelOnTop>, <reuseLastValue> and the attribute table's
#   <column type="field"> are NOT. They are a snapshot of every column QGIS once
#   saw on the layer: 26 of the 53 vector files name fields there that their
#   roster lacks, 497 names in all (crossings_pscis_assessment alone, 70: the
#   uppercase WHSE columns of an older source). The 4 dangling
#   `fish_obsrvtn_pnt_distinct_id` tags #86 was filed for are in this class,
#   so no rule over these tags can single them out. They are left to the store
#   cleanup (rfp#188), not refused here.
#
# * An expression -- previewExpression, a label fieldName, a renderer attr --
#   may name a real column the style configures no widget for. The roster is a
#   SUBSET of the layer's columns, so "must be in the roster" would refuse the
#   correct `"species_name"` preview on bcfishobs. A bare reference outside the
#   roster is therefore UNDECIDABLE without the table, not wrong: it is pinned
#   below for a person with the table to settle (tier 2), and the pin fails
#   when one is added or goes away.

qml_files <- function() {
  dir <- system.file("styles", package = "gq")
  list.files(dir, "[.]qml$", recursive = TRUE, full.names = TRUE)
}

field_scoped_xpath <- c(
  alias                = "//aliases/alias/@field",
  default              = "//defaults/default/@field",
  constraint           = "//constraints/constraint/@field",
  constraintExpression = "//constraintExpressions/constraint/@field",
  attributeEditorField = "//attributeEditorField/@name"
)

#' A QML's field roster and the references this file checks against it
#'
#' Expressions count only when the whole expression is one field reference
#' (`"name"` or a bare identifier): anything with an operator or a call needs
#' an expression parser to read, and is out of scope rather than guessed at.
qml_field_refs <- function(path) {
  d <- xml2::read_xml(path)
  roster <- xml2::xml_attr(xml2::xml_find_all(d, "//fieldConfiguration/field"),
                           "name")
  scoped <- do.call(rbind, lapply(names(field_scoped_xpath), function(k) {
    v <- xml2::xml_text(xml2::xml_find_all(d, field_scoped_xpath[[k]]))
    if (length(v) == 0) return(NULL)
    data.frame(tag = k, ref = v, stringsAsFactors = FALSE)
  }))

  bare <- function(x) {
    x <- x[!is.na(x)]
    quoted <- grepl('^"[^"]+"$', x)
    plain <- grepl("^[A-Za-z_][A-Za-z0-9_]*$", x)
    c(sub('^"(.*)"$', "\\1", x[quoted]), x[plain & !quoted])
  }
  pe <- xml2::xml_text(xml2::xml_find_all(d, "//previewExpression"))
  lab <- xml2::xml_attr(xml2::xml_find_all(d, "//labeling//text-style[@fieldName]"),
                        "fieldName")
  attr <- xml2::xml_attr(xml2::xml_find_all(d, "//renderer-v2[@attr]"), "attr")
  expr <- unique(bare(c(pe, lab, attr)))

  list(roster = roster, scoped = scoped, expr = expr)
}

#' Field-scoped references outside the roster (fail) and bare expression
#' references outside it (undecidable), for one file
qml_consistency <- function(path) {
  r <- qml_field_refs(path)
  if (length(r$roster) == 0) {
    return(list(offenders = character(0), undecidable = character(0),
                n_checked = 0L))
  }
  sc <- if (is.null(r$scoped)) character(0) else r$scoped$ref
  list(offenders = unique(setdiff(sc, r$roster)),
       undecidable = setdiff(r$expr, r$roster),
       n_checked = length(sc) + length(r$expr))
}

# Bare expression references outside their file's roster, each needing the
# table to settle. A real column with no widget is legal; a dead one is not.
undecidable_pinned <- c(
  "bcfishobs_fiss_fish_observations.qml:species_name",
  "conservancy.qml:protected_lands_name",
  "first_nation_reserve.qml:IR_NAME",
  "national_park.qml:english_name",
  "old_growth_management_areas.qml:associated_act_name",
  "roads_dra.qml:structured_name_1_id"
)


test_that("the corpus is there to check", {
  # Premise: a sweep that has never returned a hit has proven nothing, and one
  # over no files proves less.
  fs <- qml_files()
  expect_gt(length(fs), 50)
  checked <- sum(vapply(fs, function(f) qml_consistency(f)$n_checked,
                        integer(1)))
  expect_gt(checked, 100)
})


test_that("every field-scoped tag names a field in its own roster", {
  off <- unlist(lapply(qml_files(), function(f) {
    o <- qml_consistency(f)$offenders
    if (length(o)) paste0(basename(f), ":", o)
  }))
  expect_identical(off, NULL)
})


test_that("bare expression references outside the roster are the pinned set", {
  und <- unlist(lapply(qml_files(), function(f) {
    u <- qml_consistency(f)$undecidable
    if (length(u)) paste0(basename(f), ":", u)
  }))
  # Both directions: a new one needs a person with the table; one that left
  # means the pin above is stale.
  expect_setequal(und, undecidable_pinned)
  # The negative control #86 asked for: the correct `species_name` preview is
  # undecidable here, never an offender.
  expect_true("bcfishobs_fiss_fish_observations.qml:species_name" %in% und)
})


test_that("a bad field-scoped reference is refused and a bad expression is not", {
  # Restore the defect on a copy of a file that is clean today.
  src <- file.path(system.file("styles", package = "gq"), "vector",
                   "conservancy.qml")
  skip_if_not(file.exists(src), "conservancy.qml missing")
  expect_identical(qml_consistency(src)$offenders, character(0))

  bad <- withr::local_tempfile(fileext = ".qml")
  x <- readLines(src)
  i <- grep("<aliases>", x, fixed = TRUE)[1]
  expect_false(is.na(i))                                   # premise
  x <- append(x, '    <alias field="no_such_field" index="99" name=""/>',
              after = i)
  x <- sub("<previewExpression>.*</previewExpression>",
           '<previewExpression>"no_such_column"</previewExpression>', x)
  writeLines(x, bad)

  res <- qml_consistency(bad)
  expect_identical(res$offenders, "no_such_field")
  # The expression is handed on, not refused: the roster is a subset of the
  # layer's columns, so a name outside it may still be real.
  expect_true("no_such_column" %in% res$undecidable)
})
