# Progress — Add symbol size/shape translator for tmap and mapgl (#16)

## Session 2026-08-26

- Surfaced by reading the rendered flagship map after #57, not from the issue
- Measured tmap `size` = 5.08 mm per unit **(WRONG — see findings correction:
  that read the grob's input, not the ink; a circle draws 3.81 mm)**
- Established the registry's `radius` is a QGIS marker **diameter** in mm
- Found tmap oversized (27% in ink), mapgl ~1.9x undersized, disagreeing by 3x
- Confirmed shape is in the registry for 15 layers and consumed by nothing
- User approved QGIS-true 1:1 conversion plus a uniform `scale` knob
- Plan-mode exploration — phases approved by user
- Created branch `16-add-symbol-size-shape-translator-for-tma` off main
- Scaffolded PWF baseline from issue #16 with approved phases
- Next: start Phase 1
