# Where QGIS writes symbology in a project, and what tmap and MapLibre make of it

**Verified:** 2026-11-16 against the template repo's `bcrestoration_mobile.qgs` (saved by QGIS 4.2.1), `bcfishpass_30k.qlr`, a QGIS 4.1.0-Master container, CRAN tmap 4.4-1 and mapgl 0.5.2 · **Issues:** gq#103 (gq#6, #7, #23, #24, #38); spawned gq#116, #117, #120 · **Produced by:** XPath probes over the template; `gq_qgs_extract()` and its tests (`tests/testthat/test-gq_qgs_extract.R`, fixtures cut by `data-raw/fixture_extract_template.R`); a PyQGIS expression probe; a rendered-glyph measurement of tmap text. The story is in `planning/archive/2026-11-issue-103-extractor-fidelity-and-labels/`.

## Labels

- **The label source is an attribute of `<text-style>`**, `fieldName="…"`, flagged by
  `isExpression="0|1"`, not an `<Option name="fieldName">`. A hand-written fixture in the
  second shape passed its test while every real extract carried no field (gq#6).
- **`isExpression="1"` can still hold a plain column** (a bare or double-quoted name).
  In the template, 8 of 22 extracted labels are real expressions (`concat(…)`, `CASE …`,
  `title(…)`).
- **Weight is `fontWeight`, on Qt's scale:** Qt5 0-99 (50 normal, 63 demibold, 75 bold,
  87 black), Qt6 1-1000 (400, 600, 700, 900). QGIS 4.2 still writes the Qt5 numbers.
  `fontBold` appears 0 times in the template.
- **`<text-buffer>` (the halo) nests inside `<text-style>`**, not beside it.
- **Units are per size:** `fontSizeUnit` (the template: all `Point`) and `bufferSizeUnits`
  (all `MM`). Pixel, map-unit and percentage sizes have no print size.
- **Rule-based labelling** keeps one `<settings>` per `<rule>`, and a rule can be
  `active="0"`, which QGIS does not draw.
- `labelsEnabled="1"` with no `<labeling>` settings occurs (4 layers in the template);
  it draws nothing.
- Placement is `<placement placement="N">`: 0 around point, 1 over point, 2 line
  (perimeter on a polygon), 3 curved, 4 horizontal, 5 free, 6 ordered positions,
  7 perimeter curved, 8 outside polygons. `mergeLines` and `minFeatureSize` (mm) sit on
  `<rendering>`.

## Symbols

- **A symbol's top-level layers are `./layer`; `.//layer` also reaches sub-symbols**
  (a MarkerLine's marker, a pattern fill's line), which counted the railway's two layers
  as three. A layer can be `enabled="0"`.
- **Symbol `alpha` applies to the whole symbol**, outline included, and
  `<layerOpacity>` to the whole layer. The template's `roads_ften` is 0.7.
- **The railway is a black line under a MarkerLine** of `line` markers, rotated to the
  line every 3 mm: ticks, not a white dashed overlay. A line as wide as a tick is long
  (2.4 mm), dashed tick-thick on (0.2 mm) and the rest off (2.8 mm), draws the same
  thing.
- **Casing is two SimpleLines, the lower wider.** Pass order (`pass="0|1"`) matters only
  where the renderer uses symbol levels (`roads_dra`); `moti_major_structures` is pass
  0/0.
- **A categorized renderer's `<source-symbol>` is a template, not drawn.**
- **An active data-defined colour that fails to parse is ignored.** The template's
  streams carry `CASE WHEN "model_access_st" IN () …` with every list empty: QGIS reports
  `hasParserError()` and draws the category colours.
- **A `.qlr` keeps its layers as `<maplayer>` too**, with `<layername>`, so one reader
  serves both. A PostgreSQL source names its table as `table="schema"."name"`, not
  `|layername=`.

## What the renderers do with it

- **tmap 4.4:** `tm_text(size = 1)` is 12 pt (a capital H is 36 px at 300 dpi either
  way). `opt_tm_text(halo = TRUE)`, added in tmap 4.3, draws eight offset copies, with
  `halo.width` in lines of text at the text's size (a line is 1.2 × the text height).
  `ymod` is positive up. tmap below 4.3 has no halo, and grid's `lty` dashes cannot be
  thinner than the line, so the railway ticks cannot be drawn in tmap.
- **MapLibre (mapgl 0.5):** `text-size` and `text-halo-width` are pixels (pt × 96/72,
  mm × 96/25.4); `text-offset` is in ems, positive y down; `line-dasharray` is in
  multiples of the line width. The fill layer's `fill-opacity` also applies to its
  outline, so a fully transparent fill hides its outline (gq#120).
