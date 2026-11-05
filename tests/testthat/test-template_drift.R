# gq declares group composition and order; the shipped .qgs templates are what
# actually place the nodes. Nothing compared them, so the declaration drifted
# into fiction -- three groups declared that no template has, two the templates
# have that gq never declared, four names differing by case or separator.
#
# The cost was not theoretical. `rfp_project_create()` copies a template and
# trims it, so a group gq declares but the template lacks does not exist in a new
# project and gets hand-added at whatever position the person is standing in --
# which is the END of the tree. Tree order is draw order, so the group renders
# beneath `Base - misc`, which holds four opaque xyz basemaps the themes turn on.
# A field user lost a floodplain that way, and a second lost a trails layer whose
# labels drew but whose lines did not. See gq#66.
#
# The comparison is against inst/registry/template_groups.csv and
# template_layers.csv, vendored from the templates by
# data-raw/reg_extract_template_groups.R. gq is public and rfp is private, so CI
# can never read a .qgs -- the committed artifact is the shipped source of
# truth, and test-vendored_currency.R is what checks it is still current.


# --- the comparison, as a function both the real test and the alarm can call --

#' gq's declared depth-1 groups for a template, in declared order
gq_declared_groups <- function(template) {
  g <- gq_template_groups(template)
  g$group[order(g$group_order)]
}

#' A template's depth-1 groups, in document order
tpl_declared_groups <- function(tbl, template) {
  t <- tbl[tbl$template == template & tbl$depth == 1L, , drop = FALSE]
  t$group_path[order(t$order)]
}

#' Compare the two, returning every kind of divergence separately
#'
#' Order is compared on the INTERSECTION only. The two sets need not be equal --
#' `Floodplain` sat in gq above `Basemap` before rfp#216 shipped it, and gq
#' skips groups it draws nothing in (`template_group_exempt`) -- so an assertion
#' needing equal sets would be undefined the moment gq exercises the freedom it
#' is supposed to have. Relative order of what both sides carry is well-defined
#' under any set difference.
compare_groups <- function(gq_order, tpl_order) {
  common <- intersect(gq_order, tpl_order)
  list(
    declared_not_in_template = setdiff(gq_order, tpl_order),
    in_template_not_declared = setdiff(tpl_order, gq_order),
    gq_relative  = gq_order[gq_order %in% common],
    tpl_relative = tpl_order[tpl_order %in% common]
  )
}

# EMPTY IS A VALID STATE. Every entry is a tracked decision with an issue that
# removes it -- never a "not done yet". The assertion below that each exemption
# is still NEEDED is what stops this list quietly becoming the whole input, at
# which point the guard cannot fail and reads as diligence anyway.
group_exempt <- c(
  "Basemap/Terrestrial Ecology" = paste(
    "bcrestoration only, by rfp's decision: rfp#216 declined to grow it in",
    "bcfishpass, whose template carries none of its layers. groups.csv has no",
    "`template` column, so a subgroup declared once is declared for every",
    "template whose top-level group is declared, and gq cannot say",
    "'bcrestoration only'. Whether to add that column is a registry schema",
    "decision, deferred to gq#104 (gq#70, gq#100)."
  )
)

# The other direction: a template group gq deliberately does not declare. Same
# rules -- a reason each, and asserted still needed below.
#
# The distinction that makes these exempt rather than a gap: gq orders groups it
# carries layers for. Neither of these has a single layer in the registry, and
# both already sit at a sane position in the shipped tree, so nothing a project
# does can push them under the basemaps. Declaring them would put two rows in
# templates.csv that groups.csv cannot back, which is the fiction this issue is
# about, pointed the other way.
template_group_exempt <- c(
  "Project Specific" = paste(
    "holds Tracking, parameters_habitat_method and",
    "parameters_habitat_thresholds -- the three tables rfp names as",
    "'Non-spatial rfp-owned tables' (.rfp_audit_whitelist, rfp",
    "R/rfp-constants.R) -- plus the empty Field Data subgroup. Nothing there",
    "for a map to draw or order, so the three stay unregistered by decision",
    "(gq#73)."
  ),
  "Base - lidar" = paste(
    "EMPTY in both shipped templates - a placeholder a project drops lidar",
    "rasters into. There is nothing for the registry to declare."
  )
)

