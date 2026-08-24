# Task: Host the canonical QML corpus so QGIS styling has a versioned source (#39)

gq is the source of truth for layer styles, but ships only the *registry* — the
cross-backend abstraction that drives tmap and mapgl. The QGIS-native form, the
QML itself, has no home here. rfp#17 measured why that matters: against a
147-layer project the registry keeps 53 layers, one symbol layer of up to five,
~20 properties of up to 73. That is the right trade for tmap/mapgl and the wrong
one for QGIS, where the full QML is available and lossless.

**#39's premise changed after it was filed** (2026-08-03). On 2026-08-23 rfp#174
Phase A landed a committed, versioned QML store at `rfp/inst/extdata/styles/` —
64 files, 3.4 MB, with an index and standing drift tests. The corpus is no longer
"wherever someone last styled a field project"; it exists, in rfp.

Decision taken 2026-08-24: **host it in gq anyway**, because gq is where
cross-backend style ownership lives and rfp#174's own build diagram already reads
gq's CSVs beside rfp's QMLs. rfp keeps its copy for now; a follow-up rfp issue
repoints its builder at gq and deletes the duplicate.

## What exploration established

- **gq needs none of rfp's lift machinery.** The `<maplayer>` → QML boundary is
  positional-not-filter, was wrong once (rfp#130), and is pinned by a
  QGIS-container oracle in rfp. gq vendors the *committed artifact*, the same way
  `data-raw/reg_extract_themes.R` already reaches rfp's templates. No mirrored
  rule, no dependency cycle.
- **The key spaces already agree.** 45 of 50 store slugs are `groups.csv` keys,
  and gq's `normalize_layer_name()` (`R/gq_style.R:104`) and rfp's `slugify()`
  produce identical output on all 53 real layer names — including the one that
  begins with a space. Two independent implementations that happen to match:
  worth a guard, not an assumption.
- **Vendor through `index.csv`, never by globbing.** `vector/osm.trail.qml` is
  tracked but has no index row — the gq#41 trail donor, hand-added by rfp#171 one
  day before the index existed, superseded by the generated `trails.qml` (they
  differ in bytes). rfp's guard walks index → file only, so a stray file is
  invisible to it. A directory copy would silently vendor it.
- **The issue's proposed layout is wrong.** `inst/styles/<template>/<layer_key>.qml`
  duplicates 50 shared files across 2 templates. rfp measured that only **3**
  layers genuinely differ between templates; mirror its shared + per-template
  override structure instead.
- **`^styles$` in `.Rbuildignore` and the empty `styles/qml/.gitkeep`** are a
  placeholder for exactly this corpus — but a non-shipping one. `system.file()`
  needs `inst/`.

---

## Phase 1 — Vendoring script

- [x] `data-raw/styles_vendor.R`, following `reg_extract_themes.R:37-55`: locate
      rfp's store via `system.file("extdata", "styles", package = "rfp")` with an
      `RFP_STYLES_DIR` env override, erroring with the `pak::pak(...)` install
      hint when absent
- [x] Enumerate **from `index.csv`**, not from the filesystem — copy each
      `slug` + `scope` row to `inst/styles/vector/` or
      `inst/styles/vector/overrides/<template>/`; copy `raster/` and `services/`
      wholesale (no index, filenames are already slugs)
- [x] Write gq's own `inst/styles/index.csv` keyed by gq's `layer_key`
      (`normalize_layer_name()` of the recorded layer name), carrying
      `layer_key,layer,template,scope,kind` — gq's key space is authoritative in gq
- [x] Abort on: a slug where `normalize_layer_name()` disagrees with rfp's; an
      index row with no file; **a file with no index row** (the direction rfp's
      guard misses); a duplicate `layer_key,template` pair
- [x] Report, don't fail, the keys in `groups.csv` with no QML — the 4 forms are
      owned by `rfp_form_build()` and the remainder are real gaps worth naming

## Phase 2 — Accessor

- [x] `read_styles_index()` in `R/gq_style_qml.R`, `@noRd`, mirroring
      `read_groups_csv()` (`R/gq_groups.R:5-25`) exactly — `system.file()`,
      abort on `""`
- [x] `gq_style_qml(layer_key, template = NULL)` returns a **path**. This is a
      new return shape for gq — every existing export returns a list or a
      data.frame — so say so in the roxygen
- [x] Precedence override-then-shared when `template` is given, shared only when
      it is not
- [x] Error on an unknown key, naming near-misses. Returning `NA_character_`
      silently is the trap; a lookup that finds nothing must say so
- [x] Runnable `@examples` reading a real shipped key, and `devtools::document()`

## Phase 3 — Guards

- [x] Index integrity **in both directions** — every row resolves to a file, and
      every file has a row. This is the rfp gap; gq should not inherit it
- [x] `normalize_layer_name(index$layer)` equals `index$layer_key` for every row
      — pins the two-slugifier agreement measured above
- [x] Every vendored QML parses as XML, roots at `<qgis>`, and carries no source
      binding (`datasource`, `layername`, `id` absent). Cheap, structural, runs
      without rfp
- [x] Override precedence resolves; unknown key errors
- [x] Byte-identity against rfp's store, under `skip_if_not_installed("rfp")` —
      the drift guard proper, skipped where rfp is absent, which is why the
      structural assertions above stand alongside it

## Phase 4 — Build and docs

- [x] Delete `styles/qml/.gitkeep` and the now-dead `^styles$` from
      `.Rbuildignore`
- [x] Confirm `R CMD check` installed-size NOTE: gq goes ~166 KB → ~3.6 MB of
      `inst/`. Under the 5 MB threshold, but verify rather than assume
- [x] README + CLAUDE.md — the registry-sources list has no `inst/styles/` entry;
      add the corpus and `gq_style_qml()` to the translator table
- [ ] `NEWS.md` + `DESCRIPTION` 0.3.0 → **0.4.0** (new export) as the **final**
      commit

## Phase 5 — Reconcile upstream

- [ ] Edit **gq#39**'s body in place: premise superseded by rfp#174 Phase A,
      layout is shared+override not per-template, rfp retains its copy
- [ ] File **rfp**: `vector/osm.trail.qml` is an unindexed leftover, and the
      store guard walks index → file only so it cannot see one
- [ ] File **rfp**: repoint `data-raw/qgs/build_template.R` at gq's corpus and
      delete `inst/extdata/styles/` (the deferred half of this decision)

## Validation

- [ ] `devtools::test()` — 104 existing pass, 0 fail, plus the new file
- [ ] `lintr::lint_package()` clean on changed files, against the `HEAD` baseline
- [ ] `devtools::check()` no new ERROR/WARNING
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive`, then `/gh-pr-push`
