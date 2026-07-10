# Overview

The synthesis front page of this wiki — the high-level idea, kept current as the
project evolves. Start here, then follow the links.

## What this is

**`ai-assisted-development`** is a project template for starting new repositories
that will be built collaboratively with AI coding agents (Claude Code, Codex,
OpenCode, Cursor, Aider, and others). Cloning it gives a new project the
documentation layout, issue-tracker wiring, quality gates, and agent
instructions already in place — no hand-copying from reference repos.

**Primary language / runtime:** shell + Markdown (language-agnostic template).
**Package manager:** n/a (the adopted project supplies its own).

## Who uses it

- **Humans** adopting the template into a new or existing repo, and later reading
  the wiki to understand project state.
- **AI agents** that read `AGENTS.md` to behave as disciplined contributors and
  wiki maintainers.

## The core idea

The template treats its own `doc/` tree as a **development-focused LLM Wiki**: a
persistent, compounding, interlinked knowledge base that agents keep current
instead of a pile of write-once files. Knowledge is compiled once and maintained,
not re-derived on every question. See
[AGENTS.md → Project as an LLM Wiki](../AGENTS.md#project-as-an-llm-wiki) for the
schema and the ingest/query/lint operations.

Three pillars back this up:

1. **`AGENTS.md`** — the single source of truth for agent behaviour (`CLAUDE.md`
   is a symlink). It is the wiki *schema*.
2. **`bd` (beads)** — a dependency-aware, AI-native issue tracker for discrete
   work items (bugs, features, tasks), stored in a Dolt database.
3. **Pre-commit quality gates** — enforce the *"work is not complete until
   `git push` succeeds"* rule.

## How the wiki is organized

- **Idea & direction:** this page, plus [goals](goals.md) and [vision](vision/README.md).
- **Current state:** [status](status.md) (cross-linked to `bd`).
- **Decisions & considerations:** [decisions](decisions/README.md) (settled) and
  [considerations](considerations/README.md) (open).
- **Raw sources:** [sources](sources/README.md), [guidance](guidance/README.md),
  [inbox](inbox/README.md).
- **Navigation:** [index](index.md) (catalog) and [log](log.md) (timeline).

## Related

- [goals.md](goals.md) — where the project is headed
- [status.md](status.md) — where it is now
- [index.md](index.md) — full page catalog
- [../README.md](../README.md) — adoption instructions
- [../AGENTS.md](../AGENTS.md) — agent + wiki conventions
