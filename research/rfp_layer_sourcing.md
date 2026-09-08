# How rfp resolves and fetches a project's layers

**Verified:** 2026-09-07 against rfp 0.62.0 (`main`) · **Issues:** gq#82; spawned
NewGraphEnvironment/rfp#305, NewGraphEnvironment/db_newgraph#20 · **Produced by:** direct
reading of rfp's `R/` and `inst/scripts/`, plus anonymous HEAD probes of the `newgraph`
bucket

Written because gq#82 was filed on a premise that reading this chain falsifies, and
because nothing in gq records what its own `source_type` / `source_layer` columns
actually drive. Anyone reasoning about why a layer did or did not download will
otherwise re-derive it.

## gq's registry is the authority, not rfp's lookup files

```
rfp_project_create()
  -> rfp_project_layers(template)              rfp/R/rfp_project_layers.R:23-39
     -> gq::gq_template_layers(template)       :26-32
  -> download_types <- intersect(setdiff(rfp_manifest_types(), "frozen"),
                                 unique(layer_config$source_type))
                                               rfp/R/rfp_project_create.R:241-242
  -> for each type: rfp_source(type =, layers = source_layer[source_type == type])
                                               :248-258
     -> writeLines(layers, workdir/layers.txt) rfp/R/rfp_source_script_pass.R:61-62
     -> RFP_SOURCES=<that temp file>           :76
```

**`inst/lookups/rfp_source_{aws,bcdata,fwa}.txt` are not consulted on this path.** They
are the gq-absent fallback (`rfp_project_layers_fallback()`, `rfp/R/rfp_project_layers.R:43-73`)
and the default for a bare `rfp_source(type = , layers = NULL)` call
(`rfp/R/rfp_source.R:148-152`). So a layer commented out in `rfp_source_aws.txt` is still
requested by every project build, and a layer gq types wrongly is not rescued by rfp's
list being right.

Consequence for gq: **a wrong `source_type` or `source_layer` is a failed download on
every project built from either template.**

## An unknown `source_type` is dropped silently

`rfp_manifest_types()` is `c("bcdata", "fwa", "aws", "osm", "url", "stac", "frozen")`
(`rfp/R/rfp_manifest_types.R:44-46`). The `intersect()` above keeps only values present
in that vector, so a `source_type` rfp does not know contributes no pass — **no error, no
warning, the layer simply never downloads**.

This is why gq#82 typed `habitat_lateral` as `aws` rather than inventing a raster term,
and it is the blocker gq#72 has to clear before any new term can ship: gq cannot add a
`source_type` before rfp knows it.

The `intersect()` order is also load-bearing and not the config's row order — the aws
pass needs the layers directory the bcdata pass creates, so an aws-first config aborts
creation.

## `source_layer` is three things at once

| job | where |
|---|---|
| the S3 object stem | `s3_url()` = base + path + **layer** + ext, `rfp/inst/scripts/rfp_source_aws.sh:115-130` |
| the GeoPackage table name | `targets.tsv` + `ogr2ogr -nln`, `rfp/R/rfp_source_script_pass.R:66-70` |
| the `.qgs` `layername=` | e.g. `rfp/inst/templates/bcfishpass_mobile.qgs:45138` |

So renaming a layer upstream is a **three-repo change**: db_newgraph stages the new
object, gq points at it, rfp repoints both templates. Fixing only gq downloads the data
under a name the maplayer does not reference — the layer is still absent, for a different
reason.

**It cannot be aliased.** `rfp_source_aws.csv` offers a per-layer `base`/`path` override,
but `path` is a directory prefix and the stem always comes from the layer name, so there
is no way to point one layer name at a differently-named object.

Each template carries the name **twice** — the `<datasource>` element and the
`layer-tree-layer` `source=` attribute. Changing one leaves the project half-repointed.

## A failed aws layer does not fail the build

`inst/scripts/rfp_source_aws.sh` wraps every fetch in an `if`, which suppresses `errexit`
despite `set -euo pipefail`. A 404 prints `RFP-FAILED: <layer> (not found on S3)`, the
loop continues, and the pass exits 0. `rfp_project_create()` reports the line and keeps
the maplayer in the `.qgs` so a later refresh can fill it
(`rfp/R/rfp_project_create.R:315-327`) — deliberate, because a failed download and a
layer legitimately empty in the AOI are indistinguishable at that point.

**On a device they stay indistinguishable.** That is the whole reason gq#82's two 404s
survived unnoticed: the only signal is one line in a 16-minute log.

## Two layers are not GeoPackage tables

- `habitat_lateral.tif` — fetched with `rio mask` off `/vsicurl/`, AOI-clipped, written
  as a standalone `.tif` beside the project under its own `RFP-LOADED-FILE:` sentinel
  (`rfp_source_aws.sh:136-161`). Its gq `source_layer` is therefore a **filename**, the
  only row in the registry that is not `schema.table`.
- `whse_basemapping.fwa_named_streams` — not S3 at all; ogr2ogr against the hillcrestgeo
  fwapg feature service.

Also list-gated rather than unconditional since rfp#12 phase 3: `habitat_lateral.tif`,
`parameters_habitat_method`, `parameters_habitat_thresholds` and `fwa_named_streams` are
ordinary entries now, so *a manifest that omits them leaves them alone*.

## Probing the bucket

The `newgraph` bucket serves `GetObject` publicly, so presence is checkable with no
credentials and no `aws s3 ls` — and this is the honest probe, because it is the request
rfp itself makes:

```bash
curl -s -o /dev/null -w '%{http_code}\n' --max-time 20 -I \
  "https://newgraph.s3.us-west-2.amazonaws.com/<source_layer>.fgb.zip"
```

Mind the extension: `.fgb.zip` for tables, but `habitat_lateral.tif` is its own.

Measured 2026-09-07: 7 of gq's 9 distinct `aws` source_layers resolved; after gq#82,
9 of 10, the remaining 404 being `bcfishpass.dams` (db_newgraph#20).

## What stages the objects

`db_newgraph` (private) — `jobs/dump_weekly`. **Read the job, not the bucket listing**,
when asking whether a layer exists: the listing shows what some past run happened to
leave, the job says what is maintained. That is how `bcfishobs.observations` was
confirmed as a rename rather than guessed, and how `bcfishpass.dams` was established as
never staged rather than retired.
