# What gq copies from rfp, who owns it, and how staleness is caught

**Verified:** 2026-11-05 against rfp v0.93.0 · **Issues:** gq#100 (gq#70, #78, #86, #92) · **Produced by:** in-memory re-extraction with gq's own walkers from a detached rfp worktree at the tag; the corpus sweep in `tests/testthat/test-qml_consistency.R`; a column query against the newgraph database. The story is in `planning/archive/2026-11-issue-100-vendored-artifacts/`.

## The five copies, and who owns each

| gq file | built from (rfp) | owner of the content |
|---|---|---|
| `inst/registry/template_groups.csv` | `inst/templates/*.qgs` | rfp. Since v0.77.0 the `.qgs` files are build output of rfp's roster CSVs (`data-raw/qgs/roster/`), still committed |
| `inst/registry/template_layers.csv` | the same `.qgs` walk | rfp, the same roster. rtj's open placement-reconciler issue names those roster files as the owner of structure |
| `inst/registry/themes.csv` | the `.qgs` visibility presets | rfp's theme registry. Projects compose their own themes in rtj config (base plus additions and removals), which never reach the templates |
| `inst/registry/form_types.csv` | `inst/lookups/rfp_form_types.csv` | rfp. Its form-styling issue calls the re-vendor "the intended handshake" |
| `inst/styles/` (QML) | `inst/extdata/styles/` | intended to move to gq (rfp's open store issue); rfp authors it until then |

`groups.csv` is gq's own file, and rfp reads it only for membership and `source_type` (`rfp_project_layers()`, `rfp_project_create()`); see `rfp_layer_sourcing.md`. Placement and order inside it are gq's claim, checked against `template_layers.csv`.

**Copy the composed answer, not rfp's lookups.** rfp's theme lookups have the right key shape but the wrong row counts, because several of them are *composed* into the shipped presets. The built `.qgs` holds the composed result. The same holds for groups and layers: copy the built template, not the roster CSVs.

## How staleness is caught

A guard that reads a committed copy cannot see the copy go stale: `template_groups.csv` sat two months behind with the suite green, and `themes.csv` before it.

- `R/utils_vendored.R` holds one builder per roster and one writer, `vendored_write()`, shared by the `data-raw/` generators and `tests/testthat/test-vendored_currency.R`. The test rebuilds each roster from an rfp checkout and compares the file, line for line, with the committed one.
- The test runs only when `RFP_TEMPLATE_DIR` and `RFP_LOOKUPS_DIR` point at a checkout. An installed rfp is routinely behind (measured several times, versions in the generators' comments), so falling back to it fails falsely.
- gq is public and rfp private, so gq's CI can never run the test. The check that runs on every rfp change has to live in rfp's CI, which can clone gq with no credential (filed in rfp).
- **Sort with `method = "radix"`.** `order()` collates by `LC_COLLATE`: the generators run under `Rscript` (`en_US`) and testthat forces `C`. "Low detail - roads" and "Low Detail - Salmon Model" swap between the two, as do `roads_dra` and `roads2`, so a bare sort makes the test fail with nothing stale, in a way re-running the generator cannot clear.

## What the QML corpus can and cannot be checked for without a database

Measured over all 60 files at v0.93.0:

- Tags that configure one field (`alias`, `default`, `constraint`, `constraintExpression`, `attributeEditorField`) name a field in the file's own `<fieldConfiguration>` in every file. They are held to it.
- `editable`, `labelOnTop`, `reuseLastValue` and the attribute table's `column type="field"` are a **snapshot of every column QGIS once saw**. 26 of the 53 vector files name fields there that their roster lacks, 497 names in all; `crossings_pscis_assessment` alone carries 70 uppercase columns from an older source. QGIS ignores them. The four dead `fish_obsrvtn_pnt_distinct_id` references in the bcfishobs style are in this class, so no rule over these tags can pick them out.
- An expression may name a real column that has no widget. The roster is a subset of the layer's columns, so "must be in the roster" refuses correct files (the bcfishobs `"species_name"` preview). Six bare references outside their roster are pinned as undecidable.
- Against the newgraph database: `bcfishobs.observations` has 34 columns. `linear_feature_id` and `species_name` resolve, and `fish_obsrvtn_pnt_distinct_id` does not. `fid` is the key OGR adds to the GeoPackage layer the style is applied to, so it is legitimate. The database's copies of BC Data Catalogue layers hold only a subset of the WFS columns rfp downloads, so they cannot settle a bcdata layer's field references.

## Known gaps

- Order within a group, and order between sibling subgroups, disagree with the templates. gq cannot express a subgroup's position among its parent's layers, or among its siblings, without a shared order key (gq#105, with the schema questions in gq#104).
- `reg_qgis_restoration.json` is also extracted from rfp's template, and no currency check covers it (batch 8, gq#102). At v0.93.0 it matches on 48 of 48 layers except bcfishobs `source_layer`.
