# Review round 2b: branch 103-extractor-fidelity-and-labels (a5bbc30...452e379)

## Checklist read

- **code-check.md**: every H3 under `## Mechanisms`, prose only (A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice). Index only for the rest: 28 headings not read in full.
- **code-check-r.md**: `$` on a list partial-matches, so a longer sibling key answers for a missing one; A replacement function on an `xml_missing` node is a silent no-op; `nzchar(NA)` is TRUE — non-empty checks silently pass NA; A `data-raw/` script must load the source tree, not the installed package (from the index; the new data-raw script uses only xml2). Index only for the rest: about 118 headings not read in full.
- **code-check-spatial.md**: QGIS embeds a layer's style in the `.qgs`, so rewriting the `.qml` sidecar changes nothing (not applicable: the QML writer does not touch a project). Index only for the rest: about 113 not read.
- **code-check-shell.md**: none read in full. The diff has no shell. About 95 headings index only.

## Findings

- **[severity: bug]** R/gq_tmap_labels.R:99, 107, 108 — `args$size %||% 1`, `args$xmod %||% 0` and `args$ymod %||% 0` use `$` on a list that also holds the caller's `...` overrides. tm_text's own siblings `xmod.scale`, `xmod.legend`, `xmod.chart`, `ymod.*` and `size.*` are what `...` is documented to pass. When the registry label has no offset, which is true of every QGIS-sourced label, `args$xmod` partial-matches the override. gq's `%||%` then calls `is.na()` on a list and the call fails. Reproduced on tmap 4.4.1 (CRAN): `gq_tmap_labels(reg, "lake", xmod.scale = tmap::tm_scale_asis())` errors with "'length = 4' in coercion to 'logical(1)'", and `ymod.legend = tm_legend_hide()` errors with "'length = 8' …". `xmod.free = NA` instead resolves silently to 0. The fix is `args[["size"]]`, `args[["xmod"]]` and `args[["ymod"]]`; line 88 already indexes exactly.
  - **Rule:** code-check-r.md "`$` on a list partial-matches, so a longer sibling key answers for a missing one"

- **[severity: fragile]** R/gq_tmap_labels.R:7-10 and the CLAUDE.md "Style resolvers" paragraph both say "tmap has no halo, and its `shadow` and `bgcol` draw an offset copy and a box". That is true of this machine's tmap 4.2.0.9000 only. tmap's NEWS for 4.3 reads "tm_text: halo, shadow and background rectangles implemented in plot and view mode". On 4.4.1, the version CI installs, `opt_tm_text()` has `halo`, `halo.col`, `halo.width` (in lines times cex) and `halo.alpha`, and it draws the same 4 + 4 diagonal offset copies itself. The accepted design, eight copies returned as layers rather than `do.call()` arguments, rests on that sentence. It still works: under 4.4.1, test-gq_tmap_labels.R passes 22/22 and the lake, stream, road and town labels print without error. The premise was measured against the stale install, which the repo's CLAUDE.md warns against for mapgl. This is the owner's call to revisit, and nothing is broken.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

- **[severity: fragile]** R/gq_qgs_extract.R:403, 436, 499 — the branch's single-symbol fixes did not reach the categorized and graduated parsers. Single-symbol now reads only enabled top-level layers (`./layer[not(@enabled='0')]`) and names every unmodelled layer in `note`. Three gaps remain in the sibling parsers:
  - Categorized (403) and graduated (499) still take `xml_find_first(sym, ".//layer")`, which can be a disabled layer.
  - The categorized casing check (436) counts disabled layers.
  - A class symbol with extra layers that are not a casing gets no `note`, although the roxygen (lines 8-11) and CLAUDE.md say that what the registry cannot express is named in the layer's note.

  Also, when a categorized class is read as cased, `opacity` and `dash` are still computed from the first (casing) layer at lines 416-424. Only colour and width are replaced from the core, so a core with its own alpha or dash loses it. None of this fires on the shipped template: no category symbol has a disabled layer, and roads_dra's four cased symbols have equal alpha and no dash. It is latent.
  - **Rule:** code-check.md "A fix lands in one of two callers that share a harness"

- **[severity: fragile]** R/gq_qgis_style.R:83-96 — commit 452e379 gives the QML writer warnings keyed to two specific fields, `overlay` and `casing`. Its rationale was that MoTi's casing "would vanish from its QML without a word". The same holds one axis over, for every layer whose registry `note` names symbol layers the registry drops: wetland (PointPatternFill), municipalities (two stacked SimpleFills) and fire_historical_burn. Each still writes a single-layer QML with no warning. The roxygen's first paragraph does say multi-layer symbols are not written, so this may be accepted. If not, keying the warning to the outcome (warn on any layer `note`) covers every case, where a per-field rule needs a new arm for each future one.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

## Checked and clean

- **Round-1 fixes.** The offset sign now agrees between tmap (positive `ymod` is up) and MapLibre (positive y is down). `perimeter_curved` is drawn as a line label. Non-numeric `size`/`xmod`/`ymod` is detected by exact indexing. The inactive-rule XPath covers nested rules. In the template, the one `active="0"` rule (crossings_pscis_modelled_dams) is now skipped, and the shipped note reads "2 rules".
- **Committed registry.** `reg_qgis_restoration.json` equals a fresh extract of the template repo's template, apart from writer rounding of roads_dra widths. reg_main carries the CSV label units (town 9 pt, halo 0.4 mm).
- **QML writer.** `gq_qgis_style()` over every reg_main line and polygon layer: MoTi writes its orange core and warns about casing, roads_dra warns about casing, railway warns about overlay, and pipeline_permit errors as the test expects. roads_ften's 0.7 opacity is written as symbol alpha. `gq_gpkg_style_write()` takes QML strings and does not touch the registry.
- **Template units.** All 25 template labels are `fontSizeUnit="Point"` and `bufferSizeUnits="MM"`, matching the registry's unit contract. The active data-defined colours are on enabled category-symbol layers, not on `source-symbol`.
- **Fixture provenance.** The fixtures carry no hosts or credentials: only `./background_layers.gpkg` paths and the public bcfishpass `service=`.
