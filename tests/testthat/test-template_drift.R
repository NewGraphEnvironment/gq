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
# The comparison is against inst/registry/template_groups.csv, vendored from the
# templates by data-raw/reg_extract_template_groups.R. gq is public and rfp is
# private, so CI can never read a .qgs -- the committed artifact is the shipped
# source of truth, exactly as for the QML corpus and the theme roster.


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
#' Order is compared on the INTERSECTION only. The two sets are deliberately
#' not equal -- gq declares `Floodplain` above `Basemap` and no template has
#' that group yet -- so an assertion needing equal sets would be undefined the
#' moment gq exercises the freedom it is supposed to have. Relative order of
#' what both sides carry is well-defined under any set difference.
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
  Floodplain = paste(
    "bcrestoration only. gq declares it above Basemap deliberately -- 46% of",
    "one project's change area is water-class and Basemap's waterbody fills",
    "draw over it. No template has the group yet; rfp#216 adds it."
  ),
  Restoration = paste(
    "bcrestoration only. harvest_area and planting_site are `local` layers",
    "with no template equivalent. rfp#216 adds the group."
  ),
  "Basemap/Terrestrial Ecology" = paste(
    "Present in bcrestoration, absent from bcfishpass -- and groups.csv has no",
    "`template` column, so a subgroup declared once is declared for every",
    "template whose top-level group is declared. gq cannot express",
    "per-template subgroup membership. Pre-dates this issue as `Basemap/BEC`,",
    "which existed in NEITHER template; the rename made it correct for one.",
    "rfp#216 asks whether bcfishpass should carry it."
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
    "holds Tracking, Field Data and Model Parameters - none of which has a",
    "registry entry (gq#64). gq cannot order a group it styles nothing in."
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
  # When rfp#216 lands, this fails and tells you to delete the entry -- rather
  # than sitting here forever exempting a group that stopped needing it.
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
  # `Model Parameters - bcfishpass ` -- is not drift, it is gq#64.
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


# --- drift against the live templates -----------------------------------------

test_that("the vendored table is identical to what the templates say now", {
  # The drift guard proper, and the only test here that needs rfp. Skipped
  # wherever rfp is absent -- which is every CI run, since gq is public and rfp
  # is private -- hence the structural assertions above, which always run.
  #
  # RFP_TEMPLATE_DIR first, for the reason data-raw/reg_extract_themes.R takes
  # it: system.file() resolves to the INSTALLED rfp, routinely behind the
  # checkout the table was vendored from, so comparing against whatever happens
  # to be installed pins an undeclared dependency and reports false drift.
  dir <- Sys.getenv("RFP_TEMPLATE_DIR", "")
  if (!nzchar(dir)) {
    skip_if_not_installed("rfp")
    dir <- system.file("templates", package = "rfp")
  }
  skip_if(dir == "" || !dir.exists(dir), "no rfp templates to compare against")

  live <- do.call(rbind, lapply(templates, function(tpl) {
    p <- file.path(dir, paste0(tpl, ".qgs"))
    skip_if_not(file.exists(p), paste0("template absent: ", tpl))
    cbind(template = tpl, qgs_group_table(p), stringsAsFactors = FALSE)
  }))
  live <- live[order(live$template, live$group_path), ]
  row.names(live) <- NULL

  vendored <- read_template_groups_csv()
  row.names(vendored) <- NULL

  expect_equal(vendored, live)
})
