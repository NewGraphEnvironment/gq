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
2. **`national_park` and `old_growth_management_areas` do not "need real registry
   work".** gq already ships and indexes QMLs for both
   (`inst/styles/index.csv:35-36`, ~13 KB and ~15 KB), vendored 2026-08-24. The
   symbology exists; what is missing is a `groups.csv` row and a `reg_main.json`
   source_layer/type entry. `planning/archive/2026-08-issue-39-qml-corpus/findings.md:57`
   already lists both as known store-only layers.
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

- [ ] `groups.csv` rows — decide group and `order` for each
- [ ] `reg_main.json` entries via the hand-curated path, carrying
      `whse_admin_boundaries.clab_national_parks` and
      `whse_land_use_planning.rmp_ogma_non_legal_current_svw`
- [ ] **Check `reg_custom.csv` can express what these need before routing them
      through it** — its classified branch has no per-class width or dash field
      (the trap hit in #61). If either layer's QML is classified, the CSV is
      lossy and the entry belongs elsewhere
- [ ] The QMLs already ship, so `gq_style_qml()` must keep resolving for both —
      assert it still does after the registry entries land
- [ ] OGMA appears in 6 of 16 projects in the corpus sweep, national_park in 2.
      Note that asymmetry rather than treating them as one unit

## Phase 4 — The `NA` source_layer set the issue missed

- [ ] Decide each of the 11 explicitly: legitimately source-free (exempt, with
      the reason recorded) or a real gap (fix or file)
- [ ] `harvest_area` and `planting_site` are the suspicious pair — `bcdata` in
      `groups.csv` with no `source_layer`. Resolve or file separately
- [ ] Whatever is not fixed here becomes an exemption from Phase 1's guard, so
      the guard goes green honestly rather than by being narrowed

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
