# The composition chain fails silently at every join, so it needs guards.
#
# templates.csv -> groups.csv -> reg_main.json is three joins deep, and none of
# them reports a miss. `join_registry()` (R/gq_groups.R:290-304) turns an absent
# registry entry into NA_character_ with no warning and no drop; the
# groups-to-templates step is a plain `%in%` (:190), so a group nothing maps to
# simply contributes no rows.
#
# The visible cost (gq#40): a project built from `bcrestoration_mobile` shows
# cartography for five layers it never downloaded, and `Base - Orthoimagery` had
# been mapped to zero templates for the entire history of the file with a green
# suite. Nothing here is clever -- these are the assertions whose absence let
# that happen.
#
# gq#40's fix then declared `Base - Orthoimagery` without checking any template,
# where it had never existed. gq#66 deleted the group and moved
# `orthophoto_tiles` to `Basemap/Terrestrial Ecology`, which is where the
# template keeps it; test-template_drift.R is the guard that would have caught
# it. These assertions and those are complementary -- this file checks the
# registry against itself, that one checks it against the projects it
# describes.

# `source_type` is the discriminator for whether a layer needs a source_layer,
# so it has to be trustworthy before anything keys on it. It is otherwise
# unvalidated and nearly unconsumed, so a typo -- "BCDATA", "bcdata " -- would
# fall through every branch below and exempt the layer silently.
source_types_known <- c("aws", "bcdata", "fwa", "local", "osm", "wms")

test_that("source_type comes from a closed set", {
  st <- gq_groups()$source_type
  expect_gt(length(st), 0)
  expect_setequal(setdiff(unique(st), source_types_known), character(0))
})

test_that("every layer that needs a source to fetch from has one", {
  # The defect behind gq#40, generalised. A layer with cartography and no source
  # is styled for data nobody downloads.
  #
  # The rule is DERIVED from source_type rather than read off a hand-maintained
  # exemption list. That matters for the direction it fails in: a list has to be
  # extended for each new layer, so a layer added tomorrow defaults to *exempt*.
  # Under a derived rule it defaults to *checked*.
  #
  #   aws/bcdata/fwa/osm -> a real, schema-qualified table, or a named file
  #   wms                -> no table; these are tile/service endpoints
  #   local              -> source_layer == layer_key, the sentinel convention
  #                         already used by form_pscis and form_fiss_site
  reg <- gq_reg_main()
  g <- gq_groups(reg)

  needs <- g[g$source_type %in% c("aws", "bcdata", "fwa", "osm"), ]
  expect_gt(nrow(needs), 0)
  expect_setequal(needs$layer_key[is.na(needs$source_layer)], character(0))

  # This check used to be `grepl(".", source_layer, fixed = TRUE)` -- "contains
  # a dot" standing in for "is schema-qualified". The two part company the
  # moment a source is a FILE rather than a table: gq#82 typed habitat_lateral
  # `aws` with source_layer `habitat_lateral.tif`, which satisfies the dot
  # check by accident and would have gone in unexamined. A rule that blesses
  # any string containing a dot is not testing what its own comment claims.
  #
  # So the shapes are spelled out, and a file target additionally has to be
  # NAMED below. That keeps the derived-rule property this test argues for at
  # :39-42 -- a layer added tomorrow must either look like schema.table or be
  # a deliberate entry, never exempt by default.
  re_table <- "^[a-z][a-z0-9_]*\\.[a-z][a-z0-9_]*$"
  re_file <- "^[a-z][a-z0-9_]*\\.(tif|tiff)$"

  # rfp fetches this one with `rio mask` straight off /vsicurl/ and writes a
  # standalone .tif beside the project rather than a GeoPackage table -- its
  # own sentinel, `RFP-LOADED-FILE:`, in inst/scripts/rfp_source_aws.sh.
  # There is no schema to qualify it with.
  file_target_reason <- c(
    habitat_lateral = "gq#82: s3://newgraph/habitat_lateral.tif, clipped to AOI"
  )

  tables <- needs[!needs$layer_key %in% names(file_target_reason), ]
  expect_gt(nrow(tables), 0)
  expect_setequal(tables$layer_key[!grepl(re_table, tables$source_layer)],
                  character(0))

  # A named file target must actually BE one, or the entry is dead wood that
  # silently exempts a layer from the table rule. Same shape as the "must still
  # be needed" half under local_exempt below.
  files <- needs[needs$layer_key %in% names(file_target_reason), ]
  expect_setequal(files$layer_key, names(file_target_reason))
  expect_setequal(files$layer_key[!grepl(re_file, files$source_layer)],
                  character(0))
  expect_setequal(files$layer_key[grepl(re_table, files$source_layer)],
                  character(0))

  services <- g[g$source_type == "wms", ]
  expect_gt(nrow(services), 0)
  expect_setequal(services$layer_key[!is.na(services$source_layer)],
                  character(0))

  # The exemption list, and it is EMPTY -- which is not an oversight, it is the
  # state this guard is supposed to be in. Every entry was a tracked decision
  # naming the issue that would remove it, and gq#64 removed the last three:
  # form_edna and form_monitoring moved to form_types.csv (they are real forms,
  # injected per project by rfp_qgs_form_add() rather than shipped in a
  # template), and habitat_lateral gained a reg_custom.csv entry carrying its
  # paletted symbology.
  #
  # setNames() rather than character(0), and this is not style. The assertion
  # below calls names() on this, and names(character(0)) is NULL -- which
  # expect_setequal() REFUSES ("`object` must be a vector, not `NULL`"). So the
  # obvious spelling of "empty" makes this test error rather than pass.
  local_exempt <- stats::setNames(character(0), character(0))

  local <- g[g$source_type == "local", ]
  expect_gt(nrow(local), 0)
  offenders <- local$layer_key[is.na(local$source_layer) |
                                 local$source_layer != local$layer_key]
  expect_setequal(setdiff(offenders, names(local_exempt)), character(0))

  # And the exemptions must still be needed. When gq#64 lands, this fails and
  # tells you to delete them -- rather than sitting here forever exempting
  # layers that stopped needing it.
  expect_setequal(setdiff(names(local_exempt), offenders), character(0))
})

