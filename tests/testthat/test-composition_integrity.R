# The composition chain fails silently at every join, so it needs guards.
#
# templates.csv -> groups.csv -> reg_main.json is three joins deep, and none of
# them reports a miss. `join_registry()` (R/gq_groups.R:290-304) turns an absent
# registry entry into NA_character_ with no warning and no drop; the
# groups-to-templates step is a plain `%in%` (:190), so a group nothing maps to
# simply contributes no rows.
#
# The visible cost (gq#40): a project built from `bcrestoration_mobile` shows
# cartography for five layers it never downloaded, and `Base - Orthoimagery` has
# been mapped to zero templates for the entire history of the file with a green
# suite. Nothing here is clever -- these are the assertions whose absence let
# that happen.

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

  # And the shipped templates must not be assumed to agree with each other.
  tpl <- gq_templates()
  per_template <- split(tpl$group_order, tpl$template)
  for (nm in names(per_template)) {
    expect_equal(per_template[[nm]], sort(per_template[[nm]]),
                 label = paste0("group_order sorted within '", nm, "'"))
  }
})
