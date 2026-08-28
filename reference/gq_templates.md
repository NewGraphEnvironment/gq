# List all project templates

Returns a data.frame of all templates defined in the registry, showing
which groups each template includes and their order.

## Usage

``` r
gq_templates()
```

## Value

A data.frame with columns: template, group, group_order.

## Ordering

`group_order` is a **sort key and nothing else**. It is per-template,
and it requires none of: contiguity, a 1-based start, uniqueness across
templates, or agreement between templates on where a shared group sits.
A template is free to number its groups 10/20/30 to leave room for
insertions, or to use a group vocabulary no other template shares.

This is written down because the two templates shipped today are
numbered 1..N and agree on most of their vocabulary, which invites the
inference that those properties are required. They are not:
`bcrestoration_mobile` declares `Floodplain` and `Restoration`, which
`bcfishpass_mobile` does not, so the two already disagree about both
membership and every position after group 5. Do not add a contiguity
check; it would break the first project type that does not look like
these two.

An earlier version of this section cited a Roads-before-Streams
asymmetry between the templates as the evidence. There was none — both
shipped `.qgs` order `Roads,Railways,Pipelines` before `Streams`, and
the asymmetry was unchecked drift in this registry, cited as a fact
about the projects it describes. gq#66 adopted the template order and
added `tests/testthat/test-template_drift.R` so the next such claim is
measured.

## Examples

``` r
gq_templates()
#>                template                    group group_order
#> 1     bcfishpass_mobile                    Forms           1
#> 2     bcfishpass_mobile                Crossings           2
#> 3     bcfishpass_mobile     Other point features           3
#> 4     bcfishpass_mobile Roads,Railways,Pipelines           4
#> 5     bcfishpass_mobile                  Streams           5
#> 6     bcfishpass_mobile                  Basemap           6
#> 7     bcfishpass_mobile     Web Mapping Services           7
#> 8     bcfishpass_mobile              Base - misc           8
#> 9  bcrestoration_mobile                    Forms           1
#> 10 bcrestoration_mobile                Crossings           2
#> 11 bcrestoration_mobile     Other point features           3
#> 12 bcrestoration_mobile Roads,Railways,Pipelines           4
#> 13 bcrestoration_mobile                  Streams           5
#> 14 bcrestoration_mobile               Floodplain           6
#> 15 bcrestoration_mobile              Restoration           7
#> 16 bcrestoration_mobile                  Basemap           8
#> 17 bcrestoration_mobile     Web Mapping Services           9
#> 18 bcrestoration_mobile              Base - misc          10
```
