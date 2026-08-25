# Build tmap legend arguments from registry layers

Turns a set of layer keys into argument lists for
[`tmap::tm_add_legend()`](https://r-tmap.github.io/tmap/reference/tm_add_legend.html),
one per geometry type, pulling every colour, width, dash and symbol from
the registry rather than from parallel vectors typed by hand.

## Usage

``` r
gq_tmap_legend(reg, layers, present = NULL, field = NULL, titles = NULL, ...)
```

## Arguments

- reg:

  A registry, as from
  [`gq_reg_main()`](https://newgraphenvironment.github.io/gq/reference/gq_reg_main.md).

- layers:

  Layer keys. An unnamed character vector uses each layer's title-cased
  key as its label; a named vector or list uses the names as labels
  (`c("Lake" = "lake")`).

- present:

  Optional named list restricting classified layers to the values
  actually in the data, e.g. `list(roads_dra = unique(x$road_type))`. A
  legend naming classes the map does not draw is a common and quiet
  error.

- field:

  Optional named character vector overriding the classification field
  per layer, matching
  [`gq_style()`](https://newgraphenvironment.github.io/gq/reference/gq_style.md)'s
  `field`.

- titles:

  Optional named character vector of legend titles per geometry type,
  e.g. `c(symbols = "Crossings")`.

- ...:

  Extra arguments merged into every returned list — `z`, `group_id`,
  `orientation`, `position` and so on.

## Value

A named list of argument lists, one per geometry type present
(`polygons`, `lines`, `symbols`). Each is ready for
`do.call(tmap::tm_add_legend, x)`.

## Details

Classified layers expand to one entry per class; simple layers
contribute a single entry. Both kinds can appear in the same call and
are merged into the right geometry group.

## What this does not do

Layout. tmap 4.4 handles ordering (`z`), grouping (`group_id`), stacking
and framing
([`tmap::tm_components()`](https://r-tmap.github.io/tmap/reference/tm_components.html)),
and bulk placement (`tm_place_legends_*()`) — all of it better than a
wrapper could, because it can see the whole map object. `z` and
`group_id` are passed straight through so those facilities keep working.

What tmap cannot do is read a style registry, because it has no concept
of one. That translation is the whole of this function.

## See also

[`gq_tmap_style()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_style.md)
for drawing the layers themselves,
[`tmap::tm_components()`](https://r-tmap.github.io/tmap/reference/tm_components.html)
for arranging the results.

## Examples

``` r
reg <- gq_reg_main()

# mixed geometry types partition automatically
leg <- gq_tmap_legend(reg, c("lake", "railway"))
names(leg)
#> [1] "polygons" "lines"   
leg$polygons$labels
#> [1] "Lake"

# a classified layer expands to one entry per class
roads <- gq_tmap_legend(reg, "roads_dra")
length(roads$lines$labels)
#> [1] 8

# ... and can be cut down to the classes the data actually contains
some <- gq_tmap_legend(reg, "roads_dra",
                       present = list(roads_dra = c("RH1", "RA1")))
length(some$lines$labels)
#> [1] 2

# labels come from the names when supplied
gq_tmap_legend(reg, c("Waterbody" = "lake"))$polygons$labels
#> [1] "Waterbody"
```
