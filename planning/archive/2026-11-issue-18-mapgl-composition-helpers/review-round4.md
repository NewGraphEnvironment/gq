# Code-check round 4: branch 18-add-mapgl-composition-helpers @ 842bdb6

## Checklist read

- **index_code-check.md**: read in full. **index_code-check-r.md, index_code-check-shell.md, index_code-check-spatial.md**: read in full, as the indexes in the repo's CLAUDE.md, which carry the same headings and first sentences.
- **code-check.md**: I read the prose of all 14 H3s under `## Mechanisms` and skipped the table rows: A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice. I did not read the other 24 headings: nothing in 842bdb6 touches them.
- **code-check-r.md** (4 read): A URL handed to a reader goes through R's 60 s connection timeout; `$` on a list partial-matches; Cross-function consistency for label/string normalization; jsonlite writes an empty name as the element's position. Round 3's 17 sections were not re-read, because 842bdb6 adds no new use of them. About 117 not read.
- **code-check-spatial.md**: none read in full. 842bdb6 adds no sf call beyond `st_is_empty`/`st_geometry_type`, which round 3 covered. 94 not read.
- **code-check-shell.md**: none read. The diff has no shell. 71 not read.

All probes ran in detached worktrees, removed afterwards: one of HEAD (842bdb6) and one of e33d5c0 for the "worked before" comparisons. Each used `devtools::load_all()` with mapgl 0.4.4.9000. Probe scripts: `<scratchpad>/r4/p_*.R`. MapLibre behaviour comes from the `maplibre-gl.js` and `maplibregl.js` bundled with mapgl.

**Parity:** all six `test-gq_mapgl_*.R` files pass with `NOT_CRAN=true` (basemap 44, compose 40, controls 9, layer 82, popup 16, style 41; 0 failed, 0 error, 0 skipped). `test-gq_mapgl_compose.R` asserts `expect_identical(ours$x, hand$x)` slot by slot, so the knowledge parity path still holds. Every roxygen example for the `gq_mapgl_*` pages also ran clean.

## Enumeration

Legend: **OK** = handled correctly; **REF** = refused (loud); **SW** = silently wrong; **perm** = permissive but defensible. "probe" = run at HEAD.

### 1. Round 3's table, re-walked at HEAD

