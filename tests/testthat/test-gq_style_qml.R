# --- corpus integrity ---------------------------------------------------------

test_that("every index row resolves to a file", {
  idx <- read_styles_index()
  expect_gt(nrow(idx), 50)
  missing <- vapply(seq_len(nrow(idx)), function(i) {
    system.file("styles", styles_rel(idx[i, ]), package = "gq") == ""
  }, logical(1))
  expect_equal(
    sum(missing), 0,
    info = paste("No file for:", paste(idx$layer_key[missing], collapse = ", "))
  )
})

test_that("every file has an index row", {
  # The direction rfp's own store guard does not walk, which is how
  # vector/osm.trail.qml sat there unreachable. gq should not inherit the gap:
  # a shipped style nobody can resolve is dead weight at best and a stale
  # duplicate at worst.
  idx <- read_styles_index()
  root <- system.file("styles", package = "gq")
  on_disk <- sub(paste0("^", root, "/"), "",
                 list.files(root, pattern = "[.]qml$", recursive = TRUE,
                            full.names = TRUE))
  indexed <- vapply(seq_len(nrow(idx)), function(i) styles_rel(idx[i, ]),
                    character(1))
  expect_setequal(on_disk, indexed)
})

test_that("index keys are the same normalization the registry uses", {
  # Two independent slugifiers have to agree for a groups.csv key to reach a
  # QML: gq's normalize_layer_name() and rfp's slugify(). They do today, on all
  # 53 layer names including the one that begins with a space. Nothing enforces
  # that they keep agreeing, so pin it rather than assume it.
  #
  # Covers EVERY row, which is the point. An earlier cut scoped past 9 rows the
  # vendoring script left unnamed — a guard silently narrowed to a subset gives
  # the same green signal while the rest drifts. Resolving those names against
  # rfp's template roster is what let this cover the whole corpus.
  idx <- read_styles_index()
  expect_false(any(is.na(idx$layer)))
  expect_equal(normalize_layer_name(idx$layer), idx$layer_key)
})

test_that("the corpus holds only styles the templates actually use", {
  # rfp ships two raster styles no template references — dem_hillshade and
  # dem_turbo, which back rfp_raster_styles() and carry a
  # renderer/companion/stretch dimension gq vendors none of. Vendoring globbed
  # the directory at first and took them; it resolves against rfp's roster now.
  idx <- read_styles_index()
  expect_false(any(c("dem_hillshade", "dem_turbo") %in% idx$layer_key))
  expect_true("habitat_lateral" %in% idx$layer_key)
})

test_that("no key is claimed twice for one template", {
  idx <- read_styles_index()
  expect_equal(sum(duplicated(idx[c("layer_key", "template")])), 0)
})

test_that("every QML is a QGIS style document with no source binding", {
  # Structural, and deliberately independent of rfp being installed — the
  # byte-identity guard below skips without it, so something has to hold the
  # line when it does. A style carrying <datasource> or <layername> would bind
  # the corpus to one project's data, which is the whole point of lifting it.
  idx <- read_styles_index()
  paths <- vapply(seq_len(nrow(idx)), function(i) {
    system.file("styles", styles_rel(idx[i, ]), package = "gq")
  }, character(1))
  bound <- character(0)
  starts <- character(0)
  for (p in paths) {
    doc <- xml2::read_xml(p)
    expect_equal(xml2::xml_name(xml2::xml_root(doc)), "qgis")
    src <- xml2::xml_find_all(
      doc, "/qgis/datasource | /qgis/layername | /qgis/id | /qgis/provider"
    )
    if (length(src) > 0) bound <- c(bound, basename(p))
    starts <- c(starts, xml2::xml_name(xml2::xml_children(doc)[[1]]))
  }
  expect_equal(length(bound), 0,
               info = paste("Source-bound:", paste(bound, collapse = ", ")))

  # The absence check above passes on all 60 files and would keep passing
  # through an rfp#130-class regression, where a source tag LEAKS IN rather
  # than a known one appearing. rfp's real assertion is positional — the style
  # block starts at <flags> — because the lift copies from the first non-source
  # tag to the end, so anything left over shows up as a different first child.
  # That is the guard with teeth; the absence check alone is close to vacuous.
  expect_equal(unique(starts), "flags")
})


# --- gq_style_qml -------------------------------------------------------------

test_that("gq_style_qml returns a readable path to the layer's style", {
  p <- gq_style_qml("lake")
  expect_type(p, "character")
  expect_length(p, 1L)
  expect_true(file.exists(p))
  expect_equal(basename(p), "lake.qml")
  expect_equal(xml2::xml_name(xml2::xml_root(xml2::read_xml(p))), "qgis")
})

