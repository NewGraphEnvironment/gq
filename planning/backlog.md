# gq backlog: move order

**Verified:** 2026-11-04 against 43 open issues · **Produced by:** a read of every unbatched open
issue body (`gh issue list --state open`) and its comments · each older premise checked against
`main` @ `4755222`; the vendored artifacts compared with the template repo's current release

How to use this file: `/backlog-sweep` writes it. Take the first move in **Moves** that is not
ticked and not **waiting**; `/planning-init <umbrella>` plans it, one phase per batch, one PR.
`/gh-pr-merge` step 9c ticks the move on merge; `/compact-prep` names the next.

## Moves

| move | umbrella | batches | state |
|---|---|---|---|
| - [x] 1 | #100 | 1, 2: template agreement, vendored-artifact guards (7 issues) | done: https://github.com/NewGraphEnvironment/gq/pull/106 |
| - [ ] 2 | #101 | 3, 4, 5: translator opacity and labels, custom CSV reader, register styles (7 issues) | open |
| - [ ] 3 | #102 | 6, 7, 8: check gate, README and vignette, registry build inputs (8 issues) | open |
| - [ ] 4 | #103 | 9, 10: extractor fidelity, label translators (5 issues) | open |
| - [ ] 5 | #104 | 11: registry schema decisions (4 issues) | open: last, after moves 2 and 4 |

Tracks are separate efforts, not moves: gq has none.

Not batched, kept open: #18 (mapgl composition helpers), #19 (leaflet composition helpers), #13
(basemap tile sources), #8 (OSM vector basemap), #22 (Shiny layer picker) and #3 (ggplot2
translator). They share no cost and none has a consumer waiting, so an umbrella would only list
them.

## Order

| # | tracking | batch | issues | gate | why here |
|---|---|---|---:|---|---|
| 1 | #100 | Template agreement: #70, #94, #68, #73 | 4 | a `template` column in `groups.csv`; which side wins for six layer placements; register or exempt three layers | one checkout of the template repo at one version and one run of the extractors pays for all four |
| 2 | #100 | Vendored-artifact guards: #78, #86, #92 | 3 | where the guard runs now the templates are build output; which repo holds the QML store; the `bcfishobs` key rename | the same extractor scripts, run after batch 1 has made the copies current |
| 3 | #101 | Translator opacity and labels: #71, #31, #55 | 3 | named `labels` changes an exported return shape | one file, `R/gq_style.R`, and one render check of the tmap translators |
| 4 | #101 | Custom CSV reader: #42, #75 | 2 | a new `dash` column in the CSV | one function, `gq_reg_custom()` |
| 5 | #101 | Register styles: #98, #67 | 2 | two tree-change hex values; whether the QML for #67 is authored upstream | rows in `reg_custom.csv` and one registry rebuild; #98 needs batch 3 |
| 6 | #102 | Check gate: #51, #80 | 2 | none | one `R CMD check` run proves both |
| 7 | #102 | README and vignette: #95, #62, #58 | 3 | narrow the data or widen the AOI; where a tile credit sits | one pkgdown render and one figure review |
| 8 | #102 | Registry build inputs: #11, #84, #85 | 3 | delete, fold in or annotate the fish passage registry; generate the cross-reference or keep it by hand; bot commit or currency test | one script, `data-raw/reg_build_main.R`, and what it reads |
| 9 | #103 | Extractor fidelity: #6, #24, #38, #23 | 4 | how much the registry models now the QML corpus is the lossless copy | one file, `R/gq_qgs_extract.R`, and one re-extract |
| 10 | #103 | Label translators: #7 | 1 | which label properties are hints to the consumer | needs the label field from batch 9 |
| 11 | #104 | Registry schema decisions: #2, #20, #21, #72 | 4 | GeoStyler vocabulary (a breaking rename); a filter column; non-unique layer keys | one decision rescopes the others, and moves 2 and 4 add the keys it has to describe |

### 1. Template agreement

- [x] Carried by move 1, #100 (merged in https://github.com/NewGraphEnvironment/gq/pull/106)