| R3 row | R3 verdict | now | evidence (probe at HEAD) |
|---|---|---|---|
| basemap: rows present, every geometry EMPTY | SW (f8) | **REF** | `` `x` has no geometry to fit `` (basemap.R:39) |
| basemap: other rows (sf/sfc/bbox, lon/lat, point, mixed, 0-row, NA CRS, class, basemap, digits) | OK/REF | unchanged | code unchanged apart from line 39 |
| network: streams/water NULL | OK | OK | unchanged |
| network: 0-row sf | perm | perm | `&& nrow()` skip unchanged |
| network: sfc | REF | REF | probe: "invalid 'y' type in 'x && y'" (obscure, but loud) |
| network: water as **lines** | SW (f6) | **REF** | `` `type` is "fill", but the data is drawn as "line" `` |
| network: streams as **points** | SW (f6) | **REF** | `` `type` is "line", but the data is drawn as "circle" `` |
| network: streams with / without `feature_code` | OK | OK | test; the no-code path is now `color =` through `gq_mapgl_layer()` |
| network: missing `order_field` | REF | REF | network.R:53 (and check_reads would refuse it too) |
| network: `lake` with no fill colour | SW (f5) | **REF** | "registry layer `lake` carries no colour to draw" |
| network: `lake` typed line | SW (f5) | **REF** | "registry layer `lake` is a line layer, not a polygon one" |
| network: `streams_all` unclassified | REF | REF | probe: "argument is of length zero" (obscure, but loud) |
| network: no `lake` / `streams_all` | REF | REF | reg_layer |
| network: **water id == streams id** | SW (f1) | **REF** | "the map already has a layer `x`": the second `gq_mapgl_layer()` meets layer.R:92 |
| network: id already on map | REF | REF | the same guard, via `gq_mapgl_layer()` |
| layer: id checks, duplicate layer | OK/REF | OK/REF | unchanged |
| layer: legend id sanitise collision | perm | perm | unchanged |
| layer: x sf, one family / mixed / 0 rows | OK/REF | OK/REF | probe: 0-row gives "`x` has no rows to draw" |
| layer: x **sfc** | REF | **OK** | probe: draws, with an `id` column (mapgl_data) |
| layer: x data.frame | n/a | REF | "`x` must be an sf or sfc" |
| layer: **x NULL + classified key, field absent** | SW (f2) | **REF** | "the data has no `ZONE` column…" (reads `source_frame()`) |
| layer: **x NULL + simple key, other geometry** | SW (f3) | **REF** | "registry layer `lake` is a polygon layer, not a point one" |
| layer: source new/existing/absent | OK/REF | OK/REF | tests |
| layer: key simple, with or without colour; type ≠ geometry | OK/REF | OK/REF | tests |
| layer: key classified, field in x / absent | OK/REF | OK/REF | probe: `field = "nope"` refused |
| layer: **classified key, numeric column vs string keys** | SW latent (f7) | **REF** | "column `stream_order` holds numbers but its classes are strings…" |
| layer: key without reg | REF | REF | probe |
| layer: classes complete / missing parts / length mismatch | OK/REF | OK/REF | tests |
| layer: **classes `field` absent** | SW (f4) | **REF** | "the data for `a` has no column `species`…" |
| layer: classes values typed unlike the column | perm | **REF** | "column `v` holds strings but its classes are numbers…" |
| layer: classes duplicate values | perm | perm | probe: no R error; MapLibre refuses the layer in the console |
| layer: color forms | OK/REF | OK/REF | unchanged |
| layer: `field` with color/classes | perm | perm | ignored |
| layer: **explicit `type` ≠ geometry** | SW (f3) | **REF** | `` `type` is "fill", but the data is drawn as "circle" `` (for key and for color) |
| layer: type an invalid string | REF | REF | probe: `` `type` is "polygon", but the data is drawn as "circle" `` |
| layer: width number / column present | OK | OK | test |
| layer: **width column absent** | SW (f4) | **REF** | "the data for `a` has no column `order`…" |
| layer: width/radius for another type | perm | perm | (a `width` string is now also checked on fill/circle layers, where it is unused) |
| layer: radius / opacity / legend / legend_title / visible / digits / ... | OK | OK | unchanged |
| layer: popup expression | OK | OK | test |
| layer: popup column absent | perm | **REF** | probe: `popup = c("k", "zz")` and a popup expression built from other data are both refused |
| popup: every row | OK/REF/perm | unchanged | file not touched by 842bdb6 |
| controls: **partly named** | SW (f9) | **OK** | probe: `names = c("A", "b")` (the blank name is filled with the id) |
| controls: other rows | OK/REF | unchanged | — |
| classes(property): every row | OK/REF/perm | unchanged | gq_mapgl_style.R not touched |

All nine round-3 SW rows are now REF or OK by probe.

### 2. New paths in 842bdb6

