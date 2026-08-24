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
# Run after the templates change, e.g. once rfp#185 re-saves the presets to
# include the other three xyz basemaps:
#   Rscript data-raw/reg_extract_themes.R
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

#' Pull one template's themes into a long data.frame
extract_themes <- function(template, dir) {
  path <- file.path(dir, paste0(template, ".qgs"))
  if (!file.exists(path)) stop("Template not found: ", path, call. = FALSE)

  doc <- xml2::read_xml(path)

  # id -> display name, from the project's layer definitions
  maplayers <- xml2::xml_find_all(doc, "//projectlayers/maplayer")
  ids <- xml2::xml_text(xml2::xml_find_first(maplayers, "./id"))
  names_display <- xml2::xml_text(xml2::xml_find_first(maplayers, "./layername"))
  id_to_name <- stats::setNames(names_display, ids)

  presets <- xml2::xml_find_all(doc, "//visibility-presets/visibility-preset")
  if (length(presets) == 0) {
    stop("No visibility presets in ", template, call. = FALSE)
  }

  out <- lapply(presets, function(preset) {
    theme <- xml2::xml_attr(preset, "name")
    layers <- xml2::xml_find_all(preset, "./layer")
    if (length(layers) == 0) {
      return(NULL)
    }

    layer_ids <- xml2::xml_attr(layers, "id")
    display <- unname(id_to_name[layer_ids])

    unresolved <- layer_ids[is.na(display)]
    if (length(unresolved) > 0) {
      stop(
        template, " / ", theme, ": ", length(unresolved),
        " preset layer id(s) have no <maplayer>: ",
        paste(utils::head(unresolved, 3), collapse = ", "),
        call. = FALSE
      )
    }

    data.frame(
      template  = template,
      theme     = theme,
      layer_key = normalize_layer_name(display),
      visible   = xml2::xml_attr(layers, "visible") == "1",
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, out)
}

themes <- do.call(rbind, lapply(templates, extract_themes, dir = tpl_dir))

# A layer_key the roster names but groups.csv does not carry is a dangling
# reference. Abort rather than dropping it — a silent drop is how the roster
# became fiction in the first place.
group_keys <- unique(read.csv("inst/registry/groups.csv",
                              stringsAsFactors = FALSE)$layer_key)
dangling <- setdiff(unique(themes$layer_key), group_keys)
if (length(dangling) > 0) {
  stop(
    "themes reference ", length(dangling),
    " layer_key(s) absent from groups.csv: ",
    paste(dangling, collapse = ", "),
    "\nAdd them to groups.csv, or correct the template.",
    call. = FALSE
  )
}

dupes <- themes[duplicated(themes[c("template", "theme", "layer_key")]), ]
if (nrow(dupes) > 0) {
  stop("Duplicate template/theme/layer_key rows: ", nrow(dupes), call. = FALSE)
}

themes <- themes[order(themes$template, themes$theme, themes$layer_key), ]
themes$visible <- ifelse(themes$visible, "true", "false")

# The registry CSVs are written unquoted, matching groups.csv/templates.csv. A
# comma inside a theme name would then silently shift every later column, so
# refuse rather than emit a corrupt file. (Group names already contain commas —
# "Roads,Railways,Pipelines" — so this is not hypothetical for the family.)
offending <- unlist(lapply(themes, function(col) grep(",", col, value = TRUE)))
if (length(offending) > 0) {
  stop(
    "Comma in an unquoted field: ", paste(unique(offending), collapse = "; "),
    "\nQuote the output or rename upstream.",
    call. = FALSE
  )
}

write.csv(themes, "inst/registry/themes.csv", row.names = FALSE,
          quote = FALSE)

message(
  "themes.csv built: ", nrow(themes), " rows, ",
  nrow(unique(themes[c("template", "theme")])), " template-theme pairs"
)
