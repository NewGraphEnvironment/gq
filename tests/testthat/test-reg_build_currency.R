# reg_main.json is what its sources build (#11).
#
# reg_main.json is generated from reg_qgis_restoration.json and reg_custom.csv
# by data-raw/reg_build_main.R, and nothing used to notice when a source changed
# and the script was not re-run: every test that reads the registry reads the
# stale master and passes. #11 proposed a workflow that rebuilds and commits on
# main; a test was chosen instead, because a bot commit made with the Actions
# token starts no workflow run and fixes a stale source silently rather than
# showing it in review.
#
# The rebuild uses the script's own builder and writer (R/utils_reg_build.R) and
# compares the FILE, line for line: one fact derived once, as
# test-vendored_currency.R does for the rosters.

registry_file <- function(file) {
  path <- system.file("registry", file, package = "gq")
  if (path == "") stop(file, " not found - reinstall gq", call. = FALSE)
  path
}

# Lines of the master as `restoration` and `custom` build it.
rebuilt_lines <- function(restoration, custom) {
  master <- suppressMessages(reg_main_build(restoration, custom))
  live <- tempfile(fileext = ".json")
  on.exit(unlink(live), add = TRUE)
  reg_json_write(master, live)
  readLines(live)
}

test_that("reg_main.json is what its sources build", {
  live <- rebuilt_lines(registry_file("reg_qgis_restoration.json"),
                        registry_file("reg_custom.csv"))
  committed <- readLines(registry_file("reg_main.json"))

  # A rebuild that found nothing would compare an empty file with an empty one.
  expect_gt(length(live), 1000)
  expect_identical(
    live, committed,
    info = paste(
      "reg_main.json is stale: run `Rscript data-raw/reg_build_main.R`.",
      "If no source changed, a jsonlite formatting change does this too."
    )
  )
})

test_that("the currency check fails when a source changes and the master does not", {
  # Restore the bug: edit a source and do not rebuild. Without this the test
  # above could be comparing two things that cannot differ.
  dir <- tempfile("reg_src")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  file.copy(registry_file("reg_qgis_restoration.json"), dir)

  csv <- utils::read.csv(registry_file("reg_custom.csv"),
                         colClasses = "character", na.strings = character(0),
                         check.names = FALSE)
  row <- which(csv$layer_key == "bec_zone")[1]
  expect_false(is.na(row))
  csv$fill_color[row] <- "#000001"
  edited <- file.path(dir, "reg_custom.csv")
  utils::write.csv(csv, edited, row.names = FALSE)

  live <- rebuilt_lines(file.path(dir, "reg_qgis_restoration.json"), edited)
  committed <- readLines(registry_file("reg_main.json"))
  expect_false(identical(live, committed))
  expect_true(any(grepl("#000001", live, fixed = TRUE)))
})
