# Architecture Decision Records (ADR)

This directory contains Architecture Decision Records for the project.

## What is an ADR?

An Architecture Decision Record documents an important architectural decision along with its context and consequences. ADRs help teams:

- Track the evolution of the system architecture
- Understand why decisions were made
- Onboard new team members
- Avoid revisiting settled debates

Reference: [Joel Parker Henderson — architecture-decision-record](https://github.com/joelparkerhenderson/architecture-decision-record)

---

## When to Create an ADR

| Situation | ADR Required |
|-----------|--------------|
| Change to service boundaries | Yes |
| New technology/framework selection | Yes |
| Deviation from documented architecture | Yes |
| Change to API contracts | Yes |
| Change to data ownership | Yes |
| Security architecture changes | Yes |
| Performance trade-offs | Yes |
| Bug fixes | No |
| Minor refactoring | No |
| Implementation details within a service | No |

---

## ADR Lifecycle

```
Proposed → Accepted → [Deprecated | Superseded]
```

| Status | Description |
|--------|-------------|
| **Proposed** | Under discussion, not yet approved |
| **Accepted** | Approved and in effect |
| **Deprecated** | No longer valid, but kept for history |
| **Superseded** | Replaced by a newer ADR |

---

## ADR Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| _none yet_ | — | — | — |

---

## ADR Template

```markdown
# ADR-NNNN: Title

## Status
Proposed | Accepted | Deprecated | Superseded by ADR-XXXX

## Date
YYYY-MM-DD

## Context
What is the issue motivating this decision?

## Decision
What change are we proposing/doing?

## Consequences

### Positive
- What becomes easier?

### Negative
- What becomes harder?

### Risks
- What new risks are introduced?

## Alternatives Considered
What other options were evaluated?

## References
- Related documentation links
```

---

## Creating a New ADR

1. Copy the template above.
2. Create file: `ADR-NNNN-short-title.md` (next sequential number).
3. Fill in all sections.
4. Submit for review.
5. Update this README index when accepted.
