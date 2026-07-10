# Sources — Immutable Raw Layer

The **source-of-truth** layer of the wiki. Requirements, transcripts, external
references, research notes, spec dumps, and anything the wiki synthesizes *from*.

> **Immutable.** Agents **read** from these files but **never rewrite** them. If a
> source is updated upstream, add a new dated file rather than editing the old
> one. The synthesized understanding lives in the wiki pages, not here.

## Workflow (ingest)

1. Drop the raw material here (or link it, for large/binary sources).
2. Integrate it into the wiki: update [overview](../overview.md) if the big
   picture shifted, update the relevant topical page(s), and register new pages
   in [index.md](../index.md).
3. Append an `ingest` entry to [log.md](../log.md).

See [AGENTS.md → Project as an LLM Wiki](../../AGENTS.md#project-as-an-llm-wiki).

## Naming Convention

- `YYYY-MM-DD-<source>-<topic>.md` for dated captures (articles, transcripts,
  meeting notes) — e.g., `2026-07-10-user-interview-onboarding.md`.
- `<ref>.md` for stable references — e.g., `external-api-contract.md`.

## Index

| Document | Source | Date | Ingested? |
|----------|--------|------|-----------|
| _none yet_ | — | — | — |

## Related

- [Guidance](../guidance/README.md) — external expert consultations (also raw source)
- [Inbox](../inbox/README.md) — untriaged incoming requests
- [Wiki Index](../index.md)
- [Overview](../overview.md)
