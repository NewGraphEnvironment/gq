# Cut the extractor's test fixtures from real QGIS files.
#
# tests/testthat/fixtures/template_excerpt.qgs: layers from the template repo's
#   bcrestoration_mobile.qgs, each chosen for one thing the extractor reads
#   (#103): label field, expression and weight (#6), multi-layer symbols (#24),
#   layer opacity and a data-defined colour (#38), rule-based labelling.
# tests/testthat/fixtures/bcfishpass_excerpt.qlr: two layers from bcfishpass's
#   bcfishpass_30k.qlr, to pin that a layer definition file parses (#23).
#
# Hand-written fixtures pass on the shape their author imagined: the old
# mini_project.qgs carried the label field as an <Option>, which QGIS never
# writes, so the field was missing from every extracted registry while its
# test stayed green (#6). These are QGIS's own bytes, trimmed: each maplayer
# keeps only the children the extractor reads, and a categorized renderer keeps
# its first few categories and the symbols they name.
#
#   RFP_TEMPLATE=<template-repo>/inst/templates/bcrestoration_mobile.qgs \
#   BCFISHPASS_QLR=<bcfishpass>/qgis/bcfishpass_30k.qlr \
#   Rscript data-raw/fixture_extract_template.R

qgs <- Sys.getenv("RFP_TEMPLATE", "")
qlr <- Sys.getenv("BCFISHPASS_QLR", "")
if (!file.exists(qgs)) stop("Set RFP_TEMPLATE to bcrestoration_mobile.qgs", call. = FALSE)
if (!file.exists(qlr)) stop("Set BCFISHPASS_QLR to bcfishpass_30k.qlr", call. = FALSE)

keep_children <- c("id", "datasource", "layername", "renderer-v2", "labeling",
                   "layerOpacity", "blendMode", "featureBlendMode")

# Remove every maplayer child the extractor does not read, and cut a
# categorized renderer to its first `n_cat` categories.
layer_trim <- function(m, n_cat = 3) {
  for (ch in xml2::xml_children(m)) {
    if (!xml2::xml_name(ch) %in% keep_children) xml2::xml_remove(ch)
  }
  cats <- xml2::xml_find_all(m, "./renderer-v2/categories/category")
  if (length(cats) > n_cat) {
    xml2::xml_remove(cats[-seq_len(n_cat)])
    used <- xml2::xml_attr(cats[seq_len(n_cat)], "symbol")
    syms <- xml2::xml_find_all(m, "./renderer-v2/symbols/symbol")
    xml2::xml_remove(syms[!xml2::xml_attr(syms, "name") %in% used])
  }
  invisible(m)
}

layers_keep <- function(doc, names) {
  all <- xml2::xml_find_all(doc, ".//maplayer")
  nm <- xml2::xml_text(xml2::xml_find_first(all, "./layername"))
  missing <- setdiff(names, nm)
  if (length(missing)) stop("Not in source: ", paste(missing, collapse = ", "), call. = FALSE)
  xml2::xml_remove(all[!nm %in% names])
  for (m in all[nm %in% names]) layer_trim(m)
  invisible(doc)
}

# --- template excerpt ----------------------------------------------------------
tpl <- c(
  "Lake",                           # plain field, italic, halo
  "Crossings - PSCIS assessment",   # expression label, fontWeight 75, categorized point
  "Crossings - PSCIS confirmation", # labelsEnabled with no settings
  "Municipalities",                 # fontWeight 87; outline-only fill stack
  "MoTi major structures",          # line casing; rule-based labelling, 1 rule
  "Railway",                        # line + MarkerLine ticks
  "Wetland",                        # fill + point pattern fill
  "Roads - FTEN",                   # layerOpacity 0.7; rule-based labelling, 2 rules
  "Roads - DRA",                    # categorized casing; mergeLines, minFeatureSize
  "Stream labels",                  # line placement, mergeLines
  "streams_salmon"                  # data-defined colour over a categorized renderer
)
doc <- xml2::read_xml(qgs)
layers_keep(doc, tpl)
# Drop everything outside <projectlayers>: the layer tree, layouts and
# project properties are not read and would name the removed layers.
for (ch in xml2::xml_children(doc)) {
  if (xml2::xml_name(ch) != "projectlayers") xml2::xml_remove(ch)
}
xml2::write_xml(doc, "tests/testthat/fixtures/template_excerpt.qgs")

# --- QLR excerpt ---------------------------------------------------------------
qlr_keep <- c("Railway", "Lake")
doc <- xml2::read_xml(qlr)
layers_keep(doc, qlr_keep)
tree <- xml2::xml_find_all(doc, ".//layer-tree-layer")
xml2::xml_remove(tree[!xml2::xml_attr(tree, "name") %in% qlr_keep])
xml2::write_xml(doc, "tests/testthat/fixtures/bcfishpass_excerpt.qlr")

message("fixtures written: ", length(tpl), " template layers, ",
        length(qlr_keep), " QLR layers")
