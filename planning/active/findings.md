# Findings: tmap composition (gq#17)

## Neexdzii Kwa data

- BLK 360873822 (Bulkley mainstem), DRM 214900–217800
- Johnny David Creek confluence: DRM ~215017 on Bulkley
- Richfield Creek confluence: DRM ~217683 on Bulkley
- Watershed subtraction via `frs_watershed_at_measure()` with `upstream_measure`
- AOI: 21,218 ha (212 km²)
- Data sizes: streams 672KB, wetlands 173KB, wsg 436KB, wsd 48KB, lakes 27KB,
  bc 17KB, roads 4KB, railway 1KB. Total ~1.4 MB.

## Named tributaries in range (from bulk_drm query)

Full list of Bulkley tributaries with DRM on mainstem available in session.
Key ones near our AOI: McQuarrie (206235), Perow (207634), Byman (207878),
Johnny David (215017), Richfield (217683), Cesford (221010), Ailport (229640).

## tmap known issues

- `tm_scalebar()` crashes in tmap 4.2 with `object 'sbW' not found`
- `!!!` splice does NOT work — use `do.call()` pattern
- `opt_tm_text()` uses underscores: `remove_overlap` not `remove.overlap`
- Our fork: `~/Projects/repo/tmap` — can enable issues, branch, fix
