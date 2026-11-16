# Code-check round 3: branch 103-extractor-fidelity-and-labels (HEAD 8a670ed)

## Checklist read

- **code-check.md:** I read the prose of all 14 H3s under `## Mechanisms`, skipping table rows. From "Rules that stand alone" I also read "Documentation Staleness" and "An assertion that matches an interpolated value cannot see the claim around it". I did not read the other 27 headings: the rest of "Rules that stand alone", Security, and Spreadsheets and PDFs.
- **code-check-r.md:** I read these in full:
  - "`$` on a list partial-matches, so a longer sibling key answers for a missing one"
  - "Cross-function consistency for label/string normalization"
  - "A replacement function on an `xml_missing` node is a silent no-op"
  - "Tests that silently do not run"
  - "A `data-raw/` script must load the source tree, not the installed package"
  - "`nzchar(NA)` is TRUE — non-empty checks silently pass NA"
  - "A `pkg::` call in a test passes `devtools::test()` and fails `R CMD check` if `pkg` is undeclared"
  - "`tolerance` in testthat is RELATIVE, so it pins a published figure far more loosely than it looks"
  - "Under `R CMD check`, tests run from a temp dir against the INSTALLED package"

  I checked these against their index lines only: "`expect_gt()` and friends take no `info` argument", "`sort()` and `order()` collate by `LC_COLLATE`…" and "`package_version()` errors on a pre-release version string". I did not read the remaining 112.
- **code-check-spatial.md:** I read the index only. The one QGIS heading ("QGIS embeds a layer's style in the `.qgs`…") does not bear on an extractor that reads, not writes. None of its 132 sections were read in full.
- **code-check-shell.md:** I read the index only. The diff has no shell. None of its 101 sections were read in full.

## Mechanism

**One reading rule is applied by several parallel code paths, and each fix reached only the paths in front of it. Nothing holds the paths to one shared predicate.**

The extractor decides which QGIS symbol layers count, and how to fold opacity, in five places:

- `parse_single_symbol`
- `parse_categorized`
- `parse_graduated`
- `symbol_layers_extra` with `tick_overlay`
- `color_data_defined`

The two translators decide placement, halo and offset each in their own way.

Each round's fix was written as "make path B do what path A does". The paths it did not name kept the old rule:

- **Round 1:** the active-rule filter landed in `parse_labels`.
- **Round 2:** the enabled-layer filter and the casing core reached categorized. In graduated, only the enabled-layer filter landed.
- **This round:** the same split shows in the graduated parser, the overlay and outline opacity, and the data-defined scan. A related flaw is that the "unmodelled" note assumes position 1 is always modelled.

## Enumeration

Every parallel set this diff touches. "No live instance" means the measured template and the shipped registry do not exercise the disagreement.

### 1. Which symbol layers count (enabled, top-level)

| Path | Agrees? | Evidence |
|---|---|---|
| `parse_single_symbol` | agree | `./layer[not(@enabled='0')]` |
| `parse_categorized` | agree | same xpath |
| `parse_graduated` | agree | same xpath (line 508) |
| `tick_overlay` sub-symbol | agree, fails safe | `./symbol/layer` with `length != 1`: anything else returns `NULL`, and the layer gets a note |
| `color_data_defined` | **DISAGREE** | `.//layer/...` reaches disabled layers, sub-symbol layers and `<source-symbol>`. Probe: a data-defined colour only on an `enabled="0"` layer still sets the note (**F4**). No live instance: all 3 active expressions in the template are on enabled, drawn symbols (measured). |
| `parse_labels` vs its test | agree on the fixture | The parser uses `.//settings[not(ancestor::rule[@active='0'])]`. The test "every template label with bufferDraw=1 keeps its halo" counts `./labeling//settings//text-buffer` with no active filter. They agree only because the fixture has no inactive rule. |

### 2. Multi-layer symbols (casing, overlay, unmodelled note)

| Path | Agrees? | Evidence |
|---|---|---|
| single | yes | `symbol_layers_extra` gives casing, overlay or a note |
| categorized | yes | casing through `symbol_layers_extra`; an overlay is named in the note, which meets the note contract |
| graduated | **DISAGREE** | No multi-layer handling. Probe: a wide grey line under a narrow orange one gives the class `color #9c9c9c, width 2`, with no casing and no note. The categorized parser reads the same symbol as `#ffc485 / 1 / casing #9c9c9c 2` (**F1**). No live instance: the template has no graduated renderer. |
| first layer unmodelled (single and categorized) | **DISAGREE** with the contract | Notes name `classes[-1]` / `sym_layers[-1]` only. A lone unmodelled layer gets no note at all. **Live:** `pipeline_permit` (**F2**). |

### 3. Layer opacity folded "into every opacity it emits" (CLAUDE.md, extractor roxygen)

