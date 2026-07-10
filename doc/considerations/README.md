# Considerations

Open trade-offs, risks, and unresolved questions that are **not yet ADR-worthy**.
This is the thinking space that precedes a decision.

- When a consideration is settled, promote it to an [ADR](../decisions/README.md)
  and link back here.
- When it needs execution, file a `bd` ticket and/or a [plan](../plans/README.md).
- If it turns out not to matter, note the resolution and archive it.

## Naming Convention

`<topic>.md` — descriptive kebab-case (e.g., `search-engine-vs-flat-index.md`,
`monorepo-vs-split-sources.md`).

## Index

| Document | Summary | Status |
|----------|---------|--------|
| _none yet_ | — | — |

Status vocabulary: `Open` → `Leaning` → `Resolved (→ ADR-NNNN)` / `Dropped`.

## Document Template

```markdown
# Consideration: <Topic>

## Context
What situation raises this? Why does it matter now?

## Options
- **Option A** — description
- **Option B** — description

## Trade-offs
Pros/cons per option; what we gain and give up.

## Leaning
Current inclination and why (may be "undecided").

## Open Questions
- Unknowns blocking a decision

## Related
- Links to sources, decisions, plans, goals
```

## Related

- [Architecture Decisions](../decisions/README.md) — where settled considerations land
- [Vision & Ideas](../vision/README.md)
- [Implementation Plans](../plans/README.md)
- [Wiki Index](../index.md)
