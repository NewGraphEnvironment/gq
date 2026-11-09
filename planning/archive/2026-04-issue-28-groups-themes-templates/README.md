## Outcome

Added the composition layer to the registry: `groups.csv`, `templates.csv` and
`themes.csv` in `inst/registry/`, read by `gq_groups()`, `gq_group_layers()`,
`gq_templates()`, `gq_template_groups()`, `gq_template_layers()` and `gq_themes()`.
Styles stayed in JSON and composition went into CSV. `groups.csv` mapped all 53 registry
keys, because an unmapped key has nowhere to be found from. Landed in 3cee619 and merged
in PR #29 (e9f93d8), closing #28 on 2026-04-12.

These files sat untracked in `planning/active/` from April until 2026-11-09, when they
were archived before planning #102. The archive was never run at merge time. The theme
schema has changed since then: `gq_theme_groups()` became the per-layer
`gq_theme_layers()` keyed by template (#46, ffb671c). Read these files as the April design,
not the current one.
