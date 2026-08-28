# --- Internal CSV readers -----------------------------------------------------

#' Read groups.csv
#' @noRd
read_groups_csv <- function() {
  path <- system.file("registry", "groups.csv", package = "gq")
  if (path == "") stop("groups.csv not found - reinstall gq")
  utils::read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"))
}

#' Read templates.csv
#' @noRd
read_templates_csv <- function() {
  path <- system.file("registry", "templates.csv", package = "gq")
  if (path == "") stop("templates.csv not found - reinstall gq")
  utils::read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"))
}

#' Read themes.csv
#' @noRd
read_themes_csv <- function() {
  path <- system.file("registry", "themes.csv", package = "gq")
  if (path == "") stop("themes.csv not found - reinstall gq")
  utils::read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"))
}

#' Coerce a visible column to logical, refusing anything ambiguous
#'
#' read.csv() already type-converts a column of bare true/false, so a bare
#' as.logical() here was a no-op that looked like a guard. Anything it could not
#' parse — `1`/`0`, `yes`/`no`, a typo — became NA silently, and an NA visible
#' flag reads downstream as "not visible" rather than as an error.
#' @noRd
parse_visible <- function(x) {
  if (is.logical(x)) {
    return(x)
  }
  out <- ifelse(tolower(trimws(x)) == "true", TRUE,
                ifelse(tolower(trimws(x)) == "false", FALSE, NA))
  bad <- is.na(out) & !is.na(x)
  if (any(bad)) {
    stop(
      "themes.csv: 'visible' must be true or false, got: ",
      paste(unique(x[bad]), collapse = ", "),
      call. = FALSE
    )
  }
  out
}


# --- Group functions ----------------------------------------------------------

#' List all layer groups
#'
#' Returns a data.frame of all groups defined in the registry, with their
#' member layers, subgroups, and z-order. Each row is one layer-to-group
#' mapping.
#'
#' @param registry Optional registry list (from [gq_reg_main()]). If provided,
#'   `source_layer` and `type` columns are joined from the style registry.
#' @return A data.frame with columns: group, subgroup, layer_key, order,
#'   and optionally source_layer and type.
#'
#' @examples
#' # All groups and their layers
#' gq_groups()
#'
#' # With style registry info joined
#' reg <- gq_reg_main()
#' gq_groups(registry = reg)
#'
#' @export
gq_groups <- function(registry = NULL) {
  df <- read_groups_csv()
  if (!is.null(registry)) {
    df <- join_registry(df, registry)
  }
  df
}


#' Get layers in a group
#'
#' Returns all layers belonging to a group, including any nested subgroups.
#' Layers are ordered by z-order within the group.
#'
#' @param group Character. Group name (e.g., `"Basemap"`, `"Crossings"`).
#' @param registry Optional registry list (from [gq_reg_main()]). If provided,
#'   `source_layer` and `type` columns are joined from the style registry.
#' @return A data.frame with columns: group, subgroup, layer_key, order,
#'   and optionally source_layer and type. Returns empty data.frame if group
#'   not found.
#'
#' @examples
#' gq_group_layers("Basemap")
#' gq_group_layers("Streams")
#'
#' # With source_layer info
#' reg <- gq_reg_main()
#' gq_group_layers("Crossings", registry = reg)
#'
#' @export
gq_group_layers <- function(group, registry = NULL) {
  df <- read_groups_csv()
  out <- df[df$group == group, , drop = FALSE]
  if (!is.null(registry)) {
    out <- join_registry(out, registry)
  }
  # Sort by subgroup (NA first = direct children), then order
  out <- out[order(is.na(out$subgroup), out$subgroup, out$order,
                   decreasing = c(TRUE, FALSE, FALSE),
                   method = "radix"), , drop = FALSE]
  rownames(out) <- NULL
  out
}


# --- Template functions -------------------------------------------------------

#' List all project templates
#'
#' Returns a data.frame of all templates defined in the registry, showing
#' which groups each template includes and their order.
#'
#' @section Ordering:
#' `group_order` is a **sort key and nothing else**. It is per-template, and it
#' requires none of: contiguity, a 1-based start, uniqueness across templates,
#' or agreement between templates on where a shared group sits. A template is
#' free to number its groups 10/20/30 to leave room for insertions, or to use a
#' group vocabulary no other template shares.
#'
#' This is written down because the two templates shipped today are numbered
#' 1..N and agree on most of their vocabulary, which invites the inference that
#' those properties are required. They are not: `bcrestoration_mobile` declares
#' `Floodplain` and `Restoration`, which `bcfishpass_mobile` does not, so the
#' two already disagree about both membership and every position after group 5.
#' Do not add a contiguity check; it would break the first project type that
#' does not look like these two.
#'
#' An earlier version of this section cited a Roads-before-Streams asymmetry
#' between the templates as the evidence. There was none — both shipped `.qgs`
#' order `Roads,Railways,Pipelines` before `Streams`, and the asymmetry was
#' unchecked drift in this registry, cited as a fact about the projects it
#' describes. gq#66 adopted the template order and added
#' `tests/testthat/test-template_drift.R` so the next such claim is measured.
#'
#' @return A data.frame with columns: template, group, group_order.
#'
#' @examples
#' gq_templates()
#'
#' @export
gq_templates <- function() {
  read_templates_csv()
}


