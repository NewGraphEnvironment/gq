# Code-check round 5: branch 18-add-mapgl-composition-helpers @ b3fd90a

## Checklist read

- **Indexes**: read `index_code-check.md` (38 headings) and the R, shell and spatial indexes (121, 71 and 94 headings). They match the indexes in the repo's `CLAUDE.md`.
- **code-check.md**: re-read the prose of "A guard's scope, escape hatches, and remedies" and "A proxy is not the property". Both findings below fall under these. I relied on round 4's reading of the other 12 Mechanisms H3s, because b3fd90a adds no shape they cover. The other 24 headings were not read.
- **code-check-r.md, code-check-spatial.md, code-check-shell.md**: none re-read in full. b3fd90a touches only `R/gq_mapgl_layer.R` (code) and `R/gq_mapgl_network.R` (roxygen), and adds no new R, sf or shell construct. Not read: 121, 94 and 71.

Probes ran in detached worktrees of b3fd90a (HEAD) and 842bdb6, both removed afterwards. Each used `devtools::load_all()` with mapgl 0.4.4.9000. Probe scripts are `<scratchpad>/r5_p1.R` to `r5_p4.R`, and the test runner is `r5_tests.R`. The MapLibre rule quoted below is from mapgl's bundled `maplibre-gl.js`: `if("number"!=typeof t&&"string"!=typeof t)return u.error("Branch labels must be numbers or strings.")`, followed by an integer check, `Math.floor(t)!==t`. An R `NA` reaches the page as JSON `null`, because `htmlwidgets:::toJSON2` defaults to `na = "null"` (probe: `["match",["get","a"],"a",1,null,2,3]`).

**Tests, at HEAD with `NOT_CRAN=true`**: basemap 44, compose 40, controls 9, layer 91, popup 16, style 41. All six had 0 failed, 0 error and 0 skipped. `test-gq_mapgl_compose.R` is the knowledge parity test (`expect_identical(ours$x, hand$x)`), and it passes.

## Enumeration

Legend: **OK** = handled correctly; **REF** = refused loudly; **SW** = silently wrong; **perm** = permissive but defensible, or the caller's choice. "HEAD" and "842" are probe results at each commit.

### 1. Round 3 and round 4 rows, re-walked at HEAD

These files and functions are byte-identical between 842bdb6 and b3fd90a: `gq_mapgl_basemap.R`, `gq_mapgl_popup.R`, `gq_mapgl_controls.R`, `gq_mapgl_style.R`, and network's body (only its roxygen changed). Their rows carry over unchanged, and the former SW rows among them were re-probed.

