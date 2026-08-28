# Tabulate the group structure of a QGIS project's layer tree.
#
# gq declares group composition and order in inst/registry/templates.csv and
# groups.csv. Nothing ever compared that declaration against the projects it
# describes, so it drifted into fiction — gq#66. This is the reader that makes
# the comparison possible; data-raw/reg_extract_template_groups.R vendors its
# output, and tests/testthat/test-template_drift.R is the guard.
#
# Lives in R/ rather than data-raw/ so the guard can call it on a fixture and
# watch the alarm fire. A walker only the generator can reach is a walker nobody
# has seen fail.

#' Tabulate the groups in a QGIS project's layer tree
#'
#' Returns one row per group, in document order, with the path from below the
#' project root.
#'
#' Group **order is document order**. A `.qgs` carries no `order`, `index` or
#' `z` attribute on `layer-tree-group`; the `<custom-order>` element is
#' `enabled="0"`, holds only layer ids, and is partial, so it is not the source
#' of truth. Tree order is draw order — the first node draws on top — which is
#' why a group appended at the end of the tree renders beneath the opaque raster
#' basemap and disappears.
#'
#' `order` indexes group **and** layer siblings together, matching rfp's
#' `data-raw/qgs/extract_roster.R`: indexing groups alone cannot place a
#' subgroup among the layers it sits between.
#'
#' Names are byte-exact and must stay that way. The project root is
#' `"bcrestoration Mobile "`, with a trailing space; several layers carry a
#' leading one. A `trimws()` anywhere in this chain silently invalidates every
#' group reference in every theme.
#'
#' @param path Character. Path to a `.qgs` file.
#' @return A data.frame with columns `group_path`, `depth`, `order`. Zero rows
#'   if the project root has no groups.
#' @noRd
qgs_group_table <- function(path) {
  if (!is.character(path) || length(path) != 1L || is.na(path)) {
    stop("`path` must be a single non-NA string", call. = FALSE)
  }
  if (!file.exists(path)) {
    stop("Template not found: ", path, call. = FALSE)
  }

  doc <- xml2::read_xml(path)

  # The tree hangs off an UNNAMED <layer-tree-group> at /qgis. Its single named
  # child is the project root — a per-template string ("bcfishpass Mobile " vs
  # "bcrestoration Mobile ") that no cross-template registry could share, so
  # paths here are relative to below it.
  root <- xml2::xml_find_first(doc, "/qgis/layer-tree-group")
  if (inherits(root, "xml_missing")) {
    stop("No /qgis/layer-tree-group in ", path, call. = FALSE)
  }
  named <- xml2::xml_find_all(root, "./layer-tree-group[@name]")
  if (length(named) != 1L) {
    stop(
      "Expected exactly one named root group in ", path, ", found ",
      length(named),
      if (length(named) > 0) {
        paste0(": ", paste(xml2::xml_attr(named, "name"), collapse = ", "))
      } else {
        ""
      },
      call. = FALSE
    )
  }

  rows <- list()
  walk <- function(node, ancestors) {
    kids <- xml2::xml_children(node)
    # Every node carries a <customproperties> element child, so filtering by tag
    # name is required — positional indexing would count it.
    kids <- kids[xml2::xml_name(kids) %in%
                   c("layer-tree-group", "layer-tree-layer")]
    for (i in seq_along(kids)) {
      k <- kids[[i]]
      if (xml2::xml_name(k) != "layer-tree-group") next
      nm <- xml2::xml_attr(k, "name")
      if (is.na(nm)) {
        stop("Unnamed group below the project root in ", path, call. = FALSE)
      }
      # "/" is the path separator, so a group carrying one would make the path
      # ambiguous. Not hypothetical: gq's registry called this very group
      # "Roads/Rails/Pipelines" until gq#66.
      if (grepl("/", nm, fixed = TRUE)) {
        stop("Group name contains '/', which is the path separator: ", nm,
             call. = FALSE)
      }
      rows[[length(rows) + 1L]] <<- data.frame(
        group_path = paste(c(ancestors, nm), collapse = "/"),
        depth = length(ancestors) + 1L,
        order = i,
        stringsAsFactors = FALSE
      )
      walk(k, c(ancestors, nm))
    }
  }
  walk(named[[1]], character(0))

  if (length(rows) == 0L) {
    return(data.frame(group_path = character(0), depth = integer(0),
                      order = integer(0), stringsAsFactors = FALSE))
  }
  out <- do.call(rbind, rows)

  # Paths are the join key, so they have to be unique. Two same-named siblings
  # would silently collapse to one row and take a real group's placement with
  # them.
  dupes <- out$group_path[duplicated(out$group_path)]
  if (length(dupes) > 0) {
    stop("Duplicate group path(s) in ", path, ": ",
         paste(unique(dupes), collapse = ", "), call. = FALSE)
  }

  out
}


#' Read the vendored template group table
#'
#' `utils::read.csv()`, never readr: `trim_ws = TRUE` would eat the trailing
#' space in `"Project Specific/Model Parameters - bcfishpass "` and silently
#' break every path match against it.
#'
#' @noRd
read_template_groups_csv <- function() {
  path <- system.file("registry", "template_groups.csv", package = "gq")
  if (path == "") stop("template_groups.csv not found - reinstall gq")
  utils::read.csv(path, stringsAsFactors = FALSE)
}