Re-vendor `inst/registry/template_groups.csv` and `inst/registry/form_types.csv` against the
template repo's current release, then settle what the fresh copies show. #70 deletes the
`Floodplain` and `Restoration` exemptions in `tests/testthat/test-template_drift.R` and scopes
`Basemap/Terrestrial Ecology` to one template. #94 shrinks the unstyled-forms pin in
`tests/testthat/test-gq_forms.R` now eDNA is styled upstream. #68 adds a layer-level drift
guard for the six layers whose group differs. #73 decides the three `Project Specific` layers.

Measured 2026-11-04: `template_groups.csv` (last vendored 2026-08-28) has no `Floodplain` or
`Restoration` row, so the drift test is green against a stale witness; `form_types.csv` (last
vendored 2026-08-29) shows eDNA with no symbol or colour.

Starts with a read, before the plan gate (owner, 2026-11-04): themes and groups are being
reworked in the two repos that consume these rosters, the template repo and the repo that
holds each field project's config. Open there on 2026-11-04: themes composed in project config
as a base plus additions and removals, a reconciler for layer group placement after a project
is created, floodplain theme names being retired and merged, a Terrain group and theme for the
templates, and a test fixture failing against the current registries. Search both repos' open
issues and pull requests for `themes` and `groups`, read each adjacent body, and settle with
them which side owns each roster before a row moves here.

Gate: whether `groups.csv` gains a `template` column, which is stored data; for each of the six
placements, whether gq's side was a decision or unchecked drift; register or exempt `Tracking`
and the two habitat-parameter layers.

### 2. Vendored-artifact guards

- [x] Carried by move 1, #100 (merged in https://github.com/NewGraphEnvironment/gq/pull/106)

Make the staleness batch 1 repairs loud. #78 moves the theme extractor from `data-raw/` into
`R/` beside the group walker, with a perturbed fixture, so one currency test covers every
vendored artifact. #86 adds the internal-consistency check over the whole QML corpus, handing
what it cannot decide to a table check instead of refusing. #92 enumerates the causal claims
about the template repo in the `data-raw/*.R` comment blocks and gives each a named source.

Measured 2026-11-04: `fish_obsrvtn_pnt_distinct_id` still appears 4 times in the shipped
`bcfishobs` QML. The upstream style store holds four QMLs gq lacks (three raster, one vector);
the files both sides hold are byte-identical. Whether `data-raw/styles_vendor.R` is meant to
take the four was not checked.

Rests on batch 1's read of the peer repos: a guard is written against the roster shape they
are moving to, not the one vendored today.

Gate: the templates are build output upstream, so the guard points at that build and the
detection step belongs in the upstream repo's CI, which can clone gq with no credential;
whether gq becomes the single QML store is open upstream and flips where the fix for #86 lands;
whether the `bcfishobs_fiss_fish_observations` key is renamed, a coordinated change.

### 3. Translator opacity and labels

- [ ] Carried by move 2, #101

