# Build a popup for a MapLibre GL layer from column names

Returns the data with the popup's display text added as new columns
(`popup_1`, `popup_2`, ...), and the MapLibre expression that assembles
the popup from them in the browser: `Label: value`, one per line. Pass
`data` as the layer's `x` and `expr` as its `popup` in
[`gq_mapgl_layer()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_layer.md).
The columns the popup reads are left as they are, so a layer can still
be styled on one: a stream order written as text would no longer scale a
line.

## Usage

``` r
gq_mapgl_popup(x, fields, missing = "none", digits = 3L)
```

## Arguments

- x:

  An `sf` or data frame.

- fields:

  A named character vector, label = column:
  `c("Stream order" = "stream_order")`. The labels may carry HTML.

- missing:

  The text shown for a missing value.

- digits:

  Significant figures for numeric columns.

## Value

A list of `data` (`x` with the popup text columns added) and `expr` (the
popup expression). Keep only the columns the map reads before calling:
every column is written into the page.

## Details

The popup is assembled in the browser rather than pasted into an HTML
string per feature, which more than doubled the page in the map these
helpers come from. MapLibre's popup reads only a few expression
operators, so a missing value is written here as `missing`.

Numbers are rounded to `digits` significant figures one value at a time,
so `0.037` and `2.2` sit side by side rather than as `3.7e-02` and
`2.20`. Format a column yourself (to a percentage, say) and it is shown
as given.

## See also

[`gq_mapgl_layer()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_layer.md)

## Examples

``` r
x <- data.frame(stream_order = c(3L, 5L), gradient = c(0.0372, NA))
pop <- gq_mapgl_popup(x, c("Stream order" = "stream_order", "Gradient" = "gradient"))
pop$data
#>   stream_order gradient popup_1 popup_2
#> 1            3   0.0372       3  0.0372
#> 2            5       NA       5    none
str(pop$expr)
#> List of 5
#>  $ : chr "concat"
#>  $ : chr "Stream order: "
#>  $ :List of 2
#>   ..$ : chr "get"
#>   ..$ : chr "popup_1"
#>  $ : chr "<br>Gradient: "
#>  $ :List of 2
#>   ..$ : chr "get"
#>   ..$ : chr "popup_2"
```