test_that("gq_style_qml serves the trail style extraction produced, not the donor", {
  # rfp carries two trail QMLs: the indexed trails.qml the generator extracted
  # from the templates, and osm.trail.qml, the #41 donor hand-committed a day
  # before the store had an index. They differ in bytes. Only the first is real.
  expect_equal(basename(gq_style_qml("trails")), "trails.qml")
  expect_error(gq_style_qml("osm_trail"), "No QML for layer_key")
  expect_error(gq_style_qml("osm.trail"), "No QML for layer_key")
})

test_that("a template override wins, and naming a template is always safe", {
  diverged <- c("land_ownership", "range_tenure", "fisheries_sensitive_watersheds")
  for (k in diverged) {
    expect_equal(basename(dirname(gq_style_qml(k, "bcfishpass_mobile"))),
                 "bcfishpass_mobile")
    # no bcrestoration override exists, so it falls back to shared
    expect_equal(basename(dirname(gq_style_qml(k, "bcrestoration_mobile"))),
                 "vector")
    expect_equal(basename(dirname(gq_style_qml(k))), "vector")
  }
  # the override really is a different file
  expect_false(identical(
    readLines(gq_style_qml("land_ownership", "bcfishpass_mobile"), warn = FALSE),
    readLines(gq_style_qml("land_ownership"), warn = FALSE)
  ))
})

test_that("a layer with no override ignores a valid template argument", {
  expect_equal(gq_style_qml("lake"), gq_style_qml("lake", "bcfishpass_mobile"))
  expect_equal(gq_style_qml("lake"), gq_style_qml("lake", "bcrestoration_mobile"))
})

test_that("an unknown template errors rather than falling back to shared", {
  # The dangerous direction. A typo used to return the shared style, and it did
  # so on precisely the 3 layers where an override exists BECAUSE the shared
  # style is wrong for that template -- a plausible wrong file, no signal.
  expect_error(gq_style_qml("land_ownership", "bcfishpass_moble"),
               "Unknown template")
  expect_error(gq_style_qml("lake", "no_such_template"), "Unknown template")
})

test_that("raster and service styles resolve", {
  expect_equal(basename(gq_style_qml("habitat_lateral")), "habitat_lateral.qml")
  expect_equal(basename(dirname(gq_style_qml("habitat_lateral"))), "raster")
  expect_equal(basename(dirname(gq_style_qml("bing_aerial"))), "services")
})

test_that("an unknown key errors rather than returning NA", {
  # Returning NA_character_ silently is the trap: the caller writes it into a
  # layer_styles row or a file.copy() and finds out much later.
  expect_error(gq_style_qml("definitely_not_a_layer"), "No QML for layer_key")
  expect_error(gq_style_qml("lakes"), "Did you mean.*lake")
})

test_that("gq_style_qml rejects malformed arguments", {
  expect_error(gq_style_qml(c("lake", "wetland")), "single non-NA string")
  expect_error(gq_style_qml(NA_character_), "single non-NA string")
  expect_error(gq_style_qml(42), "single non-NA string")
  expect_error(gq_style_qml("lake", c("a", "b")), "NULL or a single string")
})


# --- drift against the upstream store ----------------------------------------

test_that("the vendored corpus is byte-identical to rfp's", {
  # The drift guard proper. Skipped wherever rfp is absent, which is most
  # installs — hence the structural assertions above, which always run.
  #
  # RFP_STYLES_DIR first, for the same reason data-raw/styles_vendor.R takes it:
  # system.file() resolves to the INSTALLED rfp, which is routinely behind the
  # checkout the corpus was vendored from. Measured here — installed 0.25.1
  # carries 3 raster QMLs and no store at all, while the 0.30.1 checkout carries
  # 62. Comparing against whatever happens to be installed pins an undeclared
  # dependency and reports 59 false drifts.
  src <- Sys.getenv("RFP_STYLES_DIR", "")
  if (!nzchar(src)) {
    skip_if_not_installed("rfp")
    src <- system.file("extdata", "styles", package = "rfp")
  }
  skip_if(src == "" || !dir.exists(src), "no rfp style store to compare against")
  skip_if(!file.exists(file.path(src, "vector", "index.csv")),
          "rfp store predates its index (rfp#174) - nothing to compare")

  idx <- read_styles_index()
  differing <- character(0)
  for (i in seq_len(nrow(idx))) {
    rel <- styles_rel(idx[i, ])
    up <- file.path(src, rel)
    if (!file.exists(up)) {
      differing <- c(differing, paste0(rel, " (absent upstream)"))
      next
    }
    ours <- system.file("styles", rel, package = "gq")
    if (!identical(readBin(ours, "raw", file.size(ours)),
                   readBin(up, "raw", file.size(up)))) {
      differing <- c(differing, rel)
    }
  }
  expect_equal(length(differing), 0,
               info = paste("Drifted:", paste(differing, collapse = ", ")))
})
