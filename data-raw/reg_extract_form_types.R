# Extract inst/registry/form_types.csv from rfp's form-type roster.
#
# The catalogue of Mergin survey forms a project can carry. This is a SEPARATE
# table from groups.csv on purpose, and the reason is structural rather than
# tidiness.
#
# Forms are not baked into the templates. `rfp_qgs_form_add()` injects them per
# project, and rtj's scripts/gis/projects/<name>/project.yml selects which, in
# a `forms:` list. So form membership is per-PROJECT, while groups.csv models
# per-TEMPLATE contents.
#
# Putting the whole roster into groups.csv would therefore make
# gq_template_layers() report every form in the catalogue (16 at rfp 0.93.0)
# for a template that ships 2, which is exactly the gq#40 defect -- a project
# styled for layers it never downloaded -- several times over. groups.csv keeps
# the two the templates ship; this table is the catalogue they are drawn from.
# (gq#64)
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

# The builder lives in R/utils_vendored.R (gq#78) so the currency test derives
# the roster exactly as this does. It refuses a missing column, an empty file,
# a has_spatial filter that matches every row, two labels sharing a key, and a
# roster where the label rule and the type rule no longer disagree anywhere.
#
# Non-spatial rows are child tables, not layers. cabin_visit_pebble is the
# first case (edna_sample and tree_visit followed): no geometry, parent =
# cabin_visit, written into the parent's GeoPackage and joined parent_uuid ->
# uuid. A layer roster must not carry it.
#
# The layer key derives from rfp's OWN rule, not from the `type` column.
# `.rfp_form_layer_name()` (rfp/R/rfp_qgs_form_add.R) is paste0(" Form ",
# label), and gq keys a registry on normalize_layer_name() of the layer name.
# Type and label disagree, and not rarely: `monitoring_fish_passage` is
# labelled "Fish Passage Monitoring", so its key is
# form_fish_passage_monitoring -- the reverse word order. A key built from the
# type column is wrong there and NOTHING downstream would report it, because
# every lookup goes through the key on both sides. Hence the oracle below.
n_all <- nrow(utils::read.csv(path, stringsAsFactors = FALSE))
forms <- form_types_build(path)

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
if (!all(known %in% forms$layer_key)) {
  stop("derived keys do not reproduce the keys QGIS produced: missing ",
       paste(setdiff(known, forms$layer_key), collapse = ", "),
       ". Derived: ", paste(forms$layer_key, collapse = ", "), call. = FALSE)
}

# The oracle above is necessary and NOT sufficient: paste0("form_", type)
# produces form_pscis and form_fiss_site identically, so those two rows cannot
# separate the correct rule from the wrong one. The builder's last check is the
# one that can -- it refuses once label and type stop disagreeing anywhere.

# QUOTED, for three separate reasons, any one of which is sufficient:
# label_expression contains commas AND embedded double quotes; layer_name
# begins with a deliberate space; description contains commas.
# vendored_write() reads the file back and compares every column, which is
# what catches a comma or an embedded quote breaking a row apart.
vendored_write(forms, "inst/registry/form_types.csv", quote = TRUE)

styled <- sum(nzchar(forms$color))
message(
  "form_types.csv built: ", nrow(forms), " spatial forms of ", n_all,
  " registered (", n_all - nrow(forms), " non-spatial dropped); ",
  styled, " carry a declared colour, ", nrow(forms) - styled, " do not"
)
