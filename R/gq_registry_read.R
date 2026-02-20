#' Read a gq style registry from JSON
#'
#' Loads a registry.json file into an R list. The registry maps layer names
#' to style definitions (fill, stroke, classification, labels).
#'
#' @param path Path to a registry.json file.
#' @return A list with `name`, `version`, `source`, and `layers` elements.
#'
#' @examples
#' path <- system.file("examples", "mini_registry.json", package = "gq")
#' reg <- gq_registry_read(path)
#'
#' # What layers are available?
#' names(reg$layers)
#'
#' # Inspect a single layer — fill color, stroke, opacity all in one place
#' reg$layers$lake
#'
#' @export
gq_registry_read <- function(path) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("jsonlite is required")
  jsonlite::read_json(path, simplifyVector = FALSE)
}
