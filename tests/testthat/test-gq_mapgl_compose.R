skip_if_not_installed("mapgl")
skip_if_not_installed("sf")
skip_if_not_installed("withr")

# --- knowledge parity (gq#18) ---------------------------------------------------
#
# gq's mapgl helpers are extracted from knowledge's knw_compare_mapgl(), and #18 is done when that
# map can be rebuilt on them with no visible change. The test holds it to more than that: the
# widget spec the browser receives is identical. knw_compare_mapgl() is copied into
# fixtures/knw_compare_mapgl.R; knw_rewrite() below is that function on gq's helpers, keeping
# knowledge's own class codes, popup and ids, which are its business, not gq's.
#
# Seeded: add_layers_control() names its control with sample(), so two builds differ without it.

knw <- new.env()
sys.source(test_path("fixtures", "knw_compare_mapgl.R"), envir = knw)

knw_rewrite <- function(segments, water = NULL, title = "", background = "voyager", digits = 5L) {
  seg <- segments[segments$accessible %in% TRUE, ]
  seg <- knw$.compare_classes(seg)
  pop <- knw$.compare_popup(seg)
  rule <- knw$.compare_rule_cols
  grade <- knw$.compare_grade_cols
  s <- sf::st_sf(data.frame(rc = as.integer(seg$rule_class), gc = as.integer(seg$grade_class),
                            stream_order = as.integer(seg$stream_order), pop$props,
                            stringsAsFactors = FALSE),
                 geometry = sf::st_geometry(seg))
  m <- gq_mapgl_basemap(s, background, digits)
  if (!is.null(water) && nrow(water)) {
    kind <- if ("kind" %in% names(water)) as.character(water$kind) else "water"
    m <- gq_mapgl_network(m, water = sf::st_sf(kind = kind, geometry = sf::st_geometry(water)),
                          ids = c(water = "knw_water"), digits = digits)
  }
  m |>
    gq_mapgl_layer("rules", s, source = "knw_seg",
                   classes = list(field = "rc", values = seq_along(rule), colors = unname(rule),
                                  labels = names(rule), default = "#cccccc"),
                   width = "stream_order", popup = pop$expr, legend_title = title, digits = digits) |>
    gq_mapgl_layer("grade", source = "knw_seg",
                   classes = list(field = "gc", values = seq_along(grade), colors = unname(grade),
                                  labels = names(grade), default = "#d9d9d9"),
                   width = "stream_order", popup = pop$expr, visible = FALSE,
                   legend_title = "Grade (expected use)") |>
    gq_mapgl_controls(c(Habitat = "rules", Grade = "grade"), navigation = FALSE, scale = FALSE)
}

knw_segments <- function() {
  sf::st_sf(
    accessible = c(TRUE, TRUE, TRUE, FALSE), stream_order = c(1L, 3L, 6L, 2L),
    grade_class = c("0-0.2", "0.8-1", NA, "0.4-0.6"), grade = c(0.11, 0.93, NA, 0.5),
    flag_default = c(TRUE, TRUE, FALSE, TRUE), flag_tuned = c(TRUE, FALSE, TRUE, FALSE),
    pre_default = c(TRUE, TRUE, TRUE, TRUE), pre_tuned = c(FALSE, FALSE, TRUE, FALSE),
    mad = c(0.4, 2.1, NA, 1), gradient = c(0.0372, 0.004, 0.12, 0.01),
    geometry = sf::st_sfc(lapply(0:3, function(i) {
      sf::st_linestring(rbind(c(1e6 + i * 500, 1e6, 10), c(1e6 + (i + 1) * 500, 1e6 + 300, 12)))
    }), crs = 3005)
  )
}

knw_water <- function() {
  ring <- rbind(c(1e6, 1e6 + 400), c(1e6 + 300, 1e6 + 400), c(1e6 + 300, 1e6 + 700),
                c(1e6, 1e6 + 400))
  sf::st_sf(kind = "lake", area = 4.5, geometry = sf::st_sfc(sf::st_polygon(list(ring)), crs = 3005))
}

test_that("knw_compare_mapgl() rebuilt on gq's helpers sends the browser the same map", {
  for (bg in c("voyager", "esri_topo")) {
    hand <- withr::with_seed(1, knw$knw_compare_mapgl(knw_segments(), knw_water(),
                                                      title = "Habitat definition", background = bg))
    ours <- withr::with_seed(1, knw_rewrite(knw_segments(), knw_water(),
                                            title = "Habitat definition", background = bg))
    # premise: the fixture drew everything the parity is about
    expect_identical(vapply(hand$x$layers, `[[`, "", "id"), c("knw_water", "rules", "grade"))
    expect_false(is.null(hand$x$layers_control))
    for (slot in union(names(hand$x), names(ours$x))) {
      expect_identical(ours$x[[slot]], hand$x[[slot]], label = paste0(bg, ": x$", slot))
    }
    expect_identical(ours$x, hand$x)
  }
})

test_that("the parity holds with no water", {
  hand <- withr::with_seed(2, knw$knw_compare_mapgl(knw_segments(), title = "T"))
  ours <- withr::with_seed(2, knw_rewrite(knw_segments(), title = "T"))
  expect_identical(ours$x, hand$x)
})

# --- the second caller: one switchable layer per species, over a stream network --------------

test_that("a species map over a stream network is a few calls", {
  reg <- gq_reg_main()
  obs <- neexdzii_fish_obs
  cols <- c(RB = "#377EB8", BT = "#E41A1C", CO = "#FF7F00", ZZ = "#000000")
  present <- intersect(names(cols), obs$species_code)
  expect_identical(present, c("RB", "BT", "CO"))            # premise: ZZ is not in the data

  m <- gq_mapgl_basemap(neexdzii_wsd, "positron") |>
    gq_mapgl_network(streams = neexdzii_streams["stream_order"], water = neexdzii_lakes["gnis_name_1"],
                     reg = reg, legend = TRUE)
  for (k in present) {
    pop <- gq_mapgl_popup(obs[obs$species_code == k, c("species_code", "life_stage")],
                          c(Species = "species_code", "Life stage" = "life_stage"))
    m <- gq_mapgl_layer(m, k, pop$data, color = cols[[k]], radius = 6, popup = pop$expr)
  }
  m <- gq_mapgl_controls(m, present)

  ids <- vapply(m$x$layers, `[[`, "", "id")
  expect_identical(ids, c("gq_water", "gq_streams", present))
  expect_identical(m$x$layers_control$layers, present)
  for (k in present) {
    expect_match(m$x$legend_html, paste0('data-layer-id="', k, '"'))
    n <- nrow(jsonlite::fromJSON(m$x$sources[[which(ids == k) ]]$data)$features)
    expect_identical(n, sum(obs$species_code == k))
  }
})
