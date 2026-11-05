# gq's rfp-vendored rosters equal what rfp says now (gq#78).
#
# A guard that compares against a vendored copy cannot see the copy go stale:
# test-template_drift.R read template_groups.csv while it sat frozen for two
# months, green throughout (gq#70), and themes.csv held a stale answer for a
# release the same way (gq#77). These checks rebuild each roster from a live rfp
# source with the generator's own builder and writer (R/utils_vendored.R) and
# compare the FILE, line for line, with the committed one.
#
# Gated on the RFP_*_DIR variables ONLY, with no fallback to an installed rfp:
# an installed rfp is routinely behind the checkout a roster was vendored from,
# so comparing against it fails falsely on any machine with an old install. A
# skip is not a pass -- CI never has rfp, since gq is public and rfp private --
# so detection belongs in rfp's CI, which can clone gq with no credential.
#
#   RFP_TEMPLATE_DIR=<rfp>/inst/templates RFP_LOOKUPS_DIR=<rfp>/inst/lookups \
#     Rscript -e 'devtools::test(filter = "vendored_currency")'
#
# The QML corpus is vendored too, beside these four rosters, and its byte
# comparison stays in test-gq_style_qml.R: rfp's open issue moving the store
# into gq drops that comparison, so moving it here first would be work done
# twice.

templates <- c("bcfishpass_mobile", "bcrestoration_mobile")

rfp_source <- function(var) {
  d <- Sys.getenv(var, "")
  testthat::skip_if(!nzchar(d), paste0(var, " unset: no rfp source to compare against"))
  testthat::skip_if_not(dir.exists(d), paste0(var, " does not exist: ", d))
  d
}

#' Lines of the committed roster, and of the same roster rebuilt live
roster_lines <- function(df, file, quote) {
  committed <- system.file("registry", file, package = "gq")
  if (committed == "") stop(file, " not found - reinstall gq", call. = FALSE)
  live <- tempfile(fileext = ".csv")
  on.exit(unlink(live), add = TRUE)
  vendored_write(df, live, quote = quote)
  list(committed = readLines(committed), live = readLines(live))
}


test_that("template_groups.csv is what the templates say now", {
  dir <- rfp_source("RFP_TEMPLATE_DIR")
  r <- roster_lines(template_groups_build(dir, templates),
                    "template_groups.csv", quote = TRUE)
  expect_identical(r$committed, r$live,
                   info = "re-run data-raw/reg_extract_template_groups.R")
})


test_that("template_layers.csv is what the templates say now", {
  dir <- rfp_source("RFP_TEMPLATE_DIR")
  r <- roster_lines(template_layers_build(dir, templates),
                    "template_layers.csv", quote = TRUE)
  expect_identical(r$committed, r$live,
                   info = "re-run data-raw/reg_extract_template_groups.R")
})


test_that("themes.csv is what the templates say now", {
  dir <- rfp_source("RFP_TEMPLATE_DIR")
  r <- roster_lines(themes_build(dir, templates, gq_groups()$layer_key),
                    "themes.csv", quote = FALSE)
  expect_identical(r$committed, r$live,
                   info = "re-run data-raw/reg_extract_themes.R")
})


test_that("form_types.csv is what rfp's form roster says now", {
  dir <- rfp_source("RFP_LOOKUPS_DIR")
  r <- roster_lines(form_types_build(file.path(dir, "rfp_form_types.csv")),
                    "form_types.csv", quote = TRUE)
  expect_identical(r$committed, r$live,
                   info = "re-run data-raw/reg_extract_form_types.R")
})


# --- the alarm has been seen to fire ------------------------------------------
#
# The live checks skip everywhere rfp is absent, so the comparison they make is
# shown failing here, on a committed fixture, where it always runs.

test_that("a switched layer in a map theme is reported", {
  path <- test_path("fixtures", "themes_fixture.qgs")
  skip_if_not(file.exists(path), "fixture missing")

  live <- qgs_theme_table(path, "bcrestoration_mobile")
  expect_setequal(live$layer_key, c("lake", "wetland"))   # premise: ids resolved

  shipped <- gq_themes("bcrestoration_mobile")
  shipped <- shipped[shipped$theme == "Land Tenure", ]
  m <- merge(live, shipped, by = c("template", "theme", "layer_key"),
             suffixes = c(".live", ".shipped"))
  expect_equal(nrow(m), 2L)                               # premise: both join

  changed <- m$layer_key[m$visible.live != m$visible.shipped]
  # The fixture switched `lake` off; `wetland` kept its shipped state, so the
  # comparison is discriminating rather than always-true.
  expect_identical(changed, "lake")
})


test_that("a theme naming a layer groups.csv lacks is refused", {
  # themes_build() refuses rather than drops: a silent drop is how the roster
  # became fiction. Copy the fixture under a template's name, then take
  # `wetland` out of the keys groups.csv is said to carry.
  dir <- withr::local_tempdir()
  file.copy(test_path("fixtures", "themes_fixture.qgs"),
            file.path(dir, "bcrestoration_mobile.qgs"))
  keys <- setdiff(gq_groups()$layer_key, "wetland")
  expect_error(themes_build(dir, "bcrestoration_mobile", keys),
               "absent from groups.csv: wetland")
  # And with the full key set the same call builds.
  expect_s3_class(themes_build(dir, "bcrestoration_mobile",
                               gq_groups()$layer_key), "data.frame")
})


test_that("the form builder refuses a roster it cannot represent", {
  dir <- withr::local_tempdir()
  f <- file.path(dir, "rfp_form_types.csv")
  # rfp's header at 0.93.0; the builder reads columns by name.
  hdr <- paste0("type,description,label,template_source,schema_source,",
                "geometry,symbol,color,label_expression,has_spatial,parent")

  # Every row spatial: the has_spatial vocabulary changed, or the check is
  # stale. Either way, not something to vendor silently.
  writeLines(c(hdr,
               "pscis,PSCIS,PSCIS,,s.csv,point,m,#000000,,true,",
               "fish_passage_monitoring,M,Fish Passage Monitoring,,s.csv,point,m,#000000,,true,"),
             f)
  expect_error(form_types_build(f), "matched every row")

  # Label and type agreeing everywhere: the label rule is no longer shown to
  # matter, so the derivation has lost its evidence.
  writeLines(c(hdr,
               "pscis,PSCIS,PSCIS,,s.csv,point,m,#000000,,true,",
               "pebble,P,Pebble,,s.csv,,m,#000000,,false,pscis"),
             f)
  expect_error(form_types_build(f), "distinguishes the label rule")

  # The live case: a type whose label reverses its words keys by the label.
  writeLines(c(hdr,
               "monitoring_fish_passage,M,Fish Passage Monitoring,,s.csv,point,m,#000000,,true,",
               "pebble,P,Pebble,,s.csv,,m,#000000,,false,pscis"),
             f)
  expect_identical(form_types_build(f)$layer_key,
                   "form_fish_passage_monitoring")
})
