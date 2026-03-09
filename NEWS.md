# gq (development version)

## 0.0.0.9000

* Add `gq_style()` — backend-agnostic style resolver with name-based registry
  lookup. Accepts layer names like `"lake"` or `"Crossings - PSCIS assessment"`,
  normalizes to registry keys, returns plain lists of colors, widths, and
  classification info. No tmap/mapgl dependency.

* `gq_tmap_style()` and `gq_tmap_classes()` now accept name-based lookup:
  `gq_tmap_style(reg, "lake")` instead of `gq_tmap_style(reg$layers$lake)`.
  Classified layers return full `tm_scale_categorical()` wiring — no manual
  color extraction needed. Backwards compatible with object-based calls.

* Add Neexdzii Kwa subbasin datasets: habitat, crossings, fish observations,
  falls.

* Add composition vignette showing basemap blending, habitat, crossings,
  fish observations, and falls with all styles from registry.
