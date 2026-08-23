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

# `RFP_TEMPLATE` points at a template in an rfp SOURCE CHECKOUT, for the case
# this registry is regenerated against a style that has not been released yet.
# Without it `system.file()` resolves to the INSTALLED rfp, which is routinely
# behind: when the trail style was added the installed copy was three releases
# old and its template carried no trail layer at all, so the extraction would
# have silently produced a registry missing the very layer it was run for.
qgs <- Sys.getenv("RFP_TEMPLATE", "")
if (nzchar(qgs)) {
  if (!file.exists(qgs)) {
    stop("RFP_TEMPLATE does not exist: ", qgs, call. = FALSE)
  }
  message("Using RFP_TEMPLATE (source checkout): ", qgs)
} else {
  qgs <- system.file("templates", "bcrestoration_mobile.qgs", package = "rfp")
  if (qgs == "") {
    stop(
      "rfp not installed — needed only to regenerate this registry. Install with ",
      "pak::pak('NewGraphEnvironment/rfp'), or set RFP_TEMPLATE to a checkout.",
      call. = FALSE
    )
  }
  message("Using installed rfp ", as.character(utils::packageVersion("rfp")),
          ": ", qgs)
}

reg <- gq_qgs_extract(qgs)

jsonlite::write_json(reg, "inst/registry/reg_qgis_restoration.json",
                     pretty = TRUE, auto_unbox = TRUE)

message("reg_qgis_restoration.json built: ", length(reg$layers), " layers")
