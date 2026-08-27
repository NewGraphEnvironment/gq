# Task: Restoration template layers are never downloaded: groups not mapped in templates.csv (#40)

## Context

A project built from a shipped QGIS template displays cartography for data that
was never fetched. The issue diagnoses it as missing `templates.csv` rows, which
is right — but the diagnosis stops one level short of the reason nobody noticed.

**The composition chain fails silently at every join.** `join_registry()`
(`R/gq_groups.R:290-304`) turns a registry miss into `NA_character_` with no
warning and no drop. Nothing asserts a group is mapped to any template. So
`Base - Orthoimagery` has been mapped to **zero** templates for the entire
history of the file, and `gq_template_layers("bcrestoration_mobile")` currently
returns **11 rows with `NA` source_layer**, and the suite is green.

The layers are the symptom. The absent guard is the defect.

## Three things the issue gets wrong

Measured against the files, not taken on trust:

1. **"Nine layers" is seven.** 9 counts layer×template *pairs* and double-counts
   the two the issue itself says are shared. The restoration list of 5 is exactly
   right.
2. ~~**`national_park` and `old_growth_management_areas` do not "need real
   registry work"** — gq already ships QMLs for both, so the symbology exists.~~
   **This correction of mine was FALSE and the issue was right.** Both QMLs
   contain **zero** `renderer-v2` elements — they are attribute-form QMLs
   (`fieldConfiguration`, `editform`, `widgets`), and their only `<symbol>`
   nodes are QGIS 3D elevation-profile defaults. Measured: real styled layers
   (`lake`, `wetland`) have 1 renderer; these have 0. The 13 KB / 15 KB I cited
   as evidence of symbology is form config. Exactly five QMLs in the corpus lack
   a renderer, and they are precisely the five "store-only" keys at
   `planning/archive/2026-08-issue-39-qml-corpus/findings.md:57` — which is the
   coherent reason they were never in `groups.csv`, not an oversight.
3. **It misses a larger gap.** Eight `groups.csv` keys have **no `reg_main.json`
   entry at all** — `bing_aerial`, `esri_satellite`, `esri_world_topo`,
   `google_satellite`, `fire_perimeters_current`, `form_edna`, `form_monitoring`,
   `habitat_lateral` — and three more are in the registry with no `source_layer`:
   `harvest_area`, `planting_site`, `frep_rip2021_mar2022`. The first group is
   mostly fine (xyz/WMS and local forms have no BC table). `harvest_area` and
   `planting_site` are marked `source_type=bcdata` in `groups.csv:50-51` with no
   source_layer — that looks like the same bug, unreported.

Also: `bcfishpass_mobile`'s other three "missing" layers (`floodplains`,
`harvest_area`, `planting_site`) are **deliberately** restoration-only and pinned
by `test-gq_groups.R:109-114`. Its only real gap is `orthophoto_tiles`. A guard
that cannot tell deliberate asymmetry from an accident is useless here.

## On ordering — the concern inverts

`group_order` is read by exactly two `order()` calls (`R/gq_groups.R:152,201`)
and is validated **nowhere** — not for uniqueness, contiguity, or a 1-based
start. It is already per-template, so a radically different project type can
number its groups however it likes today. The model scales.

The actual risk is the opposite one: that someone infers contiguity is required
and renumbers to preserve it. Which is exactly what "mirror bcfishpass" asks me
to do to seven existing rows. So do the mirror — the two templates share a group
vocabulary today and a field user switching between them benefits — but write
the freedom down, and pin it, so these two templates do not become a constraint
on the next twenty.

## Phase 1 — Guards first, failing on today's data

- [ ] Test: every `groups.csv` `layer_key` resolves to a `reg_main.json` entry
      with a `source_layer`, **except** an exemption set where each entry carries
      a REASON. Exemptions are for layers with no BC table by nature — xyz/WMS
      basemaps, local forms — not for "not done yet"
- [x] Test: every group in `groups.csv` is mapped to at least one template
- [x] Test: every group in `templates.csv` exists in `groups.csv` (true today by
      luck, nothing enforces it)
- [x] Deliberate template asymmetry (`Floodplain`, `Restoration` being
      restoration-only) must **not** trip these. Assert that intent explicitly
      rather than letting it pass by accident
- [ ] Confirm each guard FAILS on current data and names the real gaps. A guard
      nobody has seen fail is decoration — and check the exemption list is not
      so broad the assertion is unreachable
- [ ] Decide whether `join_registry()` should warn rather than return silent
      `NA`. Note the direction it fails in either way

## Phase 2 — The two `templates.csv` rows

- [x] `Other Point Features` at 3 for `bcrestoration_mobile`, existing 3–9
      renumbered to 4–10; `Base - Orthoimagery` at 11
