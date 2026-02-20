# Package setup tracking
# Run these interactively — they are NOT idempotent

# 1. Package scaffold
usethis::create_package(".")
usethis::use_mit_license("New Graph Environment Ltd.")

# 2. Testing
usethis::use_testthat(edition = 3)

# 3. Documentation site
usethis::use_pkgdown()
usethis::use_github_action("pkgdown")

# 4. Dev directory (self-referential)
usethis::use_directory("dev")
usethis::use_directory("data-raw")

# 5. Hex sticker (reads package name from DESCRIPTION — zero edits needed)
source("data-raw/make_hexsticker.R")

# 6. Dependencies
usethis::use_package("jsonlite")
usethis::use_package("xml2")
usethis::use_package("rlang", type = "Suggests")

# 7. Tests
usethis::use_test("gq_registry_read")
usethis::use_test("gq_qgs_extract")
usethis::use_test("gq_tmap_style")
usethis::use_test("gq_mapgl_style")

# 8. Build
devtools::document()
devtools::test()
devtools::check()
