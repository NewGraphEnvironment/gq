# Extract inst/registry/themes.csv from the QGIS templates.
#
# Provenance for the theme roster. The source `.qgs` files live in the private
# `rfp` package (it ships the Mergin/QGIS field templates), so regenerating
# requires rfp. This is a DEV-ONLY / build-time dependency — the committed CSV
# is the shipped source of truth, and gq consumers never need rfp or the `.qgs`.
#
# QGIS stores a map theme as a <visibility-preset> that enumerates
# <layer id=... visible="0|1"/> per layer. Group state appears only in
# <checked-group-nodes>, a slash-path record of layer-tree UI state, and is
# deliberately ignored here: it is not the visibility model.
#
# Layer ids are <sanitized-name>_<uuid>, and the sanitization is lossy (Esri
# World Imagery ships with the display name "Esri Satellite"), so the id stem is
# NOT a usable key. Resolve id -> <maplayer><layername> -> normalize_layer_name()
# instead, which is the same rule gq_qgs_extract() keys the registry with.
#
# Run after the templates change:
#   Rscript data-raw/reg_extract_themes.R
#
# Run for gq#88, against rfp 0.76.0, after rfp re-saved the presets to
# carry the other three xyz basemaps and `Trails` present-and-off: 268 rows over
# 9 template-theme pairs. Last run for gq#100, against rfp 0.93.0: byte-identical
# to that output.
#
# Provenance note: the rfp version used is printed on each run and recorded in
# the commit message rather than in the CSV. read.csv() sets comment.char = "",
# so a leading "#" line would have to be parsed around by every reader.

devtools::load_all()

templates <- c("bcfishpass_mobile", "bcrestoration_mobile")

# `RFP_TEMPLATE_DIR` points at inst/templates in an rfp SOURCE CHECKOUT, for the
# case the roster is regenerated against presets that have not been released
# yet. Without it system.file() resolves to the INSTALLED rfp, which is
# routinely behind — and the two disagree: the installed 0.25.1 and a 0.30.1
# checkout report different visible-counts for the same theme, so a test
# asserting a count against "whatever is installed" pins an undeclared
# dependency.
tpl_dir <- Sys.getenv("RFP_TEMPLATE_DIR", "")
if (nzchar(tpl_dir)) {
  if (!dir.exists(tpl_dir)) {
    stop("RFP_TEMPLATE_DIR does not exist: ", tpl_dir, call. = FALSE)
  }
  message("Using RFP_TEMPLATE_DIR (source checkout): ", tpl_dir)
} else {
  tpl_dir <- system.file("templates", package = "rfp")
  if (tpl_dir == "") {
    stop(
      "rfp not installed — needed only to regenerate this roster. Install with ",
      "pak::pak('NewGraphEnvironment/rfp'), or set RFP_TEMPLATE_DIR to a ",
      "checkout's inst/templates.",
      call. = FALSE
    )
  }
  message("Using installed rfp ", as.character(utils::packageVersion("rfp")),
          ": ", tpl_dir)
}

# The walker (qgs_theme_table()) and the builder (themes_build()) live in R/
# so the currency test can run them on the live templates and on a perturbed
# fixture (gq#78). themes_build() refuses a theme layer groups.csv lacks, a
# duplicate row, and a comma in any field; the CSV is written unquoted,
# matching groups.csv and templates.csv.
group_keys <- unique(read.csv("inst/registry/groups.csv",
                              stringsAsFactors = FALSE)$layer_key)
themes <- themes_build(tpl_dir, templates, group_keys)
vendored_write(themes, "inst/registry/themes.csv", quote = FALSE)

message(
  "themes.csv built: ", nrow(themes), " rows, ",
  nrow(unique(themes[c("template", "theme")])), " template-theme pairs"
)
