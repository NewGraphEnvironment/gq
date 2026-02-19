# gq — Cartographic Style Management

## Company Vision

**New Graph Environment** - With integrity, using sound science and open communication, we build productive relationships between First Nations, regulators, non-profits, proponents, scientists, and stewardship groups. Our value-added deliverables include open-source, collaborative GIS environments and interactive online reporting.

## Project Overview

**gq** is a style management system for cartography across multiple rendering targets. It extracts symbology from QGIS projects, stores it in a canonical format, and translates it to tmap, leaflet, MapLibre GL, and ggplot2.

The name is a reference — it's all about style.

## Repository Relationships

| Repo | Relationship |
|------|--------------|
| `soul` | Parent ecosystem — conventions, skills (including `cartography` skill) |
| `soul/skills/cartography` | Codified map-making patterns for tmap + fwapg (consumer of gq styles) |
| `sred-2025-2026` | R&D tracking — Experiment 6.11 |
| `awshak` | Infrastructure (future: style hosting, OGC API Styles endpoint) |
| `nrp-nutrient-loading-2025` | First consumer project (tmap watershed maps) |
| All fish passage / restoration repos | Consumer projects (leaflet maps, QGIS projects) |

## SRED Tracking

Relates to NewGraphEnvironment/sred-2025-2026#13

## Architecture

### The Problem

NGE produces maps across multiple tools:
- **QGIS** — interactive GIS, field data, Mergin Maps sync
- **tmap** — static maps in bookdown reports (R)
- **leaflet** — interactive maps in bookdown reports (R)
- **Web mapping** — PMTiles + MapLibre GL for cloud-native web maps
- **ggplot2** — statistical plots with spatial context (R)

Symbology (colors, line weights, labels, classification breaks) is currently duplicated manually across each tool. Change a color in QGIS → manually update R code → manually update web styles. This doesn't scale.

### The Solution

A canonical style registry that serves as the single source of truth:

```
QGIS Project (.qgs/.qgz)
  ↓ PyQGIS extract
QML files (.qml)
  ↓ parse to canonical
registry.json (canonical styles)
  ↓ translate per target
┌──────────┬──────────┬──────────────┬──────────┐
│  tmap    │ leaflet  │ MapLibre GL  │ ggplot2  │
│  (R)     │  (R)     │  (JSON)      │  (R)     │
└──────────┴──────────┴──────────────┴──────────┘
```

### Canonical Style Format

Each layer style in the registry maps a **layer name** to rendering properties:

```json
{
  "layers": {
    "watershed": {
      "type": "polygon",
      "fill": {
        "color": "#a8c8e0",
        "opacity": 0.4
      },
      "stroke": {
        "color": "#2c3e50",
        "width": 1.8
      },
      "label": {
        "field": "name",
        "size": 14,
        "font": "sans-serif",
        "weight": "bold",
        "color": "#1a3c5e"
      },
      "classification": null
    },
    "parks": {
      "type": "polygon",
      "fill": {
        "color": "#a3c4a3",
        "opacity": 0.35
      },
      "stroke": {
        "color": "#5a7a5a",
        "width": 0.5
      }
    },
    "streams": {
      "type": "line",
      "stroke": {
        "color": "#7ba7cc",
        "width": 0.4
      },
      "filter": {
        "field": "stream_order",
        "operator": ">=",
        "value": 5
      },
      "label": {
        "field": "gnis_name",
        "filter": {"field": "stream_order", "operator": ">=", "value": 7},
        "size": 8,
        "font": "sans-serif",
        "style": "italic",
        "color": "#1a5276"
      }
    },
    "roads": {
      "type": "line",
      "classification": {
        "field": "road_type",
        "classes": {
          "RH1": {"color": "#c0392b", "width": 2.0, "label": "Highway"},
          "RA1": {"color": "#e67e22", "width": 1.8, "label": "Arterial"},
          "RA2": {"color": "#f1c40f", "width": 1.4, "label": "Secondary"}
        }
      }
    },
    "railway": {
      "type": "line",
      "stroke": {
        "color": "#000000",
        "width": 1.2
      },
      "overlay": {
        "color": "#ffffff",
        "width": 0.6,
        "dash": "4 2"
      }
    }
  }
}
```

### Components

#### 1. Python: QGIS ↔ Registry (`python/gq/`)