templates <- c("bcfishpass_mobile", "bcrestoration_mobile")


test_that("the vendored table is shaped as the guards assume", {
  tbl <- read_template_groups_csv()
  expect_setequal(names(tbl), c("template", "group_path", "depth", "order"))
  expect_setequal(unique(tbl$template), templates)
  expect_gt(nrow(tbl), 0)
  # Premise for every depth-1 comparison below: there ARE depth-1 groups. A
  # comparison over an empty set passes for nothing.
  for (tpl in templates) {
    expect_gt(length(tpl_declared_groups(tbl, tpl)), 0)
  }
})


test_that("byte-exact names survive the CSV round-trip", {
  # `Model Parameters - bcfishpass ` ends in a space, and the project roots do
  # too. readr::read_csv() defaults to trim_ws = TRUE and would eat it; the
  # trimmed value still looks like a name, and the join it breaks reports
  # nothing. This is why read_template_groups_csv() uses utils::read.csv().
  tbl <- read_template_groups_csv()
  expect_true("Project Specific/Model Parameters - bcfishpass " %in%
                tbl$group_path)
  # And the comma, which is why the file is quoted while its siblings were not.
  expect_true("Roads,Railways,Pipelines" %in% tbl$group_path)
})


test_that("every group gq declares exists in the template", {
  tbl <- read_template_groups_csv()
  for (tpl in templates) {
    cmp <- compare_groups(gq_declared_groups(tpl), tpl_declared_groups(tbl, tpl))
    expect_setequal(
      setdiff(cmp$declared_not_in_template, names(group_exempt)),
      character(0)
    )
  }
})


test_that("every group the template has is declared by gq", {
  # The other direction, and the one that let `Project Specific` and
  # `Base - lidar` sit in both shipped templates while gq had never heard of
  # them. A group gq does not declare is a group gq cannot order.
  tbl <- read_template_groups_csv()
  for (tpl in templates) {
    cmp <- compare_groups(gq_declared_groups(tpl), tpl_declared_groups(tbl, tpl))
    expect_setequal(
      setdiff(cmp$in_template_not_declared, names(template_group_exempt)),
      character(0)
    )
  }
})


#' Every path gq declares for a template that the template does not have
#'
#' Per template, and that is the point. `groups.csv` carries no `template`
#' column -- membership is template-agnostic and filtered only at the top level
#' by `templates.csv` (R/gq_groups.R:205) -- so a subgroup declared once is
#' declared everywhere its parent is. Comparing against the UNION of both
#' templates would have called `Basemap/Terrestrial Ecology` fine because
#' bcrestoration has it, while gq was quietly declaring it for bcfishpass, which
#' does not. That is this issue's own failure mode, at depth 2.
declared_not_present <- function(tbl, template) {
  declared <- gq_declared_groups(template)
  g <- gq_groups()
  paths <- unique(ifelse(is.na(g$subgroup) | !nzchar(g$subgroup),
                         g$group, paste(g$group, g$subgroup, sep = "/")))
  # A path is this template's business only if its top-level group is.
  relevant <- paths[sub("/.*$", "", paths) %in% declared]
  c(setdiff(declared, tpl_declared_groups(tbl, template)),
    setdiff(relevant, tbl$group_path[tbl$template == template]))
}


test_that("each exemption is still needed", {
  # When the upstream change an entry waits on lands, this fails and tells you
  # to delete the entry -- rather than sitting here forever exempting a group
  # that stopped needing it. It fired for `Floodplain` and `Restoration` once
  # the copy was re-vendored after rfp#216 (gq#70).
  tbl <- read_template_groups_csv()
  needed <- unique(unlist(lapply(templates, declared_not_present, tbl = tbl)))
  expect_setequal(setdiff(names(group_exempt), needed), character(0))

  needed_tpl <- unique(unlist(lapply(templates, function(tpl) {
    compare_groups(gq_declared_groups(tpl),
                   tpl_declared_groups(tbl, tpl))$in_template_not_declared
  })))
  expect_setequal(setdiff(names(template_group_exempt), needed_tpl),
                  character(0))
})


