#' Read form_types.csv
#' @noRd
read_form_types_csv <- function() {
  path <- system.file("registry", "form_types.csv", package = "gq")
  if (path == "") stop("form_types.csv not found - reinstall gq")
  utils::read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"))
}


#' The roster of Mergin survey forms
#'
#' The catalogue of field forms a project can carry, vendored from rfp's
#' `rfp_form_types.csv`. Non-spatial child tables are excluded — this is a
#' roster of map layers.
#'
#' This is a separate table from [gq_groups()] rather than part of it, because
#' the two answer different questions. Forms are not baked into the QGIS
#' templates: `rfp_qgs_form_add()` injects them per project, and a project's
#' config selects which. So `groups.csv` carries the two forms the templates
#' ship, and this carries every form a project could ask for.
#'
#' Folding the roster into `groups.csv` would make [gq_template_layers()] report
#' thirteen forms for a template that ships two — a project styled for layers it
#' never downloaded, which is the defect the composition guards exist to catch.
#'
#' `symbol` and `color` are `NA` for a form rfp has registered but not styled.
#' That is a statement about upstream, not a gap here: gq does not invent
#' symbology for a form whose appearance nobody has decided.
#'
#' @return A data.frame with columns: layer_key, form_type, label, description,
#'   layer_name, geometry, symbol, color, label_expression. One row per spatial
#'   form, ordered by `layer_key`.
#'
#' @examples
#' forms <- gq_form_types()
#' nrow(forms)
#'
#' # the key is derived from rfp's layer name, not from its type — these differ
#' forms[forms$form_type == "monitoring_fish_passage", c("form_type", "layer_key")]
#'
#' # which forms rfp has styled, and which are still undecided
#' forms$layer_key[is.na(forms$color)]
#'
#' # the subset the shipped templates actually carry
#' intersect(forms$layer_key, gq_group_layers("Forms")$layer_key)
#'
#' @export
gq_form_types <- function() {
  read_form_types_csv()
}
