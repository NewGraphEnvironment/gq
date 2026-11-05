## Outcome

Move 2 of `planning/backlog.md` (#101), three batches in one branch. **Batch 3:** `gq_style()`
returns per-class `opacities` and names `labels` by class key; `tmap_classified()` maps opacity
onto `fill_alpha` / `col_alpha`, reading a class with none as opaque because the extractor
records opacity only below 1; legend rows carry the same alpha (#71, #31, #55). `bec_zone`, and
the translucent classes of `fire_severity`, `roads_dra` and `streams_all`, now draw at their
registry opacity. **Batch 4:** `gq_reg_custom()` reads an absent optional column as empty,
writes a classified line in the extractor's key names, takes a validated `dash` column, and
warns on any header column it will not read (#42, #75). **Batch 5:** six registry-only styles
for derived products (habitat rule comparison, expected use, flood factor, tree cover change,
land-cover change from and to, the last in drift's IO LULC palette) (#98, #67). Learned: the
plan's "all polygon" typing was wrong for the two segment-drawn layers; a classified CSV line
still needs its layer-level stroke for mapgl; and the first misspelled-header warning tested a
proxy (an unstyled layer) instead of the property (an unread column) — four review rounds,
the last ending by enumerating every column the reader's code reads. Follow-ups filed: #107
(mapgl per-class opacity) and the land-cover QML in the upstream style store; #24's body now
carries #31's casing/outline remainder.

## Measurement

- Classified layers with per-class opacity in `reg_main.json`: 5 (`bec_zone` 0.25 on all 11
  classes; `fire_severity`, `roads_dra`, `streams_all` on some; `habitat_lateral` raster). So
  #71 changed four drawn layers, not one; #71's body said 15 BEC classes, the registry has 11.
- `data-raw/reg_build_main.R` reproduced `reg_main.json` byte for byte on unchanged sources and
  again after the reader change and the empty `dash` column; the new rows added 190 lines and
  removed none (later 8 more for the restored line stroke).
- Tree gain `#ff8c42` is 12.7 / 14.1 / 10.3 CIEDE2000 from `#d95f02` / `#f2a93b` / `#e49635`;
  the space between those three oranges tops out near that, and the best-scoring candidate
  (`#fdd49e`) washed into the topo basemap (`tree_change_swatch.png`, `findings.md`).
- Every real registry CSV in the org (gq's own, drift x2, wet x2, fish passage reporting x3)
  reads with 0 warnings under the new reader.
- Suite: 307 → 311 tests, 0 failed, 4 skipped on the final tree.

## Owed

- `/gh-pr-merge` ticks move 2 and batches 3–5 in `planning/backlog.md`
- The QML for #67's three styles lands in the upstream style store (issue filed there 2026-11-05) and is vendored by `data-raw/styles_vendor.R`

Closed by: PR for branch `101-move-2-styles-reach-the-map-batches-3-4`
