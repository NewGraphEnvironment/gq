# Rebuild inst/registry/reg_main.json from source registries
#
# Run this script after updating any source registry:
#   Rscript data-raw/build_reg_main.R
#
# Sources (priority order — later wins for duplicate keys):
#   1. inst/registry/reg_qgis_restoration.json  (QGIS extraction)
#   2. inst/registry/reg_csv_custom.csv          (hand-curated)
#
# To add a new source, append it to the merge call below.

devtools::load_all()

rs <- gq_reg_read("inst/registry/reg_qgis_restoration.json")
csv_reg <- gq_reg_read_csv("inst/registry/reg_csv_custom.csv")

master <- gq_reg_merge(rs, csv_reg)
master$name <- "main"
master$source <- "reg_qgis_restoration.json + reg_csv_custom.csv"

jsonlite::write_json(master, "inst/registry/reg_main.json",
                     pretty = TRUE, auto_unbox = TRUE)

conflicts <- attr(master, "conflicts")
if (!is.null(conflicts) && nrow(conflicts) > 0) {
  message("Conflicts detected:")
  print(conflicts)
} else {
  message("reg_main.json built: ", length(master$layers), " layers, 0 conflicts")
}
