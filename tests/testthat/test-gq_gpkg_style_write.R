skip_if_not_installed("sf")

# A GeoPackage with one line layer, plus an aspatial table already registered
# in gpkg_contents: the case in which an unregistered layer_styles is invisible
# to GDAL and QGIS, so a writer that skipped the registration fails here.
gpkg_fixture <- function(env = parent.frame()) {
  g <- withr::local_tempfile(fileext = ".gpkg", .local_envir = env)
  segs <- sf::st_sf(
    kind = c("a & b", "c, d"),
    zone = c("SBS", "ESSF"),
    geom = sf::st_sfc(
      sf::st_linestring(matrix(c(0, 0, 1, 1), 2)),
      sf::st_linestring(matrix(c(1, 2, 1, 3), 2)),
      crs = 3005
    )
  )
  sf::st_write(segs, g, "segs", quiet = TRUE)
  sf::st_write(segs, g, "other", quiet = TRUE)
  sf::st_write(data.frame(note = "x"), g, "notes", quiet = TRUE)
  g
}

read_styles <- function(g) {
  sf::st_read(g, "layer_styles", quiet = TRUE, stringsAsFactors = FALSE)
}

two_styles <- function() {
  reg <- gq_reg_custom(testthat::test_path("fixtures", "qml_registry.csv"))
  c(kind = gq_qgis_style(reg, "cls_line"),
    plain = gq_qgis_style(reg, "simple_line"))
}

test_that("two styles land in layer_styles, exactly one of them the default", {
  g <- gpkg_fixture()
  st <- two_styles()
  gq_gpkg_style_write(g, "segs", st, description = c("by kind", "plain"))

  ls <- read_styles(g)
  expect_equal(nrow(ls), 2L)
  expect_setequal(ls$styleName, c("kind", "plain"))
  expect_equal(sum(ls$useAsDefault), 1L)
  expect_equal(ls$styleName[ls$useAsDefault], "kind")
  expect_equal(ls$styleQML[match(names(st), ls$styleName)], unname(st))
  expect_equal(ls$description[match(names(st), ls$styleName)],
               c("by kind", "plain"))
  expect_true(all(ls$f_table_name == "segs"))
  expect_true(all(ls$f_geometry_column == "geom"))
  # empty strings, never NULL: QGIS matches its layer on these, and a NULL
  # schema leaves the layer unstyled with the row present
  expect_identical(ls$f_table_catalog, c("", ""))
  expect_identical(ls$f_table_schema, c("", ""))
  # every column QGIS writes
  expect_true(all(c("f_table_catalog", "f_table_schema", "f_table_name",
                    "f_geometry_column", "styleName", "styleQML", "styleSLD",
                    "useAsDefault", "description", "owner", "ui",
                    "update_time") %in% names(ls)))

  # registered as an attributes table, so GDAL (and QGIS) list it
  reg <- sf::st_read(
    g, query = "SELECT data_type FROM gpkg_contents WHERE table_name = 'layer_styles'",
    quiet = TRUE
  )
  expect_equal(reg$data_type, "attributes")
  expect_true("layer_styles" %in% sf::st_layers(g)$name)

  # the stored QML still parses to the classes it was built from
  r <- xml2::xml_find_first(xml2::read_xml(ls$styleQML[ls$styleName == "kind"]),
                            ".//renderer-v2")
  expect_equal(xml2::xml_attr(xml2::xml_find_all(r, "./categories/category"),
                              "value"),
               c("a & b", "c, d", "10"))
})

test_that("a second write replaces by name and moves the default", {
  g <- gpkg_fixture()
  st <- two_styles()
  gq_gpkg_style_write(g, "segs", st)
  gq_gpkg_style_write(g, "segs", st["plain"])   # default is its only style
  ls <- read_styles(g)
  expect_equal(nrow(ls), 2L)
  expect_equal(sum(ls$useAsDefault), 1L)
  expect_equal(ls$styleName[ls$useAsDefault], "plain")

  gq_gpkg_style_write(g, "segs", st, default = "kind")
  ls <- read_styles(g)
  expect_equal(nrow(ls), 2L)
  expect_equal(ls$styleName[ls$useAsDefault], "kind")
})

test_that("another layer's styles are kept, each with its own default", {
  g <- gpkg_fixture()
  st <- two_styles()
  gq_gpkg_style_write(g, "segs", st)
  gq_gpkg_style_write(g, "other", st, default = "plain")
  ls <- read_styles(g)
  expect_equal(nrow(ls), 4L)
  for (tbl in c("segs", "other")) {
    mine <- ls[ls$f_table_name == tbl, ]
    expect_equal(sum(mine$useAsDefault), 1L, info = tbl)
  }
  expect_equal(ls$styleName[ls$f_table_name == "segs" & ls$useAsDefault], "kind")
  expect_equal(ls$styleName[ls$f_table_name == "other" & ls$useAsDefault], "plain")
})

test_that("an unchanged call writes nothing", {
  g <- gpkg_fixture()
  st <- two_styles()
  gq_gpkg_style_write(g, "segs", st)
  before <- unname(tools::md5sum(g))
  gq_gpkg_style_write(g, "segs", st)
  expect_identical(unname(tools::md5sum(g)), before)
})

test_that("bad arguments are refused before anything is written", {
  g <- gpkg_fixture()
  st <- two_styles()
  expect_error(gq_gpkg_style_write(g, "notes", st), "not a feature table")
  expect_error(gq_gpkg_style_write(g, "segs", unname(st)), "unique")
  expect_error(gq_gpkg_style_write(g, "segs", c(a = st[[1]], a = st[[2]])),
               "unique")
  expect_error(gq_gpkg_style_write(g, "segs", st, default = "nope"), "default")
  expect_error(gq_gpkg_style_write(g, "segs", c(a = "not qml")), "QML")
  expect_error(gq_gpkg_style_write(g, "segs", st, description = "one"),
               "description")
  expect_error(gq_gpkg_style_write(tempfile(), "segs", st), "existing")
  expect_false("layer_styles" %in% sf::st_layers(g)$name)
})
