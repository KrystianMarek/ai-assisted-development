# Plan: Migrate `doc/` into a Development-Focused LLM Wiki

Status: Planning
Date: 2026-07-10
Epic: `docs-llmwiki`

## Objective

Evolve this repository's `doc/` tree from a set of independent, category-siloed
folders into a **development-focused LLM Wiki** in the sense of Andrej Karpathy's
[LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f):
a persistent, compounding, interlinked knowledge base that both humans and agents
maintain, so the project's high-level idea, goals, progress, decisions,
considerations, bugs, and feature requests stay current and cross-referenced
instead of scattered.

## Cross-Reference: LLM Wiki concept vs. this repo

The LLM Wiki has **three layers** and **three operations**. Mapping to this repo:

| LLM Wiki layer | Karpathy's definition | This repo today | Gap |
|---|---|---|---|
| **Raw sources** | Immutable source of truth (articles, papers, data) | `doc/inbox/`, `doc/guidance/` partially | No explicit immutable sources area for requirements, transcripts, research |
| **The wiki** | LLM-generated interlinked markdown + index + log | `doc/*` subdirs each with a README index | No root overview/synthesis, no master index, no chronological log, weak interlinking |
| **The schema** | `AGENTS.md`/`CLAUDE.md` telling the LLM how to maintain the wiki | `AGENTS.md` (doc placement rules, bd, worktrees) | No ingest/query/lint workflows; schema describes placement, not maintenance |

| LLM Wiki operation | Karpathy's definition | This repo today | Gap |
|---|---|---|---|
| **Ingest** | Read a source, integrate it across pages, update index + log | Manual, per-doc; bd captures work items | No defined "read → file → update overview/index → log" flow |
| **Query** | Search index → drill into pages → answer w/ citations → file answer back | Ad hoc | Answers not filed back as compounding pages |
| **Lint** | Health-check: contradictions, stale claims, orphans, coverage gaps | None | No lint workflow/runbook |
| **index.md / log.md** | Content catalog + chronological append-only record | Per-subdir index tables; git/bd history | No aggregated `index.md`; no human-readable `log.md` timeline |

### What already aligns (keep)

- `AGENTS.md` as the schema layer (the "disciplined maintainer" config).
- Categorized `doc/` subdirs, each with a README, template, and index table.
- `bd` (beads) as the structured, dependency-aware tracker for discrete work
  items (bugs, features, tasks) - the wiki's narrative layer complements this,
  it does not replace it.

## Scope

**In scope:** additive wiki scaffolding on top of the existing `doc/` tree,
schema (`AGENTS.md`) additions for ingest/query/lint, a raw-sources layer, a
considerations surface, cross-linking discipline, a lint runbook, and README
updates.

**Out of scope:** deleting or renaming existing subdirs; adopting an
embedding/RAG search engine (the master index is sufficient at this scale;
revisit `qmd`-style tooling later); changing the `bd` workflow.

## Target structure

New root-level wiki files under `doc/`:

- `doc/overview.md` - synthesis / high-level idea "front page" (what, why, tech).
- `doc/index.md` - master content catalog aggregating every wiki page with a
  one-line summary, organized by category.
- `doc/log.md` - append-only chronological log; entries prefixed
  `## [YYYY-MM-DD] <type> | <title>` so `grep "^## \["` yields a timeline.
- `doc/goals.md` - long-horizon (north star) and short-horizon (current cycle) goals.
- `doc/status.md` - current progress snapshot (done / in-progress / blocked),
  cross-linked to `bd`.

New subdirectories:

- `doc/sources/` - immutable raw source layer (requirements, transcripts,
  external references, research notes). Read-only source of truth.
- `doc/considerations/` - open trade-offs, risks, and considerations not yet
  ADR-worthy.

Existing subdirs keep their role, reframed as wiki page types:
`vision/` (long-horizon ideas), `plans/` (short-horizon execution),
`decisions/` (design decisions / ADRs), `architecture/` (concept/entity pages),
`development/`, `runbooks/`, `benchmarks/`, `guidance/` (raw source),
`inbox/` (features requested / triage queue).

The user's requested tracking dimensions map as:

| Dimension | Home |
|---|---|
| High-level idea | `doc/overview.md` |
| Long / short horizon goals | `doc/goals.md` (+ `vision/`, `plans/`) |
| Current progress | `doc/status.md` (+ `bd status`) |
| Design decisions | `doc/decisions/` (ADRs) |
| Considerations | `doc/considerations/` |
| Bugs detected | `bd` (type=bug) + post-mortem docs in `development/` |
| Features requested | `doc/inbox/` |

## Schema (`AGENTS.md`) additions

Add a "Project as an LLM Wiki" section covering: the three layers mapped to this
repo, the ingest/query/lint operations adapted for development, the
`index.md`/`log.md` conventions, a cross-linking discipline (every page links
related pages; sweep for orphans), and the `bd` <-> wiki relationship (bd = discrete
work items; wiki = synthesized narrative; cross-link via ticket IDs in docs and
`--external-ref`/doc paths in tickets).

## Tasks

Tracked as `bd` tickets under epic `docs-llmwiki`:

- [ ] `docs-llmwiki-schema` - AGENTS.md wiki schema section + ingest/query/lint ops
- [ ] `docs-llmwiki-nav` - `doc/index.md` + `doc/log.md`
- [ ] `docs-llmwiki-overview` - `doc/overview.md`
- [ ] `docs-llmwiki-goals` - `doc/goals.md`
- [ ] `docs-llmwiki-status` - `doc/status.md`
- [ ] `docs-llmwiki-considerations` - `doc/considerations/`
- [ ] `docs-llmwiki-sources` - `doc/sources/`
- [ ] `docs-llmwiki-bugs` - bug-tracking convention (bd + post-mortem surface)
- [ ] `docs-llmwiki-lint` - wiki lint runbook/workflow
- [ ] `docs-llmwiki-crosslink` - retrofit existing READMEs + orphan sweep
- [ ] `docs-llmwiki-readme` - update root `README.md` to document the wiki model

## Dependencies

`docs-llmwiki-schema` is foundational and blocks the page-creation tickets.
`docs-llmwiki-lint` depends on `docs-llmwiki-nav`. `docs-llmwiki-crosslink` and
`docs-llmwiki-readme` depend on the page-creation tickets landing first.

## Success Criteria

- `doc/overview.md`, `doc/index.md`, `doc/log.md`, `doc/goals.md`,
  `doc/status.md` exist and are interlinked.
- `doc/sources/` and `doc/considerations/` exist with READMEs, naming, templates.
- `AGENTS.md` documents the wiki layers and ingest/query/lint operations.
- A lint runbook exists and a first lint pass reports no orphan pages.
- Root `README.md` describes the project as a development-focused LLM Wiki.
- `bd` epic `docs-llmwiki` and its child tickets exist and are linked.