PyQGIS-driven tools to:
- **Export:** Extract layer styles from a QGIS project → QML files → canonical JSON
- **Import:** Apply canonical JSON styles back to QGIS layers
- **Sync:** Round-trip styles between QGIS and registry

Requires QGIS Python environment (PyQGIS).

#### 2. R Package: Registry → R Renderers (`R/gq/`)

R functions to:
- `gq_read_registry()` — load canonical styles from registry.json
- `gq_tmap_style()` — translate canonical style to tmap v4 aesthetics
- `gq_leaflet_style()` — translate to leaflet options
- `gq_ggplot_style()` — translate to ggplot2 scale/theme
- `gq_maplibre_style()` — generate MapLibre GL JSON style spec

#### 3. Style Registry (`registry/`)

- `registry.json` — the canonical style definitions
- Versioned alongside code
- Schema validation

#### 4. QML Archive (`styles/qml/`)

- Extracted QML files from QGIS projects
- Source material for the canonical registry
- Preserved for round-tripping back to QGIS

### Multi-Backend Data Sources

Styles are **data-source-independent**. The same style applies whether the layer comes from:
- PostgreSQL (bcfishpass, fwapg via db-newgraph)
- SQLite / SpatiaLite
- DuckDB (DuckDB Spatial)
- GeoPackage (.gpkg)
- Shapefiles / GeoJSON
- Cloud-native (PMTiles, COG, FlatGeobuf)

The registry maps **layer names** to styles, not data sources to styles. The consuming tool (tmap, leaflet, etc.) handles data access separately.

### Web Mapping Pipeline

For cloud-native web mapping:
1. Data in PMTiles (vector) or COG (raster)
2. Styles from registry → MapLibre GL JSON style spec
3. Hosted on S3/Cloudflare
4. Viewer at `viewer.a11s.one` or custom MapLibre app

### Future: Standards Integration

- **QGIS Hub API** — publish/discover community styles
- **OGC API Styles** — serve styles via standard endpoint (awshak)
- **Mapbox/MapLibre Style Spec** — direct output for web mapping

## Prior Research Context

### PyQGIS Style Export (from prior conversation)

Architecture explored for extracting styles from QGIS projects:
- Use `QgsProject.instance().read()` to load .qgs/.qgz
- Iterate `mapLayers()` to access each layer
- `layer.renderer()` gives the symbology renderer (single, categorized, graduated, rule-based)
- `layer.exportNamedStyle()` exports QML XML
- Parse QML XML to extract fill/stroke/label properties
- Handle renderer types: `QgsSingleSymbolRenderer`, `QgsCategorizedSymbolRenderer`, `QgsGraduatedSymbolRenderer`, `QgsRuleBasedRenderer`
- Symbol layers: `QgsSimpleFillSymbolLayer`, `QgsSimpleLineSymbolLayer`, `QgsMarkerSymbolLayer`

### Registry Schema (from prior conversation)

The `registry.json` schema was designed with:
- Layer-name-based lookup (not file-based)
- Support for classification (categorized, graduated, rule-based)
- Filter expressions for rendering vs labeling thresholds
- Overlay support (e.g., railway double-line trick)
- Label hierarchy (size, weight, style, color, min-scale, max-scale)

## Key Patterns

### Style Precedence

1. **Project override** — project-specific `gq_styles.json` overrides registry defaults
2. **Registry default** — `registry/registry.json` canonical styles
3. **Fallback** — sensible defaults if no style found

### NGE Color Palette (from cartography skill)

| Element | Fill | Border | Alpha |
|---------|------|--------|-------|
| Watershed A | `#a8c8e0` | `#2c3e50` | 0.40 |
| Watershed B | `#6a9bc3` | `#2c3e50` | 0.40 |
| Parks | `#a3c4a3` | `#5a7a5a` | 0.35 |
| Lakes | `#c6ddf0` | `#7ba7cc` | 0.85 |
| Streams | `#7ba7cc` | — | — |
| Highway | `#c0392b` | — | — |
| Railway | `#000000` + `#ffffff` dash | — | — |

## Development

### Python setup
```bash
cd python && pip install -e .
```

### R package
```r
devtools::install("R/gq")
```

## Learning Preferences

Teach extreme programming (XP) principles when relevant:
- **YAGNI** — Don't build until you need it
- **KISS** — Simplest solution that works
- **Small commits** — Atomic, focused changes
- **Test early** — Verify as you go