- [x] Mirror `bcfishpass_mobile`'s position deliberately, and **document in the
      CSV header comment or roxygen that `group_order` is sort-only,
      per-template, and requires neither contiguity nor cross-template
      agreement** — so the next project type is not held to these two
- [x] Pin that freedom with a test using non-contiguous values, so nobody later
      adds a contiguity validator and breaks a future template
- [x] Verify: `gq_template_layers("bcrestoration_mobile")` gains exactly the 5;
      `bcfishpass_mobile` gains `orthophoto_tiles`; no layer appears twice

## Phase 3 — `national_park` and `old_growth_management_areas`

Rewritten after the review disproved this phase's premise. There is no shipped
symbology to register; it has to come from somewhere.

- [ ] Symbology from the corpus via `gq_qgs_extract()` on a project that carries
      the layer — the only route giving faithful entries with real provenance.
      Falling back to authoring fresh in `reg_custom.csv` is acceptable (both are
      polygons, the simple branch handles fill/stroke/label) **but the `note`
      must say the symbology is authored, not extracted**
- [ ] `reg_custom.csv` row + `Rscript data-raw/reg_build_main.R` — NOT a direct
      edit of `reg_main.json`, which is a build artifact
- [ ] `groups.csv` rows with `source_type` and a `source_layer` that is real and
      schema-qualified, so the Phase 1 guard passes on its own terms
- [ ] Record that `rmp_ogma_non_legal_current_svw` is the deliberate choice over
      the `_legal_` variant, or the next person "fixes" it
- [ ] Acceptance is NOT `gq_style_qml()` returning a path — it never parses the
      file and would return one for a zero-byte QML. Assert the QML **has a
      renderer**, which today it does not
- [ ] OGMA is in 6 of 16 corpus projects, national_park in 2 — treat separately
      rather than as one unit

## Phase 4 — The `NA` source_layer set the issue missed

- [x] Rule **derived from `source_type`**, not a hand-maintained exemption list.
      The direction of failure is the point: a list must be extended per layer,
      so a new layer defaults to *exempt*; a derived rule defaults to *checked*
- [x] `source_type` validated against a closed set first — it was unvalidated
      and nearly unconsumed, so a typo would have fallen through every branch
- [x] `wms` layers pinned to `index.csv` `kind == "service"` — two separately
      authored columns that must agree, each now a witness for the other
- [x] `harvest_area` / `planting_site`: the bug was **`source_type=bcdata`**,
      not the missing `source_layer`. Their own `reg_custom.csv` notes say
      "buffered river corridor" and "proposed restoration planting location" —
      project-authored, not BCGW tables. Changed to `local` with the sentinel
- [x] The three that cannot be resolved here — `form_edna`, `form_monitoring`,
      `habitat_lateral` — exempted with **gq#64** named as the reason, plus an
      assertion that each exemption is still needed so they cannot outlive it

## Phase 5 — Reconcile the issue body

- [ ] 7 distinct layers, not 9 — and say why the 9 arose
- [ ] Correct "need real registry work": the QMLs already ship
- [ ] Add the 11-layer `NA` finding, which is the larger version of the same bug
- [ ] Note that `bcfishpass_mobile`'s other three gaps are deliberate and
      test-pinned, so the issue's "2 missing" for that template is really 1

## Phase 6 — Land it

- [ ] `NEWS.md` + `DESCRIPTION` 0.9.0 → **0.10.0**. Minor: `gq_template_layers()`
      returns more rows for both templates, which is a visible behaviour change
      for any consumer building a project from a template
- [ ] `/planning-archive`, `/gh-pr-push`

## Validation

- [ ] `devtools::test()` — 922 passing plus new
- [ ] `lintr` clean on changed files (repo baseline is 0)
- [ ] `devtools::check()` no new ERROR/WARNING/NOTE against main's 0/2/2
- [ ] `/code-check` per commit; PWF checkboxes match landed work

## Verification

```r
devtools::load_all()
reg <- gq_reg_main()

# Phase 2 — the five restoration layers arrive
r <- gq_template_layers("bcrestoration_mobile", reg)
stopifnot(all(c("fiss_obstacles", "bcfishobs_fiss_fish_observations",
                "fiss_stream_sample_sites",
                "hydrometric_stations_environment_canada",
                "orthophoto_tiles") %in% r$layer_key))

# ...and nothing is styled without a source to fetch it from
subset(r, is.na(source_layer))$layer_key   # only the declared exemptions

# Phase 3 — symbology still resolves for the two added layers
gq_style_qml("old_growth_management_areas")
```

The guards are the real deliverable: a layer that is styled but never downloaded
should fail the suite, not the field day.
