#' Build a popup for a MapLibre GL layer from column names
#'
#' Returns the data with the popup's display text added as new columns
#' (`popup_1`, `popup_2`, ...), and the MapLibre expression that assembles the
#' popup from them in the browser: `Label: value`, one per line. Pass `data`
#' as the layer's `x` and `expr` as its `popup` in [gq_mapgl_layer()]. The
#' columns the popup reads are left as they are, so a layer can still be styled
#' on one: a stream order written as text would no longer scale a line.
#'
#' The popup is assembled in the browser rather than pasted into an HTML
#' string per feature, which more than doubled the page in the map these
#' helpers come from. MapLibre's popup reads only a few expression operators,
#' so a missing value is written here as `missing`.
#'
#' Numbers are rounded to `digits` significant figures one value at a time,
#' so `0.037` and `2.2` sit side by side rather than as `3.7e-02` and `2.20`.
#' Format a column yourself (to a percentage, say) and it is shown as given.
#'
#' @param x An `sf` or data frame.
#' @param fields A named character vector, label = column: `c("Stream order"
#'   = "stream_order")`. The labels may carry HTML.
#' @param missing The text shown for a missing value.
#' @param digits Significant figures for numeric columns.
#' @return A list of `data` (`x` with the popup text columns added) and `expr`
#'   (the popup expression). Keep only the columns the map reads before
#'   calling: every column is written into the page.
#'
#' @seealso [gq_mapgl_layer()]
#'
#' @examples
#' x <- data.frame(stream_order = c(3L, 5L), gradient = c(0.0372, NA))
#' pop <- gq_mapgl_popup(x, c("Stream order" = "stream_order", "Gradient" = "gradient"))
#' pop$data
#' str(pop$expr)
#'
#' @export
gq_mapgl_popup <- function(x, fields, missing = "none", digits = 3L) {
  if (!is.data.frame(x)) stop("`x` must be a data frame or an sf", call. = FALSE)
  labs <- names(fields)
  if (!is.character(fields) || !length(fields) || is.null(labs) ||
        anyNA(labs) || !all(nzchar(labs))) {
    stop("`fields` must be a named character vector, label = column", call. = FALSE)
  }
  miss <- setdiff(fields, names(x))
  if (length(miss)) {
    stop("`x` has no column ", paste0("`", miss, "`", collapse = ", "), call. = FALSE)
  }
  if (!is.character(missing) || length(missing) != 1L || is.na(missing)) {
    stop("`missing` must be one string", call. = FALSE)
  }
  check_digits(digits)
  if (digits < 1) stop("`digits` must be 1 or more", call. = FALSE)

  keys <- paste0("popup_", seq_along(fields))
  clash <- intersect(keys, names(x))
  if (length(clash)) {
    stop("`x` already has a column ", paste0("`", clash, "`", collapse = ", "),
         "; gq_mapgl_popup() writes its text there", call. = FALSE)
  }
  expr <- list("concat")
  for (i in seq_along(fields)) {
    x[[keys[[i]]]] <- popup_text(x[[fields[[i]]]], missing, digits)
    lead <- if (i == 1L) "" else "<br>"
    expr <- c(expr, list(paste0(lead, labs[[i]], ": ")), list(list("get", keys[[i]])))
  }
  list(data = x, expr = expr)
}

#' One column as display text
#' @noRd
popup_text <- function(v, missing, digits) {
  out <- if (is.numeric(v)) {
    # per value: format() over a vector picks one notation for all of them
    vapply(v, function(z) trimws(formatC(signif(z, digits), digits = digits, format = "fg")),
           character(1))
  } else if (is.logical(v)) {
    ifelse(v, "yes", "no")
  } else {
    as.character(v)
  }
  out[is.na(v)] <- missing
  unname(out)
}
