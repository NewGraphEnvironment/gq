# Extract inst/registry/form_types.csv from rfp's form-type roster.
#
# The catalogue of Mergin survey forms a project can carry. This is a SEPARATE
# table from groups.csv on purpose, and the reason is structural rather than
# tidiness.
#
# Forms are not baked into the templates. `rfp_qgs_form_add()` injects them per
# project, and rtj's scripts/gis/projects/<name>/project.yml selects which --
# nelson carries `forms: [trail_feature, viewscape, cabin_visit]`. So form
# membership is per-PROJECT, while groups.csv models per-TEMPLATE contents.
#
# Putting the whole roster into groups.csv would therefore make
# gq_template_layers() report 13 forms for a template that ships 2, which is
# exactly the gq#40 defect -- a project styled for layers it never downloaded --
# at six times the scale. groups.csv keeps the two the templates ship; this
# table is the catalogue they are drawn from. (gq#64)
#
# Like reg_extract_themes.R, reg_extract_template_groups.R and styles_vendor.R,
# this is a DEV-ONLY / build-time dependency on rfp. The committed CSV is the
# shipped source of truth and gq consumers never need rfp.
#
#   Rscript data-raw/reg_extract_form_types.R
#
# Provenance note: the rfp version and commit are printed on each run and
# recorded in the commit message rather than in the CSV. read.csv() sets
# comment.char = "", so a leading "#" line would have to be parsed around by
# every reader.

pkgload::load_all(quiet = TRUE)

# `RFP_LOOKUPS_DIR` points at inst/lookups in an rfp SOURCE CHECKOUT, for the
# case the roster is vendored from form types that have not been released yet.
# Without it system.file() resolves to the INSTALLED rfp, which is routinely
# behind -- measured 2026-08-29 at installed 0.36.0 against a 0.45.0 checkout.
#
# Point it at a CLEAN checkout. Generating from a working tree copies whatever
# a parallel session has half-finished into a gq commit, and the git status
# printed below is what tells you that happened.
src <- Sys.getenv("RFP_LOOKUPS_DIR", "")
if (nzchar(src)) {
  if (!dir.exists(src)) {
    stop("RFP_LOOKUPS_DIR does not exist: ", src, call. = FALSE)
  }
  message("Using RFP_LOOKUPS_DIR (source checkout): ", src)
} else {
  src <- system.file("lookups", package = "rfp")
  if (src == "") {
    stop(
      "rfp not installed — needed only to regenerate this roster. Install with ",
      "pak::pak('NewGraphEnvironment/rfp'), or set RFP_LOOKUPS_DIR to a ",
      "checkout's inst/lookups.",
      call. = FALSE
    )
  }
  message("Using installed rfp ", as.character(utils::packageVersion("rfp")),
          ": ", src)
}

path <- file.path(src, "rfp_form_types.csv")
if (!file.exists(path)) {
  stop("rfp_form_types.csv not found in ", src, call. = FALSE)
}

