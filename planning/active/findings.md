# Findings — Registry disagrees with rfp's aws source list on three rows (#82)

## Measurement: gq's aws layers against the bucket

Anonymous HTTP HEAD against `https://newgraph.s3.us-west-2.amazonaws.com/`,
2026-09-07. No credentials needed — the bucket serves `GetObject` publicly.

gq carries **13 `aws` rows** in `groups.csv`, **9 distinct `source_layer`** values:

| source_layer | `.fgb.zip` |
|---|---|
| `bcfishpass.crossings_vw` | 200 |
| `bcfishpass.streams_vw` | 200 |
| `whse_basemapping.transport_line` | 200 |
| `whse_cadastre.pmbc_parcel_fabric_poly_svw` | 200 |
| `whse_fish.fiss_obstacles_pnt_sp` | 200 |
| `whse_forest_tenure.ften_range_poly_carto_vw` | 200 |
| `whse_forest_tenure.ften_road_section_lines_svw` | 200 |
| **`bcfishobs.fiss_fish_obsrvtn_events_vw`** | **404** |
| **`bcfishpass.dams`** | **404** |

`habitat_lateral.tif` — **200**. `bcfishobs.observations.fgb.zip` — **200**.

Bucket root holds 14 objects (`aws s3 ls s3://newgraph/`), matching rtj#318's count.

## The issue body's premise is wrong

gq#82 states that `rfp/inst/lookups/rfp_source_aws.txt` "is the list rfp's aws pass
acts on". It is not, for the path that matters:

```
rfp_project_create()
  -> rfp_project_layers(template)            rfp/R/rfp_project_layers.R:23-39
     -> gq::gq_template_layers(template)     :26-32
  -> layer_config$source_layer[source_type == "aws"]
                                             rfp/R/rfp_project_create.R:248-258
  -> rfp_source(type = "aws", layers = <that vector>)
     -> writeLines(layers, workdir/layers.txt)
                                             rfp/R/rfp_source_script_pass.R:61-62
     -> RFP_SOURCES=<that temp file>         :76
```

`inst/lookups/rfp_source_aws.txt` is consulted only when **gq is absent**
(`rfp_project_layers_fallback()`, `rfp/R/rfp_project_layers.R:43-73`) or when
`rfp_source()` is called directly with `layers = NULL` (`rfp/R/rfp_source.R:148-152`).

**So gq's registry is the cause of the two failed requests.** rfp's commented-out
line 9 does nothing for a project build. This matters for who fixes what: the issue
framed gq as one of two disagreeing lists; gq is in fact the authority rfp reads.

## `source_layer` does three jobs at once

One string, three consumers, and they must all agree:

| job | where |
|---|---|
| S3 object stem | `s3_url()` = base + path + **layer** + ext, `rfp/inst/scripts/rfp_source_aws.sh:115-130` |
| GeoPackage table name | `targets.tsv` + `ogr2ogr -nln`, `rfp/R/rfp_source_script_pass.R:66-70` |
| `.qgs` `layername=` | `rfp/inst/templates/bcfishpass_mobile.qgs:45138` |

`s3_url()` composes the stem from the layer name itself — `path` is a directory
prefix only — so **an S3 rename cannot be aliased** through `rfp_source_aws.csv`'s
per-layer `base`/`path` override.

Consequence: a gq-only rename of `bcfishobs` downloads the data under a name the
template's maplayer does not point at. The layer is absent either way today; the
rename unblocks it but does not by itself restore it. Hence the paired rfp issue.

## `bcfishobs` is a confirmed rename — from the producer, not inferred

`db_newgraph/jobs/dump_weekly:41-47`:

```bash
aws s3 rm s3://newgraph/bcfishobs.observations.fgb.zip
ogr2ogr -f FlatGeobuf /vsizip//vsis3/newgraph/bcfishobs.observations.fgb.zip \
  PG:$DATABASE_URL -nln bcfishobs.observations \
  -sql "select * from bcfishobs.observations"
```

The `db_newgraph` branch `aws_rename` carries `52f0280 change names to address #31 —
should remove old files after they are all regenerated before closing`. So the rename
was deliberate and staged.

Read from the **producer** rather than inferred from the bucket listing, per
`karpathy.md` §7 — the job that stages data says what exists.

## `bcfishpass.dams` was never staged

- No job on any `db_newgraph` branch (`newgraph`, `main`, `aws_rename`, `simon/main`)
  mentions `dams`.
- The database has `bcfishpass.dams_vw` — a materialized view, `db/grants.sql:179`.
  Note the **name differs** from what gq requests (`bcfishpass.dams`).
- So this is a staging gap, not a retirement. gq's row is a statement of intent the
  project side assumes; removing it would hide the gap.

