# Rebuild inst/registry/reg_main.json from source registries
#
# Run this script after updating any source registry:
#   Rscript data-raw/build_reg_main.R
#
# Sources (priority order — later wins for duplicate keys):
#   1. inst/registry/reg_qgis_restoration.json  (QGIS extraction)
#   2. inst/registry/reg_custom.csv          (hand-curated)
#
# To add a new source, append it to the merge call below.

devtools::load_all()

rs <- gq_reg_read("inst/registry/reg_qgis_restoration.json")
csv_reg <- gq_reg_custom("inst/registry/reg_custom.csv")

master <- gq_reg_merge(rs, csv_reg)
master$name <- "main"
master$source <- "reg_qgis_restoration.json + reg_custom.csv"


# --- Upstream label correction: bcfishpass#13 --------------------------------
#
# `mapping_code` is `<habitat use>;<barrier status>[;INTERMITTENT]`. The source
# QGIS project labels token1 `ACCESS` with the token2 vocabulary -- "No known
# barriers" -- so every ACCESS class reads back as "No known barriers; known
# barrier", which contradicts itself in a legend. `SPAWN` -> "Spawning" and
# `REAR` -> "Rearing" are correct, as is every token2 status.
#
# This is not a gq defect. The bug is authored in qgis/bcfishpass_30k.qlr,
# reaches gq through the rfp .qgs templates, and `gq_qgs_extract()` copies the
# category label verbatim, which is the right behaviour. Tracked at source
# in NewGraphEnvironment/bcfishpass#13, which carries the full class table.
#
# Correcting it here rather than waiting was a deliberate call: three consumer
# repos had each independently hand-rolled a token decoder to work around it,
# which is precisely the duplication the registry exists to prevent.
#
# DELETE THIS BLOCK once bcfishpass#13 lands and the rfp templates are
# regenerated. The guard below tells you when that has happened -- it stops,
# rather than quietly correcting nothing and living here forever.

bad_prefix <- "No known barriers; "
good_prefix <- "Accessible; "

n_corrected <- 0L
n_already_good <- 0L
n_unrecognised <- 0L

for (key in names(master$layers)) {
  cls <- master$layers[[key]]$classification$classes
  if (is.null(cls)) next

  for (cv in grep("^ACCESS;", names(cls), value = TRUE)) {
    lab <- cls[[cv]]$label
    if (is.null(lab) || is.na(lab)) next

    if (startsWith(lab, bad_prefix)) {
      master$layers[[key]]$classification$classes[[cv]]$label <-
        paste0(good_prefix, substring(lab, nchar(bad_prefix) + 1L))
      n_corrected <- n_corrected + 1L
    } else if (startsWith(lab, good_prefix)) {
      n_already_good <- n_already_good + 1L
    } else {
      n_unrecognised <- n_unrecognised + 1L
      message("  unrecognised ACCESS label: ", key, " / ", cv, " -> ", lab)
    }
  }
}

# Fail toward "something changed", never toward "nothing to do". A correction
# that silently matches nothing is indistinguishable from a working one, and
# outlives the bug it was written for.
if (n_corrected == 0L) {
  stop("No ACCESS labels needed correcting (", n_already_good,
       " already read 'Accessible; ').\n",
       "  If bcfishpass#13 has landed and the rfp templates were regenerated, ",
       "delete this block.\n",
       "  If it has not, the class keys have changed and this correction is ",
       "no longer finding them.",
       call. = FALSE)
}
if (n_unrecognised > 0L) {
  stop(n_unrecognised, " ACCESS label(s) matched neither the buggy nor the ",
       "corrected prefix -- see above. Upstream wording has changed; ",
       "re-check bcfishpass#13 before trusting this correction.",
       call. = FALSE)
}
message("ACCESS labels corrected (bcfishpass#13): ", n_corrected)

jsonlite::write_json(master, "inst/registry/reg_main.json",
                     pretty = TRUE, auto_unbox = TRUE)

conflicts <- attr(master, "conflicts")
if (!is.null(conflicts) && nrow(conflicts) > 0) {
  message("Conflicts detected:")
  print(conflicts)
} else {
  message("reg_main.json built: ", length(master$layers), " layers, 0 conflicts")
}
