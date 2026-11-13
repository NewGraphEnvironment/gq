# Web maps with gq and mapgl

A gq web map takes four calls.
[`gq_mapgl_basemap()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_basemap.md)
starts the map on a basemap fitted to the data.
[`gq_mapgl_network()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_network.md)
adds lakes and streams styled from the registry, with streams drawn
wider by stream order.
[`gq_mapgl_layer()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_layer.md)
adds each layer with its legend, and
[`gq_mapgl_controls()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_controls.md)
adds a switch for the layers, zoom buttons and a scale bar. Each legend
is tied to its layer, so switching a layer off hides its legend too.

Both maps below are drawn in a subbasin of the Neexdzii Kwa (Upper
Bulkley River), between Johnny David Creek and Richfield Creek, with the
data bundled in gq.

``` r

library(gq)
library(sf)
sf_use_s2(FALSE)
reg <- gq_reg_main()
```

## Where has each salmon and trout been recorded?

One layer per species makes each one a switch. The colours are named
here because the registry styles fish observations as one layer, not by
species.

``` r

species <- c(RB = "rainbow trout", BT = "bull trout", CO = "coho", DV = "Dolly Varden",
             CH = "chinook", ST = "steelhead", CT = "cutthroat trout")
colours <- c(RB = "#377EB8", BT = "#E41A1C", CO = "#FF7F00", DV = "#984EA3",
             CH = "#4DAF4A", ST = "#A65628", CT = "#F781BF")
outline <- st_cast(neexdzii_wsd, "MULTILINESTRING")

m <- gq_mapgl_basemap(neexdzii_wsd, "positron") |>
  gq_mapgl_network(streams = neexdzii_streams["stream_order"],
                   water = neexdzii_lakes["gnis_name_1"], reg = reg, legend = TRUE) |>
  gq_mapgl_layer("subbasin", outline, color = "#2c3e50", width = 1.5, legend = FALSE)

for (code in names(species)) {
  obs <- neexdzii_fish_obs[neexdzii_fish_obs$species_code == code,
                           c("observation_date", "life_stage")]
  pop <- gq_mapgl_popup(obs, c(Recorded = "observation_date", "Life stage" = "life_stage"))
  m <- gq_mapgl_layer(m, species[[code]], pop$data, color = colours[[code]], radius = 6,
                      popup = pop$expr, circle_stroke_color = "#ffffff",
                      circle_stroke_width = 1)
}

gq_mapgl_controls(m, unname(species))
```

Fish observations of salmon, trout and char in the Neexdzii Kwa
subbasin, one layer per species. Use the switch at the top right to show
one species at a time. Observations at one site sit on top of each
other, so switch a species off to see the ones beneath. Other species
recorded here are left out.

The popup is built by
[`gq_mapgl_popup()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_popup.md).
It writes a missing value as `none`, and the browser assembles each
popup from the columns, which keeps the page small.

## A classified layer from the registry

A registry key draws a layer in the registry’s classes, with one legend
row per class. Here the crossings are coloured by barrier status. Their
data names the column `barrier_status` where the registry names it
`barrier_result_code`, so `field` says which column to read.

``` r

assessed <- neexdzii_crossings[neexdzii_crossings$barrier_status != "POTENTIAL",
                               c("barrier_status", "gnis_stream_name", "crossing_type_code")]
pop <- gq_mapgl_popup(assessed, c(Status = "barrier_status", Stream = "gnis_stream_name",
                                  Type = "crossing_type_code"))

gq_mapgl_basemap(neexdzii_wsd, "positron") |>
  gq_mapgl_network(streams = neexdzii_streams["stream_order"],
                   water = neexdzii_lakes["gnis_name_1"], reg = reg, legend = TRUE) |>
  gq_mapgl_layer("subbasin", outline, color = "#2c3e50", width = 1.5, legend = FALSE) |>
  gq_mapgl_layer("crossings", pop$data, key = "crossings_pscis_assessment", reg = reg,
                 field = "barrier_status", legend_title = "Barrier status",
                 popup = pop$expr, circle_stroke_color = "#ffffff",
                 circle_stroke_width = 1) |>
  gq_mapgl_controls(c("Assessed crossings" = "crossings"))
```

Assessed stream crossings in the Neexdzii Kwa subbasin, coloured by
barrier status from the gq registry. The 130 crossings that are modelled
but not yet assessed are left out. Click a crossing for its stream and
type.

## What the web map does not draw

The registry carries more than MapLibre draws through these helpers. A
classified line layer draws every class at one width and with no dashes,
and a point layer draws as circles whatever shape the registry gives it.
The static maps from
[`gq_tmap_style()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_style.md)
draw both.
