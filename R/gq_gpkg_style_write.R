#' Store QGIS styles for a layer in a GeoPackage
#'
#' Writes one or more QML documents into a GeoPackage's `layer_styles` table,
#' the table QGIS reads when a layer is opened from the file, so the layer
#' arrives styled with no `.qml` beside it. One style is the default QGIS
#' applies; the others are listed by name under the layer's
#' *Properties > Symbology > Style > Load Style... > From Database*.
#'
#' Rows are written with the twelve columns QGIS itself writes. The
#' `f_table_catalog` and `f_table_schema` cells are empty strings, never NULL,
#' because QGIS matches a row to its layer on all four `f_*` columns, and a NULL
#' schema leaves the layer unstyled even though the row is there.
#'
#' The table is written through GDAL (via sf), which registers it in
#' `gpkg_contents` as an `attributes` table, as QGIS does: a `layer_styles`
#' table that is not registered is invisible to QGIS in any GeoPackage that
#' already carries another attributes table.
#'
#' A style already stored for `layer` under one of the names in `styles` is
#' replaced; styles stored under other names, and every other layer's styles,
#' are kept. The style named by `default` becomes the layer's only default. When
#' every style is already stored as given, nothing is written, so a second call
#' leaves the file's bytes as they were.
#'
#' @param gpkg Path to an existing GeoPackage.
#' @param layer Name of a feature table in `gpkg`.
#' @param styles A named character vector (or list of strings) of QML
#'   documents, such as [gq_qgis_style()] returns; names become the
#'   `styleName`s and must be unique and non-empty.
#' @param default Name of the style QGIS applies when it opens the layer. One
#'   of `names(styles)`; the first by default.
#' @param description Optional descriptions, one per style, written to the
#'   `description` column. Empty by default.
#'
#' @return `gpkg`, invisibly.
#'
#' @seealso [gq_qgis_style()] to build a QML from a registry layer,
#'   [gq_style_qml()] for the QML files gq ships.
#'
#' @examplesIf requireNamespace("sf", quietly = TRUE)
#' reg <- gq_reg_custom(system.file("registry", "reg_custom.csv", package = "gq"))
#'
#' # a small line layer carrying both classification fields
#' segs <- sf::st_sf(
#'   rule_class = c("both", "first"),
#'   grade_class = c("0.6-0.8", "0-0.2"),
#'   geom = sf::st_sfc(
#'     sf::st_linestring(matrix(c(0, 0, 1, 1), 2)),
#'     sf::st_linestring(matrix(c(1, 2, 1, 3), 2)),
#'     crs = 3005
#'   )
#' )
#' gpkg <- tempfile(fileext = ".gpkg")
#' sf::st_write(segs, gpkg, "segments", quiet = TRUE)
#'
#' # rule class as the default style, grade class as a second named style
#' gq_gpkg_style_write(gpkg, "segments", styles = c(
#'   rule = gq_qgis_style(reg, "habitat_rule_comparison"),
#'   grade = gq_qgis_style(reg, "habitat_expected_use")
#' ))
#'
#' st <- sf::st_read(gpkg, "layer_styles", quiet = TRUE)
#' st[, c("f_table_name", "f_geometry_column", "styleName", "useAsDefault")]
#'
#' @export
gq_gpkg_style_write <- function(gpkg, layer, styles, default = names(styles)[1],
                                description = NULL) {
  if (!requireNamespace("sf", quietly = TRUE)) {
    stop("gq_gpkg_style_write() needs the sf package: pak::pak(\"sf\")",
         call. = FALSE)
  }
  if (!is.character(gpkg) || length(gpkg) != 1L || is.na(gpkg) ||
        !file.exists(gpkg)) {
    stop("`gpkg` must be the path of an existing GeoPackage", call. = FALSE)
  }
  if (!is.character(layer) || length(layer) != 1L || is.na(layer) ||
        !nzchar(layer)) {
    stop("`layer` must be a single table name", call. = FALSE)
  }
  if (is.list(styles)) styles <- unlist(styles, use.names = TRUE)
  nm <- names(styles)
  if (!is.character(styles) || length(styles) == 0L || is.null(nm) ||
        anyNA(nm) || !all(nzchar(nm)) || anyDuplicated(nm)) {
    stop("`styles` must be a character vector of QML documents with unique, ",
         "non-empty names", call. = FALSE)
  }
  if (anyNA(styles) || !all(grepl("<qgis[ >]", styles))) {
    stop("every element of `styles` must be a QML document (a <qgis> root)",
         call. = FALSE)
  }
  if (!is.character(default) || length(default) != 1L || !default %in% nm) {
    stop("`default` must be one of names(styles): ", paste(nm, collapse = ", "),
         call. = FALSE)
  }
  if (is.null(description)) description <- rep("", length(styles))
  if (length(description) != length(styles) || anyNA(description)) {
    stop("`description` must give one non-NA string per style", call. = FALSE)
  }

  geom_col <- gpkg_geom_column(gpkg, layer)
  tables <- gpkg_sql(
    gpkg, "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'layer_styles'"
  )
  exists <- nrow(tables) > 0L
  if (exists && !"layer_styles" %in% sf::st_layers(gpkg)$name) {
    # GDAL could not delete and recreate a table it does not list, and QGIS
    # cannot see the styles in it either; registering it is the fix.
    stop("`layer_styles` exists in ", basename(gpkg), " but is not registered ",
         "in gpkg_contents, so GDAL and QGIS do not list it. Register it as an ",
         "'attributes' table first.", call. = FALSE)
  }

  new <- data.frame(
    f_table_catalog = "",
    f_table_schema = "",
    f_table_name = layer,
    f_geometry_column = geom_col,
    styleName = nm,
    styleQML = unname(styles),
    styleSLD = "",
    useAsDefault = nm == default,
    description = as.character(description),
    owner = "",
    ui = "",
    update_time = Sys.time(),
    stringsAsFactors = FALSE
  )

  old <- if (exists) {
    sf::st_read(gpkg, "layer_styles", quiet = TRUE, stringsAsFactors = FALSE)
  } else {
    new[0, ]
  }
  for (col in setdiff(names(new), names(old))) old[[col]] <- na_like(new[[col]], nrow(old))
  for (col in setdiff(names(old), names(new))) new[[col]] <- na_like(old[[col]], nrow(new))
  new <- new[, names(old), drop = FALSE]

  # This layer's rows: same table and geometry column, empty catalog and
  # schema. NA reads as no match, so a NULL cell never selects a row.
  mine <- !is.na(old$f_table_name) & old$f_table_name == layer &
    !is.na(old$f_geometry_column) & old$f_geometry_column == geom_col &
    vapply(old$f_table_catalog, function(x) is.na(x) || !nzchar(x), logical(1)) &
    vapply(old$f_table_schema, function(x) is.na(x) || !nzchar(x), logical(1))
  replaced <- mine & old$styleName %in% nm
  kept_mine <- mine & !replaced

  if (styles_unchanged(old[replaced, , drop = FALSE], new) &&
        !any(old$useAsDefault[kept_mine] %in% TRUE)) {
    return(invisible(gpkg))
  }

  final <- old[!replaced, , drop = FALSE]
  final$useAsDefault[kept_mine[!replaced]] <- FALSE
  final <- rbind(final, new)
  rownames(final) <- NULL

  sf::st_write(final, gpkg, "layer_styles", delete_layer = exists,
               layer_options = "FID=id", quiet = TRUE)
  invisible(gpkg)
}


