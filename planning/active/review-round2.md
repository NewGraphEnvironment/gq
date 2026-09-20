# Review round 2 — #90 re-vendor `inst/styles/`

Reviewed at `21ab7b0` (three-dot against `origin/main` `b7ebbbf`) plus the unstaged
`NEWS.md` and `planning/active/findings.md`.

**Note on a moving tree.** A third commit (`21ab7b0`, "Derive the form/gap split") and a
new `NEWS.md` bullet landed *during* this review — the first snapshot I took did not have
either. Every measurement below was re-taken against the tree as it stands at the time of
writing. rfp also advanced two commits while reviewing (`v0.76.0-6` → `04282b75`);
`git log --stat -- inst/extdata/styles data-raw/qgs/roster` is empty across them, and the
byte sweep was re-run afterwards (60 checked, 0 drifted), so the vendored corpus is still
current.

---

## Findings

- **[bug]** `data-raw/styles_vendor.R:199-202` — the comment makes two claims about rfp
  that are both false, and the second is *added by this diff*. This is in the comment the
  diff exists to correct, on the one axis its own enumeration did not sweep.

  > `dem_hillshade and dem_turbo alone are QGIS-authored sidecars rather than`
  > `lifted <maplayer> blocks, which is why they alone open with`
  > `<map-layer-style-manager> instead of <flags>. airphoto_gray was repaired out`
  > `of that form upstream (rfp#235 follow-up) and is an ordinary QML.`

  **(a) "QGIS-authored sidecars … which is why" is a false cause, refuted by a file the
  same paragraph names.** `airphoto_gray.qml` is QGIS-authored — more directly than either
  dem file. `git log --follow --name-status` shows it entering rfp at `11ec65fc` (#235,
  2026-08-30) as **`C100  inst/testdata/nodes/raster_gdal.qml → inst/extdata/styles/raster/airphoto_gray.qml`**,
  a 100% copy of a reference node; `inst/testdata/nodes/README.md` describes those as
  "What QGIS itself writes for a layer, emitted by `QgsMapLayer.writeLayerXml()`"; rfp's
  own `data-raw/qgs/nodes_author.R:254-255` says "rfp lifts its shipped airphoto_gray.qml
  out of raster_gdal"; and rfp NEWS 0.49.0 calls it "backed by a QGIS-authored
  `singlebandgray` QML … the `raster_gdal.qml` reference byte for byte".

  The clean control: **all nine** QGIS-authored nodes in `rfp/inst/testdata/nodes/*.qml`
  open with `<flags>` — including `raster_hillshade.qml`. A QGIS-authored hillshade opens
  with `<flags>` while the shipped `dem_hillshade.qml` opens with
  `<map-layer-style-manager>`, so authorship cannot be the discriminator. What actually
  differs is the *export*: `dem_hillshade.qml` carries
  `<map-layer-style-manager current="default"><map-layer-style/></map-layer-style-manager>`,
  the style-manager category, which is written when a style is saved from the Style dialog
  / `saveNamedStyle` rather than from `writeLayerXml()` on a bare layer.

  **(b) "airphoto_gray was repaired out of that form upstream (rfp#235 follow-up)" is
  false.** It was never in that form. Measured per revision with `xml2`:

  | rev | first child |
  |---|---|
  | `11ec65fc` (creates it, #235) | `flags` |
  | `4938318c~1` | `flags` |
  | `4938318c` (the "follow-up") | `flags` |

  `4938318c` repaired the **contrast stretch**, not the document form: it shipped
  `<minValue>1</minValue><maxValue>9</maxValue>` with `extent = WholeRaster` (the range of
  the 3×3 `dtm.tif` fixture) and rendered "2 colours, 99.5% white" on a real scan; the fix
  moved it to `extent = UpdatedCanvas`. rfp's phrase **"bare sidecar"** means *a `.qml`
  applied directly to a raster file without a project* — a deployment mode
  (`rfp_styles_apply()` writes a `.qml` byte-verbatim beside a `tif`/`tiff`/`vrt`) — not a
  document form. The word was carried across from rfp's commit title and its meaning
  inverted on the way. rfp NEWS states the same thing plainly: "`airphoto_gray` no longer
  renders **flat** as a bare sidecar."

  Suggested repair: keep the observation, drop the cause and the history. e.g.
  *"`dem_hillshade` and `dem_turbo` are the only two files in the store that open with
  `<map-layer-style-manager>` rather than `<flags>` — they were exported with the
  style-manager category. Measured 2026-09-20 across all 66 store QMLs. `airphoto_gray` is
  an ordinary `<flags>` QML (a verbatim copy of rfp's `raster_gdal` reference node). None
  of the three is gq's to ship, for the roster reason above."*

  `planning/active/findings.md` carries the same wrong characterisation ("rfp repaired it
  out of the bare-sidecar form after rfp#235") and wants the same correction.

- **[fragile]** `NEWS.md:48-53` — *"The class is closed by enumeration … All hold"* is not
  supported, and it is the sentence that tells the next reader to stop looking.

  Three separate problems, each independently sufficient:

  1. **The axis set is three of six.** The enumeration was scoped to "a count, a member
     list or a superlative". `conventions/code-check.md` (rfp#299 row) names six ways a
     restatement identifies its population — count, member list, **rank or superlative**,
     what a sibling assertion catches, **behaviour of a second function**, universal
     quantifier — and prescribes sweeping each across four subjects including *external
     systems*. Finding 1 sits squarely on the unswept axes (a causal claim about how rfp
     authors files, plus a historical claim about an rfp repair). The sweep's own axis
     choice is what let it through, which is exactly the failure rfp#299 records.
  2. **The `:199` row reads a truncated version of the line it checks.**
     `findings.md` logs it as *"dem_hillshade and dem_turbo **alone open with**
     `<map-layer-style-manager>`" → ✓*. That half is true (`grep -rl` over all 66 store
     QMLs returns exactly those two — I re-measured). The line in the file also asserts
     *why*, and that half is false. Enumerating the claim as the part you already believe
     is how a ✓ gets recorded against a false sentence.
  3. **The sentence this diff added is not in the table at all.** `:201-202`
     ("airphoto_gray was repaired out of that form upstream") post-dates every row in the
     enumeration, and nothing swept the diff's own new prose.

  Everything the table *does* list I re-measured independently and all of it holds: 53
  vector index rows on both sides; 3 override rows / 3 distinct keys
  (`fisheries_sensitive_watersheds`, `land_ownership`, `range_tenure`); exactly 3 raster
  extras and 0 service extras upstream; `rfp_raster_styles.csv` = `dem_turbo`,
  `dem_hillshade`, `habitat_lateral`, `airphoto_gray` with `habitat_lateral` vendored; 66
  store QMLs (54 vector + 4 raster + 6 services + 2 forms). So the enumeration is accurate
  within its scope — it is the *terminal claim* that overreaches.

  Suggested repair: narrow the sentence to what was measured ("every count, member list
  and superlative in this script was checked against its source") and drop "the class is
  closed", or extend the sweep to causal/behavioural claims and re-run it against the
  final tree.

- **[fragile]** `NEWS.md:17` — *"This resolves **part** of #86 — the preview expression and
  5 of the 7 fields it named."* The literal reading is true (#86 listed 7; 5 are gone), but
  it leaves a reader with "2 dead fields remain", and #86's own revised body says the
  opposite is unresolved:

  > "Do not carry '7 dead fields' forward as a measurement; it is superseded and only
  > partly re-verified."
  > "rfp#307 measured the surviving 19 against the live object and reports **0 dangling**.
  > Both cannot be right about `fid` and `linear_feature_id`."

  This is the same roster-absent ≠ column-absent inference the branch already caught itself
  making about `species_name` (findings.md, "rfp#307 corrected my #86 re-scope"), surviving
  into the release note one noun over. Suggest "5 of the 7 fields it listed; whether the
  remaining 2 are dead at all is an open question in #86" or similar.

---

## Checked and clean

Recording these so a later round does not re-derive them.

**The new guard is not vacuous.** Driven directly (`/tmp/vac.R`, testthat 3e):

| input | raster pin | verdict |
|---|---|---|
| as shipped | `expect_setequal("habitat_lateral", "habitat_lateral")` | PASS |
| an extra raster vendored | `c("habitat_lateral","airphoto_gray")` | **FAIL** |
| 0-row index | `character(0)` | **FAIL** |
| `kind` column absent/renamed | `character(0)` | **FAIL** |
| one service dropped | 5 vs 6 | **FAIL** |

`expect_setequal(character(0), character(0))` does pass, but no reachable input produces
that — the RHS is a non-empty hardcoded literal in both pins, so the degenerate cases all
fail rather than passing vacuously. `expect_setequal(NULL, …)` errors ("`object` must be a
vector"), which scores as an error not a pass. The hardcoding is correct per
`code-check.md`: an expected set must come from a producer the subject cannot influence,
and deriving it from the index under test would make it `x == x`.

**The retained `expect_false` at :72 is not strictly redundant** — the comment at :69 says
"Redundant against the positive pins above". A row with the *wrong* `kind` (e.g.
`airphoto_gray` as `kind = "vector"`) evades the raster pin and trips the negative one, so
the two arms catch different things, which is what `code-check.md` prescribes ("check it by
name *and* pair it with a catch-all complement"). Not reporting it as a finding — no
current code path can produce that row — but calling it redundant is an invitation to
delete it later.

**Every number in NEWS bullet 1 re-derived independently:**

| claim | measured |
|---|---|
| 60 files checked, 2 drifted before, 0 after | 60 / 0 now; `git diff --stat origin/main...HEAD -- inst/styles/` names exactly the 2 QMLs |
| 5 fields removed, named | `fish_obsrvtn_event_id wscode_ltree localcode_ltree waterbody_key species_id` ✓ |
| "each across five blocks" | roster / alias / policy / default / constraint(+constraintExpressions) ✓ |
| roster 24 → 19 | 24 → 19 ✓ |
| 4 `fish_obsrvtn_pnt_distinct_id` refs remain | 4 ✓ |
| `index.csv` byte-unchanged | three-dot diff is 0 lines ✓ |
| six services | 6 ✓ |
| `feature_name` → `floodplain_name` "wrong attribute" | both are real fields in `floodplains.qml`'s roster, so "wrong attribute" (not "missing") is right ✓ |
| "rfp *later* added airphoto_gray … a list written before it existed" | gq guard written 2026-08-24 (`1e294e7`); airphoto_gray created in rfp 2026-08-30 (`11ec65fc`) ✓ |
| NEWS bullet 3: groups.csv had 4 form keys, has 2; 8 gaps = 2 form + 6 genuine | at `6bf069d`: `form_edna form_fiss_site form_monitoring form_pscis`; today 2; gaps = 8 / 2 / 6 ✓ |

**Pre-existing-failure claim verified.** Full suite with `RFP_STYLES_DIR` set:
`FAIL 1 | WARN 1 | SKIP 0 | PASS 1117`, the two being
`test-gq_registry_read.R` "errors on missing file" (warning) and `test-template_drift.R`
"the vendored table is identical to what the templates say now" (failure, gq#70). Neither
is reachable from this diff: the branch touches only
`inst/styles/vector/{bcfishobs_fiss_fish_observations,floodplains}.qml`,
`data-raw/styles_vendor.R`, `tests/testthat/test-gq_style_qml.R` and `planning/`. The
template-drift test reads `inst/registry/template_groups.csv` and rfp's `.qgs` files via
`RFP_TEMPLATE_DIR`; the registry-read test reads
`tests/testthat/fixtures/mini_registry.json`. `SKIP 0` confirms the byte-identity guard ran
rather than skipping. (`task_plan.md` records PASS 1116 against the prompt's 1117 — the
third commit's test file moved it; worth re-pointing before archive.)

**Restatements elsewhere in the repo, all still true:** `CLAUDE.md` "50 shared vector
styles" (50), "the 3 layers" (3), "1 raster, 6 WMS/xyz basemaps" (1 / 6), "`layer_key,layer,template,scope,kind`,
quoted (layer names carry commas and one begins with a space)" (`Crossings - PSCIS,  modelled, dams`
and ` Biogeoclimatic Ecosystem Classification` both present);
`R/gq_style_qml.R:66` + `man/gq_style_qml.Rd:38` "3 layers of 53"; `README.md` carries no
corpus counts (dropped in `043a31d`). No stale copies of either changed QML anywhere in the
tree (`find . -name '*.qml' -not -path './inst/styles/*'` is empty), and no gq artifact is
derived from their bytes — `index.csv` is unchanged and `reg_main.json` comes from `.qgs`
extraction, not from the QML corpus.

**Other script comment claims spot-checked:** `data-raw/reg_extract_restoration.R` and
`data-raw/reg_extract_themes.R` both exist and the latter uses `RFP_TEMPLATE_DIR` (5
occurrences); `rfp/inst/testdata/nodes/` exists; `rfp/.Rbuildignore` carries `^data-raw$`;
`vector/osm.trail.qml` is still present upstream, so the `orphans_known` entry and its
rfp#187 note are live and the script's `stale` message correctly stays silent.
`^planning$` is in gq's `.Rbuildignore`, so the new PWF files do not ship.

**Minor, not a finding:** `findings.md` (unstaged) says "the dated `6bf069d` note in the new
comment" is one of the time-qualified restatements left alone, but no `6bf069d` appears in
`data-raw/styles_vendor.R`. The historical claim it refers to is there and is correct; only
the SHA citation is absent from the file it describes.