| Path | Agrees? | Evidence |
|---|---|---|
| single fill, single line stroke, single casing | yes | |
| categorized fill, line and casing core | yes | |
| graduated fill and line | yes | |
| single SimpleFill outline `stroke` | **NO** | Probe with `layerOpacity` 0.5: fill opacity 0.5, stroke has no opacity, which the registry reads as opaque (**F3**). No live instance: the only polygon below 1 is `pipeline_permit` (0.993), which has no fill or stroke. |
| `overlay` (`tick_overlay`) | **NO** | Probe with `layerOpacity` 0.5 and tick colour alpha 128: stroke opacity 0.5, overlay none (**F3**). No live instance: the railway is at 1 and opaque. |
| markers | consistent | No path emits marker opacity; the graduated parser says so in a comment. |
| categorized casing's own alpha | dropped | The schema has no `casing_opacity`. Not flagged. |

### 4. Label translators: tmap vs mapgl

| Property | Agrees? | Evidence |
|---|---|---|
| source | agree | Shared `label_source()` |
| size | agree | Both read points: tmap `/12`, mapgl `*96/72` |
| halo width | agree | Both read mm. tmap's grid offset is `halo.width * lineIn * cex` (read from `tmapGridDataPlot.tm_data_text`, tmap 4.4.1), which matches the `/(size*12*1.2*0.3528)` arithmetic. |
| halo with a width but no colour | **disagree** | tmap uses `#ffffff`; mapgl leaves `text_halo_color` unset, and MapLibre's default is transparent. No live instance: 0 of 14 halos lack a colour (measured). Not raised as a finding. |
| placement | disagree by design | mapgl follows the line for line, curved, perimeter and perimeter_curved. tmap does so only for line and curved, as its roxygen says. No live instance: no perimeter placement is shipped. |
| offset | sign agrees | tmap `ymod = -offset_y`. The magnitude differs by 1.2 (lines vs ems), which the code comment calls approximate. |
| opacity | agree | `col_alpha` / `text_opacity` |
| weight and slant | agree | mapgl passes neither by design |

### 5. Docs vs code

| Doc | Agrees? | Evidence |
|---|---|---|
| CLAUDE.md "folded into every opacity it emits" | **no** | See F3 |
| CLAUDE.md and roxygen "named in the layer's `note`" | **no** | See F1 and F2 |
| CLAUDE.md railway and MoTi JSON examples | agree | Same values as the shipped registry |
| CLAUDE.md "`tm_text()` arguments … tmap's own halo" | agree | At HEAD |
| `gq_qgis_style` roxygen "overlay and casing (a warning names each)" | agree | Lines 83-96 |
| `gq_style` roxygen casing and outline vectors | agree | Key names match the extractor (`casing_color`, `casing_width`) and the CSV (`outline_color`) |
| `gq_reg.R` "offsets in ems, as the extractor writes them" | **no** (doc only) | The extractor writes no offsets, and the template's `offsetUnits` are MM. Not raised as a finding. |
| `gq_mapgl_labels` roxygen line modes | agree | Same as `line_modes` |

### 6. Fixtures and derived artifacts vs their sources (all measured this round)

| Artifact | Agrees? | Evidence |
|---|---|---|
| `template_excerpt.qgs` and `bcfishpass_excerpt.qlr` | agree | Regenerated with `data-raw/fixture_extract_template.R` in a worktree: byte-identical (clean `git status`) |
| `reg_qgis_restoration.json` | agree | Fresh `gq_qgs_extract()` of the template repo's template written with `reg_json_write()`: md5 identical |
| `reg_main.json` | agree | `test-reg_build_currency.R` passes |
| `test-vendored_currency.R` with the template repo dirs set | agree | 13 pass |
| `mini_project.qgs` in `inst/examples` vs `tests/testthat/fixtures` | agree | Label blocks identical |
| `reg_custom.csv` conversions vs tests | agree | 9 pt = 12 px; 0.4 mm = 1.51 px; offset 1.2 |

### 7. tmap version contract

| Pair | Agrees? | Evidence |
|---|---|---|
| DESCRIPTION `tmap (>= 4.3)` vs tests `skip_if_not_installed("tmap", "4.3")` | agree | |
| DESCRIPTION vs the guard in `gq_tmap_labels()` | **no** | The guard is `requireNamespace("tmap")` only (**F5**) |

### 8. QML writer vs registry

| Pair | Agrees? |
|---|---|
| overlay warning vs layer `overlay` | agree |
| casing warning vs layer `casing` and class `casing_color` | agree |
| graduated layers | agree: they never carry casing |

### 9. `$` partial match on labels and classes

Agree. The label keys (`field`, `expression`, `size`, `style`, `weight`, `color`, `opacity`, `halo`, `placement`, `offset_x`, `offset_y`, `merge_lines`, `min_feature_size`, `note`) and the class keys contain no pair where one key is a prefix of another.

### Tests run (worktree at HEAD, `NOT_CRAN=true`, tmap 4.4.1)

None failed or errored:

| File | Passes |
|---|---|
| extract | 112 |
| style | 54 |
| tmap_labels | 22 |
| mapgl_labels | 54 |
| qgis_style | 113 |
| reg_build_currency | 5 |
| vendored_currency | 13 |
| reg | 74 |
| gpkg_style_write | 33 |

