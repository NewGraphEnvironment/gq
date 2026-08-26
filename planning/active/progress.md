# Progress — gq_basemap_tiles() returns watermarked placeholder tiles as success (#57)

## Session 2026-08-26

- Found by rendering the vignettes and reading the figures, not by any test
- Confirmed the watermark is live on the published pkgdown artifact (HTTP 200)
- Measured: the watermark is zoom-dependent (clean z9, watermarked z10/z11)
- Measured: a global-luminance content probe **cannot** separate watermarked from clean —
  the watermarked z11 tile has fewer dark pixels than the clean z9 tile
- Measured: `Esri.WorldTerrain` returns a constant tile (sd 0, 1 unique value) — a second
  success-shaped failure, and one that IS detectable
- Chose `Esri.WorldGrayCanvas` as the replacement; verified visually
- Plan-mode exploration — phases approved by user
- Created branch `57-gq-basemap-tiles-returns-watermarked-pla` off main
- Scaffolded PWF baseline from issue #57 with approved phases
- Next: start Phase 1
