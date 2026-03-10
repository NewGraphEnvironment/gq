# Merge multiple gq registries

Takes any number of registry list objects and merges their layers into a
single master registry. For duplicate layer keys, the `priority`
argument controls which source wins. Conflicts are logged as an
attribute.

## Usage

``` r
gq_reg_merge(..., csv = NULL, priority = c("last", "first"))
```

## Arguments

- ...:

  Registry list objects (from
  [`gq_reg_read()`](https://newgraphenvironment.github.io/gq/reference/gq_reg_read.md),
  [`gq_reg_custom()`](https://newgraphenvironment.github.io/gq/reference/gq_reg_custom.md),
  or
  [`gq_registry_read()`](https://newgraphenvironment.github.io/gq/reference/gq_registry_read.md)).

- csv:

  Optional character vector of CSV file paths to include. Each is read
  via
  [`gq_reg_custom()`](https://newgraphenvironment.github.io/gq/reference/gq_reg_custom.md)
  and appended to the merge inputs.

- priority:

  Either `"last"` (default, later sources win) or `"first"` (earlier
  sources win) for duplicate layer keys.

## Value

A merged registry list. Conflicts are stored in a `"conflicts"`
attribute (a data.frame with columns: layer_key, source_a, source_b).

## Examples

``` r
path <- system.file("examples", "mini_registry.json", package = "gq")
reg1 <- gq_reg_read(path)
reg2 <- gq_reg_read(path)
merged <- gq_reg_merge(reg1, reg2)
length(merged$layers)
#> [1] 4
```
