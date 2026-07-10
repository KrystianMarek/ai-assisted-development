# Wiki Log

Append-only chronological record of wiki activity. **Newest entries at the top.**

Each entry starts with a consistent prefix so the log is greppable:

```
## [YYYY-MM-DD] <type> | <title>
```

Types: `ingest` (new source integrated), `decision` (an ADR or choice landed),
`progress` (work status changed), `lint` (health-check pass).

Quick timeline: `grep "^## \[" doc/log.md | head -10`

---

## [2026-07-10] progress | LLM Wiki migration complete

Epic `ai-assisted-development-llmwiki` closed (11/11 tickets). `doc/` is now a
development-focused LLM Wiki: `AGENTS.md` carries the wiki schema and
ingest/query/lint operations; core pages (`overview`, `index`, `log`, `goals`,
`status`) and new subdirs (`sources/`, `considerations/`) exist; a
[wiki-lint](runbooks/wiki-lint.md) runbook is in place; existing READMEs
cross-link to the wiki hub (orphan sweep clean); README documents the model.
Baseline before this work is tagged `v0.0.1`.

## [2026-07-10] progress | LLM Wiki migration underway

Migrating `doc/` into a development-focused LLM Wiki (Karpathy pattern). Added
the wiki schema to `AGENTS.md`, created `index.md` and `log.md`, and began
building the core pages. Tracked under `bd` epic
`ai-assisted-development-llmwiki`. Plan:
[plans/2026-07-10-llm-wiki-migration.md](plans/2026-07-10-llm-wiki-migration.md).
