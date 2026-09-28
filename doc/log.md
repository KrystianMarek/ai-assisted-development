# Wiki Log

Chronological record of wiki and project activity. This page holds **no
entries** — it explains the format and lists the monthly files. Entries live in
`doc/log/YYYY-MM.md`, one file per month.

## Format

One line per event, **appended at the bottom** of the current month's file
(create the file if the month is new, starting with `# Log: YYYY-MM`):

```text
- YYYY-MM-DD <type> | <what happened> → <bd-id or page link>
```

- **Types:** `ingest`, `decision`, `progress`, `lint`.
- **One line, at most 240 characters.** The log is an index, not a narrative:
  the detail lives where the pointer goes.

  | Type | Detail lives in |
  |---|---|
  | `progress` | the `bd` issue — close reason, `bd note`, `--external-ref` for the MR/PR |
  | `decision` | an ADR in [decisions/](decisions/README.md), or a `bd` issue of type `decision` |
  | `ingest` | the dated page in [sources/](sources/README.md) (+ its README index row) |
  | `lint` | a `bd` chore for the sweep; findings in its close reason |

## Why this shape

Parallel agents each append to the log from their own worktree. A single
growing file edited at the same spot conflicts on nearly every merge. Monthly
files use git's `union` merge driver (see `.gitattributes`), which keeps both
sides' appended lines — safe **only** because each entry is a single line. The
`wiki-log-format` pre-commit hook rejects multi-line, over-long, or malformed
entries; `wiki-log-no-entries-in-index` rejects entries written here.

## Timeline

```shell
cat doc/log/*.md | grep '^- ' | tail -20      # recent activity
grep -h ' decision | ' doc/log/*.md           # all decisions
```

## Months

- [2026-09](log/2026-09.md)
- [2026-07](log/2026-07.md)

## Related

- [index.md](index.md) — page catalog · [status.md](status.md) — current state
- [AGENTS.md → Project as an LLM Wiki](../AGENTS.md#project-as-an-llm-wiki)
