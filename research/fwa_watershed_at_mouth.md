# A watershed taken at a creek's mouth can include the receiving river

**Verified:** 2026-11-09 · **Issues:** #102 (found while re-composing gq-intro, #62) ·
**Produced by:** `data-raw/bittner_creek.R`, queries against a fwapg database; the
measurements are in `planning/archive/2026-11-issue-102-move-3-package-face-check-gate/README.md`

`fwa_watershedatmeasure(blue_line_key, 0)` returns the watershed upstream of a stream's
mouth. Where the stream's lowest segment runs inside the receiving river's polygon
(`whse_basemapping.fwa_rivers_poly`), the result includes the river corridor as well.
For Bittner Creek, which enters the Fraser at Prince George, that was ~500 ha of Fraser and
Nechako channel attached to the 4,008 ha creek watershed, 9% of the polygon. It put a
Fraser crossing "inside" the watershed and stretched every map frame over downtown.

Nothing about the polygon flags this: it is a single valid part, with an area field that
looks plausible (the old figure, ~56 km², was quoted in docs for nine months).

## What works

Take the watershed at the lowest measure whose segment lies outside every river polygon,
plus 1 m:

- **The segment test:** a segment is inside a river polygon when its midpoint falls within
  one. Bittner's lowest segment, 0-165.97 m, is edge type 1450 with its midpoint in the
  Fraser polygon.
- **Why the extra metre:** at exactly the boundary measure, fwapg still takes the segment
  below. At 165.97 m the watershed is 5,128 ha with 844 ha of river polygon; at 166.97 m it
  is 4,008 ha with none.
- **The check:** the river polygon area inside the result should be about 0. The script
  stops if it is over 1 ha.

The query is in `data-raw/bittner_creek.R`.

## Where else this applies

Any pull of a tributary's watershed at its mouth where the receiving stream is mapped as a
river polygon. A main stem's end on the receiving river's centreline is a related trap
(`code-check-spatial.md`, "A Freshwater Atlas main stem's downstream end lies on the
receiving river's centreline, not at the confluence").