test_that("gq and the template agree on the order of what they share", {
  tbl <- read_template_groups_csv()
  for (tpl in templates) {
    cmp <- compare_groups(gq_declared_groups(tpl), tpl_declared_groups(tbl, tpl))
    expect_equal(cmp$gq_relative, cmp$tpl_relative, info = tpl)
  }
})


test_that("every group path gq declares exists in that template", {
  # templates.csv carries depth-1 only, so subgroup drift hid there: gq called
  # `Basemap/Terrestrial Ecology` "Basemap/BEC" and `Streams/Habitat models`
  # "Streams/Habitat Models", and nothing looked.
  #
  # One direction only. A template group holding no gq layers -- `Field Data`,
  # `Model Parameters - bcfishpass ` -- is not drift: its contents are
  # no-geometry tables gq does not register (gq#73).
  tbl <- read_template_groups_csv()
  for (tpl in templates) {
    offenders <- declared_not_present(tbl, tpl)
    expect_setequal(setdiff(offenders, names(group_exempt)), character(0))
  }
})


# --- the narrow check ---------------------------------------------------------

test_that("nothing is declared below the bottom of the template's stack", {
  # THE check. Tree order is draw order and the last node draws bottom, so a
  # group declared past the template's last group is a group beneath the opaque
  # basemaps -- invisible on the device, with nothing in the project looking
  # wrong.
  #
  # Derived, not listed: the rule reads the template's own bottom rather than a
  # hand-maintained set of "groups you must not go below", so a group added
  # tomorrow is checked by default rather than exempt by default.
  #
  # This was RED when written. gq declared `Base - Orthoimagery` at group_order
  # 11 for bcrestoration_mobile and 9 for bcfishpass_mobile -- below
  # `Base - misc` at 10 and 8 -- so the registry itself placed orthophoto tiles
  # beneath ESRI World Topo. The group had never existed in any template.
  tbl <- read_template_groups_csv()
  for (tpl in templates) {
    gq_order  <- gq_declared_groups(tpl)
    tpl_order <- tpl_declared_groups(tbl, tpl)
    expect_equal(gq_order[length(gq_order)], tpl_order[length(tpl_order)],
                 info = tpl)
  }
})


test_that("the premise of the narrow check still holds", {
  # The rule above is worth enforcing only because the template's bottom group
  # is where the opaque raster basemaps live. That is a fact about the data, not
  # a property of the rule, so assert it beside the rule: if the basemaps move,
  # this fails and names the reason rather than leaving a check that guards
  # nothing.
  opaque <- c("esri_world_topo", "bing_aerial", "esri_satellite",
              "google_satellite")
  tbl <- read_template_groups_csv()
  g <- gq_groups()

  for (tpl in templates) {
    tpl_order <- tpl_declared_groups(tbl, tpl)
    bottom <- tpl_order[length(tpl_order)]
    in_bottom <- g$layer_key[g$group == bottom &
                               (is.na(g$subgroup) | !nzchar(g$subgroup))]
    expect_equal(setdiff(opaque, in_bottom), character(0), info = tpl)
  }
})


# --- the alarm has been seen to fire ------------------------------------------

