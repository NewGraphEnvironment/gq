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
#' Returns a data.frame of all themes defined in the registry, showing
#' which groups are visible or hidden in each theme.
#'
#' @return A data.frame with columns: theme, group, visible.
#'
#' @examples
#' gq_themes()
#'
#' @export
gq_themes <- function() {
  df <- read_themes_csv()
  df$visible <- as.logical(df$visible)
  df
}


#' Get group visibility for a theme
#'
#' Returns which groups are visible or hidden for a given theme.
#'
#' @param theme Character. Theme name (e.g., `"Field View"`).
#' @return A data.frame with columns: theme, group, visible.
#'   Returns empty data.frame if theme not found.
#'
#' @examples
#' gq_theme_groups("Field View")
#'
#' @export
gq_theme_groups <- function(theme) {
  df <- gq_themes()
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