test_that("the three aws rows gq#82 settled still say what was decided", {
  # gq's registry is what rfp REQUESTS from the newgraph bucket -- not
  # rfp/inst/lookups/rfp_source_aws.txt, which is only the gq-absent fallback.
  # rfp_project_create() -> rfp_project_layers() -> gq::gq_template_layers(),
  # and the aws source_layers go straight into RFP_SOURCES. So a wrong value
  # here is a failed download on every project build, reported as one line in a
  # 16-minute log and otherwise indistinguishable from a layer that is simply
  # empty in the AOI.
  #
  # Measured against the bucket 2026-09-07 (anonymous HEAD, no credentials):
  # 7 of 9 distinct aws source_layers resolved 200; these three are the ones
  # that had to move or be explained.
  g <- gq_groups(gq_reg_main())
  row_for <- function(key) {
    r <- g[g$layer_key == key, ]
    expect_equal(nrow(r), 1L)   # not a set-membership question; a per-row pin
    r
  }

  # Was `local` with the sentinel source_layer == layer_key, so
  # rfp_project_create() never asked for it and every project hand-clipped the
  # raster. It is an ordinary S3 object and always was.
  hl <- row_for("habitat_lateral")
  expect_equal(hl$source_type, "aws")
  expect_equal(hl$source_layer, "habitat_lateral.tif")

  # Renamed upstream. db_newgraph/jobs/dump_weekly writes
  # bcfishobs.observations.fgb.zip from `select * from bcfishobs.observations`;
  # the old name 404s. Read from the producer rather than inferred from a
  # bucket listing.
  #
  # NOTE this value is deliberately AHEAD of rfp's templates, whose maplayer
  # datasource still reads `layername=bcfishobs.fiss_fish_obsrvtn_events_vw`.
  # source_layer is simultaneously the S3 object stem, the GeoPackage table
  # name and that datasource, so the layer only resolves once rfp lands its
  # side. This assertion is what turns a re-extraction that reverts us red.
  ob <- row_for("bcfishobs_fiss_fish_observations")
  expect_equal(ob$source_type, "aws")
  expect_equal(ob$source_layer, "bcfishobs.observations")

  # Deliberately UNCHANGED. Nothing stages it -- no job on any db_newgraph
  # branch uploads a dams object, and the database calls the view
  # bcfishpass.dams_vw. That is a staging gap, and dropping the row here would
  # hide it: the project side assumes the layer exists. Filed upstream against
  # our own fork.
  dm <- row_for("dam")
  expect_equal(dm$source_type, "aws")
  expect_equal(dm$source_layer, "bcfishpass.dams")
})

test_that("renaming bcfishobs did not cost it its symbology", {
  # gq_reg_merge() REPLACES a layer entry rather than merging its fields --
  # measured: an entry carrying only type + source_layer dropped `mark`
  # entirely. So the obvious way to retarget this layer, a one-column
  # reg_custom.csv row, would silently delete the symbology gq_qgs_extract()
  # lifted from the .qgs.
  #
  # These four values are that symbology. They are pinned here rather than
  # left implicit because the deletion is invisible: the layer would still
  # resolve, still have a source, and simply draw as nothing.
  lyr <- gq_reg_main()$layers$bcfishobs_fiss_fish_observations

  expect_equal(lyr$type, "point")
  expect_equal(lyr$mark$color, "#db1e2a")
  expect_equal(lyr$mark$shape, "triangle")
  expect_equal(lyr$label$font, "Courier")
})

test_that("wms layers are exactly the services in the QML index", {
  # Two hand-maintained columns, authored separately, that must agree. Cheap to
  # pin and it makes each a second witness for the other.
  idx_path <- system.file("styles", "index.csv", package = "gq")
  idx <- utils::read.csv(idx_path, stringsAsFactors = FALSE)
  g <- gq_groups()

  wms <- sort(unique(g$layer_key[g$source_type == "wms"]))
  svc <- sort(unique(idx$layer_key[idx$kind == "service"]))
  expect_gt(length(wms), 0)
  expect_equal(wms, svc)
})

