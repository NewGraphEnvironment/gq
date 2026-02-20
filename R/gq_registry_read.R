#' Read a gq style registry from JSON
#'
#' Loads a registry.json file into an R list. The registry maps layer names
#' to style definitions (fill, stroke, classification, labels).
#'
#' @param path Path to a registry.json file.
#' @return A list with `name`, `version`, `source`, and `layers` elements.
#'
#' @examples
#' \dontrun{
#' reg <- gq_registry_read("registry/registry.json")
#' names(reg$layers)
#' reg$layers$lake
#' }
gq_registry_read <- function(path) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("jsonlite is required")
  jsonlite::read_json(path, simplifyVector = FALSE)
}