## Trap: `gq_reg_merge()` REPLACES a layer entry, it does not merge fields

Probed 2026-09-07:

```r
a <- list(layers = list(x = list(type = "point", source_layer = "old",
                                 mark = list(color = "#fff"))))
b <- list(layers = list(x = list(type = "point", source_layer = "new")))
str(gq_reg_merge(a, b)$layers$x)
#> List of 2
#>  $ type        : chr "point"
#>  $ source_layer: chr "new"          <- mark is GONE
```

So `bcfishobs_fiss_fish_observations` cannot be fixed with a one-column
`reg_custom.csv` row — that would silently delete its `mark` (`#db1e2a`, triangle,
r 2.4) and `label` (Courier 5, `#000000`). The change belongs in the extracted JSONs.

This is why Phase 1 pins the symbology alongside the `source_layer`: the assertion is
what makes the trap visible to whoever later tries to "simplify" it.

## Trap: the `aws` guard's dot-check is a proxy, not the property

`tests/testthat/test-composition_integrity.R:54`:

```r
expect_setequal(needs$layer_key[!grepl(".", needs$source_layer, fixed = TRUE)],
                character(0))
```

The comment above it (`:44`) says the rule is "a real, schema-qualified table". The
check is "contains a dot anywhere". `habitat_lateral.tif` satisfies it **by accident**
— a filename passing a schema-qualification test. Retyping to `aws` without tightening
this leaves the rule blessing any string with a dot in it, which is the direction that
fails toward pass.

## Why a new `source_type` for rasters is not the answer here

`rfp_project_create()` computes the passes to run as

```r
download_types <- intersect(setdiff(rfp_manifest_types(), "frozen"),
                            unique(layer_config$source_type))
```

(`rfp/R/rfp_project_create.R:241-242`), and `rfp_manifest_types()` is
`c("bcdata", "fwa", "aws", "osm", "url", "stac", "frozen")`
(`rfp/R/rfp_manifest_types.R:44-46`). An unknown `source_type` is therefore **silently
dropped** by the `intersect()` — no error, no warning, the layer simply never
downloads. So gq cannot introduce a term before rfp knows it. That is gq#72's blocker,
and `aws` sidesteps it: `habitat_lateral.tif` genuinely is an S3 object.

## Verification at merge

Re-probed with the corrected registry, same method, 2026-09-07. gq now carries **10**
distinct `aws` source_layers (`habitat_lateral.tif` joined the set):

| | before | after |
|---|---|---|
| resolve 200 | 7 of 9 | **9 of 10** |
| 404 | `bcfishobs.fiss_fish_obsrvtn_events_vw`, `bcfishpass.dams` | `bcfishpass.dams` only |

The one remaining 404 is the deliberately-kept row, filed at
NewGraphEnvironment/db_newgraph#20. `habitat_lateral.tif` is probed with its own
extension, not `.fgb.zip`.

End-to-end through the composition rfp actually consumes — `gq_template_layers()`, both
templates, 14 `aws` rows each (was 13):

```
dam                              bcfishpass.dams
bcfishobs_fiss_fish_observations bcfishobs.observations
habitat_lateral                  habitat_lateral.tif
```

`devtools::document()` leaves NAMESPACE unchanged at 30 exports;
`pkgdown::check_pkgdown()` clean. Full suite 1111 pass, 2 fail — both pre-existing on
`origin/main` at identical lines (`test-gq_style_qml.R:201`, `test-template_drift.R:353`),
confirmed by running those two files in a throwaway worktree detached at `e3b0178`.
They are the stale rfp-vendored artifacts of gq#70 and gq#78; this branch touches
neither test's inputs. They only fire at all because rfp is checked out on this machine
— in CI both skip, which is the weakness gq#78 exists for.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| `gh issue view 31 --repo NewGraphEnvironment/db_newgraph` — "Could not resolve" | #31 is smnorris's numbering; our fork has its own. Issues ARE enabled on the fork (`hasIssuesEnabled=true`, 4 open) |
| First bucket read used `aws s3 ls`, which needs credentials | Anonymous `curl -I` against the https endpoint works and is what rfp itself does (`wget`), so it is the honest probe of what a build sees |
| An assertion that the file target does NOT match `^schema.table$` went red on correct data | `habitat_lateral.tif` matches it — `tif` is a valid table token. No regex separates a filename from a qualified table, which is why the exemption has to be a named list. The comment now says so instead of implying a shape test could do the work |
| The first plan-review agent died mid-run (`ENOTFOUND`) and reported nothing | Re-run rather than recorded as clean — an agent that returns nothing is indistinguishable from one that found nothing, and only one of those is a pass |
