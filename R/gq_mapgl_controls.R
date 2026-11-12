#' Add navigation, a scale bar and a layer switch to a MapLibre GL map
#'
#' The last call of a gq web map. The layer switch lists the layers by the
#' names a reader sees, so a layer's id can stay short. The four corners each
#' get one element: legends top left (from [gq_mapgl_layer()]), the switch at
#' `position`, navigation bottom right and the scale bar bottom left.
#'
#' @param map A map from [gq_mapgl_basemap()].
#' @param layers The layers to switch: a named character vector, label = layer
#'   id (`c(Habitat = "rules")`), or unnamed ids, which are shown as they are.
#'   `NULL` switches every layer on the map. `character(0)` adds no switch.
#' @param position The switch's corner.
#' @param navigation Add zoom and compass buttons.
#' @param scale Add a scale bar.
#' @return `map`, with the controls added.
#'
#' @seealso [gq_mapgl_layer()]
#'
#' @examplesIf requireNamespace("mapgl", quietly = TRUE) && requireNamespace("sf", quietly = TRUE)
#' obs <- neexdzii_fish_obs
#' m <- gq_mapgl_basemap(neexdzii_wsd, "positron") |>
#'   gq_mapgl_layer("co", obs[obs$species_code == "CO", "species_code"],
#'                  color = "#FF7F00", legend_title = "Coho") |>
#'   gq_mapgl_layer("rb", obs[obs$species_code == "RB", "species_code"],
#'                  color = "#377EB8", legend_title = "Rainbow trout") |>
#'   gq_mapgl_controls(c(Coho = "co", "Rainbow trout" = "rb"))
#' m$x$layers_control$layers
#'
#' @export
gq_mapgl_controls <- function(map, layers = NULL, position = "top-right",
                              navigation = TRUE, scale = TRUE) {
  mapgl_need()
  have <- vapply(map$x$layers, `[[`, "", "id")
  if (is.null(layers)) layers <- have
  if (!is.character(layers)) stop("`layers` must be layer ids", call. = FALSE)
  # a partly named vector would give the unnamed layers a switch with no text
  if (!is.null(names(layers))) {
    blank <- is.na(names(layers)) | !nzchar(names(layers))
    names(layers)[blank] <- layers[blank]
  }
  miss <- setdiff(unname(layers), have)
  if (length(miss)) {
    stop("the map has no layer ", paste0("`", miss, "`", collapse = ", "), call. = FALSE)
  }
  if (isTRUE(navigation)) map <- mapgl::add_navigation_control(map, position = "bottom-right")
  if (isTRUE(scale)) map <- mapgl::add_scale_control(map, position = "bottom-left")
  if (length(layers)) map <- mapgl::add_layers_control(map, layers = layers, position = position)
  map
}
