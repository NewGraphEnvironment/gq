# gq — Cartographic Style Management

## Company Vision

**New Graph Environment** - With integrity, using sound science and open
communication, we build productive relationships between First Nations,
regulators, non-profits, proponents, scientists, and stewardship groups.
Our value-added deliverables include open-source, collaborative GIS
environments and interactive online reporting.

## Project Overview

**gq** is a style management system for cartography across multiple
rendering targets. It extracts symbology from QGIS projects, stores it
in a canonical format, and translates it to tmap, leaflet, MapLibre GL,
and ggplot2.

The name is a reference — it’s all about style.

## Repository Relationships

| Repo | Relationship |
|----|----|
| `soul` | Parent ecosystem — conventions, skills (including `cartography` skill) |
| `soul/skills/cartography` | Codified map-making patterns for tmap + mapgl + fwapg (consumer of gq styles) |
| `sred` | R&D tracking — Experiment 6.11 (#13), Experiment 6.17 (#19, QWC2) |
| `awshak` | Infrastructure — QWC2 deployment (#61), geomapper (#58), future OGC API Styles |
| `nrp-nutrient-loading-2025` | First consumer project (tmap watershed maps) |
| All fish passage / restoration repos | Consumer projects (leaflet maps, QGIS projects) |
| QWC2 (`qgis/qwc2`) | Browser-based viewer — serves `.qgs` via QGIS Server; gq extracts from same `.qgs` |

## SRED Tracking

Tag SRED on **PRs only** (not issues or commits) so all commits stay in
lineage and are discrete.

PR body: `Relates to NewGraphEnvironment/sred#13`

- Experiment 6.11: sred#13 — gq core
- Experiment 6.17: sred#19 — QWC2

## Architecture

### The Problem

New Graph produces maps across multiple tools: - **QGIS** — interactive
GIS, field data, Mergin Maps sync - **tmap** — static maps in bookdown
reports (R) - **leaflet** — interactive maps in bookdown reports (R) -
**Web mapping** — PMTiles + MapLibre GL for cloud-native web maps -
**ggplot2** — statistical plots with spatial context (R)

Symbology (colors, line weights, labels, classification breaks) is
currently duplicated manually across each tool. Change a color in QGIS →
manually update R code → manually update web styles. This doesn’t scale.

### The Solution

A canonical style registry that serves as the single source of truth:

    QGIS Project (.qgs)          Hand-curated CSV
      ↓ gq_qgs_extract()           ↓ gq_reg_custom()
    registry JSON                 registry list
      ↓                             ↓
      └──── gq_reg_merge() ────────┘
                  ↓
            reg_main.json (master registry)
                  ↓ gq_reg_main()
      ┌───────────┼───────────┐
      │ tmap      │ mapgl     │ (future: leaflet, ggplot2)
      │ (static)  │ (web)     │
      └───────────┴───────────┘

### Canonical Style Format

Each layer style in the registry maps a **layer name** to rendering
properties:

``` json
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

#### R Package (the package root IS the R package)

**Registry functions:** -
[`gq_reg_main()`](https://newgraphenvironment.github.io/gq/reference/gq_reg_main.md)
— load the master registry (53 layers, no arguments needed) -
`gq_registry_read(path)` — read any registry JSON file -
`gq_reg_read(path)` — alias for
[`gq_registry_read()`](https://newgraphenvironment.github.io/gq/reference/gq_registry_read.md) -
`gq_reg_custom(path)` — read a hand-curated CSV registry -
`gq_reg_merge(..., csv, priority)` — merge multiple registries

**Style resolvers:** - `gq_style(reg, name, field)` — backend-agnostic
style resolver (colors, widths, classification) -
`gq_tmap_style(reg, name, field)` — translate layer → tmap v4
polygon/line/point args - `gq_tmap_classes(reg, name, field)` —
translate classified layer → field, values, labels -
`gq_mapgl_style(layer)` — translate layer → MapLibre GL paint
properties - `gq_mapgl_classes(layer)` — translate classified layer →
MapLibre match expression

The `field` parameter overrides the classification field name when data
comes from an alternative source (e.g., bcfishpass `barrier_status` vs
WHSE `barrier_result_code`). See `inst/registry/xref_layers.csv`.

**QGIS extraction:** - `gq_qgs_extract(path)` — parse .qgs XML →
registry JSON (no PyQGIS needed)

#### Registry sources (`inst/registry/`)

- `reg_main.json` — master merged registry (single source of truth)
- `reg_qgis_restoration.json` — extracted from restoration QGIS project
  (47 layers)
- `reg_qgis_fishpassage.json` — extracted from fish passage QGIS project
  (42 layers)
- `reg_custom.csv` — hand-curated styles for layers without QGIS source

#### Build script (`data-raw/reg_build_main.R`)

Merges all registry sources into `reg_main.json`. Run manually after
updating any source registry.

### Multi-Backend Data Sources

Styles are **data-source-independent**. The same style applies whether
the layer comes from: - PostgreSQL (bcfishpass, fwapg via db-newgraph) -
SQLite / SpatiaLite - DuckDB (DuckDB Spatial) - GeoPackage (.gpkg) -
Shapefiles / GeoJSON - Cloud-native (PMTiles, COG, FlatGeobuf)

The registry maps **layer names** to styles, not data sources to styles.
The consuming tool (tmap, leaflet, etc.) handles data access separately.

### Future

- **leaflet translator** — `gq_leaflet_style()` for interactive bookdown
  maps
- **ggplot2 translator** — `gq_ggplot_style()` for statistical plots
- **GitHub Action** — auto-rebuild `reg_main.json` on registry source
  changes (gq#11), potentially trigger QWC2 theme refresh
- **QWC2 integration** — browser-based map viewer serving same `.qgs`
  projects via QGIS Server (awshak#61, sred#19). No style translation
  needed — QGIS Server renders natively. Complements Mergin Maps (field)
  and gq (reports).
- **OGC API Styles** — serve styles via standard endpoint (awshak)

## Key Patterns

### Usage pattern

``` r

library(gq)
reg <- gq_reg_main()  # load once per script

# Simple layer → tmap (name-based lookup)
tm_shape(lakes_sf) + do.call(tm_polygons, gq_tmap_style(reg, "lake"))

# Classified layer → tmap
tm_shape(roads_sf) + do.call(tm_lines, gq_tmap_style(reg, "roads_dra"))

# Override field when data source differs from registry
tm_shape(crossings_sf) +
  do.call(tm_dots, gq_tmap_style(reg, "crossings_pscis_assessment",
                                  field = "barrier_status"))

# Backend-agnostic style extraction
gq_style(reg, "railway")$stroke$color  # "#000000"

# Simple layer → mapgl
lake_gl <- gq_mapgl_style(reg$layers$lake)
add_fill_layer(id = "lakes", source = lakes_sf, fill_color = lake_gl$paint[["fill-color"]])

# Classified layer → mapgl
bec_expr <- gq_mapgl_classes(reg$layers$bec_zone)
add_fill_layer(id = "bec", source = bec_sf, fill_color = bec_expr)
```

### Style precedence

[`gq_reg_merge()`](https://newgraphenvironment.github.io/gq/reference/gq_reg_merge.md)
controls precedence. Default is `priority = "last"` (later sources win).
Projects can merge their own CSV on top of
[`gq_reg_main()`](https://newgraphenvironment.github.io/gq/reference/gq_reg_main.md)
to override specific layers.

### Title case labels

[`gq_tmap_classes()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_classes.md)
auto-converts ALL CAPS fallback labels to title case (e.g., BARRIER →
Barrier). Explicit `label` or `class_label` fields in the registry
override this — use for acronyms like BEC zone codes.

## Development

### Install

``` r

pak::pak("NewGraphEnvironment/gq")
```

### Dev workflow

``` r

devtools::load_all()
devtools::test()        # 127+ tests
devtools::document()    # if roxygen changed
devtools::check()       # before release
```

### Rebuild master registry

``` r

source("data-raw/reg_build_main.R")
```

## Learning Preferences

Teach extreme programming (XP) principles when relevant: - **YAGNI** —
Don’t build until you need it - **KISS** — Simplest solution that
works - **Small commits** — Atomic, focused changes - **Test early** —
Verify as you go

\<!– BEGIN SOUL CONVENTIONS — DO NOT EDIT BELOW THIS LINE –\>

# Cartography

## Style Registry

Use the `gq` package for all shared layer symbology. Never hardcode hex
color values when a registry style exists.

``` r

library(gq)
reg <- gq_reg_main()  # load once per script — 51+ layers
```

**Core pattern:** `reg$layers$lake`, `reg$layers$road`,
`reg$layers$bec_zone`, etc.

### Translators

| Target | Simple layer | Classified layer |
|----|----|----|
| tmap | `gq_tmap_style(layer)` → `do.call(tm_polygons, ...)` | `gq_tmap_classes(layer)` → field, values, labels |
| mapgl | `gq_mapgl_style(layer)` → paint properties | `gq_mapgl_classes(layer)` → match expression |

### Custom styles

For project-specific layers not in the main registry, use a hand-curated
CSV and merge:

``` r

reg <- gq_reg_merge(gq_reg_main(), gq_reg_read_csv("path/to/custom.csv"))
```

Install: `pak::pak("NewGraphEnvironment/gq")`

## Map Targets

| Output | Tool | When |
|----|----|----|
| PDF / print figures | `tmap` v4 | Bookdown PDF, static reports |
| Interactive HTML | `mapgl` (MapLibre GL) | Bookdown gitbook, memos, web pages |
| QGIS project | Native QML | Field work, Mergin Maps |

## Key Rules

- **`sf_use_s2(FALSE)`** at top of every mapping script
- **Compute area BEFORE simplify** in SQL
- **No map title** — title belongs in the report caption
- **Legend over least-important terrain** — swap legend and logo sides
  when it reduces AOI occlusion. No fixed convention for which side.
- **Four-corner rule** — legend, logo, scale bar, keymap each get their
  own corner. Never stack two in the same quadrant.
- **Bbox must match canvas aspect ratio** — compute the ratio from
  geographic extents and page dimensions. Mismatch causes white space
  bands.
- **Consistent element-to-frame spacing** — all inset elements should
  have visually equal margins from the frame edge
- **Map fills to frame** — basemap extends edge-to-edge, no dead bands.
  Use near-zero `inner.margins` and `outer.margins`.
- **Suppress auto-legends** — build manual ones from registry values
- **ALL CAPS labels appear larger** — use title case for legend labels
  (gq
  [`gq_tmap_classes()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_classes.md)
  handles this automatically via `to_title()` fallback)

## Self-Review (after every render)

Read the PNG and check before showing anyone:

1.  Correct polygon/study area shown? (verify source data, not just the
    bbox)
2.  Map fills the page? (no white/black bands)
3.  Keymap inside frame with spacing from edge?
4.  No element overlap? (each in its own corner)
5.  Legend over least-important terrain?
6.  Consistent spacing across all elements?
7.  Scale bar breaks appropriate for extent?

See the `cartography` skill for full reference: basemap blending, BC
spatial data queries, label hierarchy, mapgl gotchas, and worked
examples.

## Land Cover Change

Use [drift](https://github.com/NewGraphEnvironment/drift) and
[flooded](https://github.com/NewGraphEnvironment/flooded) together for
riparian land cover change analysis. flooded delineates floodplain
extents from DEMs and stream networks; drift tracks what’s changing
inside them over time.

**Pipeline:**

``` r

# 1. Delineate floodplain AOI (flooded)
valleys <- flooded::fl_valley_confine(dem, streams)

# 2. Fetch, classify, summarize (drift)
rasters   <- drift::dft_stac_fetch(aoi, source = "io-lulc", years = c(2017, 2020, 2023))
classified <- drift::dft_rast_classify(rasters, source = "io-lulc")
summary    <- drift::dft_rast_summarize(classified, unit = "ha")

# 3. Interactive map with layer toggle
drift::dft_map_interactive(classified, aoi = aoi)
```

- Class colors come from drift’s shipped class tables (IO LULC, ESA
  WorldCover)
- For production COGs on S3, `dft_map_interactive()` serves tiles via
  titiler — set `options(drift.titiler_url = "...")`
- See the [drift
  vignette](https://www.newgraphenvironment.com/drift/articles/neexdzii-kwa.html)
  for a worked example (Neexdzii Kwa floodplain, 2017-2023)

# CI Monitoring

When this repo has GitHub Actions workflows, scan recent runs on session
start. Catches failed pkgdown deploys, broken vignette builds, and stale
citation regenerations that would otherwise linger until the user
manually checks.

## On Session Start

``` bash
gh run list --limit 5 --json status,conclusion,name,createdAt,databaseId \
  --jq '.[] | select(.conclusion == "failure")'
```

If any failures since the last visit, surface to the user before
starting other work:

> Workflow `<name>` failed `<time>` ago (run `<id>`). Investigate with
> `gh run view <id> --log-failed`. Fix or proceed with current task?

User decides; do not auto-fix.

## Particular Failures Worth Naming

- **pkgdown** — docs site on GitHub Pages broken
- **R-CMD-check** — package may not install
- **Vignette / build-vignettes** — vignette docs incomplete
- **update-citation-cff** — CITATION.cff stale

## Why This Matters

Without this scan, post-merge workflow failures linger until someone
(often the user) notices a stale docs site or a missing vignette. The
session-start sweep catches them on the first re-entry into the repo.

## Pairs with `/gh-pr-merge`

The skill watches workflows triggered by a fresh merge in real time —
that’s the targeted catch. This convention is the backstop for failures
that landed when no one was watching (merges via web UI, scheduled
triggers, manually-triggered workflows).

# Code Check Conventions

Structured checklist for reviewing diffs before commit. Used by
`/code-check`. Add new checks here when a bug class is discovered — they
compound over time.

## Shell Scripts

### Quoting

- Variables in double-quoted strings containing single quotes break if
  value has `'`
- `"echo '${VAR}'"` — if VAR contains `'`, shell syntax breaks
- Use `printf '%s\n' "$VAR" | command` to pipe values safely
- Heredocs: unquoted `<<EOF` expands variables locally, `<<'EOF'` does
  not — know which you need
- Pass-through-ssh args: `printf '%q'` escapes per-arg so workload paths
  with spaces / quotes / metacharacters survive the local-shell →
  ssh-argv → remote-shell round-trip. Without it,
  `ssh host 'cmd' "$path"` joins args with spaces on remote and
  re-parses, losing argument boundaries.

### Heredoc precedence in pipelines

- `cmd1 | cmd2 <<EOF` — the heredoc binds to `cmd2` (the rightmost
  simple command). If you intended `cmd1` to receive it, put `<<EOF` on
  cmd1 explicitly: `cmd1 <<EOF | cmd2`.
- Symptom when wrong: ssh body silently echoed by tee/cat/etc, ssh side
  gets empty stdin, exits 0 (or near-0) without doing anything. Caught
  the hard way 2026-05-01 in cypher_restore-fwapg.sh.

### pipefail with ssh+tee

- `set -eu` does NOT propagate exit codes through pipelines.
  `ssh ... | tee log` returns tee’s exit (always 0 for healthy tee),
  masking ssh failure.
- Use `set -euo pipefail` for any script that pipes a meaningful command
  into tee/cat/grep/etc. Or check `${PIPESTATUS[0]}` explicitly.
- Symptom when wrong: task notifications report “exit 0 / completed”
  while remote work was actually skipped or errored.

### Paths

- Hardcoded absolute paths (`/Users/airvine/...`) break for other users
- Use `REPO_ROOT="$(cd "$(dirname "$0")/<relative>" && pwd)"`
- After moving scripts, verify `../` depth still resolves correctly
- Usage comments should match actual script location

### Silent Failures

- `|| true` hides real errors — is the failure actually safe to ignore?
- Empty variable before destructive operation (rm, destroy) — add guard:
  `[ -n "$VAR" ] || exit 1`
- `grep` returning empty silently — downstream commands get empty input

### `mktemp` template needs enough X’s, and a failed `mktemp` leaves an empty var

- BSD/macOS `mktemp -d -t <name>` requires the template to contain at
  least 3 `X`s (`XXXXXX` is the safe default). Without them, mktemp
  errors to stderr (`too few X's in template`) and **prints nothing to
  stdout**.
- Pattern:
  `SCRATCH=$(mktemp -d -t aider-smoke) && cd "$SCRATCH" && <destructive>`.
  When mktemp fails, `$SCRATCH=""`. `cd ""` is a no-op that **leaves you
  in the caller’s cwd**. The destructive command (`rm`, `git init`,
  `git add+commit`) then runs in cwd instead of a throwaway tmpdir.
- Caught the hard way 2026-05-13: a Claude smoke test inside the rtj
  checkout did exactly this, accidentally committed a `demo.R` to the
  active feature branch, which then rode the squash-merge into rtj/main
  and had to be cleaned up post-merge.
- Fix patterns:
  - Always use `XXXXXX` (6 X’s) in the template:
    `mktemp -d -t aider-smoke.XXXXXX`.
  - Guard the result:
    `SCRATCH=$(mktemp -d ...) || exit 1; [ -n "$SCRATCH" ] || exit 1`.
  - Use `set -euo pipefail` so the failed command-substitution kills the
    script.

### BSD vs GNU sed/grep portability (macOS hits this constantly)

- macOS ships BSD `sed`/`grep`. Linux CI/cloud-init hosts ship GNU.
  Snippets that work on one silently misbehave on the other.
- **`\+` and `\|` are GNU BRE extensions.** On BSD they’re treated as
  literal `+` and `|`, so the regex still “matches” but matches nothing
  useful — leaving raw input unchanged.
  - Symptom seen 2026-05-28: `sed 's/[^a-z0-9]\+/-/g'` on macOS left
    spaces in an issue-title slug, producing an invalid git branch name.
  - Fix: use `sed -E` (POSIX ERE) so `+`, `|`, `?`, `(...)` all work
    without escapes on both flavors. The same regex becomes
    `sed -E 's/[^a-z0-9]+/-/g'`.
- **`s|pat|repl|` delimiter conflicts with `|` in
  alternation/replacement on BSD.** Pick a delimiter that does not
  appear in pattern or replacement (`#`, `,`, `:` are common choices).
  Compound `s|x|y|; s|^| /||` chains where the trailing `||` looks like
  an empty delimiter break on BSD sed even when GNU accepts them.
- **Don’t parse `ls`.** BSD `ls` emits ANSI colour codes when stdout is
  a TTY *or* when `CLICOLOR_FORCE` is set in env (often by shell rc
  files), and the codes leak through pipes. Downstream `grep`/`sed`
  chokes on the embedded escapes (`[01;31m...[0m`).
  - Use
    `find <dir> -maxdepth 1 -mindepth 1 -type d -exec basename {} \;`
    for directory listings, or `printf '%s\n' <dir>/*/` for a glob, or
    `for d in <dir>/*/; do basename "$d"; done`.
- **When writing a snippet you expect to ship in a `skills/` SKILL.md or
  any cloud-init runcmd**: it must be POSIX-portable. Default to
  `sed -E`, avoid `\+`/`\|`, and don’t pipe `ls`.

### Process Visibility

- Secrets passed as command-line args are visible in `ps aux`
- Use env files, stdin pipes, or temp files with `chmod 600` instead

## Cloud-Init (YAML)

### ASCII

- Must be pure ASCII — em dashes, curly quotes, arrows cause silent
  parse failure
- Check with: `perl -ne 'print "$.: $_" if /[^\x00-\x7F]/' file.yaml`

### YAML flow-mapping in runcmd

- Any runcmd item containing both `{` and `:` is at risk of being parsed
  as a YAML flow-mapping (dict), not a literal string. Cloud-init’s
  shellify hits a non-string and throws TypeError, **aborting all
  subsequent runcmd steps silently** while `final_message` still fires.

- Don’t write: `- test -s /file || { echo "FATAL: ..." }` — the `:`
  inside braces makes YAML see a dict.

- Do write: use `- |` block scalar with explicit `if/then/fi`:

  ``` yaml
  - |
    if [ ! -s /file ]; then
      echo "FATAL: ..." >&2
      exit 1
    fi
  ```

- Validate post-edit:
  `python3 -c "import yaml; runcmd=yaml.safe_load(open('cloud-init.yaml').read().split(chr(10),1)[1])['runcmd']; print([type(x).__name__ for x in runcmd if not isinstance(x,str)] or 'all strings')"`.
  If the output is anything other than `all strings`, the runcmd will
  fail.

### State

- `cloud-init clean` causes full re-provisioning on next boot — almost
  never what you want before snapshot
- Use `tailscale logout` not `tailscale down` before snapshot
  (deregister vs disconnect)
- Wipe `/var/lib/tailscale/*` before snapshot too — `tailscale logout`
  deauthorizes server-side but local node identity blob persists in
  tailscaled.state. Snapshot restored elsewhere inherits prior key
  material until `tailscale up` runs again.
- Wipe `/etc/ssh/ssh_host_*` before snapshot — otherwise droplets
  spawned from the same image share host identity.

### Template Variables

- Secrets rendered via `templatefile()` are readable at
  `169.254.169.254` metadata endpoint
- Acceptable for ephemeral machines, document the tradeoff
- Heredocs in runcmd that write secrets: `<<'EOF'` (quoted) prevents
  bash from re-expanding `$X` sequences in already-substituted
  credential strings. AWS keys rarely contain `$` but base64-padded
  secrets might.

### Repo + key install ordering

- `apt-key adv --keyserver` is deprecated on Ubuntu 24.04 noble —
  silently fails AND APT ignores resulting keyring. Use
  `gpg --dearmor` + `signed-by=` keyring file pattern.
- Repo .list files in `write_files:` trigger the implicit
  `package_update` BEFORE runcmd installs the keyring → first apt-get
  update fails with NO_PUBKEY. Put the repo line in runcmd alongside the
  key install, not in write_files.

### Cloud-init users vs DO SSH key injection

- DO injects `ssh_key_ids` only into `/root/.ssh/authorized_keys`
  (cloud-init’s `cc_ssh` module). Cloud-init `users:` block with
  `ssh_authorized_keys: []` does NOT pick those up.

- Non-root users that need SSH access must copy from root’s keys in
  runcmd:

  ``` yaml
  - mkdir -p /home/<user>/.ssh
  - cp /root/.ssh/authorized_keys /home/<user>/.ssh/authorized_keys
  - chown -R <user>:<user> /home/<user>/.ssh
  ```

- Guard with `test -s /root/.ssh/authorized_keys` to fail loudly if
  `cc_ssh` hasn’t run before runcmd (rare race).

## OpenTofu / Terraform

### State

- Parsing `tofu state show` text output is fragile — use `tofu output`
  instead
- Missing outputs that scripts need — add them to main.tf
- Snapshot/image IDs in tfvars after deleting the snapshot — stale
  reference

### Destructive Operations

- Validate resource IDs before destroy: `[ -n "$ID" ] || exit 1`
- `tofu destroy` without `-target` destroys everything including
  reserved IPs
- Snapshot ID extraction by name: use
  `awk -v n="$NAME" '$2 == n {print $1}'` (exact match on column 2).
  `grep -F "$NAME"` is substring-match and can grab a stale snapshot
  whose name contains the new name as a substring.

### “Has been deleted” in plan output is not authoritative — verify against the cloud API first

- The AWS provider (5.x and some 6.x) has a known class of bug where a
  transient read error (false 404, regional-endpoint hiccup) is
  interpreted as “resource deleted outside of OpenTofu.” The plan will
  show the resource and any children scheduled for destroy + recreate
  (`forces replacement` cascades through children that interpolate the
  parent’s id/arn).
- If you didn’t delete the resource and the plan says it’s gone,
  **verify against the cloud API before applying**:
  `aws s3 head-bucket --bucket X`, `aws iam get-role --role-name X`,
  etc. A `tofu plan -refresh=true` re-run a moment later often reports
  “No changes.”
- Caught 2026-05-14 in rtj env/prod for stac-era5-land: bucket fully
  intact (60 objects, 307 MB) but plan said deleted with 5 child
  resources “must be replaced.” Apply would have clobbered the policy +
  lifecycle configs against the still-existing bucket. Recovery via
  `-target` on the unrelated resource being added (rtj#157 then codifies
  `lifecycle { prevent_destroy = true }` on the bucket + load-bearing
  children).
- **Belt-and-suspenders defense:** add
  `lifecycle { prevent_destroy = true }` to high-value resources (S3
  buckets, RDS instances, anything irreplaceable) in their module. Tofu
  will refuse to plan a destroy until the lifecycle line itself is
  removed in config — converts the failure mode from “apply silently
  clobbers” into “plan errors with `Instance cannot be destroyed`.”
  Don’t apply it to count-based resources where `count: 1 → 0` is a
  legitimate transition.

## DigitalOcean

### Snapshot disk-size constraint

- DO snapshots include the source droplet’s disk size. New droplets from
  a snapshot must have disk **\>=** snapshot disk. Resize **up** is
  fine; resize **down** below the snapshot disk is impossible without
  rebuilding.
- Build the snapshot at the smallest droplet size you’d ever want to
  spin from it. Sizes vs disks at writing: `g-4vcpu-16gb` = 50 GB,
  `g-8vcpu-32gb` / `m-4vcpu-32gb` = 100 GB, `m-8vcpu-64gb` = 200 GB.
- If your workload requires X GB RAM minimum, your snapshot floor is
  whatever droplet has X GB AND the smallest disk class.

### Reserved IP detach behavior

- Targeted destroy
  (`tofu destroy -target=module.droplet -target=...assignment...`)
  preserves the reserved IP at \$4/mo. Full `tofu destroy` releases it
  (next apply gets a NEW IP).

### Reserved IP assignment race (rtj#55, rtj#85)

- DO returns 422 “Droplet already has a pending event” when reserved IP
  assignment fires immediately after droplet+firewall creation. The
  droplet’s internal event queue takes time to drain.
- **Every DO droplet module that uses a reserved IP MUST have:**
  1.  `time_sleep` resource between droplet creation and IP assignment,
      with `create_duration ≥ 60s` (10s and 30s have both been observed
      to race; 60s has more headroom)
  2.  `depends_on = [time_sleep.<name>]` on the
      `digitalocean_reserved_ip_assignment` resource
  3.  A retry fallback in the wrapping shell script (`up.sh` style) that
      detects the 422 in tofu output and uses
      `doctl compute reserved-ip-action assign <ip> <droplet-id>` to
      recover. Tofu doesn’t retry; it leaves state half-applied
      (assignment recorded but DO didn’t actually attach).
- **Snapshot-based spins are MORE prone to the race** than first-boot
  from blank Ubuntu (more startup events compete for the droplet’s event
  queue).
- **Audit existing modules:**
  `grep -L 'time_sleep' env/do/*/<host>/main.tf` finds modules missing
  the gate. As of 2026-05-02, openclaw and geoserv have no `time_sleep`
  — they will race eventually.

## Docker / Postgres

### Postgis init time

- `imresamu/postgis` (and similar postgis images) on first cold start
  (empty data volume) take **5-12 min** to install all extensions —
  varies with disk IO and noisy-neighbor lottery on cloud hosts.
  Health-wait scripts must allow 15 min minimum, ideally with
  hard-fail + log dump on timeout.

### Tuning vs host RAM

- fresh’s `docker/docker-compose.yml` defaults are tuned for a 128 GB
  host (`shared_buffers=32GB`, `shm_size=36gb`). On smaller hosts,
  postgres OOMs at startup with “could not map anonymous shared memory”.
- 32 GB host floor: use the M1/cypher 32 GB-host preset
  (`scripts/fwapg/compose.override.m1.yml`) which sets
  `shared_buffers=8GB, shm_size=12gb`.
- Below 32 GB: postgres can technically start with smaller
  `shared_buffers` but fwapg work becomes painful. Don’t run fwapg
  pipelines on \<32 GB hosts.

### `search_path` is data, not config

- `ALTER DATABASE <db> SET search_path TO ...` is a database-level
  setting **stored in the postgres data dir**. Wiped with
  `docker compose down -v`. Must be re-applied on every restore.
- Codify in your restore script, not in cloud-init or compose env (those
  don’t apply to db-level settings).

### `pkill <R/Python/etc. client>` does NOT cancel its Postgres query

- Killing the client (R, Python, psql) closes its connection. The libpq
  backend on the server keeps running the in-flight query until it
  finishes — **server-side orphan**. The orphaned backend holds whatever
  locks it had (table, view, advisory). Every later `DROP VIEW` /
  `LOCK TABLE` / `ALTER` on the same object blocks behind it
  indefinitely — *silent hangs* indistinguishable from a slow query.

- Caught 2026-05-25 in link#205: a `pkill`’d `wsg_run_one.R` left a
  `frs_network_features` SELECT running 1h45m; subsequent recomputes
  wedged on `DROP VIEW barriers_bt_access` for 1h08m before someone
  noticed.

- **Always terminate the server-side backend**, not just the client:

  ``` sql
  SELECT pid, pg_terminate_backend(pid)
  FROM pg_stat_activity
  WHERE datname='<db>' AND state='active' AND now()-query_start > interval '3 minutes'
    AND pid <> pg_backend_pid();
  ```

  Then kill the client. Order matters when you don’t know which side
  will block.

### Set `statement_timeout` + `lock_timeout` on long DB ops

- Any long-running DB op from an R/Python/etc. client should set both at
  session start, ideally via env
  (`PGOPTIONS='-c statement_timeout=600000 -c lock_timeout=60000'`) or
  on the connection itself
  (`DBI::dbExecute(conn, "SET statement_timeout = '600000'")`). A
  runaway query then cancels server-side (no orphan); a blocked
  `DROP VIEW` gives up rather than wedging behind a zombie lock. Without
  it, silent hangs become indistinguishable from “still working” and you
  wait hours.
- Pick a generous-but-bounded timeout (10× expected query time). The
  point isn’t tight enforcement — it’s “fail loud instead of fail
  silent.”

### Function-as-join-predicate: index visibility depends on inlineability

- `JOIN b ON some_function(a.cols, b.cols)` — Postgres can only use the
  underlying indexes if `some_function` is `LANGUAGE sql` (inlineable).
  `plpgsql` functions are opaque and force per-row evaluation → seq scan
  / nested loop without indexes. Verify with `\df+ <function>` (look at
  `Language`) and `EXPLAIN` (look for the function body expanded into
  Filter / Index Cond).
- Caught in link#205 with `whse_basemapping.fwa_downstream` — it IS
  `LANGUAGE sql` + the planner did inline it; the symptom was elsewhere
  (see below). But if a function-based join is slow and the function is
  plpgsql, that’s the first thing to look at.

### Joining on a per-tenant key (e.g. `id_segment` per-WSG) against a multi-tenant table is cartesian

- `id_segment` in link’s persist schema is unique *within* a WSG, not
  globally (link#203).
  `WHERE id_segment IN (SELECT id_segment FROM streams WHERE wsg=aoi)`
  against persist matches access rows from *every* WSG sharing those
  id_segment values → N(WSGs)× duplicates → PK violations downstream and
  50× memory.
- Fix: filter by the full tenant key (`watershed_group_code = aoi`) when
  the table has it. Pattern: introspect via `information_schema.columns`
  at runtime and branch — the same function can serve a working schema
  (single tenant, no WSG col) and persist (multi-tenant, with WSG col).

### View vs. real table changes the planner’s join direction

- A `CREATE VIEW v AS SELECT * FROM big_table WHERE …` carries no
  row-count statistics. Used as a join input, the planner may pick the
  other side (big) as the outer driver, blowing nested-loop cost ~1000×
  — the symptom looks like “the indexes aren’t being used” but it’s
  actually a wrong-direction nested loop.
- Caught in link#205: AOI-scoping streams via a `VIEW` left Postgres
  thinking the 26k FINA segments were as big as the 800k persist
  barriers; it picked barriers as outer; 71M estimated result rows; \>10
  min wall.
- Fix when AOI-scoping into a smaller dataset: **materialise as a real
  `CREATE TABLE` with indexes + `ANALYZE`**. The planner then sees the
  small row count and picks it as outer. Drop the table on `on.exit` if
  it’s transient.

### Two-statement DELETE/INSERT into a persist table is not atomic

- A “DELETE WHERE wsg=‘X’; INSERT …” pair into a persist table from an
  orchestration script: if the INSERT fails (e.g. duplicate key from a
  subtle JOIN bug), the DELETE already ran → **data loss for that WSG**.
  Wrap in a single transaction (`BEGIN; … ; COMMIT`) when the persist
  table is the only source of truth, so a failed INSERT rolls back the
  DELETE. (link#205 lost FINA’s `streams_mapping_code` to this; the
  surrounding cheap-recompute orchestration in `wsg_recompute_one.R`
  should wrap both statements in a tx.)

## Tailscale

### ACL “users” semantics

- Tailscale SSH ACL `"users": ["autogroup:nonroot"]` for `tag:compute`
  blocks `ssh root@<node>` over the tailnet. Use `ssh <user>@<node>` +
  sudo for root operations.
- For SSH-as-root from off-tailnet (regular OpenSSH on the public IP),
  the ACL doesn’t apply — but you need the SSH key registered on the
  node.

### Reusable + ephemeral auth keys

- Cypher-style ephemeral compute droplets need both flags on the auth
  key: **Reusable** (same key works across destroy/recreate) +
  **Ephemeral** (tailnet entries auto-clean when offline \>5 min).
- Tag the key (e.g. `tag:compute`) at creation time. Nodes joining with
  that key inherit the tag automatically — no `--advertise-tags` needed
  at `tailscale up` time.

## Security

### Secrets in Committed Files

- `.tfvars` must be gitignored (contains tokens, passwords)
- `.tfvars.example` should have all variables with empty/placeholder
  values
- Sensitive variables need `sensitive = true` in variables.tf

### Firewall Defaults

- `0.0.0.0/0` for SSH is world-open — document if intentional
- If access is gated by Tailscale, say so explicitly

### Credentials

- Passwords with special chars (`'`, `"`, `$`, `!`) break naive shell
  quoting
- `printf '%q'` escapes values for shell safety
- Temp files for secrets: create with `chmod 600`, delete after use

## R / Package Installation

### pak Behavior

- pak stops on first unresolvable package — all subsequent packages are
  skipped
- Removed CRAN packages (like `leaflet.extras`) must move to GitHub
  source
- PPPM binaries may lag a few hours behind new CRAN releases

### Reproducibility

- Branch pins (`pkg@branch`) are not reproducible — document why used
- Pinned download URLs (RStudio .deb) go stale — document where to
  update

### Base name shadowing in formal args

- Avoid `names`, `length`, `data`, `c`, `t`, `T`, `F`, etc. as formal
  argument names. R’s function-lookup fallback often rescues `names(x)`
  calls inside a function whose arg is also called `names` — but it’s a
  confusing read, breaks under refactors, and generates a real “could
  not find function” error when the lookup heuristic misses (e.g. inside
  lapply/vapply/match.fun chains). Prefer descriptive alternatives:
  `label_names`, `n`, `df`, etc.
- Caught in mc#33 round 1 — `mc_label_ensure(names)` worked by luck when
  calling `names(existing)` to read a named-vector’s names; renamed to
  `label_names` for safety.

### Cross-function consistency for label/string normalization

- When two functions in the same package both decide whether a string is
  a “system value” (or any normalized form), they MUST use the same
  comparison. Mismatches are silent bugs that surface only on edge
  cases.
- mc#33 example: `mc_label_ensure` used `toupper(nm) %in% sys`
  (case-insensitive system-label skip), but `resolve_label_names` used
  `nm %in% sys` (case-sensitive). Result: `add = "inbox"` with
  `create_missing = TRUE` was silently broken — ensure skipped creation,
  resolve couldn’t match. Fix: both use `toupper(nm) %in% sys` and the
  resolver normalizes its return to the canonical case.
- Generalized check: when reviewing a diff that adds normalization
  (case, whitespace, prefix-trim) on one side of an interaction, grep
  for the other side and align them.

## General

### Adopting Existing Config

When importing config from one location into a canonical one (legacy
`~/.bash_profile` → dotfiles repo, old script’s env → repo, another
project’s `settings.json` → soul):

- **Verify every referenced path/binary exists.** Dead PATH exports,
  missing interpreters, stale env vars should be cut, not codified.
  Shell paths:
  `for p in $(echo "$PATH" | tr ':' ' '); do [ -d "$p" ] || echo "DEAD: $p"; done`
- **Ask before dropping a reference** — it may be something the user
  forgot to reinstall on this machine, not something to delete.
- **Curated subset, not verbatim copy.** The diff should reflect what
  you verified, not the whole source.

### Documentation Staleness

- Moving/renaming scripts: update CLAUDE.md, READMEs, usage comments
- New variables: update .tfvars.example
- New workflows: update relevant README

# NGE Feature Workflow

For non-trivial issue-driven work, follow this checklist. Each step
exists for a reason — skipping leads to rework, broken builds, and
avoidable bugs that we’ve hit repeatedly.

## The Sequence

1.  **Start with `/planning-init <N>`** — given an issue number, enters
    plan mode for codebase exploration, presents a phase breakdown for
    user approval, then scaffolds branch + PWF baseline with the
    approved phases. One command replaces the manual issue → explore →
    plan → branch → scaffold dance.
2.  **Write robust tests first** — failing tests that reproduce the
    issue or document the new behavior. Tests are the contract; they
    fail until the work makes them pass.
3.  **Name with intent** — functions, parameters, internal helpers carry
    the naming style of the package they live in. Look at existing
    exports as the guide; consistency over cleverness. (Per-package
    naming convention TBD — see soul issue tracking.)
4.  **Examples that run** — every exported function gets a runnable
    `@examples` block. Pkgdown renders them; CI executes them. An
    example that doesn’t run is documentation rot.
5.  **Code-check before each commit** — `/code-check` on staged diff.
    Catches what tests miss: edge cases, hard-coded paths, unguarded
    variables, security issues.
6.  **Atomic commits** — each commit bundles code change + checkbox flip
    in `task_plan.md`. The diff and the progress live in the same
    commit; `git log -- planning/` tells the full story.
7.  **`/planning-archive` when complete** — moves PWF to
    `archive/YYYY-MM-issue-N-slug/`, creates a fresh `active/`. Then
    `/gh-pr-push` opens the PR; `/gh-pr-merge` handles the release
    bookkeeping.

## When to Skip

For one-line typo fixes, version-bump-only PRs, or trivial documentation
edits, the full workflow is overhead. Use judgment. The threshold is
roughly: **multi-step issue, multi-file change, or anything that
requires scoping** → use the workflow.

## Skills That Slot In

- `/planning-init <N>` — start
- `/planning-update` — sync checkboxes mid-session
- `/code-check` — before every commit
- `/planning-archive` — when issue closes
- `/gh-pr-push` — open the PR
- `/gh-pr-merge` — merge with release bookkeeping

## Why This Exists

We’ve hit snags repeatedly when half-doing this — branches that mix
concerns, tests bolted on after, code-check skipped (and then a bug
ships in the diff), examples that fail in pkgdown. Each step is small;
the cumulative reliability gain is real. The convention is here so it
becomes the default expectation, not a thing the user has to remind
every session about.

# LLM Behavioral Guidelines

Behavioral guidelines to reduce common LLM coding mistakes. Merge with
project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For
trivial tasks, use judgment.

## 1. Think Before Coding

**Don’t assume. Don’t hide confusion. Surface tradeoffs.**

Before implementing: - State your assumptions explicitly. If uncertain,
ask. - If multiple interpretations exist, present them - don’t pick
silently. - If a simpler approach exists, say so. Push back when
warranted. - If something is unclear, stop. Name what’s confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No “flexibility” or “configurability” that wasn’t requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: “Would a senior engineer say this is overcomplicated?” If
yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code: - Don’t “improve” adjacent code, comments,
or formatting. - Don’t refactor things that aren’t broken. - Match
existing style, even if you’d do it differently. - If you notice
unrelated dead code, mention it - don’t delete it.

When your changes create orphans: - Remove imports/variables/functions
that YOUR changes made unused. - Don’t remove pre-existing dead code
unless asked.

The test: Every changed line should trace directly to the user’s
request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals: - “Add validation” → “Write tests
for invalid inputs, then make them pass” - “Fix the bug” → “Write a test
that reproduces it, then make it pass” - “Refactor X” → “Ensure tests
pass before and after”

For multi-step tasks, state a brief plan:

    1. [Step] → verify: [check]
    2. [Step] → verify: [check]
    3. [Step] → verify: [check]

Strong success criteria let you loop independently. Weak criteria (“make
it work”) require constant clarification.

**These guidelines are working if:** fewer unnecessary changes in diffs,
fewer rewrites due to overcomplication, and clarifying questions come
before implementation rather than after mistakes.

# New Graph Environment Conventions

Core patterns for professional, efficient workflows across New Graph
Environment repositories.

## Ecosystem Overview

Six repos form the governance and operations layer across all New Graph
Environment work:

| Repo | Purpose | Analogy |
|----|----|----|
| [compass](https://github.com/NewGraphEnvironment/compass) | Ethics, values, guiding principles | The “why” |
| [soul](https://github.com/NewGraphEnvironment/soul) | Standards, skills, conventions for LLM agents | The “how” |
| [compost](https://github.com/NewGraphEnvironment/compost) | Communications templates, email workflows, contact management | The “who” |
| [rtj](https://github.com/NewGraphEnvironment/rtj) (formerly awshak) | Infrastructure as Code, deployment | The “where” |
| [gq](https://github.com/NewGraphEnvironment/gq) | Cartographic style management across QGIS, tmap, leaflet, web | The “look” |
| [crate](https://github.com/NewGraphEnvironment/crate) | Data governance: canonical schemas, data dictionary, QC rules (scoping; normalization functions are Year 2+) | The “what” |

**Adaptive management:** Conventions evolve from real project work, not
theory. When a pattern is learned or refined during project work,
propagate it back to soul so all projects benefit. The `/claude-md-init`
skill builds each project’s `CLAUDE.md` from soul conventions.

**Cross-references:**
[sred](https://github.com/NewGraphEnvironment/sred) tracks R&D
activities across repos. Compost is the centralized communications
workflow — all email drafts, contact registry, and external outreach are
authored there, not in individual project repos.

## Three-Layer Repo Architecture

Repos live in one of three layers, distinguished by audience and what
context they carry:

| Layer | Role | Examples |
|----|----|----|
| **Public — tools** | Atomic, reusable, no NGE-specific context | R packages (`mc`, `crate`, `fresh`, `drift`, `flooded`, `gq`, `link`), `bcfishpass`, `fwapg`, STAC catalogs, post-publication reports |
| **Private — coordination** | How tools compose into NGE workflows. The competitive moat. | `compost` (uses `mc`), `rfp` (uses `fresh`/`link`/etc.), `rtj` (uses `crate`, deploys), `fish_passage_template_reporting`, all proposals (never public) |
| **Private — governance** | Strategy, values, conventions, R&D | `soul`, `logic`, `compass`, `sred` |

**Rule:** tools don’t know about each other or about NGE. Coordination
repos know how to use tools. `mc/CLAUDE.md` does not know `compost`
exists; `compost/CLAUDE.md` knows “for email use `mc`.”

**Publication flip:** when a private repo flips public (e.g., `crate`
once `link` requires it; reports on publication), three things happen in
the same commit: removed from comms peer list, `comms/` directory
purged, `CLAUDE.md` scrubbed to public-safe form. Use
`/claude-md-init --public-clean` for the scrub.

**Per-repo classification** is recorded in `.claude/visibility` (one
line: `public` or `internal`; default `internal` if missing). Soul
conventions carry `visibility:` frontmatter (`public-safe` or
`internal`); `/claude-md-init` filter skips internal-only conventions
when repo is marked public.

Strategic call recorded in
`logic/comms/soul/20260428_public_vs_internal_repo_architecture.md`.

## Issue Workflow

### Before Creating an Issue (non-negotiable)

1.  **Check for duplicates:**
    `gh issue list --state open --search "<keywords>"` – search before
    creating
2.  **One issue, one concern.** Keep focused.

SRED cross-refs go in **PR bodies only** (via `/gh-pr-push`), not in
issues or commits. PRs aggregate commits and are the merge unit;
per-issue and per-commit SRED tags add noise without adding
traceability.

### Professional Issue Writing

Write issues with clear technical focus:

- **Use normal technical language** in titles and descriptions
- **Focus on the problem and solution** approach
- **Add tracking links at the end** (e.g., `Relates to Owner/repo#N`)

#### Client-aware tone

Issues, PR descriptions, and commit messages are client-visible
deliverables, not internal notes.

Avoid in these artifacts: - Framing work as unsolicited or unpaid (“not
assigned by a client”) - Self-justifying adjectives (“defensible”,
“rigorous”) — show, don’t claim - Internal workflow meta (PWF refs, SRED
xrefs, planning context) - Performative effort language (“attempts were
unsuccessful”) — state factual current state

**Integrity-preserving ≠ self-effacing.** Factual, not performatively
humble.

**Scope:** repo artifacts (issues, PRs, commits, reports). Does not
apply to internal planning docs, CLAUDE.md, or chat.

**Issue body structure:**

``` markdown
## Problem
<what's wrong or missing>

## Proposed Solution
<approach>

Relates to #<local>
```

#### Infrastructure references

Use **tailnet hostnames** (`cypher`, `m1`, `openclaw`) in issue and PR
bodies, not public IPs. Within NGE infrastructure, those hostnames are
how scripts and operators address machines anyway; the public IP is an
implementation detail that belongs in gitignored `*.tfvars` and the
Tailscale admin panel.

Public IPs in issues are appropriate only when the IP itself is the
subject — reserved-IP migrations, DNS records, firewall rules that key
on a specific IP. For everything else, use a placeholder like
`<cypher_public_ip>` if the shape of the value matters at all.

Aggregation is the risk: any single IP in a private repo is fine, but
issue bodies tend to collect IP + hostname + service description +
access path into a coherent attack-surface map. Tailnet hostnames keep
the map terse.

### GitHub Issue Creation - Always Use Files

The `gh issue create` command with heredoc syntax fails repeatedly with
EOF errors. ALWAYS use `--body-file`:

``` bash
cat > /tmp/issue_body.md << 'EOF'
## Problem
...

## Proposed Solution
...
EOF

gh issue create --title "Brief technical title" --body-file /tmp/issue_body.md
```

## Closing Issues

**DO:** Close issues via commit messages. The commit IS the closure and
the documentation.

    Fix broken DEM path in loading pipeline

    Update hardcoded path to use config-driven resolution.

    Fixes #20
    Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

**DON’T:** Close issues with `gh issue close`. This breaks the audit
trail — there’s no linked diff showing what changed.

- `Fixes #N` or `Closes #N` — auto-closes and links the commit to the
  issue
- `Relates to #N` — partial progress, does not close
- Always close issues when work is complete. Don’t leave stale open
  issues.

## Commit Quality

Write clear, informative commit messages:

    Brief description (50 chars or less)

    Detailed explanation of changes and impact.

    Fixes #<issue> (or Relates to #<issue>)

    Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

**When to commit:** - Logical, atomic units of work - Working state
(tests pass) - Clear description of changes

**What to avoid:** - “WIP” or “temp” commits in main branch - Combining
unrelated changes - Vague messages like “fixes” or “updates”

## LLM Agent Conventions

Rules learned from real project sessions. These apply across all repos.

- **Install missing packages, don’t workaround** — if a package is
  needed, ask the user to install it (e.g. `pak::pak("pkg")`). Don’t
  write degraded fallback code to avoid the dependency.
- **Never hardcode extractable data** — if coordinates, station names,
  or metadata can be pulled from an API or database at runtime, do that.
  Don’t hardcode values that have a programmatic source.
- **Close issues via commits, not `gh issue close`** — see Closing
  Issues above.
- **Cite primary sources** — see references conventions.

## Naming Conventions

**Pattern: `noun_verb-detail`** – noun first, verb second across all
naming:

| What       | Example                                                  |
|------------|----------------------------------------------------------|
| Skills     | `claude-md-init`, `gh-issue-create`, `planning-update`   |
| Scripts    | `stac_register-baseline.sh`, `stac_register-pypgstac.sh` |
| Logs       | `20260209_stac_register-baseline_stac-dem-bc.txt`        |
| Log format | `yyyymmdd_noun_verb-detail_target.ext`                   |

Scripts and logs live together: `scripts/<module>/logs/`

### Which logs to commit

Logs are R&D evidence — but only the curated ones. Distinguish two
classes:

- **Evidence logs** (commit): the dated, conventionally-named runs at
  the top of a `logs/` dir (`yyyymmdd_noun_verb-detail_target.ext`). One
  benchmark/timing/run log per intentional run. These are committed to
  the **default branch** — git gives free versioning and
  commit-provenance (the log sits next to the change that produced it),
  and committed logs are discoverable cross-machine via the GitHub API
  without cloning.
- **Bulk run-output** (gitignore): archives, per-shard/per-watershed
  dumps, aborted/offline reruns, and other machine-generated iteration
  output. Put these under a gitignored subdir (e.g. `logs/runs/`,
  `logs/archive/`) so they never bloat the repo.

Rules of thumb: if you’d hand it to an auditor as proof of an
experiment, commit it. If it’s hundreds of files a pipeline emitted,
gitignore it. Don’t reach for S3 for text logs — git is the right home;
external object storage only earns its place for large binaries. Logs
that aren’t committed to the default branch are invisible to other
machines and to evidence tooling — so commit evidence logs **before**
moving machines, or it’s stranded.

## Projects vs Milestones

- **Projects** = daily cross-repo tracking (always add to relevant
  project)
- **Milestones** = iteration boundaries (only for release/claim prep)
- Don’t double-track unless there’s a reason

| Content | Project |
|----|----|
| R&D, experiments, SRED-related | **SRED R&D Tracking (#8)** |
| Data storage, sqlite, postgres, pipelines | **Data Architecture (#9)** |
| Fish passage field/reporting | **Fish Passage 2025 (#6)** |
| Restoration planning | **Aquatic Restoration Planning (#5)** |
| QGIS, Mergin, field forms | **Collaborative GIS (#3)** |

# Planning Conventions

How Claude manages structured planning for complex tasks using
planning-with-files (PWF).

## When to Plan

Use PWF when a task has multiple phases, requires research, or involves
more than ~5 tool calls. Triggers: - User says “let’s plan this”, “plan
mode”, “use planning”, or invokes `/planning-init` - Complex issue work
begins (multi-step, uncertain approach) - Claude judges the task
warrants structured tracking

Skip planning for single-file edits, quick fixes, or tasks with obvious
next steps.

## The Workflow

1.  **Explore first** — Enter plan mode (read-only). Read code, trace
    paths, understand the problem before proposing anything.
2.  **Plan to files** — Write the plan into 3 files in
    `planning/active/`:
    - `task_plan.md` — Phases with checkbox tasks
    - `findings.md` — Research, discoveries, technical analysis
    - `progress.md` — Session log with timestamps and commit refs
3.  **Plan-review with the Plan agent before committing the plan** —
    After scaffolding `task_plan.md` but BEFORE the baseline commit,
    spawn the Plan subagent
    (`Agent({subagent_type: "Plan", prompt: "..."}`) and ask it to
    critically review the task_plan against the issue body + actual
    codebase. Categorize findings as Blocker / Gap / Ordering /
    Assumption / Scope / Acceptance. Address each before committing. The
    agent reads files fresh — it catches what you miss when you’ve been
    thinking about the design too long. Real example: caught 21 issues
    including hardcoded literals across 4 files not listed in the plan,
    untested DB column mismatches, unfixable test-literal-string
    assertions, and a baseline-cache-shadow that would have produced a
    6-second no-op run. Cost: ~5 min agent. Saves: hours of
    mid-implementation rework.
4.  **Commit the plan** — After Plan-agent review + fixes. This is the
    baseline.
5.  **Work in atomic commits** — Each commit bundles code changes WITH
    checkbox updates in the planning files. The diff shows both what was
    done and the checkbox marking it done.
6.  **Code check before commit** — Run `/code-check` on staged diffs
    before committing. Don’t mark a task done until the diff passes
    review.
7.  **Archive when complete** — Move `planning/active/` to
    `planning/archive/` via `/planning-archive`. Write a README.md in
    the archive directory with a one-paragraph outcome summary and
    closing commit/PR ref — future sessions scan these to catch up fast.

## Atomic Commits (Critical)

Every commit that completes a planned task MUST include: - The
code/script changes - The checkbox update in `task_plan.md` (`- [ ]` -\>
`- [x]`) - A progress entry in `progress.md` if meaningful

This creates a git audit trail where `git log -- planning/` tells the
full story. Each commit is self-documenting — you can backtrack with git
and understand everything that happened.

## File Formats

### task_plan.md

Phases with checkboxes. This is the core tracking file.

``` markdown
# Task Plan

## Phase 1: [Name]
- [ ] Task description
- [ ] Another task

## Phase 2: [Name]
- [ ] Task description
```

Mark tasks done as they’re completed: `- [x] Task description`

### findings.md

Append-only research log. Discoveries, technical analysis, things
learned.

``` markdown
# Findings

## [Topic]
[What was found, with source/date]
```

### progress.md

Session entries with commit references.

``` markdown
# Progress

## Session YYYY-MM-DD
- Completed: [items]
- Commits: [refs]
- Next: [items]
```

## Directory Structure

    planning/
      active/          <- Current work (3 PWF files)
      archive/         <- Completed issues
        YYYY-MM-issue-N-slug/

If `planning/` doesn’t exist in the repo, run `/planning-init` first.

## Skills

| Skill               | When to use                                        |
|---------------------|----------------------------------------------------|
| `/planning-init`    | First time in a repo — creates directory structure |
| `/planning-update`  | Mid-session — sync checkboxes and progress         |
| `/planning-archive` | Issue complete — archive and create fresh active/  |

# R Package Development Conventions

Standards for R package development across New Graph Environment
repositories. Based on [R Packages (2e)](https://r-pkgs.org/) by Hadley
Wickham and Jenny Bryan.

**Reference packages:** When starting a new package, study these
existing packages for patterns: `flooded`, `gq`. They demonstrate the
conventions below in practice (DESCRIPTION fields, README layout,
NEWS.md style, pkgdown setup, test structure, hex sticker, etc.).

## Style

- tidyverse style guide: snake_case, pipe operators (`|>` or `%>%`)

- Match existing patterns in each codebase

- Use `pak` for package installation (not `install.packages`)

- Prefix column name vectors with `cols_` for discoverability in the
  environment pane: `cols_all`, `cols_carry`, `cols_split`,
  `cols_writable`. Same principle for other grouped vectors (`params_`,
  `tbl_`, etc.)

- For SQL DDL+INSERT pairs that share a schema, use a single named
  vector as the source of truth. Both `CREATE TABLE` and
  `INSERT (cols) SELECT cols` derive their column lists from the same
  `cols_*` vector. Avoids drift between table shape and write projection
  — when columns change, you edit one place. Example:

  ``` r

  cols_streams <- c(
    id_segment           = "integer NOT NULL",
    watershed_group_code = "varchar(4) NOT NULL",
    geom                 = "geometry(MultiLineStringZM, 3005)"
    # …
  )
  # CREATE TABLE consumes both names + types
  ddl_body <- paste(names(cols_streams), unname(cols_streams), sep = " ",
                    collapse = ", ")
  # INSERT consumes names only
  proj <- paste(names(cols_streams), collapse = ", ")
  ```

## Package Structure

Follow R Packages (2e) conventions: - `R/` for functions,
`tests/testthat/` for tests, `man/` for docs - `DESCRIPTION` with proper
fields (Title, Description, <Authors@R>) - `DESCRIPTION` URL field:
include both the GitHub repo and the pkgdown site so pkgdown links
correctly (e.g.,
`URL: https://github.com/OWNER/PKG, https://owner.github.io/PKG/`) -
`NAMESPACE` managed by roxygen2 (`#' @export`, `#' @import`,
`#' @importFrom`) - Never edit `NAMESPACE` or `man/` by hand

## One Function, One File

Each exported function gets its own R file and its own test file: -
`R/fl_mask.R` → `tests/testthat/test-fl_mask.R` - Commit the function
and its tests together - Use `Fixes #N` in the commit message to close
the corresponding issue

## GitHub Issues and SRED Tracking

### Issue-per-function workflow

File a GitHub issue for each function before building it. This creates a
traceable record of what was planned, built, and verified.

### Branching for SRED

For new packages or major features, work on a branch and merge via PR:

    main ← scaffold-branch (PR closes with "Relates to NewGraphEnvironment/sred#N")

This gives one PR that contains all commits — a single SRED
cross-reference covers the entire body of work. Individual commits
within the branch close their respective function issues with
`Fixes #N`.

### Closing issues

Close function issues via commit messages — see Closing Issues in
newgraph conventions.

## Testing

- Use testthat 3e (`Config/testthat/edition: 3` in DESCRIPTION)

- Run `devtools::test()` before committing

- Test files mirror source: `R/utils.R` -\>
  `tests/testthat/test-utils.R`

- Test for edge cases and potential failures, not just happy paths

- Tests must pass before closing the function’s issue

- Always grep for errors in the same command as the test run to avoid
  running twice:

  ``` bash
  Rscript -e 'devtools::test()' 2>&1 | grep -E "(FAIL|ERROR|PASS)" | tail -5
  ```

  For error context: `grep -E "(ERROR:|FAIL )" -A 10 | head -25`

### Common pitfalls

- **[`cli::cli_alert_warning()`](https://cli.r-lib.org/reference/cli_alert.html)
  is not [`warning()`](https://rdrr.io/r/base/warning.html).** It’s
  visual only — callers can’t catch it with
  `withCallingHandlers(warning = ...)` and testthat’s `expect_warning()`
  won’t fire. When a function offers a `warn` mode that callers may want
  to react to programmatically, use
  [`warning()`](https://rdrr.io/r/base/warning.html). Reserve
  `cli_alert_warning()` for FYI messages with no programmatic contract.

- **`expect_match(x, ..., all = FALSE)` passes silently on
  `character(0)`.** If the input is empty (e.g. no warnings fired), the
  assertion succeeds vacuously and defeats the test. Always pair with
  `expect_gt(length(x), 0)` first when input may be empty.

## Examples and Vignettes

### Runnable examples on every exported function

Examples are how users discover what a function does. They must: -
**Actually run** — no `\dontrun{}` unless external resources are
required - **Use bundled test data** via
[`system.file()`](https://rdrr.io/r/base/system.file.html) so they work
for anyone - **Show why the function is useful** — not just that it
runs, but what it produces and why you’d use it - **Use qualified
names** for non-exported dependencies
([`terra::rast()`](https://rspatial.github.io/terra/reference/rast.html),
[`sf::st_read()`](https://r-spatial.github.io/sf/reference/st_read.html))
since examples run in the user’s environment

### Vignettes

At least one vignette showing the full pipeline on real data: -
Demonstrates the package solving an actual problem end-to-end - Uses
bundled test data (committed to `inst/testdata/`) - Hosted on pkgdown so
users can read it without installing

**Output format:** Use `bookdown::html_vignette2` (not
[`rmarkdown::html_vignette`](https://pkgs.rstudio.com/rmarkdown/reference/html_vignette.html))
for figure numbering. Requires `bookdown` in Suggests and chunks must
have `fig.cap` / `caption =` for numbered figures and tables.

**Gotcha — cross-references don’t resolve in vignettes.**
`Table \@ref(tab:foo)` and `Figure \@ref(fig:foo)` markers compile to a
literal `\@ref(...)` in the rendered HTML rather than a numbered link.
Bookdown’s cross-ref machinery isn’t fully wired through
`html_vignette2` under pkgdown. Use natural language instead — “the
table below”, “the floodplain map”, “the parameter table” — and let the
captions speak for themselves. If you need real numbered cross-refs, use
`bookdown::html_document2` (matches the cd-style report-appendix
pattern) and accept that the output is no longer a true package
vignette.

**Vignettes that need external resources (DB, API, STAC):** Do NOT use
the `.Rmd.orig` pre-knit pattern — it breaks `bookdown` figure numbering
because knitr evaluates chunks during pre-knit and emits `![](path)`
markdown that bookdown can’t number.

Instead, separate data generation from presentation: 1.
`data-raw/vignette_data.R` — runs the queries, saves results as `.rds`
to `inst/testdata/` (or `inst/vignette-data/`) 2. Vignette loads `.rds`
files, all chunks run live during pkgdown build 3. Note at top of
vignette: “Data generated by `data-raw/script.R`” 4. bookdown controls
all chunks — figure numbers, cross-refs work

This is the same pattern as test data: `data-raw/` documents how the
data was produced, committed artifacts make vignettes reproducible
without the external resource.

### Test data

- Created via a script in `data-raw/` that documents exactly how the
  data was produced (database queries, spatial crops, etc.)
- Committed to `inst/testdata/` — small enough to ship with the package
- Used by tests, examples, and vignettes — one dataset, three purposes

## Documentation

- roxygen2 for all exported functions
- `@import` or `@importFrom` in the package-level doc
  (`R/<pkg>-package.R`) to populate NAMESPACE — don’t rely on `::`
  everywhere in function bodies
- pkgdown site for public packages with `_pkgdown.yml` (bootstrap 5)
- GitHub Action for pkgdown (`usethis::use_github_action("pkgdown")`)

## lintr

Run `lintr::lint_package()` before committing R package code. Fix all
warnings — every lint should be worth fixing.

### Recommended .lintr config

``` r

linters: linters_with_defaults(
    line_length_linter(120),
    object_name_linter(styles = c("snake_case", "dotted.case")),
    commented_code_linter = NULL
  )
exclusions: list(
    "renv" = list(linters = "all")
  )
```

- 120 char line length (default 80 is too strict for data pipelines)
- Allow dotted.case (common in base R and legacy code)
- Suppress commented code lints (exploratory R scripts often have
  commented alternatives)
- Exclude renv directory entirely

## Dependencies

- Minimize Imports — use `Suggests` for packages only needed in
  tests/vignettes
- Pin versions only when breaking changes are known
- Prefer packages already in the tidyverse ecosystem

## Releasing

1.  Update `NEWS.md` — keep it concise:
    - First release: one line (e.g., “Initial release. Brief
      description.”)
    - Later releases: describe what changed and why, not
      function-by-function. Link to the pkgdown reference page for
      details — don’t duplicate it.
    - Don’t list every function; the pkgdown reference page is the
      single source of truth for what’s in the package.
2.  Bump version in `DESCRIPTION` (e.g., `0.0.0.9000` → `0.1.0`) — as
    the **final** commit of the branch, after verification numbers/tests
    are final. Mid-branch bumps are premature and churn: additional code
    changes end up bundled inside a “release” that already claimed the
    version.
3.  Commit as “Release vX.Y.Z”
4.  Tag: `git tag vX.Y.Z && git push && git push --tags`

## Repository Setup

### Branch protection

Protect main from deletion and force pushes:

``` bash
gh api repos/OWNER/REPO/rulesets --method POST --input - <<'EOF'
{
  "name": "Protect main",
  "target": "branch",
  "enforcement": "active",
  "bypass_actors": [
    { "actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "always" }
  ],
  "conditions": { "ref_name": { "include": ["refs/heads/main"], "exclude": [] } },
  "rules": [ { "type": "deletion" }, { "type": "non_fast_forward" } ]
}
EOF
```

### Scaffold checklist

- `usethis::create_package(".")`
- `usethis::use_mit_license("New Graph Environment Ltd.")`
- `usethis::use_testthat(edition = 3)`
- `usethis::use_pkgdown()`
- `usethis::use_github_action("pkgdown")`
- `usethis::use_directory("dev")` — reproducible setup script
- `usethis::use_directory("data-raw")` — data generation scripts
- Hex sticker via `hexSticker` (see `data-raw/make_hexsticker.R`)
- Set GitHub Pages to serve from `gh-pages` branch

### dev/dev.R

Keep a `dev/dev.R` file that documents every setup step. Not idempotent
— run interactively. This is the reproducible recipe for the package
scaffold.

## README

Keep the README lean: - Hex sticker, one-line description, install,
example showing *why* it’s useful - Link to pkgdown vignette and
function reference — don’t duplicate them - Don’t maintain a function
table — it’s just another thing to keep updated and pkgdown’s reference
page is the single source of truth

## LLM Workflow

When an LLM assistant modifies R package code: 1. Run
`lintr::lint_package()` — fix issues before committing 2. Run
`devtools::test()` with error grep — ensure tests pass in one call:
`bash Rscript -e 'devtools::test()' 2>&1 | grep -E "(FAIL|ERROR|PASS)" | tail -5`
3. Run `devtools::document()` and grep for results:
`bash Rscript -e 'devtools::document()' 2>&1 | grep -E "(Writing|Updating|warning)" | tail -10`
4. Check `devtools::check()` passes for releases — capture results in
one call:
`bash Rscript -e 'devtools::check()' 2>&1 | grep -E "(ERROR|WARNING|NOTE|errors|warnings|notes)" | tail -10`

# Reference Management Conventions

How references flow between Claude Code, Zotero, and technical writing
at New Graph Environment.

## Tool Routing

Three tools, different purposes. Use the right one.

| Need | Tool | Why |
|----|----|----|
| Search by keyword, read metadata/fulltext, semantic search | **MCP `zotero_*` tools** | pyzotero, works with Zotero item keys |
| Look up by citation key (e.g., `irvine2020ParsnipRiver`) | **`/zotero-lookup` skill** | Citation keys are a BBT feature — pyzotero can’t resolve them |
| Create items, attach PDFs, deduplicate | **`/zotero-api` skill** | Connector API for writes, JS console for attachments |

**Citation keys vs item keys:** Citation keys (like
`irvine2020ParsnipRiver`) come from Better BibTeX. Item keys (like
`K7WALMSY`) are native Zotero. The MCP works with item keys.
`/zotero-lookup` bridges citation keys to item data.

**BBT citation key storage:** As of Feb 2025+, BBT stores citation keys
as a `citationKey` field directly in `zotero.sqlite` (via Zotero’s item
data system), not in a separate BBT database. The old
`better-bibtex.sqlite` and `better-bibtex.migrated` files are stale and
no longer updated. Query citation keys with:
`SELECT idv.value FROM items i JOIN itemData id ON i.itemID = id.itemID JOIN itemDataValues idv ON id.valueID = idv.valueID JOIN fields f ON id.fieldID = f.fieldID WHERE f.fieldName = 'citationKey'`.

## Adding References Workflow

### 1. Search and flag

When research turns up a reference: - **DOI available:** Tell the user —
Zotero’s magic wand (DOI lookup) is the fastest path - **ResearchGate
link:** Flag to user for manual check — programmatic fetch is blocked
(403), but full text is often there - **BC gov report:** Search
[ACAT](https://a100.gov.bc.ca/pub/acat/), for.gov.bc.ca library, EIRS
viewer - **Paywalled:** Note it, move on. Don’t waste time trying to
bypass.

### 2. Add to Zotero

**Preferred order:** 1. DOI magic wand in Zotero UI (fastest, most
complete metadata) 2. Web API POST with `collections` array (grey
literature, local PDFs — targets collection directly, no UI interaction
needed) 3. `saveItems` via `/zotero-api` (batch creation from structured
data — requires UI collection selection) 4. JS console script for group
library (when connector can’t target the right collection)

**Collection targeting:** `saveItems` drops items into whatever
collection is selected in Zotero’s UI. Always confirm with the user
before calling it. **Web API bypasses this** — include
`"collections": ["KEY"]` in the POST body. Find collection keys with
`?q=name` search on the collections endpoint.

### 3. Attach PDFs

`saveItems` attachments silently fail. Don’t use them. Instead:

1.  **Web API S3 upload (preferred):** Create attachment item → get
    upload auth → build S3 body (Python: prefix + file bytes + suffix) →
    POST to S3 → register with uploadKey. Works without Zotero running.
    See `/zotero-api` skill section 4.
2.  **JS console fallback:** Download with `curl`, attach via
    `item_attach_pdf.js` in Zotero JS console.
3.  Verify attachment exists via MCP: `zotero_get_item_children`

### 4. Verify

After manual adds, confirm via MCP: - `zotero_search_items` — find by
title - `zotero_get_item_metadata` — check fields are complete -
`zotero_get_item_children` — confirm PDF attached

### 5. Clean up

If duplicates were created (common with `saveItems` retries): - Run
`collection_dedup.js` via Zotero JS console - It keeps the copy with the
most attachments, trashes the rest

## In Reports (bookdown)

### Bibliography generation

``` yaml
# index.Rmd — dynamic bib from Zotero via Better BibTeX
bibliography: "`r rbbt::bbt_write_bib('references.bib', overwrite = TRUE)`"
```

`rbbt` pulls from BBT, which syncs with Zotero. Edit references in
Zotero → rebuild report → bibliography updates.

**Library targeting:** rbbt must know which Zotero library to search.
This is set globally in `~/.Rprofile`:

``` r

# default library — NewGraphEnvironment group (libraryID 9, group 4733734)
options(rbbt.default.library_id = 9)
```

Without this option, rbbt searches only the personal library
(libraryID 1) and won’t find group library references. The library IDs
map to Zotero’s internal numbering — use `/zotero-lookup` with
`SELECT DISTINCT libraryID FROM citationkey` against the BBT database to
discover available libraries.

### Citation syntax

- `[@key2020]` — parenthetical: (Author 2020)
- `@key2020` — narrative: Author (2020)
- `[@key1; @key2]` — multiple
- `nocite:` in YAML — include uncited references

### Cite primary sources

When a review paper references an older study, trace back to the
original and cite it. Don’t attribute findings to the review when the
original exists. (See LLM Agent Conventions in `newgraph.md`.)

**When the original is unavailable** (paywalled, out of print, can’t
locate): use secondary citation format in the prose and include bib
entries for both sources:

> Smith et al. (2003; as cited in Doctor 2022) found that…

Both `@smith2003` and `@doctor2022` go in the `.bib` file. The reader
can then track down the original themselves. Flag incomplete metadata on
the primary entry — it’s better to have a partial reference than none at
all.

## PDF Fallback Chain

When you need a PDF and the obvious URL doesn’t work:

1.  DOI resolver → publisher site (often has OA link)
2.  Europe PMC
    (`europepmc.org/backend/ptpmcrender.fcgi?accid=PMC{ID}&blobtype=pdf`)
    — ncbi blocks curl
3.  SciELO — needs `User-Agent: Mozilla/5.0` header
4.  ResearchGate — flag to user for manual download
5.  Semantic Scholar — sometimes has OA links
6.  Ask user for institutional access

Always verify downloads: `file paper.pdf` should say “PDF document”, not
HTML.

## Searching Paper Content (ragnar)

### Setup (per project)

- `scripts/rag_build.R` — maps citation keys to Zotero PDF attachment
  keys, builds DuckDB
- `data/rag/` gitignored — store is local, not committed
- Dependencies: ragnar, Ollama with nomic-embed-text model
- See `/lit-search` skill for full recipe

### Query

`ragnar_store_connect()` then `ragnar_retrieve()` — returns chunks with
source file attribution.

### Anti-patterns

- NEVER write abstracts manually — if CrossRef has no abstract, leave
  blank
- NEVER cite specific numbers without verifying from the source PDF via
  ragnar search
- NEVER paraphrase equations — copy exact notation and cite page/section

# SRED Conventions

How SR&ED tracking integrates with New Graph Environment’s development
workflows.

## The Claim: One Project

All SRED-eligible work across NGE falls under a **single continuous
project**:

> **Dynamic GIS-based Data Processing and Reporting Framework**

- **Field:** Software Engineering (2.02.09)
- **Start date:** May 2022
- **Fiscal year:** May 1 – April 30
- **Consultant:** Boast Capital (prepares final technical report)

**Do not fragment work into separate claims.** Each fiscal year’s work
is structured as iterations within this one project. Internal tracking
(experiment numbers in `sred`) maps to iterations — Boast assembles the
final narrative.

## Tagging Work for SRED

### PRs (single enforcement point)

SRED cross-references (`Relates to NewGraphEnvironment/sred#N`) go in
**PR body templates only** — not in issue bodies, commit messages, or
any other surface. The `/gh-pr-push` skill is the single enforcement
point. PRs aggregate commits and are the merge unit, so per-issue and
per-commit SRED tags only add noise.

### Time entries (rolex)

Tag hours with `sred_ref` field linking to the relevant `sred` issue
number.

## What Qualifies as SRED

**Eligible (systematic investigation to overcome technological
uncertainty):** - Building tools/functions that don’t exist in standard
practice - Prototyping new integrations between systems (GIS ↔︎ reporting
↔︎ field collection) - Testing whether an approach works and documenting
why it did/didn’t - Iterating on failed approaches with new hypotheses

**Not eligible:** - Standard configuration of known tools - Routine bug
fixes in working systems - Writing reports using the framework (that’s
service delivery)

**The test:** “Did we try something we weren’t sure would work, and did
we learn something from the attempt?” If yes, it’s likely eligible.
