# Wiki Index

Master catalog of every page in this development-focused LLM Wiki. Read this
first when answering a query, then drill into the relevant pages. Update it on
every ingest (see [AGENTS.md → Project as an LLM Wiki](../AGENTS.md#project-as-an-llm-wiki)).

Status: ✅ live · 🚧 stub / planned

## Core wiki pages

| Page | Summary | Status |
|---|---|---|
| [overview.md](overview.md) | High-level idea: what this project is, who uses it, headline tech | ✅ |
| [goals.md](goals.md) | Long-horizon (north star) and short-horizon (current cycle) goals | ✅ |
| [status.md](status.md) | Current progress snapshot, cross-linked to `bd` | ✅ |
| [log.md](log.md) | Append-only chronological log of ingests / decisions / progress / lint | ✅ |
| [index.md](index.md) | This catalog | ✅ |

## Raw sources (immutable)

| Area | Summary |
|---|---|
| [sources/](sources/README.md) | Requirements, transcripts, external references, research notes |
| [guidance/](guidance/README.md) | External expert consultations (requests + responses) |
| [inbox/](inbox/README.md) | Untriaged incoming feature requests |

## Knowledge & decisions

| Area | Summary |
|---|---|
| [architecture/](architecture/README.md) | System design, component / concept pages |
| [decisions/](decisions/README.md) | Architecture Decision Records (ADRs) |
| [considerations/](considerations/README.md) | Open trade-offs, risks, unresolved questions |
| [vision/](vision/README.md) | Exploratory product ideas and future concepts |

## Execution & operations

| Area | Summary |
|---|---|
| [plans/](plans/README.md) | Implementation plans and task tracking |
| [runbooks/](runbooks/README.md) | Operational procedures (incl. [wiki-lint](runbooks/wiki-lint.md)) |
| [development/](development/README.md) | Developer guides, setup, post-mortems |
| [benchmarks/](benchmarks/README.md) | E2E verification scenarios and benchmark runs |

## Related

- [AGENTS.md](../AGENTS.md) — the wiki schema (conventions + ingest/query/lint workflows)
- Discrete work items live in `bd`; run `bd ready` / `bd status`.
