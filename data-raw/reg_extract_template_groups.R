# Extract inst/registry/template_groups.csv from the QGIS templates.
#
# The witness for gq's declared group composition. `templates.csv` says which
# groups a project has and in what order; nothing ever checked that against a
# project, so it drifted into fiction — three groups declared that no template
# has, two the templates have that gq never declared, and four names that differ
# by case or separator (gq#66).
#
# The source `.qgs` files live in the private `rfp` package, and gq is public, so
# CI can never read one. Same answer as the QML corpus and the theme roster: a
# DEV-ONLY / build-time dependency on rfp, with the committed CSV as the shipped
# source of truth. Structural guards run against the committed file everywhere;
# the live comparison, test-vendored_currency.R, runs only when RFP_TEMPLATE_DIR
# points at an rfp checkout (gq#78).
#
# This script also writes template_layers.csv, the same walk's layer rows
# (gq#68).
#
# Run after the templates change:
#   Rscript data-raw/reg_extract_template_groups.R
#
# Provenance note: the rfp version used is printed on each run and recorded in
# the commit message rather than in the CSV. read.csv() sets comment.char = "",
# so a leading "#" line would have to be parsed around by every reader.

devtools::load_all()

templates <- c("bcfishpass_mobile", "bcrestoration_mobile")

# `RFP_TEMPLATE_DIR` points at inst/templates in an rfp SOURCE CHECKOUT, for the
# case the table is regenerated against a tree that has not been released yet.
# Without it system.file() resolves to the INSTALLED rfp, which is routinely
# behind — the same trap reg_extract_themes.R documents, where installed 0.25.1
# and a 0.30.1 checkout disagree about the same template.
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
      "rfp not installed — needed only to regenerate this table. Install with ",
      "pak::pak('NewGraphEnvironment/rfp'), or set RFP_TEMPLATE_DIR to a ",
      "checkout's inst/templates.",
      call. = FALSE
    )
  }
  message("Using installed rfp ", as.character(utils::packageVersion("rfp")),
          ": ", tpl_dir)
}

groups <- template_groups_build(tpl_dir, templates)

# No sibling-order uniqueness check here: `order` is the sibling loop index, so
# it is distinct within a parent by construction. Asserting it would be a guard
# that cannot fail — which reads as diligence and is worse than nothing. The
# assertion that CAN fail is the round-trip inside vendored_write().

# QUOTED, unlike groups.csv and templates.csv were before gq#66. The correct
# group name is "Roads,Railways,Pipelines" — a comma inside an unquoted field
# would silently shift every later column — and
# "Project Specific/Model Parameters - bcfishpass " ends in a space that only
# quoting preserves through a round-trip. The builder and the writer live in
# R/utils_vendored.R so the currency test serializes exactly as this does.
vendored_write(groups, "inst/registry/template_groups.csv", quote = TRUE)

message(
  "template_groups.csv built: ", nrow(groups), " groups across ",
  length(templates), " templates (",
  paste(sprintf("%s %d", templates,
                vapply(templates, function(t) sum(groups$template == t),
                       integer(1))), collapse = ", "), ")"
)


# --- template_layers.csv: where each layer sits (gq#68) ------------------------
#
# Same walk, the layer rows. The witness for layer PLACEMENT, which the group
# table cannot see: a layer filed under the wrong group changes what it draws
# over, and test-template_drift.R compares each groups.csv row against this.
layers <- template_layers_build(tpl_dir, templates)

# Quoted for the reasons above, and because display names carry leading spaces.
vendored_write(layers, "inst/registry/template_layers.csv", quote = TRUE)

message(
  "template_layers.csv built: ", nrow(layers), " layers across ",
  length(templates), " templates (",
  paste(sprintf("%s %d", templates,
                vapply(templates, function(t) sum(layers$template == t),
                       integer(1))), collapse = ", "), ")"
)