#' Get groups in a template
#'
#' Returns the groups that make up a project template, in layer-panel order.
#'
#' @param template Character. Template name (e.g., `"bcfishpass_mobile"`).
#' @return A data.frame with columns: template, group, group_order.
#'   Returns empty data.frame if template not found.
#'
#' @examples
#' gq_template_groups("bcfishpass_mobile")
#'
#' @export
gq_template_groups <- function(template) {
  df <- read_templates_csv()
  out <- df[df$template == template, , drop = FALSE]
  out <- out[order(out$group_order), , drop = FALSE]
  rownames(out) <- NULL
  out
}


#' Resolve template to layers
#'
#' Expands a template through its groups to produce a flat data.frame of
#' every layer needed for that project type. Joins with the style registry
#' to include `source_layer` and `type`.
#'
#' @param template Character. Template name (e.g., `"bcfishpass_mobile"`).
#' @param registry Optional registry list (from [gq_reg_main()]). If `NULL`,
#'   loads via [gq_reg_main()].
#' @return A data.frame with columns: template, group, group_order, subgroup,
#'   layer_key, order, source_layer, source_type, type.
#'
#' @examples
#' gq_template_layers("bcfishpass_mobile")
#'
#' @export
gq_template_layers <- function(template, registry = NULL) {
  if (is.null(registry)) registry <- gq_reg_main()

  tpl <- gq_template_groups(template)
  if (nrow(tpl) == 0) {
    return(data.frame(
      template = character(), group = character(), group_order = integer(),
      subgroup = character(), layer_key = character(), order = integer(),
      source_layer = character(), type = character(),
      stringsAsFactors = FALSE
    ))
  }

  groups_df <- read_groups_csv()

  # Filter to groups in this template
  layers <- groups_df[groups_df$group %in% tpl$group, , drop = FALSE]

  # Merge group_order from template
  layers <- merge(layers, tpl[, c("group", "group_order")], by = "group",
                  all.x = TRUE)
  layers$template <- template

  # Join registry info
  layers <- join_registry(layers, registry)

  # Sort: group_order, then subgroup (direct children first), then layer order
  layers <- layers[order(layers$group_order,
                         !is.na(layers$subgroup), layers$subgroup,
                         layers$order), , drop = FALSE]

  cols <- c("template", "group", "group_order", "subgroup", "layer_key",
            "order", "source_layer", "source_type", "type")
  cols <- intersect(cols, names(layers))
  layers <- layers[, cols, drop = FALSE]
  rownames(layers) <- NULL
  layers
}


# --- Theme functions ----------------------------------------------------------

#' List all visibility themes
#'
#' Returns the theme roster extracted from the QGIS templates: which layers each
#' template's map themes show or hide.
#'
#' Themes are recorded per layer because that is how QGIS stores them — a
#' `<visibility-preset>` enumerates each layer it governs with an explicit
#' visible flag. The same theme name can therefore carry different content in
#' different templates, which is why `template` is part of the key rather than a
#' filter applied afterwards.
#'
#' A theme governs only the layers it names. Templates carry more layers than
#' any one theme lists, so a returned set is partial: a layer absent from a
#' theme is not "hidden by" it, it is simply unmanaged and keeps whatever state
#' it had.
#'
#' @param template Character. Optional template name to restrict to, e.g.
#'   `"bcfishpass_mobile"`. Default `NULL` returns every template.
#' @return A data.frame with columns: template, theme, layer_key, visible.
#'
#' @examples
#' # every theme in every template
#' head(gq_themes())
#'
#' # which themes a template ships
#' unique(gq_themes("bcrestoration_mobile")$theme)
#'
#' @export
gq_themes <- function(template = NULL) {
  df <- read_themes_csv()
  df$visible <- parse_visible(df$visible)
  if (!is.null(template)) {
    df <- df[df$template == template, , drop = FALSE]
    rownames(df) <- NULL
  }
  df
}


#' Get layer visibility for a theme
#'
#' Returns which layers a theme shows or hides.
#'
#' Without `template`, a theme name that ships in more than one template returns
#' every template's rows concatenated — check the `template` column, or pass it,
#' when you want one project's answer. `High Detail - Crossings` is the live
#' example: it ships in both templates with materially different content.
#'
#' @param theme Character. Theme name, e.g. `"High Detail - Crossings"`.
#' @param template Character. Optional template name to restrict to.
#' @return A data.frame with columns: template, theme, layer_key, visible.
#'   Returns an empty data.frame if the theme is not found.
#'
#' @examples
#' # the same theme differs by template
#' xing <- gq_theme_layers("High Detail - Crossings")
#' tapply(xing$visible, xing$template, sum)
#'
#' # one template's answer
#' head(gq_theme_layers("Land Tenure", template = "bcrestoration_mobile"))
#'
#' @export
gq_theme_layers <- function(theme, template = NULL) {
  df <- gq_themes(template = template)
  out <- df[df$theme == theme, , drop = FALSE]
  rownames(out) <- NULL
  out
}


# --- Internal helpers ---------------------------------------------------------

#' Join registry source_layer and type onto a groups data.frame
#' @noRd
join_registry <- function(df, registry) {
  df$source_layer <- vapply(df$layer_key, function(key) {
    layer <- registry$layers[[key]]
    if (is.null(layer)) return(NA_character_)
    layer$source_layer %||% NA_character_
  }, character(1))

  df$type <- vapply(df$layer_key, function(key) {
    layer <- registry$layers[[key]]
    if (is.null(layer)) return(NA_character_)
    layer$type %||% NA_character_
  }, character(1))

  df
}
