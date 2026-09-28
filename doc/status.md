# Status

Current progress snapshot. This is the narrative complement to `bd status` —
refresh it whenever work state changes, and on every [wiki-lint](runbooks/wiki-lint.md)
pass. For the authoritative, live work queue, run `bd ready` and `bd status`.

_Last updated: 2026-09-28_

## At a glance

| Dimension | State |
|---|---|
| Release | `v0.0.1` tagged (template baseline) |
| Active epic | _none_ — log / `external/` / hygiene change complete (branch `feat/tmpl-hygiene`) |

## In progress

- _none_

## Done recently

- **Log, `external/`, repo hygiene** ([plan](plans/2026-09-28-log-external-hygiene.md)),
  from the odin adoption review: one-line monthly log files with union merge
  and format hooks; `external/` reference-clone scaffold; `.worktrees/` root,
  [repo-hygiene](runbooks/repo-hygiene.md) runbook + `scripts/repo-hygiene.sh`;
  `adopt.sh --diff` upgrade report; smoke test covers all of it.

- `v0.0.1` template baseline tagged and pushed.
- **LLM Wiki migration complete** (`ai-assisted-development-llmwiki`, 11/11):
  wiki schema in `AGENTS.md`; core pages `overview`/`index`/`log`/`goals`/`status`;
  new `sources/` and `considerations/`; `wiki-lint` runbook; cross-linked READMEs
  (orphan sweep clean); README refreshed.

## Blocked / waiting

- **`bd` database not usable on this machine:** `bd bootstrap` clones the
  remote Dolt data but refuses to auto-apply 34 schema migrations (v32 → v66)
  to a remote-backed database. Needs one designated migrator
  (`bd migrate --force && bd dolt push`). Until then no `bd` tickets exist
  for the plan's `tmpl-hygiene-*` tasks.

## Next up

- Run the first scheduled [wiki-lint](runbooks/wiki-lint.md) pass on the next
  batch of ingested sources.
- Upgrade odin to the new log / hygiene conventions (owner-driven; see
  [Upgrading an existing adoption](development/adopting-with-script.md#upgrading-an-existing-adoption)).

## How this page is maintained

Update on any status change and during lint passes. Keep it short — link to `bd`
for detail rather than duplicating ticket bodies. Reference ticket IDs so the
page stays cross-linked to the tracker.

## Related

- [goals.md](goals.md) — where we are headed
- [log.md](log.md) — chronological history
- [plans/](plans/README.md) — active plans
- [index.md](index.md) — full catalog
