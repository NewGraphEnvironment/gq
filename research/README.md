# research

What is now *known* — a settled method, a measured fact about an external system, an
established absence — kept so nobody re-derives it. Not a work log: the story of one
issue lives in `planning/archive/<issue>/`, and the numbers live with the run that
produced them.

Naming: `<topic>.md`, revised in place, from 2026-09-07. `git log --follow` is the
version record; each file carries its own provenance line under the H1.

| file | covers |
|---|---|
| [`rfp_layer_sourcing.md`](rfp_layer_sourcing.md) | How rfp resolves and fetches a project's layers, and what gq's `source_type` / `source_layer` columns actually drive. Why an unknown `source_type` is dropped silently, why `source_layer` is a three-repo coupling, and how to probe the `newgraph` bucket without credentials |

## Related work

- `rfp` (private) — the consumer; `inst/scripts/rfp_source_aws.sh` and
  `R/rfp_project_create.R` are the code the above describes
- `db_newgraph` (private) — `jobs/dump_weekly` is what stages the objects gq's `aws`
  rows name

`research/` is excluded from the tarball via `^research$` in `.Rbuildignore`. gq is a
**public** repo, so anything here is world-readable: report findings from client work
aggregated, never by the names of who it was for.
