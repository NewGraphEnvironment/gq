# gq

> It's all about style.

Cartographic style management across QGIS, tmap, leaflet, and web mapping (MapLibre GL / PMTiles).

**gq** extracts symbology from QGIS projects (QML), stores it in a canonical JSON registry, and translates it to any rendering target — so your maps look the same whether they're static reports, interactive leaflet maps, or cloud-native web tiles.

## Architecture

```
QGIS Project (.qgs/.qgz)
  ↓ PyQGIS extract
QML files (.qml)
  ↓ parse
Canonical Style Registry (JSON)
  ↓ translate
┌─────────┬──────────┬─────────────┬─────────┐
│  tmap   │ leaflet  │ MapLibre GL │ ggplot2 │
│  (R)    │   (R)    │   (JSON)    │  (R)    │
└─────────┴──────────┴─────────────┴─────────┘
```

## Status

Early R&D. See [SRED tracking](https://github.com/NewGraphEnvironment/sred-2025-2026/issues/13).

## License

TBD
