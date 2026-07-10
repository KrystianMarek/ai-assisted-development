# Goals

Long-horizon (north star) and short-horizon (current cycle) goals. Keep this
current: when a goal is met, move it to "Achieved"; when direction changes,
revise it and note the change in [log.md](log.md).

## North star (long horizon)

The durable direction — rarely changes.

- **Zero-friction adoption.** Any repo can become fully agent-ready (docs, issue
  tracking, quality gates, conventions) with a single command and minimal manual
  follow-up.
- **Agents as disciplined maintainers.** `AGENTS.md` makes any agent behave as a
  consistent contributor and wiki maintainer, not a generic chatbot.
- **A compounding knowledge base.** The `doc/` wiki gets richer with every source
  and decision, so project context is never lost between sessions or agents.

## Current cycle (short horizon)

Concrete goals for the active cycle. Cross-link to [plans](plans/README.md) and
`bd` (`ai-assisted-development-llmwiki`).

- [ ] Complete the LLM Wiki migration (epic `ai-assisted-development-llmwiki`):
      overview/index/log/goals/status, `sources/` + `considerations/`, lint
      runbook, cross-linking, README refresh.
- [ ] First clean `wiki-lint` pass with no orphan pages.

## Achieved

- [x] Template baseline tagged `v0.0.1` (docs tree, `AGENTS.md`, `bd` wiring,
      pre-commit gates, `adopt.sh`).

## Adding / retiring a goal

1. Add it under the right horizon with a one-line rationale.
2. If it implies work, create a `bd` ticket and link it here.
3. On completion, move it to **Achieved**; on a direction change, revise and log
   the change in [log.md](log.md).

## Related

- [overview.md](overview.md) — the high-level idea
- [status.md](status.md) — current progress
- [vision/](vision/README.md) — exploratory ideas not yet committed
- [plans/](plans/README.md) — how goals get executed
