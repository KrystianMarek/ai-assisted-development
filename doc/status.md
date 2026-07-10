# Status

Current progress snapshot. This is the narrative complement to `bd status` —
refresh it whenever work state changes, and on every [wiki-lint](runbooks/wiki-lint.md)
pass. For the authoritative, live work queue, run `bd ready` and `bd status`.

_Last updated: 2026-07-10_

## At a glance

| Dimension | State |
|---|---|
| Release | `v0.0.1` tagged (template baseline) |
| Active epic | _none_ — LLM Wiki migration complete |

## In progress

- _none_

## Done recently

- `v0.0.1` template baseline tagged and pushed.
- **LLM Wiki migration complete** (`ai-assisted-development-llmwiki`, 11/11):
  wiki schema in `AGENTS.md`; core pages `overview`/`index`/`log`/`goals`/`status`;
  new `sources/` and `considerations/`; `wiki-lint` runbook; cross-linked READMEs
  (orphan sweep clean); README refreshed.

## Blocked / waiting

- _none_

## Next up

- Run the first scheduled [wiki-lint](runbooks/wiki-lint.md) pass on the next
  batch of ingested sources.

## How this page is maintained

Update on any status change and during lint passes. Keep it short — link to `bd`
for detail rather than duplicating ticket bodies. Reference ticket IDs so the
page stays cross-linked to the tracker.

## Related

- [goals.md](goals.md) — where we are headed
- [log.md](log.md) — chronological history
- [plans/](plans/README.md) — active plans
- [index.md](index.md) — full catalog
