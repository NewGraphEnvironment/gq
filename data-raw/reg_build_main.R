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

# --- Upstream rename: bcfishobs observations (gq#82) -------------------------
#
# db_newgraph renamed the staged object. `jobs/dump_weekly` now writes
# `bcfishobs.observations.fgb.zip` from `select * from bcfishobs.observations`;
# the old name 404s in the bucket. rfp's .qgs templates still carry the old
# name in their maplayer datasource, so `gq_qgs_extract()` faithfully copies it
# into reg_qgis_restoration.json -- which is the right behaviour for a
# transcript of a template.
#
# Corrected here rather than in the extracted JSON for the same reason as the
# ACCESS block above: the JSON is a record of what the template says, and
# editing it would make it lie about its own provenance AND be silently
# reverted by the next re-extraction. reg_custom.csv is not the route either --
# gq_reg_merge() REPLACES a layer entry rather than merging its fields, so a
# one-column row would delete this layer's mark and label and it would draw as
# nothing.
#
# source_layer is three things at once: the S3 object stem, the GeoPackage
# table name, and the .qgs `layername=`. So this correction fixes the DOWNLOAD
# and the layer stays absent from the map until rfp updates its templates --
# tracked in the rfp issue named from gq#82.
#
# DELETE THIS BLOCK once rfp's templates are regenerated with the new name. The
# guard below tells you when that has happened.

obs_key <- "bcfishobs_fiss_fish_observations"
obs_old <- "bcfishobs.fiss_fish_obsrvtn_events_vw"
obs_new <- "bcfishobs.observations"

# `[[` on both hops, never `$`. A `$` read partial-matches, so if a future
# extraction produced `source_layer_qgis` and no `source_layer`, `$source_layer`
# would return it and the `else` arm below would stop with a message naming a
# value that is not the one it thinks it read.
obs_have <- master$layers[[obs_key]][["source_layer"]]
if (identical(obs_have, obs_old)) {
  master$layers[[obs_key]]$source_layer <- obs_new
  message("bcfishobs source_layer corrected (gq#82): ", obs_old, " -> ", obs_new)
} else if (identical(obs_have, obs_new)) {
  stop("bcfishobs already reads '", obs_new, "' in the extracted registry.\n",
       "  rfp's templates have been regenerated -- delete this block.",
       call. = FALSE)
} else {
  stop("bcfishobs source_layer is neither the old nor the new name: ",
       if (is.null(obs_have)) "<absent>" else obs_have, "\n",
       "  The layer key or the upstream name has moved; re-check gq#82 before ",
       "trusting this correction.", call. = FALSE)
}

jsonlite::write_json(master, "inst/registry/reg_main.json",
                     pretty = TRUE, auto_unbox = TRUE)

conflicts <- attr(master, "conflicts")
if (!is.null(conflicts) && nrow(conflicts) > 0) {
  message("Conflicts detected:")
  print(conflicts)
} else {
  message("reg_main.json built: ", length(master$layers), " layers, 0 conflicts")
}