| row (origin) | R3 | R4 | HEAD | evidence (HEAD probe) |
|---|---|---|---|---|
| basemap: every geometry EMPTY (R3 f8) | SW | REF | **REF** | "`x` has no geometry to fit" |
| basemap: sf/sfc/bbox, lon/lat, point, mixed, 0-row, NA CRS, class, basemap, digits | OK/REF | same | same | file unchanged |
| network: NULL / 0-row / sfc / missing order_field / no lake / unclassified streams_all | OK/perm/REF | same | same | body unchanged |
| network: water as lines (R3 f6) | SW | REF | **REF** | "`type` is "fill", but the data is drawn as "line"" |
| network: streams as points (R3 f6) | SW | REF | **REF** | "`type` is "line", but the data is drawn as "circle"" |
| network: **streams as polygons** | (SW class, f6) | REF | **SW** | see §2 and finding 1. Draws the polygons' outlines in stream style, with no error |
| network: lake with no fill colour (R3 f5) | SW | REF | **REF** | "registry layer `lake` carries no colour to draw" |
| network: lake typed line (R3 f5) | SW | REF | **REF** | "registry layer `lake` is a line layer, not a polygon one" |
| network: water id == streams id (R3 f1) | SW | REF | **REF** | "the map already has a layer `x`" |
| network: streams with feature_code / via color | OK | OK | OK | parity test 40/40 |
| layer: id checks, duplicate layer, legend-id sanitise collision | OK/REF/perm | same | same | unchanged lines 89-99, 193 |
| layer: x sf one family / mixed / 0 rows / sfc / data.frame | OK/REF | OK/REF | same | lines 106-115 unchanged |
| layer: x NULL + classified key, field absent (R3 f2) | SW | REF | **REF** | "the data has no `ZONE` column…" |
| layer: x NULL + simple key of another geometry (R3 f3) | SW | REF | **REF** | "registry layer `lake` is a polygon layer, not a point one" |
| layer: source new / existing / absent | OK/REF | same | same | lines 108-118 |
| layer: key simple with/without colour; classified, field present/absent | OK/REF | same | same | tests |
| layer: numeric column vs string keys (R3 f7) | SW latent | REF | **REF** | "column `stream_order` holds numbers but its classes are strings…" |
| layer: classes complete / missing parts / length mismatch | OK/REF | same | same | tests |
| layer: classes field absent (R3 f4) | SW | REF | **REF** | "the data for `c` has no column `species`…" |
| layer: classes values typed unlike the column | perm | REF | **REF** | "column `edge` holds strings but its classes are numbers…" |
| layer: classes duplicate values | perm | perm | perm | the same MapLibre parse refusal as below, but a caller error, as R3 called it |
| layer: **classes values containing NA** | — | — | **SW** | finding 2. `c("a", NA)` writes a `null` branch label, with no R error |
| layer: **classes non-integer numeric values** | — | — | **SW** | finding 2. `c(1.5, 2)` over a numeric column, no R error |
| layer: explicit type ≠ geometry (R3 f3), color and key | SW | REF | **REF** | "`type` is "fill", but the data is drawn as "circle"" |
| layer: type an invalid string, readable source | REF | REF | REF | layer_type refuses |
| layer: width column absent (R3 f4) | SW | REF | **REF** | "…has no column `order`…" |
| layer: width / radius / opacity expression reading an absent column (R4 f3) | — | SW | **REF** | three probes: "…no column `order`", "`size`", "`alpha`" (at 842: NO ERROR for all three) |
| layer: zoom-only width/radius interpolate | — | OK | OK | NO ERROR (`zoom` is not a `get`) |
| layer: boolean classes over a logical column, inline data (R4 f4) | — | SW latent | **REF** | "column `lg` is classed on TRUE and FALSE…" (at 842: NO ERROR) |
| layer: popup column absent / expression | perm→REF / OK | same | same | check_reads |
| layer: URL GeoJSON source, x NULL (R4 f1) | — | broken | **OK** | `type = "line"`: NO ERROR, no fetch (at 842: "cannot open the connection") |
| layer: vector-tile / PMTiles source, x NULL (R4 f1) | — | broken | **OK** | `type = "line", source_layer =`: NO ERROR (at 842: "is not GeoJSON gq can read") |
| layer: type = "line" over polygons, `color` (R4 f2) | — | broken | **OK** | layer type `line`, NO ERROR |
| source_frame: geometry-only mapgl source / all-EMPTY / all-null column | — | REF/REF/perm | same | function unchanged past line 264 |
| controls: partly named (R3 f9) | SW | OK | **OK** | `layers_config` labels `A`, `b` |
| popup, controls, classes(property): every other row | OK/REF/perm | same | same | files unchanged |
| knowledge parity | OK | OK | **OK** | 40/40 |

### 2. Paths b3fd90a introduced

**Unreadable source** (`source_frame()` returns NULL). Probed on all three forms: `add_vector_source` (type `vector`), `add_pmtiles_source` (type `vector`) and `add_source(url)` (type `geojson`, data `http…`). The results were identical across all three.

| form | verdict | evidence |
|---|---|---|
| `color`, no `type` | REF | "give `type`: source `v` is not GeoJSON on the map…" |
| `color`, `type = "line"` | OK | drawn, nothing fetched |
| `classes`, no `type` | REF | same message |
| `classes`, `type = "circle"` | OK | drawn |
| `key = "lake"`, no `type` | OK | type `fill` from the registry |
| `key = "lake"`, `type = "fill"` | OK | — |
| `key = "lake"`, `type = "line"` | REF | "registry layer `lake` is a polygon layer, not a line one" |
| `key = "bec_zone"` (classified), no `type` | OK (documented) | type `fill`, and the legend lists 11 rows, which are the 11 keys |
| classified key with `field = "zone"` | perm | unchecked by design: there is no data to check |
| **classes TRUE/FALSE, `type = "circle"`** | **SW** | NO ERROR. The label check is data-independent, but it runs only inside `check_reads()`, which is skipped here (finding 2) |
| width expression on an absent column | perm | unchecked by design |
| `type = "polygon"` / `c("line", "fill")` | REF | obscure but loud: "'what' must be a function or character string" and "no such index at level 1". With a key: "…is a polygon layer, not a  one" |
| key `habitat_lateral` (raster), no `type` | REF | "give `type`…" |
| raster source with `type = "fill"` | perm | NO ERROR. `src$type == "raster"` is known in R, but drawing a fill layer over a raster source is the caller's choice. MapLibre refuses it in the console |
| inline GeoJSON that is not a FeatureCollection | n/a | `mapgl::add_source()` accepts only sf or a URL ("Data must be an sf object or a URL…"), so the `startsWith("{")` test sees only what geojsonsf writes |
| `add_source` with list data | n/a | the same mapgl refusal |

**Line over fill** (`layer_type()` line 251):

