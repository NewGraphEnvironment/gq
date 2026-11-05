# Tabulate the map themes (visibility presets) of a QGIS project.
#
# Moved here from data-raw/reg_extract_themes.R (gq#78) for the reason
# R/utils_qgs_groups.R gives: a walker only the generator can reach is a walker
# nobody has seen fail. The currency test calls it on the live templates and on
# a perturbed fixture.

#' Tabulate one template's map themes
#'
#' QGIS stores a map theme as a `<visibility-preset>` that enumerates
#' `<layer id=... visible="0|1"/>` per layer. Group state appears only in
#' `<checked-group-nodes>`, a slash-path record of layer-tree UI state, and is
#' deliberately ignored here: it is not the visibility model.
#'
#' Layer ids are `<sanitized-name>_<uuid>`, and the sanitization is lossy (Esri
#' World Imagery ships with the display name "Esri Satellite"), so the id stem
#' is NOT a usable key. Resolve id -> `<maplayer><layername>` ->
#' `normalize_layer_name()` instead, which is the same rule `gq_qgs_extract()`
#' keys the registry with.
#'
#' @param path Character. Path to a `.qgs` file.
#' @param template Character. The template name written into each row.
#' @return A data.frame with columns `template`, `theme`, `layer_key`,
#'   `visible` (logical), in document order. Zero rows when every preset is
#'   empty.
#' @noRd
qgs_theme_table <- function(path, template) {
  if (!is.character(path) || length(path) != 1L || is.na(path)) {
    stop("`path` must be a single non-NA string", call. = FALSE)
  }
  if (!file.exists(path)) stop("Template not found: ", path, call. = FALSE)

  doc <- xml2::read_xml(path)

  # id -> display name, from the project's layer definitions
  maplayers <- xml2::xml_find_all(doc, "//projectlayers/maplayer")
  ids <- xml2::xml_text(xml2::xml_find_first(maplayers, "./id"))
  names_display <- xml2::xml_text(xml2::xml_find_first(maplayers,
                                                       "./layername"))
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
      layer_key = vapply(display, normalize_layer_name, character(1),
                         USE.NAMES = FALSE),
      visible   = xml2::xml_attr(layers, "visible") == "1",
      stringsAsFactors = FALSE
    )
  })

  out <- do.call(rbind, out)
  if (is.null(out)) {
    return(data.frame(template = character(0), theme = character(0),
                      layer_key = character(0), visible = logical(0),
                      stringsAsFactors = FALSE))
  }
  out
}