# Provenance, printed rather than stored. Two questions, and a clean answer to
# the first does not imply the second:
#
#   1. is the roster modified in the working tree?   git status --porcelain
#   2. does it match origin/main?                    git diff origin/main HEAD
#
# A checkout sitting on a feature branch can be perfectly clean and still hold a
# roster nobody has merged, so vendoring from it produces a gq commit that
# cannot be reproduced from rfp's main. Only the second check sees that.
#
# Every branch below reports the exit STATUS as well as the output, because a
# guard that cannot tell "the command failed" from "there is nothing to report"
# fails toward reassurance. `git status --porcelain` prints nothing both when
# the file is clean and when git refused to run, and the second is the case this
# whole function exists to notice.
#
# system2() shell-quotes the command but NOT the args, so `dir` and `file` are
# quoted here — an rfp checkout under a path containing a space otherwise
# reports as "not a git checkout" and every later check is skipped.
git_provenance <- function(dir, file) {
  git_out <- function(...) {
    out <- suppressWarnings(system2("git", c("-C", shQuote(dir), ...),
                                    stdout = TRUE, stderr = FALSE))
    if (!is.null(attr(out, "status")) && attr(out, "status") != 0L) NULL else out
  }
  git_ok <- function(...) {
    suppressWarnings(system2("git", c("-C", shQuote(dir), ...),
                             stdout = FALSE, stderr = FALSE)) == 0L
  }

  sha <- git_out("rev-parse", "--short", "HEAD")
  if (is.null(sha) || length(sha) != 1L) {
    message("!! rfp source is not a readable git checkout — ",
            "provenance UNVERIFIED, not verified-clean")
    return(invisible(NULL))
  }

  # Three states, not two: modified, clean, or the check itself did not run.
  status <- git_out("status", "--porcelain", "--", shQuote(file))
  dirty <- if (is.null(status)) NA else length(status) > 0L

  # `git diff --quiet` signals through its exit status, so read that rather than
  # its (always empty) stdout. A missing origin/main is its own answer, not a
  # pass.
  differs <- if (!git_ok("rev-parse", "--verify", "--quiet", "origin/main")) NA
             else !git_ok("diff", "--quiet", "origin/main", "HEAD", "--",
                          shQuote(file))

  branch <- paste(git_out("branch", "--show-current"), collapse = "")
  message(
    "rfp commit ", sha, if (nzchar(branch)) paste0(" on ", branch) else "",
    if (isTRUE(dirty)) "  *** UNCOMMITTED CHANGES to the roster ***"
    else if (is.na(dirty)) "  !! could not read working-tree status" else "",
    if (isTRUE(differs)) "  *** roster DIFFERS from origin/main ***"
    else if (is.na(differs)) "  !! no origin/main to compare against"
    else "  (roster matches origin/main)"
  )
}
git_provenance(src, path)

# trim_ws is readr's default and it is wrong here: `label` feeds a layer name
# whose leading space is deliberate. read.csv() does not trim quoted fields.
types <- utils::read.csv(path, stringsAsFactors = FALSE)

required <- c("type", "description", "label", "geometry", "symbol", "color",
              "label_expression", "has_spatial", "parent")
missing <- setdiff(required, names(types))
if (length(missing) > 0) {
  stop("rfp_form_types.csv missing expected columns: ",
       paste(missing, collapse = ", "), call. = FALSE)
}
if (nrow(types) == 0L) {
  stop("rfp_form_types.csv is empty", call. = FALSE)
}

# Non-spatial rows are child tables, not layers. cabin_visit_pebble is the live
# case: no geometry, parent = cabin_visit, written into the parent's GeoPackage
# and joined parent_uuid -> uuid. A layer roster must not carry it.
#
# Filtering on has_spatial rather than on an empty `geometry` because that is
# the column rfp uses to mean it, and the two could diverge.
n_all <- nrow(types)
spatial <- types[types$has_spatial == "true", , drop = FALSE]
if (nrow(spatial) == n_all) {
  stop("the has_spatial filter matched every row. Either rfp changed the ",
       "column's vocabulary (it is the literal string \"true\", not a logical), ",
       "or every non-spatial form has legitimately been removed upstream — in ",
       "which case delete this check rather than working around it.",
       call. = FALSE)
}

# The layer key is derived from rfp's OWN rule, not from the `type` column.
# `.rfp_form_layer_name()` (rfp/R/rfp_qgs_form_add.R) is paste0(" Form ",
# label), and gq keys a registry on normalize_layer_name() of the layer name.
#
# Type and label disagree, and not rarely: `monitoring_fish_passage` is
# labelled "Fish Passage Monitoring", so its key is
# form_fish_passage_monitoring -- the reverse word order. A key built from the
# type column is wrong there and NOTHING downstream would report it, because
# every lookup goes through the key on both sides. Hence the oracle below.
layer_name <- paste0(" Form ", spatial$label)
layer_key <- vapply(layer_name, normalize_layer_name, character(1),
                    USE.NAMES = FALSE)

if (anyDuplicated(layer_key) != 0L) {
  dup <- unique(layer_key[duplicated(layer_key)])
  stop("two form labels normalize to the same layer_key: ",
       paste(dup, collapse = ", "), call. = FALSE)
}