test_that("draw order is unambiguous within a group", {
  # `order` is z-order: which layer draws over which. A duplicate makes the
  # result depend on row order in the file rather than on the value, so two
  # polygons silently swap depending on how the CSV was last edited.
  #
  # Added after inserting two rows into Basemap produced exactly that -- a
  # shifted tail collided with an inserted value, and nothing complained.
  g <- gq_groups()
  g$subgroup[is.na(g$subgroup)] <- ""
  for (k in unique(paste(g$group, g$subgroup, sep = "|"))) {
    parts <- strsplit(k, "|", fixed = TRUE)[[1]]
    rows <- g[g$group == parts[1] & g$subgroup == (if (length(parts) > 1) parts[2] else ""), ]
    expect_equal(anyDuplicated(rows$order), 0L,
                 label = paste0("duplicate order in '", k, "'"))
  }
})

test_that("layer_key is unique across groups.csv", {
  # gq_template_layers() asserts its output has no duplicates; that holds only
  # because keys are unique here. Pin the thing the other assertion rests on.
  expect_equal(anyDuplicated(gq_groups()$layer_key), 0L)
})

test_that("every group in groups.csv is mapped to at least one template", {
  # The failure gq#40 is about. A group nothing maps to is dead weight: its
  # layers are styled, indexed and ordered, and no template ever asks for them.
  groups <- unique(gq_groups()$group)
  mapped <- unique(gq_templates()$group)

  expect_gt(length(groups), 0)   # premise: there are groups to check at all
  expect_setequal(setdiff(groups, mapped), character(0))
})

test_that("every group named in templates.csv exists in groups.csv", {
  # The same join from the other side. True today by luck -- nothing enforces
  # it, so a typo in templates.csv would silently contribute zero layers rather
  # than erroring.
  groups <- unique(gq_groups()$group)
  mapped <- unique(gq_templates()$group)

  expect_gt(length(mapped), 0)
  expect_setequal(setdiff(mapped, groups), character(0))
})

test_that("a template's layers are the union of its groups' layers", {
  # Pins the chain end to end, so a future change to either join has to break
  # this rather than quietly returning fewer rows.
  reg <- gq_reg_main()
  for (tpl in unique(gq_templates()$template)) {
    expected <- unlist(lapply(gq_template_groups(tpl)$group,
                              function(g) gq_group_layers(g)$layer_key))
    got <- gq_template_layers(tpl, reg)$layer_key
    expect_setequal(got, expected)
    expect_equal(anyDuplicated(got), 0L)   # a layer must not arrive twice
  }
})

test_that("template asymmetry is deliberate, not accidental", {
  # `Floodplain` and `Restoration` are restoration-only ON PURPOSE. Recording
  # that here means the guards above cannot be satisfied by quietly mapping
  # every group to every template -- which would make them pass and make the
  # templates wrong.
  restoration_only <- c("Floodplain", "Restoration")
  tpl <- gq_templates()

  for (g in restoration_only) {
    mapped_to <- tpl$template[tpl$group == g]
    expect_equal(mapped_to, "bcrestoration_mobile",
                 label = paste0("groups mapped for '", g, "'"))
  }
})

test_that("group_order is sort-only: neither contiguous nor cross-template", {
  # gq#40 asked whether the ordering model survives many project types. It does:
  # `group_order` is read by two order() calls (R/gq_groups.R:152, :201) and
  # validated nowhere -- not for uniqueness, contiguity, or a 1-based start.
  #
  # This test exists to KEEP that true. The risk is not that the model fails to
  # scale, it is that someone infers contiguity is required from the two
  # templates that happen to have it, and adds a validator that breaks a future
  # template numbering its groups 10/20/30 or sharing no vocabulary at all.
  df <- data.frame(
    template = "sparse_project",
    group = c("Zulu", "Alpha", "Mike"),
    group_order = c(300, 100, 200)
  )
  sorted <- df[order(df$group_order), , drop = FALSE]
  expect_equal(sorted$group, c("Alpha", "Mike", "Zulu"))

  # Uniqueness within a template is the property that actually matters -- it is
  # what makes the sort deterministic. Nothing else about the values does.
  #
  # The first version of this asserted the rows appear IN THE FILE in ascending
  # order, which contradicts the freedom the test exists to protect: appending a
  # future group at the bottom of a block with a mid-range number would have
  # failed it. An assertion that forbids the thing named in its own header is
  # worse than none.
  tpl <- gq_templates()
  per_template <- split(tpl$group_order, tpl$template)
  for (nm in names(per_template)) {
    expect_equal(anyDuplicated(per_template[[nm]]), 0L,
                 label = paste0("duplicate group_order within '", nm, "'"))
  }
})
