# Review round 4 — the causal paragraph in `data-raw/styles_vendor.R`

Scope: the comment block above `extra <- setdiff(...)` (lines ~199–228) at `35d97cd`,
branch `90-re-vendor-inst-styles-rfp-has-repaired`. Third attempt at one causal claim.

**Verdict: closer than attempts 1 and 2, every citation verbatim — but the headline
claim is still wrong.** "The cause is authorship" is falsified by `habitat_lateral`,
named three lines above in the same comment. The real cause is the **export boundary
list**, which rfp states in one sentence the comment did not cite.

---

## 1. Citations — all four check out

| cited as | actual location | verdict |
|---|---|---|
| `R/rfp_qgs_style_export.R` — "those were exported by rfp, so they report this scan back rather than QGIS's opinion" | `R/rfp_qgs_style_export.R:31-33` | **verbatim** |
| `test-rfp_qgs_style_set.R:460` — "rfp's own output under the old `order =` override, not a pre-#130 leak" | `tests/testthat/test-rfp_qgs_style_set.R:460-461` | **verbatim**, line number right |
| `inst/testdata/nodes/README.md` — QGIS "begins at flags, exactly as a vector's does" | `README.md:88` | **verbatim** |
| `C100` at `11ec65fc` | real, but only under `--follow -M -C --find-copies-harder`; plain `git show --name-status` reports `A` | **accurate, wrong instrument** — see §4 |

Minor: the first quote is a **body comment inside** `.rfp_qgs_style_src_tags()`, not its
roxygen. The comment cites the file, not the block, so nothing is misstated.

The "66 store QMLs, two style-manager" measurement is **correct** — verified against
rfp's `inst/extdata/styles` (66 files: 64 `flags`, 2 `map-layer-style-manager`). Note
gq's own `inst/styles` is 60, all `flags`; "the store" means rfp's `src` here, which is
this file's usage elsewhere, and `66` disambiguates it. Defensible, worth one word.

---

## 2. BLOCKER — the partition is not clean

The four shipped rasters, measured (first child, version, how produced):

| file | version | first child | how produced |
|---|---|---|---|
| `airphoto_gray.qml` | 4.2.1 | `flags` | QGIS `saveNamedStyle()` sidecar; **later patched 7 lines by rfp** (`4938318c`) |
| `habitat_lateral.qml` | 3.30.1 | `flags` | **rfp lifted it out of both templates** (`54389cc0`) |
| `dem_hillshade.qml` | 4.0.0 | `map-layer-style-manager` | rfp export, old `order =` override |
| `dem_turbo.qml` | 4.0.0 | `map-layer-style-manager` | rfp export, old `order =` override |

There **is** now variation in the independent variable — so the round-3 objection to
repair 1 does not apply, and the comment is right that `dem_hillshade` is the control
repair 1 lacked. But the partition it produces is **not** authorship.

`54389cc0`'s own message:

> The third style costs nothing: **habitat_lateral was already shipped, styled and
> paletted, inside both templates. Lifting it out** doubles as evidence for the Phase 1
> spike — with noData treated as source, **its boundary lands on `flags`**, exactly the
> child list a QGIS-authored raster .qml carries.

So an **rfp-produced file opens at `flags`**. QGIS-authored ⟹ `flags` holds; `flags` ⟹
QGIS-authored does **not**. The comment's sentence

> airphoto_gray opens with `<flags>` because it IS a QGIS-authored sidecar

asserts exactly that converse as an explanation — and `habitat_lateral`, the raster gq
actually vendors and which this same comment names three lines earlier, is the
counterexample sitting in the same directory.

This is the third distinct wrong shape in one paragraph: polarity backwards → variable
thrown out → **a sufficient condition stated as the cause**.

---

## 3. The `order =` mechanism is real, and rfp states it in one sentence

Not a stacked inference. `R/rfp_qgs_style_set.R:522-529`, current:

> `map-layer-style-manager` is a SOURCE tag and never a style child — measured, zero
> occurrences after the boundary across both templates and every oracle node — but
> **rfp's own shipped raster styles carry it FIRST, because they were exported under the
> old `order =` override** that `.rfp_qgs_style_src_tags()`'s comment describes.

That is the whole claim in one place, and the comment cites three weaker sources instead.

Confirmed empirically — both files' children are

```
map-layer-style-manager, flags, temporal, elevation, customproperties,
mapTip, pipe-data-defined-properties, pipe, blendMode, legend
```

i.e. the `<maplayer>` tail beginning at `map-layer-style-manager`, which is the
second-to-last entry in `.rfp_qgs_style_src_tags()` — exactly what a positional scan
stopping there emits. The cause is **where the boundary stopped**, not who ran it.

---

## 4. The `C077` worry — resolved, but it exposes the method

