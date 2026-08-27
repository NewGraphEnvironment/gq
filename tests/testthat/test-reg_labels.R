# Guards on the label text shipped in reg_main.json.
#
# These are data assertions, not function assertions: reg_main.json is a build
# artifact of data-raw/reg_build_main.R, and the thing being guarded is that the
# build's label correction actually reached the shipped registry.

# The three layers whose mapping_code classification carries an ACCESS token.
mapping_code_layers <- c("streams_salmon", "streams_st", "streams_bt")

class_labels <- function(reg, layer) {
  cls <- reg$layers[[layer]]$classification$classes
  vapply(cls, function(x) x$label %||% NA_character_, character(1))
}

test_that("no ACCESS class is labelled with a barrier-status phrase", {
  # `mapping_code` is `<habitat use>;<barrier status>[;INTERMITTENT]`. Token 1
  # is habitat use -- SPAWN is "Spawning", REAR is "Rearing", ACCESS is
  # "Accessible". Labelling ACCESS with a barrier phrase produces
  # "No known barriers; known barrier", which contradicts itself in a legend.
  #
  # Upstream authoring bug, corrected at build time until bcfishpass#13 lands.
  reg <- gq_reg_main()

  for (layer in mapping_code_layers) {
    labs <- class_labels(reg, layer)
    access <- labs[grepl("^ACCESS;", names(labs))]

    # The premise: this layer really does have ACCESS classes to check. Without
    # it a renamed key would empty the vector and the assertion below would pass
    # for nothing.
    expect_gt(length(access), 0)
    expect_false(any(grepl("^No known barriers; ", access)),
                 label = paste0(layer, " ACCESS labels"))
    expect_true(all(grepl("^Accessible; ", access)),
                label = paste0(layer, " ACCESS labels"))
  }
})

test_that("the correction leaves SPAWN and REAR labels alone", {
  # The rewrite is anchored to the leading token, so it must not touch the other
  # two habitat tiers -- nor the token2 status wording, which is correct
  # everywhere and is where "no known barriers" legitimately appears.
  reg <- gq_reg_main()
  labs <- class_labels(reg, "streams_salmon")

  expect_equal(labs[["SPAWN;ASSESSED"]], "Spawning; known barrier")
  expect_equal(labs[["REAR;NONE"]], "Rearing; no known barriers")

  # token2 survives intact on a corrected class
  expect_equal(labs[["ACCESS;NONE"]], "Accessible; no known barriers")
  expect_equal(labs[["ACCESS;ASSESSED"]], "Accessible; known barrier")
  expect_equal(labs[["ACCESS;ASSESSED;INTERMITTENT"]],
               "Accessible; known barrier; intermittent")
})

test_that("the correction changes labels only, never symbology", {
  # A text fix that silently moved a colour or width would be far worse than the
  # bug. These are the values the QML authored; they must survive the rewrite.
  reg <- gq_reg_main()
  cls <- reg$layers$streams_salmon$classification$classes

  expect_equal(cls[["ACCESS;ASSESSED"]]$color, "#ef4545")
  expect_equal(cls[["ACCESS;NONE"]]$color, "#129bdb")
  expect_equal(cls[["ACCESS;MODELLED"]]$color, "#ff9f85")

  # Habitat tier is carried in width: ACCESS is the thinnest of the three.
  w <- function(k) cls[[k]]$width
  expect_lt(w("ACCESS;ASSESSED"), w("REAR;ASSESSED"))
  expect_lt(w("REAR;ASSESSED"), w("SPAWN;ASSESSED"))
})
