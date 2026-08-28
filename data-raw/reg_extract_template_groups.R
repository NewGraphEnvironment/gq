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
# the live comparison in test-template_drift.R skips when rfp is absent.
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

groups <- do.call(rbind, lapply(templates, function(template) {
  tbl <- qgs_group_table(file.path(tpl_dir, paste0(template, ".qgs")))
  if (nrow(tbl) == 0L) {
    stop("No groups in ", template, call. = FALSE)
  }
  cbind(template = template, tbl, stringsAsFactors = FALSE)
}))

groups <- groups[order(groups$template, groups$group_path), ]

# No sibling-order uniqueness check here: `order` is the sibling loop index, so
# it is distinct within a parent by construction. Asserting it would be a guard
# that cannot fail — which reads as diligence and is worse than nothing. The
# assertion that CAN fail is the round-trip below.


# QUOTED, unlike groups.csv and templates.csv were before gq#66. The correct
# group name is "Roads,Railways,Pipelines" — a comma inside an unquoted field
# would silently shift every later column — and
# "Project Specific/Model Parameters - bcfishpass " ends in a space that only
# quoting preserves through a round-trip.
write.csv(groups, "inst/registry/template_groups.csv", row.names = FALSE,
          quote = TRUE)

# Prove the round-trip rather than trusting it. A name whose trailing space is
# eaten still looks like a name, and the join it breaks reports nothing.
back <- utils::read.csv("inst/registry/template_groups.csv",
                        stringsAsFactors = FALSE)
if (!identical(back$group_path, groups$group_path)) {
  differing <- which(back$group_path != groups$group_path)
  stop("group_path did not survive the CSV round-trip: ",
       paste(sprintf("%s -> %s", groups$group_path[differing],
                     back$group_path[differing]), collapse = "; "),
       call. = FALSE)
}

message(
  "template_groups.csv built: ", nrow(groups), " groups across ",
  length(templates), " templates (",
  paste(sprintf("%s %d", templates,
                vapply(templates, function(t) sum(groups$template == t),
                       integer(1))), collapse = ", "), ")"
)