`fff6f7c7 C077 dem_hillshade.qml -> raster_gdal.qml` does **not** undermine
`raster_gdal.qml`'s QGIS authorship. That commit's own message states the generator:

> Each reference node now ships beside the .qml **QGIS itself wrote for the same layer,
> via QgsMapLayer.saveNamedStyle()**

and goes on to name the circularity the comment is trying to avoid:

> the shipped dem_turbo.qml carries map-layer-style-manager as its first child, which
> looks like QGIS saying rasters differ - **but rfp exported that file, so it reports
> this scan back.**

Two `singlebandgray`-family raster QMLs sharing 77% boilerplate is expected.

**But the suspicion in the brief is right about the method.** `git -C` is a similarity
heuristic, not a provenance record. The comment reads `C100` **as provenance** in one
direction while the identical heuristic pointing the other way (`C077`) would, read the
same way, make the QGIS reference node a copy of an rfp export. The conclusion survives
only because rfp says it independently — `11ec65fc`'s message:

> airphoto_gray, **the raster_gdal.qml reference byte for byte**, carrying from_data_p2_98.

That is the citation to use. `C100` should go. And note the comment's own closing rule —
*"a CAUSAL claim about rfp is settled by reading rfp's own account of itself, never by
re-measuring rfp's output"* — is **violated by the one sentence that cites git**, which
is a measurement of rfp's output where a commit message was available.

Also: `airphoto_gray` was byte-for-byte `raster_gdal.qml` at `11ec65fc` and has since
been patched (`4938318c`: `WholeRaster`→`UpdatedCanvas`, `1/9`→`0/255`, serialization).
Present-tense "it IS a QGIS-authored sidecar" is loose; origin is right, first child
unaffected.

## 5. The implied universal holds

All nine `.qml` in `rfp/inst/testdata/nodes/` open at `flags` (measured), and rfp asserts
it in three places. Both `flags` rasters are consistent with it. No problem here —
it is just not *sufficient* to identify an author.

## 6. Self-description — accurate

Checked against `8d95de8` and `2216e80`:

- "the original had the polarity BACKWARDS, calling the style-manager pair the
  QGIS-authored ones" — original read *"dem_hillshade and dem_turbo alone are
  QGIS-authored sidecars ... which is why they alone open with
  `<map-layer-style-manager>`"*. **Accurate.**
- "the first repair over-corrected to 'authorship does not discriminate', citing nine
  reference nodes that are all QGIS-authored AND all `<flags>`" — repair 1 read *"all
  nine ... are what QGIS itself writes, and all nine ... open with `<flags>`. So
  authorship does not discriminate."* **Accurate**, and the criticism of it is valid.

---

## Smallest correct wording

State the cause — withholding is not the fix, and rfp states it outright. Replace the
two paragraphs from "The cause is authorship" through "(`C100` at 11ec65fc)" with:

```r
  # The cause is the export BOUNDARY, not who ran the export, and rfp states it
  # in one sentence:
  #   R/rfp_qgs_style_set.R:522  "`map-layer-style-manager` is a SOURCE tag and
  #                               never a style child ... but rfp's own shipped
  #                               raster styles carry it FIRST, because they
  #                               were exported under the old `order =` override"
  # Their child lists confirm it: both run `map-layer-style-manager, flags,
  # temporal, ...`, the <maplayer> tail from the point a positional scan
  # stopped. QGIS's own output always begins at `flags` (all nine sidecars in
  # rfp/inst/testdata/nodes/).
  #
  # Authorship is sufficient but NOT the discriminator, and that is the trap:
  # habitat_lateral — the raster gq DOES vendor — was lifted out of the
  # templates by rfp (rfp 54389cc0, "its boundary lands on flags") and opens
  # with <flags>. QGIS-authored implies <flags>; <flags> implies nothing.
```

Then keep the existing "two earlier passes" paragraph, amending the second bullet's
lesson so it reads *"the control that settles it is dem_hillshade, and the control that
stops the next over-correction is habitat_lateral"*.

**Why this is not the withholding that already failed.** Repair 1 failed for two reasons,
and only one was "declined to state a cause": it also *asserted* a negative claim
("authorship does not discriminate") on a sample that could not support it. Stating the
boundary-list cause from rfp's own account is the opposite of withholding — it is the
rule the comment's own closing sentence prescribes, applied to the sentence that
currently breaks it.

## What would have to be true for the current wording to be right

`habitat_lateral.qml` would have to be QGIS-authored rather than rfp-lifted. It is not:
`54389cc0` says rfp lifted it out of the templates, and cites its `flags` boundary as
*evidence for rfp's own spike* — i.e. rfp is explicitly claiming its lift reproduces
QGIS's child list, which is the same thing as saying the output does not identify the
author.
