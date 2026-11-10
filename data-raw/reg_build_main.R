# Rebuild inst/registry/reg_main.json from source registries
#
# Run this script after updating any source registry:
#   Rscript data-raw/reg_build_main.R
#
# Sources (priority order -- later wins for duplicate keys):
#   1. inst/registry/reg_qgis_restoration.json  (QGIS extraction)
#   2. inst/registry/reg_custom.csv             (hand-curated)
#
# The merge and the bcfishpass#13 label correction are reg_main_build() in
# R/utils_reg_build.R, and the writer is reg_json_write(), so
# tests/testthat/test-reg_build_currency.R rebuilds with the same code and fails
# when reg_main.json was not rebuilt after a source changed (#11). To add a
# source, add it there.

devtools::load_all()

master <- reg_main_build("inst/registry/reg_qgis_restoration.json",
                         "inst/registry/reg_custom.csv")
reg_json_write(master, "inst/registry/reg_main.json")

conflicts <- attr(master, "conflicts")
if (!is.null(conflicts) && nrow(conflicts) > 0) {
  message("Conflicts detected:")
  print(conflicts)
} else {
  message("reg_main.json built: ", length(master$layers), " layers, 0 conflicts")
}
