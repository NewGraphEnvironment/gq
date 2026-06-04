# Extract inst/registry/reg_qgis_restoration.json from the QGIS template.
#
# Provenance for the restoration source registry. The source `.qgs` lives in the
# private `rfp` package (it ships the Mergin/QGIS field templates), so
# regenerating requires rfp installed. This is a DEV-ONLY / build-time
# dependency — the committed JSON is the shipped source of truth, and gq
# consumers (tmap, mapgl, link) never need rfp or the `.qgs`. That decoupling is
# the point: gq owns the canonical styles; rfp owns the upstream project.
#
# Run after changing the extractor (R/gq_qgs_extract.R) or the template, then
# rebuild the master registry with data-raw/reg_build_main.R:
#   Rscript data-raw/reg_extract_restoration.R
#   Rscript data-raw/reg_build_main.R

devtools::load_all()

qgs <- system.file("templates", "bcrestoration_mobile.qgs", package = "rfp")
if (qgs == "") {
  stop(
    "rfp not installed — needed only to regenerate this registry. Install with ",
    "pak::pak('NewGraphEnvironment/rfp')",
    call. = FALSE
  )
}

reg <- gq_qgs_extract(qgs)

jsonlite::write_json(reg, "inst/registry/reg_qgis_restoration.json",
                     pretty = TRUE, auto_unbox = TRUE)

message("reg_qgis_restoration.json built: ", length(reg$layers), " layers")