# The oracle. form_pscis and form_fiss_site reached reg_main.json through
# gq_qgs_extract() reading a .qgs that QGIS itself wrote, so those two keys are
# ground truth produced by the consumer rather than by this script's reasoning.
# If the derivation above is wrong, it is wrong here first.
reg <- gq_reg_main()
known <- intersect(c("form_pscis", "form_fiss_site"), names(reg$layers))
if (length(known) != 2L) {
  stop("expected form_pscis and form_fiss_site in reg_main.json as the ",
       "derivation oracle; found: ", paste(known, collapse = ", "),
       call. = FALSE)
}
if (!all(known %in% layer_key)) {
  stop("derived keys do not reproduce the keys QGIS produced: missing ",
       paste(setdiff(known, layer_key), collapse = ", "),
       ". Derived: ", paste(layer_key, collapse = ", "), call. = FALSE)
}

# The oracle above is necessary and NOT sufficient, which is worth being explicit
# about: paste0("form_", type) produces form_pscis and form_fiss_site identically,
# so those two rows cannot separate the correct rule from the wrong one. The
# check that can is that label and type genuinely disagree somewhere --
# monitoring_fish_passage is labelled "Fish Passage Monitoring", reversing the
# word order. If that stops being true, this script's whole reason for deriving
# from the label has gone with it, and it should be reconsidered rather than
# silently kept.
if (!any(layer_key != paste0("form_", spatial$type))) {
  stop("every derived key now equals paste0(\"form_\", type), so nothing in ",
       "this roster distinguishes the label rule from the type rule. Either ",
       "rfp relabelled its forms, or the derivation regressed.", call. = FALSE)
}

# `parent` is dropped rather than carried: it is populated only on
# cabin_visit_pebble, which the spatial filter removes, so it would ship as a
# column with no values in any row. A column that cannot vary says nothing and
# invites a reader to infer a relationship the table does not model.
forms <- data.frame(
  layer_key = layer_key,
  form_type = spatial$type,
  label = spatial$label,
  description = spatial$description,
  layer_name = layer_name,
  geometry = spatial$geometry,
  symbol = spatial$symbol,
  color = spatial$color,
  label_expression = spatial$label_expression,
  stringsAsFactors = FALSE
)
forms <- forms[order(forms$layer_key), ]

# QUOTED, for three separate reasons, any one of which is sufficient:
# label_expression contains commas AND embedded double quotes; layer_name
# begins with a deliberate space; description contains commas.
utils::write.csv(forms, "inst/registry/form_types.csv", row.names = FALSE,
                 quote = TRUE)

# Prove the round-trip rather than trusting it.
#
# What this actually guards is QUOTING, not whitespace. read.csv() does not trim
# a quoted field, so the leading space on layer_name survives regardless -- and
# normalize_layer_name() trims anyway, so a lost space could not change a key.
# Claiming otherwise would be a comment describing a failure this cannot see.
#
# The failure it CAN see is a comma or an embedded double quote breaking the row
# apart: label_expression carries both, and description carries commas. Compare
# every column rather than two, since a shifted row corrupts whichever column
# happens to sit at the break.
back <- utils::read.csv("inst/registry/form_types.csv", stringsAsFactors = FALSE)
if (!identical(dim(back), dim(forms))) {
  stop("form_types.csv changed shape on round-trip: wrote ",
       paste(dim(forms), collapse = "x"), ", read ",
       paste(dim(back), collapse = "x"), call. = FALSE)
}
for (col in names(forms)) {
  if (!identical(back[[col]], forms[[col]])) {
    bad <- which(back[[col]] != forms[[col]])
    stop("column '", col, "' did not survive the CSV round-trip: ",
         paste(sprintf("%s -> %s", forms[[col]][bad], back[[col]][bad]),
               collapse = "; "), call. = FALSE)
  }
}

styled <- sum(nzchar(forms$color))
message(
  "form_types.csv built: ", nrow(forms), " spatial forms of ", n_all,
  " registered (", n_all - nrow(forms), " non-spatial dropped); ",
  styled, " carry a declared colour, ", nrow(forms) - styled, " do not"
)