`gq_style()` returns a per-class opacity vector and `tmap_classified()` maps it to
`fill_alpha` / `col_alpha`, keyed on `names(cls$values)` (#71). #31 is the same gap filed
earlier, with casing and outline as its lower-priority remainder. #55 names the `labels`
vector by class key. Touches `R/gq_style.R`, the tmap translators and their tests.

Measured 2026-11-04: `R/gq_style.R` reads no per-class opacity, so all 15 `bec_zone` classes
draw at full opacity.

Gate: #55 changes an exported function's documented return shape.

### 4. Custom CSV reader

- [ ] Carried by move 2, #101

`gq_reg_custom()`'s classified branch emits `width` and `dash` in place of `outline_width`, and
an absent optional column reads as `NA` instead of raising (#42, #75). Touches `R/gq_reg.R`
and its tests.

Gate: a `dash` column in the CSV, and which spellings it accepts.

### 5. Register styles

- [ ] Carried by move 2, #101

Rows in `inst/registry/reg_custom.csv` and a rebuild of `reg_main.json`: rule comparison,
expected use, flood factor, tree loss and gain, and a stream label entry (#98); the nine-class
land-cover palette with `from_class` and `to_class` renderers (#67). Opacity is per class, so
this batch needs batch 3.

Gate: the two tree-change hex values, chosen on the blended basemap beside the existing
oranges; whether the QML for #67 is authored upstream, since gq vendors QML and does not write
it.

### 6. Check gate

- [ ] Carried by move 3, #102

Clear the two `R CMD check` WARNINGs and drop `error-on: '"error"'` from
`.github/workflows/R-CMD-check.yaml` (#51); fix the off-by-one `00_pkg_src` path in
`tests/testthat/test-vignette_legend_coverage.R` and prove the branch is reachable (#80).

Measured 2026-11-04: three non-ASCII string literals remain (`R/gq_qgs_extract.R:75`, `:197`,
`R/gq_reg.R:19`) and five demo datasets are undocumented in `R/data.R`. The tarball NOTE half
of #51 is already fixed. Batch 9 rewrites the note at `R/gq_qgs_extract.R:197`, so this batch
lands first.

### 7. README and vignette

- [ ] Carried by move 3, #102

Move finished roadmap items into the README's function overview and reconcile the registry
count (#95); re-compose `vignettes/gq-intro.Rmd` with a registry legend, scale bar and keymap
on the current `gq_tmap_style(reg, "x")` signature (#62); carry the tile provider's credit out
of `gq_basemap_tiles()` and render it in both vignettes (#58).

Gate: narrow the crossings to the AOI or widen the AOI and retitle; where a credit goes when
legend, logo, scale bar and keymap hold the four corners; what a blended basemap credits.

### 8. Registry build inputs

- [ ] Carried by move 3, #102

Decide what `data-raw/reg_build_main.R` reads and what proves `reg_main.json` is current.
#85: `reg_qgis_fishpassage.json` is an input to nothing. #84: `xref_layers.csv` names a layer
the registry does not. #11: rebuild automatically when a source changes.

Measured 2026-11-04: `xref_layers.csv:2` still reads `bcfishpass.crossings`; #11 names a
source file by a name the repo no longer uses.

Gate: delete, fold into the merge, or annotate the fish passage registry; generate the
cross-reference from the registry or keep it by hand; a bot commit or a test that fails when
the rebuild differs.

### 9. Extractor fidelity

- [ ] Carried by move 4, #103

`R/gq_qgs_extract.R` reads the label field and weight from where QGIS writes them (#6),
extracts overlay and casing from single-symbol renderers (#24), reads layer opacity, cap and
join style, and flags a data-defined colour (#38), and accepts a `.qlr` (#23). One re-extract
and one registry rebuild.

Measured 2026-11-04: 0 of 25 labelled layers in `reg_main.json` carry `label.field`;
`railway` carries the `3 symbol layers` note and no `overlay`.

Gate: how far the registry goes, given it models what tmap and mapgl can render and the QML
corpus is the lossless copy; whether #23 still has a source worth extracting.

### 10. Label translators

- [ ] Carried by move 4, #103

`gq_tmap_labels()` and `gq_mapgl_labels()` (#7), for plain-field labels first. Needs batch 9's
label field. The audit in #7's comment lists what maps cleanly, what approximately, and the
six hard tmap limits.

Gate: whether `merge_lines` and `min_feature_size` are carried in the registry as hints for
the consumer's data prep.

### 11. Registry schema decisions

- [ ] Carried by move 5, #104

Reconcile the documented format with what ships and formalize it as json-schema (#2); a
convention for project-specific overrides, which needs a filter (#20); `name_qgis` and a
legend-name cross-reference (#21); a `source_type` for project rasters and a key that survives
two layers sharing a name (#72).

Gate: GeoStyler vocabulary, a breaking rename of registry keys; a filter column; a layer key
that is not derived from the name alone. The raster `source_type` needs the template repo to
know the term first, or the layer is dropped silently; new source types for URL and catalogue
layers are open in the project-config repo, so read those before proposing a term. The worked
example at the top of #20
rests on a measurement since withdrawn as taken on a stale checkout: re-check it before
anything builds on it.
