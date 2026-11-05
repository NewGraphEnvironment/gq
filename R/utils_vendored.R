# Build and write the rosters gq vendors from rfp.
#
# Each builder returns exactly the data.frame its data-raw/ generator writes,
# and vendored_write() is the one writer. So the currency test
# (tests/testthat/test-vendored_currency.R) can build from a live rfp source,
# write to a tempfile, and compare BYTES with the committed file: one fact
# derived once, compared at the file rather than through a reader (gq#78).
#
# The QML corpus is not here. data-raw/styles_vendor.R copies files rather than
# building a table, and test-gq_style_qml.R already compares bytes; rfp#188
# moves that store into gq, at which point that comparison is dropped.

#' Group tree of each template, as template_groups.csv carries it
#' @param tpl_dir Directory holding `<template>.qgs`.
#' @param templates Character vector of template names.
#' @noRd
template_groups_build <- function(tpl_dir, templates) {
  groups <- do.call(rbind, lapply(templates, function(template) {
    tbl <- qgs_group_table(file.path(tpl_dir, paste0(template, ".qgs")))
    if (nrow(tbl) == 0L) {
      stop("No groups in ", template, call. = FALSE)
    }
    cbind(template = template, tbl, stringsAsFactors = FALSE)
  }))
  groups[order(groups$template, groups$group_path), ]
}


#' Layer placement in each template, as template_layers.csv carries it (gq#68)
#' @inheritParams template_groups_build
#' @noRd
template_layers_build <- function(tpl_dir, templates) {
  layers <- do.call(rbind, lapply(templates, function(template) {
    tbl <- qgs_layer_table(file.path(tpl_dir, paste0(template, ".qgs")))
    if (nrow(tbl) == 0L) {
      stop("No layers in ", template, call. = FALSE)
    }
    cbind(template = template, tbl, stringsAsFactors = FALSE)
  }))
  layers <- layers[order(layers$template, layers$group_path, layers$order), ]

  # A key two layers share in one template would make the placement join
  # ambiguous: refuse rather than let one row stand for both.
  dup <- layers[duplicated(layers[c("template", "layer_key")]), ]
  if (nrow(dup) > 0) {
    stop("layer_key repeated within a template: ",
         paste(sprintf("%s %s", dup$template, dup$layer_key), collapse = "; "),
         call. = FALSE)
  }
  layers
}


#' Map themes of each template, as themes.csv carries it
#'
#' Refuses a theme layer `groups.csv` does not carry -- a silent drop is how
#' the roster became fiction in the first place -- and a comma in any field,
#' because themes.csv is written unquoted.
#'
#' @inheritParams template_groups_build
#' @param group_keys Layer keys `groups.csv` carries.
#' @noRd
themes_build <- function(tpl_dir, templates, group_keys) {
  themes <- do.call(rbind, lapply(templates, function(template) {
    qgs_theme_table(file.path(tpl_dir, paste0(template, ".qgs")), template)
  }))

  dangling <- setdiff(unique(themes$layer_key), group_keys)
  if (length(dangling) > 0) {
    stop(
      "themes reference ", length(dangling),
      " layer_key(s) absent from groups.csv: ",
      paste(dangling, collapse = ", "),
      "\nAdd them to groups.csv, or correct the template.",
      call. = FALSE
    )
  }

  dupes <- themes[duplicated(themes[c("template", "theme", "layer_key")]), ]
  if (nrow(dupes) > 0) {
    stop("Duplicate template/theme/layer_key rows: ", nrow(dupes),
         call. = FALSE)
  }

  themes <- themes[order(themes$template, themes$theme, themes$layer_key), ]
  themes$visible <- ifelse(themes$visible, "true", "false")

  offending <- unlist(lapply(themes, function(col) grep(",", col, value = TRUE)))
  if (length(offending) > 0) {
    stop(
      "Comma in an unquoted field: ", paste(unique(offending), collapse = "; "),
      "\nQuote the output or rename upstream.",
      call. = FALSE
    )
  }
  themes
}


