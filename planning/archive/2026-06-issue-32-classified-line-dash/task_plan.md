# Task: Classified line layers drop QGIS dash pattern (line_style/customdash) (#32)

## Problem

Classified line layers drop the QGIS line **style** (dash pattern). The
extractor's classified-line branch (`R/gq_qgs_extract.R:223-229`) captures only
`color`/`width`/`opacity` per class — it never reads `line_style` / `customdash`.
So every class in a classified line layer comes out **solid**, even when the
source `.qgs` styles some classes dashed (e.g. the `;INTERMITTENT`
`mapping_code_salmon` classes in `streams_salmon`).

**Verified against `bcrestoration_mobile.qgs`** (rfp template): the dash is NOT
encoded as `line_style="custom_dash"` (what the simple branch's line 160
assumes). QGIS keeps `line_style="solid"` and flags the dash via
`use_custom_dash="1"` + `customdash="0.66;2"`. So both the classified branch
(missing entirely) and the simple branch (wrong key) need dash logic that keys
off `use_custom_dash`.

## Decisions (user-approved)

- **Store raw QGIS value** — named `line_style` ("dash dot") when present, else
  the `customdash` pattern ("0.66;2"). Preserves flexibility; consumers
  normalize downstream.
- **Shared helper across both branches** — fixes the latent `use_custom_dash`
  gap in the simple branch too. Still strictly line-style (not #31).
- **gq is source of truth** — committed `reg_qgis_restoration.json` is the
  durable artifact; the private rfp `.qgs` is upstream input only. Provenance
  script is dev-only (requires rfp installed).

## Phase 1 — Shared dash helper + extractor capture
- [x] Add `parse_dash(layer_node)` in `R/gq_qgs_extract.R`: returns `customdash`
      when `use_custom_dash=="1"`, else `line_style` when not `solid`, else `NA`
- [x] Route the simple-line branch through `parse_dash()` —
      fixes the latent `use_custom_dash` gap
- [x] Add `cls$dash <- parse_dash(sym_layer)` (when non-NA) to the
      classified-line branch
- [x] Tests: `parse_dash` for named / custom-dash / solid; extractor test on the
      `roads` fixture classified line carrying `use_custom_dash` (38 pass)

## Phase 2 — Regenerate registries
- [x] Add `data-raw/reg_extract_restoration.R` documenting extraction via
      `gq_qgs_extract(system.file("templates","bcrestoration_mobile.qgs", package="rfp"))`,
      guarded if rfp absent
- [x] Re-extract `reg_qgis_restoration.json` (47 layers)
- [x] Run `data-raw/reg_build_main.R` → `reg_main.json` (53 layers, 0 conflicts)
- [x] Verified: `streams_salmon` `;INTERMITTENT` classes carry `dash:"0.66;2"`,
      `transmission_line` still `"dash dot"`; reg_main.json diff strictly
      dash-only (57 added, 0 removed, 0 non-dash). Also captured named "dash"/"dot"
      on road classes and "2.5;3.5" on another stream layer.

## Phase 3 — Surface in resolvers
- [x] `gq_style()`: build a `dashes` vector parallel to `widths` (vapply over
      `$dash`, drop `__empty__`, attach if any non-NA)
- [x] `gq_tmap_classes()`: add `dashes` to the returned list
- [x] Add `dash_to_lty()`: normalize raw QGIS dash (mm pattern / unknown) →
      valid tmap `lty` (`"dashed"`); valid named lty passes through. Applied in
      `tmap_line_args` so the `"Pipeline installed"` raw pattern doesn't break
      tmap (raw stays in registry for mapgl's exact length)
- [x] roxygen `@return` updates for `gq_style` + `gq_tmap_classes`; `document()`
      (man/gq_style.Rd, man/gq_tmap_classes.Rd)
- [x] Tests: `gq_style` + `gq_tmap_classes` return `dashes`; `dash_to_lty`
      units; tmap_line_args lty mapping. Added `dash` to mini_registry arterial
      class. Full suite green (238 pass) with tmap 4.3 installed.

## Phase 4 — Validate
- [x] `devtools::test()` green (238 pass, 0 fail; 1 pre-existing warn at
      test-gq_registry_read.R:25). Installed tmap 4.3 + mapgl 0.4.6 (Suggests).
- [x] `lintr::lint_package()` clean on changed files (only pre-existing
      `# buffer/halo` commented-code note at gq_qgs_extract.R:376, untouched)
- [x] `document()` + `check()`: no ERROR. 2 WARN (non-ASCII em dashes
      package-wide; undocumented `data/` datasets) + 2 NOTE (gq.Rproj; future
      timestamps) are ALL pre-existing and unrelated to #32. planning/ +
      data-raw/ already in .Rbuildignore — change adds nothing to check.

## Out of scope
- mapgl classified dash (issue surfaces via `gq_style` + `gq_tmap_classes` only)
- All #31 dimensions (opacity, casing, outline, radii, shapes)

## Validation
- [x] Tests pass (238)
- [x] `/code-check` clean on each commit (Phase 1 + Phase 3 rounds: Clean)
- [x] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
