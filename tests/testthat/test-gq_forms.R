# The form roster is vendored from rfp, so every guard here is really asking one
# question: did the vendoring preserve the thing gq keys on?
#
# The answer cannot come from re-running the derivation, because that is what is
# under test. It comes from `reg_main.json`, whose form_pscis and form_fiss_site
# keys were produced by gq_qgs_extract() reading a .qgs that QGIS itself wrote.

test_that("the roster is shaped as its consumers assume", {
  f <- gq_form_types()

  expect_setequal(
    names(f),
    c("layer_key", "form_type", "label", "description", "layer_name",
      "geometry", "symbol", "color", "label_expression")
  )
  expect_gt(nrow(f), 0)
  expect_equal(anyDuplicated(f$layer_key), 0L)
  expect_equal(anyDuplicated(f$form_type), 0L)

  # No NA in the identity columns. `na.strings = c("", "NA")` means an empty
  # field reads as NA, so a truncated row would arrive as a silent NA key rather
  # than as a parse error.
  for (col in c("layer_key", "form_type", "label", "layer_name", "geometry")) {
    expect_false(anyNA(f[[col]]), label = paste0("NA in ", col))
  }
})

test_that("layer_key is derivable from layer_name for every row", {
  # The structural invariant, not a list of examples. A fixture set of
  # hand-picked keys tests the keys someone thought of; this sweeps the whole
  # table and cannot be satisfied by choosing convenient rows.
  f <- gq_form_types()

  expect_true(all(startsWith(f$layer_name, " Form ")))
  expect_equal(
    vapply(f$layer_name, normalize_layer_name, character(1), USE.NAMES = FALSE),
    f$layer_key
  )
})

test_that("the derived keys reproduce the keys QGIS produced", {
  # THE ORACLE. Everything else here checks the roster against itself; this
  # checks it against the consumer's own output. form_pscis and form_fiss_site
  # reached reg_main.json from a .qgs QGIS wrote, so if the ` Form <label>`
  # derivation is wrong, it is wrong here first.
  f <- gq_form_types()
  reg <- gq_reg_main()

  oracle <- c("form_pscis", "form_fiss_site")
  expect_true(all(oracle %in% names(reg$layers)))   # premise
  expect_true(all(oracle %in% f$layer_key))
})

test_that("the key comes from the label, not the type", {
  # The discriminating case, and the reason the derivation is not simply
  # paste0("form_", type): rfp labels `monitoring_fish_passage` as "Fish Passage
  # Monitoring", so the key reverses the word order.
  #
  # A key built from the type column would be form_monitoring_fish_passage, and
  # NOTHING downstream would report it -- every lookup goes through the key on
  # both sides, so the wrong key is merely a key that matches nothing.
  f <- gq_form_types()
  row <- f[f$form_type == "monitoring_fish_passage", ]

  expect_equal(nrow(row), 1L)                                   # premise
  expect_equal(row$layer_key, "form_fish_passage_monitoring")
  # and the two genuinely disagree, so this test can fail
  expect_false(row$layer_key == paste0("form_", row$form_type))
})

test_that("the roster carries only spatial forms", {
  # rfp registers non-spatial child tables in the same file --
  # cabin_visit_pebble has no geometry, a parent of cabin_visit, and is written
  # into the parent's GeoPackage. A layer roster must not carry it.
  f <- gq_form_types()

  # `nzchar(NA)` is TRUE and the reader maps an empty field to NA, so
  # `all(nzchar(x))` passes for BOTH reachable states and cannot fail. anyNA()
  # is the assertion that does the work; keep the emptiness check paired with
  # it rather than standing alone.
  expect_false(anyNA(f$geometry))
  expect_true(all(!is.na(f$geometry) & nzchar(f$geometry)))
  expect_false("form_cabin_pebbles" %in% f$layer_key)

  # Premise: the parent IS present, so the exclusion is of the child
  # specifically rather than of the whole cabin family -- which is what a
  # too-broad filter would look like from here.
  expect_true("form_cabin_visit" %in% f$layer_key)
})

test_that("an unstyled form reads as NA, and some forms are styled", {
  # gq does not invent symbology for a form rfp has not styled. Pinning that
  # needs BOTH halves: without the second expectation a roster where every
  # colour was lost to a parsing bug would pass the first.
  f <- gq_form_types()

  expect_true(any(is.na(f$color)))
  expect_true(any(!is.na(f$color)))
  expect_true(all(is.na(f$color) == is.na(f$symbol)))

  # The four rfp has registered without deciding an appearance. Named, because
  # this is the list the rfp issue asks to shrink -- when it does, this fails
  # and says so rather than silently tracking whatever is currently unstyled.
  expect_setequal(
    f$layer_key[is.na(f$color)],
    c("form_edna", "form_fhap", "form_fish_sample", "form_monitoring")
  )
})

test_that("every form the templates ship is in the roster", {
  # The join that matters. groups.csv carries the forms the templates ship;
  # form_types.csv is the catalogue they are drawn from. A form grouped but
  # absent from the catalogue is the gq#64 defect coming back.
  f <- gq_form_types()
  grouped <- gq_group_layers("Forms")$layer_key

  expect_gt(length(grouped), 0)                     # premise
  expect_setequal(setdiff(grouped, f$layer_key), character(0))
})