`tm_text` with the registry halo renders on both points and lines.

## Findings

- **[bug] R/gq_qgs_extract.R:486-535 (`parse_graduated`).** Round 2's fix (37f06db) gave the graduated parser only the enabled-layer filter.
  - The graduated parser has no multi-layer handling. A cased graduated line therefore takes the **casing's** colour and width as the class style. It gets no `casing_color` and no note.
  - This is exactly the defect the categorized parser was fixed for. Probe: the same two-SimpleLine symbol gives `#9c9c9c / 2` under graduated and `#ffc485 / 1` plus a casing under categorized.
  - Any other multi-layer graduated symbol is silently partial, which breaks the contract that the `note` names what is not modelled.
  - No graduated renderer in the template repo's template, so no shipped data is affected. `gq_qgs_extract()` reads any `.qgs` or `.qlr`.
  - Fix: call `symbol_layers_extra()` as the categorized parser does.
  - **Rule:** code-check.md "A fix lands in one of two callers that share a harness"

- **[bug] R/gq_qgs_extract.R:374 and :451.** The unmodelled-layer note names only the layers **after** the first: `classes[-1]` and `sym_layers[-1]`.
  - When the first enabled layer is itself unmodelled (a pattern fill, an SVG or font marker), it is never named. A symbol with a lone such layer gets no note at all.
  - **Live in shipped data.** In `pipeline_permit` (`inst/registry/reg_qgis_restoration.json` and `reg_main.json:718-722`), the template symbol is LinePatternFill + SimpleLine. The registry carries no fill and no stroke, and the note reads "symbol layers not modelled: SimpleLine". The hatch, which is what QGIS mostly draws, goes unnamed.
  - That contradicts CLAUDE.md "What the registry does not model … is named in the layer's `note`".
  - Probe: LinePatternFill alone gives `type` and `source_layer` only, with no note.
  - The fixtures cannot reach this: every multi-layer fixture symbol starts with a modelled class.
  - **Rule:** code-check.md "A proxy is not the property" ; code-check.md "A fixture that cannot reach the failure mode"

- **[fragile] R/gq_qgs_extract.R:369 (`tick_overlay(sym_layers[[2]])`) and :321-324 (single-symbol SimpleFill `stroke`).** Layer opacity is not folded into two of the paths that emit a colour, so both read as opaque.
  - **Overlay:** `symbol_layers_extra()` receives `alpha` but never passes it to `tick_overlay()`. `tick_overlay()` also ignores the tick colour's own alpha and the marker sub-symbol's `alpha`.
  - **Polygon outline:** gets neither `layer_opacity` nor `sym_alpha`. Its line-layer sibling `line_stroke()` gets both.
  - Probe: with `layerOpacity` 0.5, a stroke under ticks gets 0.5 and the overlay nothing. With the same opacity on a polygon, the fill gets 0.5 and the outline nothing.
  - The registry reads a missing opacity as opaque (CLAUDE.md), so both contradict "a layer's own opacity is folded into every opacity it emits" in CLAUDE.md and the extractor roxygen.
  - No shipped layer is affected: the railway and its ticks are opaque at opacity 1, and the only polygon below 1, `pipeline_permit`, has no stroke.
  - **Rule:** code-check.md "A fix lands in one of two callers that share a harness"

- **[fragile] R/gq_qgs_extract.R:163-177 (`color_data_defined`).** It scans `.//layer`, which reaches more than the parsers read:
  - disabled symbol layers;
  - layers inside sub-symbols;
  - the categorized renderer's undrawn `<source-symbol>`.

  The parsers read only enabled top-level layers.
  - A data-defined colour on a disabled layer sets the note "QGIS draws its colour instead of these wherever it evaluates", which is false because that layer is not drawn. Reproduced with an `enabled="0"` layer.
  - This is the round-1 shape (inactive label rules counted) on the one remaining path that does not use the parsers' predicate.
  - Shipped notes are correct: all 3 active expressions in the template sit on enabled, drawn symbols (measured).
  - Fix: restrict to `./symbols/symbol/layer[not(@enabled='0')]` and the single symbol's top-level layers, or share one helper with the parsers.
  - **Rule:** code-check.md "A fix lands in one of two callers that share a harness"

- **[fragile] R/gq_tmap_labels.R:62.** The guard is `requireNamespace("tmap")`, but the function needs `opt_tm_text(halo=)`, which exists from tmap 4.3 (tmap NEWS 4.3).
  - A `Suggests` version is not enforced at install. A user with tmap 4.2 passes the guard and then gets "unused arguments (halo = TRUE, …)" from inside `do.call(tmap::opt_tm_text, opts)`, for every haloed label.
  - DESCRIPTION and the tests both state 4.3, but the function checks presence, not the capability it uses.
  - Fix: `if (utils::packageVersion("tmap") < "4.3") stop(...)`.
  - **Rule:** code-check.md "A proxy is not the property"

/Users/airvine/Projects/repo/gq/planning/active/review-round3.md