#' The spatial form roster, as form_types.csv carries it
#'
#' Reads rfp's `rfp_form_types.csv`. Non-spatial rows are child tables, not
#' layers, and are dropped on `has_spatial`, the column rfp uses to mean it.
#' The layer key derives from rfp's own rule, `paste0(" Form ", label)` through
#' `normalize_layer_name()`, NOT from `type`: the two disagree (a type
#' `monitoring_fish_passage` is labelled "Fish Passage Monitoring"), and a key
#' built from the type is wrong there with nothing downstream to report it.
#'
#' @param path Path to `rfp_form_types.csv`.
#' @noRd
form_types_build <- function(path) {
  if (!file.exists(path)) {
    stop("rfp_form_types.csv not found: ", path, call. = FALSE)
  }
  # trim_ws is readr's default and it is wrong here: `label` feeds a layer name
  # whose leading space is deliberate. read.csv() does not trim quoted fields.
  types <- utils::read.csv(path, stringsAsFactors = FALSE)

  required <- c("type", "description", "label", "geometry", "symbol", "color",
                "label_expression", "has_spatial", "parent")
  missing <- setdiff(required, names(types))
  if (length(missing) > 0) {
    stop("rfp_form_types.csv missing expected columns: ",
         paste(missing, collapse = ", "), call. = FALSE)
  }
  if (nrow(types) == 0L) {
    stop("rfp_form_types.csv is empty", call. = FALSE)
  }

  spatial <- types[types$has_spatial == "true", , drop = FALSE]
  if (nrow(spatial) == nrow(types)) {
    stop("the has_spatial filter matched every row. Either rfp changed the ",
         "column's vocabulary (it is the literal string \"true\", not a ",
         "logical), or every non-spatial form has legitimately been removed ",
         "upstream -- in which case delete this check rather than working ",
         "around it.", call. = FALSE)
  }

  layer_name <- paste0(" Form ", spatial$label)
  layer_key <- vapply(layer_name, normalize_layer_name, character(1),
                      USE.NAMES = FALSE)

  if (anyDuplicated(layer_key) != 0L) {
    dup <- unique(layer_key[duplicated(layer_key)])
    stop("two form labels normalize to the same layer_key: ",
         paste(dup, collapse = ", "), call. = FALSE)
  }

  # paste0("form_", type) and the label rule agree on most rows, so the
  # derivation is only shown to matter where they disagree. If they stop
  # disagreeing anywhere, the reason for deriving from the label has gone.
  if (!any(layer_key != paste0("form_", spatial$type))) {
    stop("every derived key now equals paste0(\"form_\", type), so nothing in ",
         "this roster distinguishes the label rule from the type rule. Either ",
         "rfp relabelled its forms, or the derivation regressed.",
         call. = FALSE)
  }

  # `parent` is dropped: it is populated only on the non-spatial child tables,
  # which the filter above removes, so it would be a column with no values.
  forms <- data.frame(
    layer_key = layer_key,
    form_type = spatial$type,
    label = spatial$label,
    description = spatial$description,
    layer_name = layer_name,
    geometry = spatial$geometry,
    symbol = spatial$symbol,
    color = spatial$color,
    label_expression = spatial$label_expression,
    stringsAsFactors = FALSE
  )
  forms[order(forms$layer_key), ]
}


#' Write a vendored roster, and prove it reads back as written
#'
#' The one writer, so a generator and the currency test cannot serialize
#' differently. The read-back compares every column as text: a comma or an
#' embedded quote that breaks a row apart corrupts whichever column sits at
#' the break, and a trailing space eaten by a reader still looks like a name.
#'
#' @param df Data frame from one of the builders above.
#' @param path Output path.
#' @param quote Logical, passed to `utils::write.csv()`.
#' @noRd
vendored_write <- function(df, path, quote) {
  utils::write.csv(df, path, row.names = FALSE, quote = quote)

  back <- utils::read.csv(path, colClasses = "character",
                          na.strings = character(0), check.names = FALSE)
  if (!identical(dim(back), dim(df)) || !identical(names(back), names(df))) {
    stop(basename(path), " changed shape on round-trip: wrote ",
         paste(dim(df), collapse = "x"), ", read ",
         paste(dim(back), collapse = "x"), call. = FALSE)
  }
  for (col in names(df)) {
    want <- as.character(df[[col]])
    want[is.na(want)] <- "NA"
    if (!identical(unname(back[[col]]), unname(want))) {
      bad <- which(back[[col]] != want)
      stop(basename(path), ": column '", col,
           "' did not survive the CSV round-trip: ",
           paste(sprintf("%s -> %s", want[bad], back[[col]][bad]),
                 collapse = "; "), call. = FALSE)
    }
  }
  invisible(path)
}