| form | HEAD | 842 | verdict |
|---|---|---|---|
| `color`, `type = "line"`, polygons | NO ERROR (line layer) | REF | OK, as intended |
| `classes`, `type = "line"`, polygons | NO ERROR | REF | OK |
| `key = "lake"` / `"bec_zone"` (polygon), `type = "line"` | REF "…is a polygon layer, not a line one" | REF | perm (loud; a registry outline of a polygon layer is not offered) |
| **`key = "streams_all"` (a line layer), `type = "line"`, polygons** | **NO ERROR** | REF | **SW**: the same call without `type` is refused ("is a line layer, not a polygon one") (finding 1) |
| **x NULL, polygon source, `key = "streams_all"`, `type = "line"`** | **NO ERROR** | REF | **SW** (finding 1) |
| **`gq_mapgl_network(streams = <polygons>)`**, with or without feature_code | **NO ERROR**, line layer | REF | **SW**: the network's geometry check is its explicit `type = "line"` (finding 1) |

**check_reads inputs:**

| form | verdict | evidence |
|---|---|---|
| user `opacity` NULL | OK | `walk()` returns on a non-list |
| user `opacity` number | OK | the same |
| user `opacity` list, column present / absent | OK / REF | probe |
| user `opacity` with a classified registry key | OK | `sty$opacity` is still walked; it reads the same column as `sty$color` |
| `radius` / `width` given for a type that ignores them | perm | checked though unused (as R4 noted for a width string) |

**Boolean labels:**

| form | verdict | evidence |
|---|---|---|
| `classes` TRUE/FALSE, inline data | REF | probe |
| registry keys `TRUE`/`FALSE` over a logical column | REF | "holds booleans but its classes are strings". Registry keys are names, so they are always strings (`gq_mapgl_classes()` line 188) |
| registry keys `TRUE`/`FALSE` over a text column (`field =`) | OK | string == string |
| `classes` TRUE/FALSE over an unreadable source | **SW** | finding 2 |

## Findings

- **[severity: fragile]** R/gq_mapgl_layer.R:251, 350-354; R/gq_mapgl_network.R:60, 66. The line-over-fill exception was added for outlines, and it also bypasses the two geometry guards that are keyed to `type`:
  - `layer_paint()` checks a registry key against the **requested** `type`, not the drawn geometry. So `gq_mapgl_layer(m, "o", polygons, key = "streams_all", reg = reg, type = "line")` draws a stream style over polygon outlines with no error, while the same call without `type` is refused: "registry layer `streams_all` is a line layer, not a polygon one". That is round 3's finding 3 (registry type vs data), reopened by naming `type`. It also runs backwards: the registry outline that would make sense, a polygon key with `type = "line"`, is refused, and a line key over polygons is accepted.
  - `gq_mapgl_network()` gets its only geometry check by passing `type = "line"` for streams (the R3 f6 fix). So `gq_mapgl_network(base, streams = <polygons>)` now draws every polygon's outline in stream blue, scaled by order, with no error, with or without `feature_code`. At 842bdb6 both calls were refused: "`type` is "line", but the data is drawn as "fill"".

  The exception should apply only where no registry type is asserted. Allow line over fill for `color`/`classes`, and keep `want` compared against the data's own type when `key` is given. For the network, check that the streams data draws as lines before passing `type`.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies" ("when you add a guarantee, grep the bypasses … The hatch may also be in your own diff")

- **[severity: fragile]** R/gq_mapgl_layer.R:145-150, 291-295. The new branch-label guard tests a proxy, and it is placed where some forms skip it. MapLibre refuses at parse any `match` label that is not a string or an integral number, so the whole layer is dropped while its legend still lists every class.
  - It tests only `is.logical(labels[[1]])`. An `NA` among `classes$values` reaches the page as a `null` label. Probe: `values = c("a", NA)` writes `["match",["get","sp"],"a","#FF0000",null,"#0000FF","#cccccc"]` with no R error, and `c(NA, "a")` and `c(1, NA)` behave the same. A non-integer numeric label also fails MapLibre's `Math.floor(t)!==t` check. Probe: `values = c(1.5, 2)` over a numeric column gave no R error.
  - It sits inside `check_reads()`, which is skipped for a source gq cannot read. But whether a label is valid does not depend on the data, so `classes = list(values = c(TRUE, FALSE), …)` over a vector-tile, PMTiles or URL source passes with no error (probe: NO ERROR on all three). That path is new in b3fd90a: at 842bdb6 these sources were refused outright.

  Validate every label in `layer_paint()`, whatever the source: each must be a non-NA string, or a finite whole number.
  - **Rule:** code-check.md "A proxy is not the property"

Notes, not findings:
- An invalid `type` over an unreadable source is refused, but with mapgl's or R's message ("'what' must be a function or character string", or "…is a polygon layer, not a  one"), not gq's. It is loud, so it is not a finding.
- A fill, line or circle layer over a **raster** source (`src$type == "raster"`) passes. MapLibre refuses it in the console. It is the caller's own source, but R knows its type and could refuse.