# --- internal helpers --------------------------------------------------------

#' Run a read-only SQL query on a GeoPackage through GDAL
#' @noRd
gpkg_sql <- function(gpkg, sql) {
  suppressWarnings(sf::st_read(gpkg, query = sql, quiet = TRUE,
                               stringsAsFactors = FALSE))
}

#' The geometry column of a feature table, or an error naming the tables
#' @noRd
gpkg_geom_column <- function(gpkg, layer) {
  sql <- paste0(
    "SELECT column_name FROM gpkg_geometry_columns WHERE table_name = '",
    gsub("'", "''", layer, fixed = TRUE), "'"
  )
  hit <- gpkg_sql(gpkg, sql)
  if (nrow(hit) != 1L) {
    feats <- gpkg_sql(gpkg, "SELECT table_name FROM gpkg_geometry_columns")
    stop("'", layer, "' is not a feature table in ", basename(gpkg),
         ". Feature tables: ", paste(feats$table_name, collapse = ", "),
         call. = FALSE)
  }
  hit$column_name[[1]]
}

#' NA of the type of `x`, `n` times
#' @noRd
na_like <- function(x, n) x[0][seq_len(n)]

#' Whether the stored rows already hold exactly these styles
#'
#' Compared on what QGIS reads (name, QML, default flag, description), not on
#' `update_time`, which differs on every call.
#' @noRd
styles_unchanged <- function(stored, new) {
  if (nrow(stored) != nrow(new)) return(FALSE)
  if (anyDuplicated(stored$styleName)) return(FALSE)
  i <- match(new$styleName, stored$styleName)
  if (anyNA(i)) return(FALSE)
  s <- stored[i, , drop = FALSE]
  identical(as.character(s$styleQML), new$styleQML) &&
    identical(s$useAsDefault %in% TRUE, new$useAsDefault) &&
    identical(ifelse(is.na(s$description), "", as.character(s$description)),
              new$description)
}