test_that("a renamed group in a template is reported", {
  # A drift guard nobody has seen fail is decoration. The fixture is the
  # bcrestoration group tree with `Basemap` renamed to `Basemaps` and
  # `Web Mapping Services` deleted -- one name divergence and one absence, the
  # two shapes this issue is about.
  #
  # The first draft deleted `Base - lidar` instead, which gq deliberately does
  # not declare (see template_group_exempt), so its absence could not surface as
  # gq-side drift and the assertion failed for the right reason. A perturbation
  # has to touch something the registry actually claims.
  path <- test_path("fixtures", "template_drift_fixture.qgs")
  skip_if_not(file.exists(path), "fixture missing")

  tbl <- qgs_group_table(path)
  tbl$template <- "bcrestoration_mobile"
  cmp <- compare_groups(gq_declared_groups("bcrestoration_mobile"),
                        tpl_declared_groups(tbl, "bcrestoration_mobile"))

  # The rename shows from both sides: gq's `Basemap` is absent upstream, and
  # the fixture's `Basemaps` is undeclared.
  expect_true("Basemap" %in% cmp$declared_not_in_template)
  expect_true("Basemaps" %in% cmp$in_template_not_declared)
  # The deletion shows from one.
  expect_true("Web Mapping Services" %in% cmp$declared_not_in_template)

  # And against the real table the same call reports neither, so the assertion
  # above is discriminating rather than always-true.
  clean <- compare_groups(gq_declared_groups("bcrestoration_mobile"),
                          tpl_declared_groups(read_template_groups_csv(),
                                              "bcrestoration_mobile"))
  expect_false("Basemap" %in% clean$declared_not_in_template)
  expect_false("Web Mapping Services" %in% clean$declared_not_in_template)
  expect_setequal(
    setdiff(clean$in_template_not_declared, names(template_group_exempt)),
    character(0)
  )
})


test_that("qgs_group_table refuses what it cannot represent", {
  expect_error(qgs_group_table(42), "single non-NA string")
  expect_error(qgs_group_table("no_such_file.qgs"), "Template not found")

  # "/" is the path separator, so a group carrying one makes every path
  # ambiguous. Not hypothetical: gq's own registry called that group
  # `Roads/Rails/Pipelines` until this issue.
  slashed <- withr::local_tempfile(fileext = ".qgs")
  writeLines(c(
    "<qgis version=\"4.2.1\">",
    "  <layer-tree-group>",
    "    <layer-tree-group name=\"root \">",
    "      <layer-tree-group name=\"Roads/Rails/Pipelines\"/>",
    "    </layer-tree-group>",
    "  </layer-tree-group>",
    "</qgis>"
  ), slashed)
  expect_error(qgs_group_table(slashed), "path separator")
})


# --- layer placement (gq#68) --------------------------------------------------
#
# The group-level checks above cannot see a layer filed under the wrong group,
# and each such filing is a draw-order claim: `streams_all` under `Streams`
# draws over different things than `streams_all` under `Basemap/Waterbodies`.
# Six layers disagreed until gq#68; every one of gq's six rows dated from the
# registry's first commit with no measurement behind it, so the templates'
# placement was adopted rather than defended.

#' Each layer gq and the template both carry, where gq's group path differs
placement_drift <- function(layers, template) {
  g <- gq_groups()
  gq_path <- ifelse(is.na(g$subgroup) | !nzchar(g$subgroup), g$group,
                    paste(g$group, g$subgroup, sep = "/"))
  names(gq_path) <- g$layer_key
  t <- layers[layers$template == template, , drop = FALSE]
  t <- t[t$layer_key %in% names(gq_path), , drop = FALSE]
  bad <- t$group_path != gq_path[t$layer_key]
  data.frame(layer_key = t$layer_key[bad],
             template_path = t$group_path[bad],
             gq_path = unname(gq_path[t$layer_key[bad]]),
             stringsAsFactors = FALSE)
}

# EMPTY IS A VALID STATE, and the state gq#68 left it in. Same rules as
# group_exempt: a reason each, asserted still needed.
# Named-empty, not character(0): names(character(0)) is NULL, which the
# setdiff() checks below would read as "no names to check" only by accident.
layer_exempt <- stats::setNames(character(0), character(0))

# Template layers gq deliberately does not register. A layer that is neither
# here nor in groups.csv fails below, so a layer added upstream is a decision
# someone has to make rather than one nobody notices.
layer_unregistered_exempt <- c(
  tracking = paste(
    "rfp_tracking, the provenance table every source pass appends to; rfp",
    "lists it as non-spatial in .rfp_audit_whitelist (R/rfp-constants.R).",
    "Nothing for a map to draw (gq#73)"
  ),
  parameters_habitat_method = paste(
    "bcfishpass parameter table, non-spatial per rfp's .rfp_audit_whitelist.",
    "Its QML is vendored for QGIS, which shows it as a table (gq#73)"
  ),
  parameters_habitat_thresholds = paste(
    "bcfishpass parameter table, non-spatial per rfp's .rfp_audit_whitelist.",
    "Its QML is vendored for QGIS, which shows it as a table (gq#73)"
  )
)


