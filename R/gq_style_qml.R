# --- Internal ----------------------------------------------------------------

#' Read the QML corpus index
#'
#' Quoted, unlike the registry CSVs, because layer names carry commas
#' ("Crossings - PSCIS,  modelled, dams") and one begins with a space. read.csv()
#' handles the quoting; `strip.white` is left at its default because it applies
#' only to unquoted fields, so the leading space survives either way.
#' @noRd
read_styles_index <- function() {
  path <- system.file("styles", "index.csv", package = "gq")
  if (path == "") stop("styles/index.csv not found - reinstall gq")
  utils::read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"))
}

#' Absolute path to a corpus file, given its index-relative location
#' @noRd
styles_path <- function(rel) {
  path <- system.file("styles", rel, package = "gq")
  if (path == "") stop("styles/", rel, " not found - reinstall gq")
  path
}

#' Rebuild a row's on-disk location from its key, template and scope
#'
#' Derived rather than stored: a path column in the index would be a second
#' source of truth for something the scope already determines, and the two would
#' eventually disagree. Mirrors the layout data-raw/styles_vendor.R writes.
#' @noRd
styles_rel <- function(row) {
  file.path(
    switch(row$kind,
      vector  = if (identical(row$scope, "override")) {
        file.path("vector", "overrides", row$template)
      } else {
        "vector"
      },
      raster  = "raster",
      service = "services",
      stop("Unknown kind in styles index: ", row$kind, call. = FALSE)
    ),
    paste0(row$layer_key, ".qml")
  )
}


# --- Exported ----------------------------------------------------------------

#' Get the QGIS-native QML style for a layer
#'
#' Returns the path to a layer's QML — the QGIS-native form of its symbology,
#' complete in a way the registry is not. `gq_reg_main()` and the
#' `gq_tmap_style()` / `gq_mapgl_style()` translators model roughly 20 symbol
#' properties and a single symbol layer, because that is what tmap and mapgl can
#' render. A QML carries everything QGIS authored: multi-layer symbols, casing
#' and overlay, labelling, per-class dash. Use the registry for tmap and mapgl,
#' and this for anything that speaks to QGIS — Desktop, Mergin field projects,
#' QGIS Server / QWC2, or a `layer_styles` table.
#'
#' Unlike every other gq export, this returns a **file path** rather than a list
#' or a data frame. The QML is shipped as-is, byte-for-byte what QGIS wrote, so
#' handing back a path lets the caller copy it, read it, or write it into a
#' `layer_styles` row without gq re-serializing it and introducing drift.
#'
#' Styles are shared across project templates unless a template genuinely
#' diverges — measured upstream, 3 layers of 53 do. Passing `template` returns
#' that template's override when one exists and the shared style otherwise, so
#' naming a valid template is always safe. An unknown template name errors
#' rather than falling back, since a silent fallback would hand back the shared
#' style on exactly the layers where an override exists because the shared one
#' is wrong for that template.
#'
#' @param layer_key Layer key, as used by [gq_groups()] and the registry (e.g.
#'   `"lake"`). See [gq_groups()] for the roster.
#' @param template Optional project template (e.g. `"bcfishpass_mobile"`).
#'   When supplied, a template-specific override wins over the shared style.
#'   Must name a template [gq_templates()] knows. When `NULL` (default) the
#'   shared style is returned.
#'
#' @return A length-one character path to a `.qml` file.
#'
#' @seealso [gq_reg_main()] for the cross-backend registry, [gq_tmap_style()]
#'   and [gq_mapgl_style()] for the tmap and mapgl translations.
#'
#' @examples
#' # the QGIS-native style for lakes
#' qml <- gq_style_qml("lake")
#' basename(qml)
#'
#' # a QML is a full QGIS style document, not a property digest
#' doc <- xml2::read_xml(qml)
#' xml2::xml_name(xml2::xml_root(doc))
#'
#' # three layers differ between templates; the rest are shared
#' basename(dirname(gq_style_qml("land_ownership", "bcfishpass_mobile")))
#' basename(dirname(gq_style_qml("land_ownership", "bcrestoration_mobile")))
#'
#' @export
gq_style_qml <- function(layer_key, template = NULL) {
  if (!is.character(layer_key) || length(layer_key) != 1L || is.na(layer_key)) {
    stop("`layer_key` must be a single non-NA string", call. = FALSE)
  }
  if (!is.null(template) &&
        (!is.character(template) || length(template) != 1L)) {
    stop("`template` must be NULL or a single string", call. = FALSE)
  }

  idx <- read_styles_index()
  hits <- idx[idx$layer_key == layer_key, , drop = FALSE]

  if (nrow(hits) == 0) {
    # Naming near-misses rather than returning NA: a lookup that silently yields
    # nothing is the trap, and the caller usually has a typo or is holding a
    # groups.csv key with no QML (see the vendoring script's report).
    # Ranked by edit distance, not by agrep: agrep's max.distance is a fraction
    # of the PATTERN, so a short key matches loosely into long keys and buries
    # the obvious answer ("lake" came 5th for "lakes", behind
    # "habitat_lateral"). Substring hits are kept too, since a key the caller
    # half-remembers is a different kind of near miss.
    keys <- unique(idx$layer_key)
    d <- utils::adist(layer_key, keys)[1, ]
    near <- unique(c(
      keys[order(d)][d[order(d)] <= max(2L, nchar(layer_key) %/% 3L)],
      grep(layer_key, keys, fixed = TRUE, value = TRUE)
    ))
    stop(
      "No QML for layer_key '", layer_key, "'",
      if (length(near) > 0) {
        paste0(". Did you mean: ", paste(utils::head(near, 5), collapse = ", "),
               "?")
      } else {
        ". See gq_groups() for keys, and note not every key has a QML."
      },
      call. = FALSE
    )
  }

  # Override first, shared as the fallback — so naming a template is safe for
  # the majority of layers that have no template-specific style.
  #
  # But only for a template that EXISTS. Falling back silently on an unknown
  # name means a typo returns the shared style, and it does so on exactly the
  # layers where an override exists because the shared style is wrong for that
  # template — the caller gets a plausible file and no signal. Validate instead.
  row <- NULL
  if (!is.null(template)) {
    known <- unique(gq_templates()$template)
    if (!template %in% known) {
      stop("Unknown template '", template, "'. Known: ",
           paste(known, collapse = ", "), call. = FALSE)
    }
    ovr <- hits[hits$scope == "override" & hits$template == template, ,
                drop = FALSE]
    if (nrow(ovr) == 1L) row <- ovr
  }
  if (is.null(row)) {
    shared <- hits[hits$scope == "shared", , drop = FALSE]
    if (nrow(shared) != 1L) {
      stop("Expected exactly one shared style for '", layer_key, "', found ",
           nrow(shared), call. = FALSE)
    }
    row <- shared
  }

  styles_path(styles_rel(row))
}