| path | form | verdict | evidence |
|---|---|---|---|
| source_frame | GeoJSON string gq wrote | OK | the parity test draws `rules` and `grade` from one source; probe: a partly-empty source parses, and its null geometry is dropped from `types` |
| source_frame | **URL GeoJSON** (`mapgl::add_source(map, id, "https://…")`, the only non-sf form mapgl stores) | **broken** | `jsonlite::fromJSON(url)` fetches the remote file from R. Probe: "cannot open the connection to 'http://127.0.0.1:9/x.geojson'". At e33d5c0 the same call drew with no fetch (finding 1) |
| source_frame | **vector tile / PMTiles source** (no `data`) | **broken** | probe: "source `v` is not GeoJSON gq can read; give the data as `x`". At e33d5c0, `color` + `type` + `source_layer` drew (finding 1) |
| source_frame | geometry-only sf added by mapgl (bare geometry, not a FeatureCollection) | REF | "source `geo` has no features" |
| source_frame | mapgl source of all-EMPTY geometries | REF | "$ operator is invalid for atomic vectors" (obscure, loud; gq's own path refuses earlier) |
| source_frame | all-null property column | perm | parses as logical NA, so "holds booleans" is refused (the x path reads an all-NA *character* column as string, so the two forms differ only on degenerate data) |
| source_frame | cost | OK | 0.1 s for the 672 kB neexdzii_streams source |
| source_frame | `$` partial matching on `j$features`, `f$properties`, `f$geometry$type`, `src$data` | OK | every key is present in what geojsonsf and mapgl write; no prefix sibling exists |
| layer_type | inferred from x / from source | OK | tests, probes above |
| layer_type | explicit, agreeing | OK | the network passes `type = "fill"`/`"line"` |
| layer_type | **explicit `"line"` over polygons (outline)** | **broken** | probe: `` `type` is "line", but the data is drawn as "fill" ``. At e33d5c0: drew. Round 3 had asked for this case to stay allowed (finding 2) |
| check_reads | sty$color / sty$opacity / width string / popup | OK | probes above |
| check_reads | nested walk: grouped classes (roads_dra) | OK | gq_mapgl_classes flattens groups to scalar labels, so `labels[[1]]` is representative |
| check_reads | **`width`, `radius` or `opacity` given as an expression** | **SW** | never passed to check_reads. Probe: `width = mapgl::interpolate("order", …)` over data with `stream_order`, `radius = list("get", "size")` and `opacity = list("get", "alpha")` all give NO ERROR (finding 3) |
| check_reads | `filter` and paint args through `...` | perm | raw mapgl passthrough, documented as such |
| value_kind | factor, Date, POSIXct | OK | geojsonsf writes all three as JSON strings (probe: `"f":"x","dt":"2020-01-01","ts":"2020-01-01 10:00:00"`), and value_kind reads string on both forms |
| value_kind | numeric / integer | OK | number on both forms |
| value_kind | **logical column with logical class values** | **SW (latent)** | passes as boolean == boolean. Probe: `["match",["get","lg"],true,"#FF0000",false,…]`. MapLibre refuses boolean labels at parse ("Branch labels must be numbers or strings.", maplibre-gl.js), so the layer is dropped in the browser (finding 4) |
| network | water via `gq_mapgl_layer(key = "lake", type = "fill")` | OK | parity identical |
| network | streams via `key = "streams_all"` (feature_code present) | OK, with a behaviour change | the legend is now titled "Streams", with one row per look present ("Stream", "Stream - intermittent", both `#a9e0ff`), where the roxygen promises "a one-row legend … named by … the stream class's label". At e33d5c0 it was one untitled "Stream" row. Doc drift, not a failure (see Notes) |
| network | feature_code present but all unregistered or all NA | REF (was drawn) | "the data has none of registry layer `streams_all`'s classes". At e33d5c0 it drew in the fallback colour. Loud, and arguably right |
| network | streams via `color =` (no feature_code) | OK | parity and vignette |
| knowledge parity path | — | OK | 40/40, `expect_identical(ours$x, hand$x)` |
| style-layer ids (`"water"`, `"building"` in the Carto and OpenFreeMap styles) | gq layer id equal to a basemap style layer id | perm (predates the branch) | mapgl wraps each `addLayer` in try/catch ("Failed to add layer", maplibregl.js:1401), so only that layer is lost, visibly. The ids are unknowable in R for URL styles |

## Findings

- **[severity: bug]** R/gq_mapgl_layer.R:111-116, 238-249 — `source_frame()` makes `x = NULL` work only on a GeoJSON string gq or mapgl serialised from an sf. Every other source a map can hold now either fails or is fetched, and both forms worked at e33d5c0:
  - **Vector tiles and PMTiles** (`mapgl::add_vector_source()`, `add_pmtiles_source()`) have no `data`. Probe: `gq_mapgl_layer(m, "l", source = "v", color = "red", type = "line", source_layer = "streams")` drew at e33d5c0 and now stops with "is not GeoJSON gq can read; give the data as `x`". That remedy cannot be followed for a tile source, and CLAUDE.md lists PMTiles among the sources styles must serve.
  - **A remote GeoJSON URL**, the only non-sf form `mapgl::add_source()` stores (`grepl("^http", data)`), is passed to `jsonlite::fromJSON(src$data)`, which downloads the whole file inside R while the map is being built. Probe: "cannot open the connection to 'http://127.0.0.1:9/x.geojson'". Offline builds now fail, and a large file meets R's 60 s connection timeout with a message naming the reader.

  Fall back to the old behaviour (an explicit `type`, no column checks) for a source gq did not write, or refuse only after `x`/`type` cannot settle it. Never read a URL there.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies" (a guard written against one artifact refusing correct input of another kind, with a remedy the caller cannot run). The URL half is code-check-r.md "A URL handed to a reader goes through R's 60 s connection timeout".

- **[severity: fragile]** R/gq_mapgl_layer.R:230-232 — `layer_type()` requires an explicit `type` to equal the geometry's own type, so `type = "line"` over polygons is now refused (probe: `` `type` is "line", but the data is drawn as "fill" ``). At e33d5c0 it drew the polygon outlines. A MapLibre line layer over a polygon source is a legitimate outline, and round 3's fix note asked for exactly this case to stay allowed. The vignette works around it with `st_cast(…, "MULTILINESTRING")`, so nothing shipped breaks. But a caller drawing an AOI boundary from the polygon it already has, which the cartography convention asks for on every map, now gets an error for a call that used to work. Allow `line` when the data is `fill`.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

- **[severity: fragile]** R/gq_mapgl_layer.R:129-131, 150-161 — `check_reads()` receives `width` only when it is a column-name string. A `width` expression, a `radius` expression and an `opacity` override are written into the paint unchecked, though the roxygen offers "a MapLibre expression" for both `width` and `radius`. Probe at HEAD: `width = mapgl::interpolate("order", values = c(1, 6), stops = c(0.6, 3))` over data whose column is `stream_order`, `radius = list("get", "size")` and `opacity = list("get", "alpha")` all give no error. MapLibre then evaluates a null `get` per feature and falls back to its default width (1), radius (5) and opacity (1). That is round 3's finding 4 (width column absent) reached through the expression form of the same argument: the guard is keyed to the string form, not to "every property the paint reads exists". Pass `width`, `radius` and `opacity` (whatever their form) to `check_reads()`. It ignores non-lists and zoom-only expressions already.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

- **[severity: fragile]** R/gq_mapgl_layer.R:271, 291-293 — the `match` check compares JSON kinds and accepts boolean == boolean. MapLibre rejects a boolean branch label at parse time: maplibre-gl.js has `if("number"!=typeof t&&"string"!=typeof t)return u.error("Branch labels must be numbers or strings.")`. Probe: `classes = list(field = "lg", values = c(TRUE, FALSE), …)` over a logical column gives no R error and writes `["match",["get","lg"],true,…,false,…]`, which the browser refuses, so the layer never draws while its legend shows both classes. Same-kind is a proxy for "MapLibre will match". A logical column (barrier yes/no, accessible) is a plausible thing to classify. Refuse boolean labels, or say to convert the column to text.
  - **Rule:** code-check.md "A proxy is not the property"

Notes, not findings:
- The `gq_mapgl_network(legend =)` roxygen still promises "a one-row legend … named by the registry: `Lake`, and the stream class's label". For a network that carries `feature_code`, the streams legend is now titled "Streams", with one row per look present. That change came from routing through `gq_mapgl_layer()`. Neither the parity test nor the vignette reaches it, because neither carries `feature_code`.
- A network whose `feature_code` holds no registered code (or only NA) is now refused rather than drawn in the fallback colour. That is loud, and probably the right call, but it is new behaviour.