test_that("the vendored layer table joins to the registry", {
  # Premise for the placement check: a join over nothing passes for nothing.
  # The six gq#68 moved must all be in the overlap, in both templates where
  # the template carries them.
  layers <- read_template_layers_csv()
  expect_setequal(names(layers),
                  c("template", "group_path", "layer", "layer_key", "order"))
  expect_setequal(unique(layers$template), templates)
  # The placement join needs one row per key per template; two would let one
  # row's group stand for the other's. The extractor refuses this at write
  # time, and this holds the committed file to it.
  expect_false(anyDuplicated(layers[c("template", "layer_key")]) > 0)
  keys <- gq_groups()$layer_key
  for (tpl in templates) {
    shared <- intersect(layers$layer_key[layers$template == tpl], keys)
    expect_gt(length(shared), 30)
    expect_true(all(c("streams_all", "stream_labels", "first_nation_reserve",
                      "fisheries_sensitive_watersheds") %in% shared),
                info = tpl)
  }
  expect_true(all(c("terrain_mapping_project_boundaries",
                    "terrestrial_ecosystem_information_scanned_map_boundary") %in%
                    layers$layer_key[layers$template == "bcrestoration_mobile"]))
})


test_that("every layer sits in the group the template puts it in", {
  # One way only: a layer the template carries and groups.csv does not is the
  # next test's business, and a groups.csv layer absent from a template (town,
  # dam, the two Restoration layers...) has no placement to compare.
  layers <- read_template_layers_csv()
  for (tpl in templates) {
    d <- placement_drift(layers, tpl)
    expect_equal(d[!d$layer_key %in% names(layer_exempt), , drop = FALSE],
                 d[0, , drop = FALSE], info = tpl)
  }
})


test_that("every template layer is registered or exempt", {
  layers <- read_template_layers_csv()
  unregistered <- setdiff(layers$layer_key, gq_groups()$layer_key)
  expect_setequal(setdiff(unregistered, names(layer_unregistered_exempt)),
                  character(0))
})


test_that("each layer exemption is still needed", {
  layers <- read_template_layers_csv()
  drifted <- unique(unlist(lapply(templates, function(tpl) {
    placement_drift(layers, tpl)$layer_key
  })))
  expect_setequal(setdiff(names(layer_exempt), drifted), character(0))

  unregistered <- setdiff(layers$layer_key, gq_groups()$layer_key)
  expect_setequal(setdiff(names(layer_unregistered_exempt), unregistered),
                  character(0))
})


test_that("a layer filed under the wrong group is reported", {
  # The fixture files `Lake` under `Streams`; groups.csv has it in
  # `Basemap/Waterbodies`.
  path <- test_path("fixtures", "template_layers_fixture.qgs")
  skip_if_not(file.exists(path), "fixture missing")

  tbl <- qgs_layer_table(path)
  # The leading space survives the walk, and the key sees past it.
  expect_true(" Biogeoclimatic Ecosystem Classification" %in% tbl$layer)
  expect_true("biogeoclimatic_ecosystem_classification" %in% tbl$layer_key)

  tbl$template <- "bcrestoration_mobile"
  d <- placement_drift(tbl, "bcrestoration_mobile")
  expect_equal(d$layer_key, "lake")
  expect_equal(d$template_path, "Streams")
  expect_equal(d$gq_path, "Basemap/Waterbodies")

  # Against the real table the same call reports nothing for `lake`, so the
  # assertion above is discriminating rather than always-true.
  clean <- placement_drift(read_template_layers_csv(), "bcrestoration_mobile")
  expect_false("lake" %in% clean$layer_key)
})


# --- drift against the live templates -----------------------------------------
#
# Moved to test-vendored_currency.R (gq#78), which rebuilds template_groups.csv
# and template_layers.csv -- and the theme and form rosters -- from a live rfp
# source and compares the files. Everything above reads the committed copies,
# so it is only as current as the last re-vendor; that test is what says so.
