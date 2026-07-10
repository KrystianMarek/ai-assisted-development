# Wiki Lint

## Purpose

Periodic health-check of the `doc/` LLM Wiki. Catches the failure mode where the
wiki silently rots: stale status, contradictions, orphan pages, and gaps. Adapted
from the lint pass in Andrej Karpathy's
[LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).

## When to Use

- Before landing a large batch of changes (session completion).
- After ingesting several sources.
- On a regular cadence as the wiki grows.

## Prerequisites

- Repo checkout; ability to run `rg`/`grep` and `bd`.

## Procedure — run the checks in order

### 1. Freshness

Confirm [status.md](../status.md) reflects reality and [log.md](../log.md) has an
entry for recent work. Flag `status.md` if its "Last updated" date lags the newest
`log.md` entry.

```shell
grep "^## \[" ../doc/log.md | head -5
```

### 2. Contradictions & stale claims

Read [overview.md](../overview.md), [goals.md](../goals.md), and recently changed
pages. Flag statements that newer sources or decisions have superseded. Propose
fixes; do not silently rewrite settled history.

### 3. Orphan check

Every page must have at least one inbound link and be reachable from
[index.md](../index.md). List any page not referenced anywhere else.

```shell
# From repo root: list doc pages, then check each for inbound references.
for f in $(cd doc && ls *.md **/*.md 2>/dev/null); do
  base=$(basename "$f")
  n=$(rg -l --glob '!**/'"$base" "$base" doc | wc -l | tr -d ' ')
  [ "$n" -eq 0 ] && echo "ORPHAN: doc/$f"
done
```

### 4. Coverage gaps

Scan the wiki for tools, concepts, or decisions mentioned but lacking their own
page. List them; do not auto-create — flag for the next ingest or the user.

### 5. Index & log integrity

Confirm every page appears in [index.md](../index.md) and that `log.md` entries
use the `## [YYYY-MM-DD] <type> | <title>` prefix.

### 6. Ticket ↔ wiki consistency

Cross-check `bd` against the wiki: closed epics reflected in `status.md`, open
work surfaced, no plan in `doc/plans/` left `Active` for closed tickets.

```shell
bd ready --plain
bd status
```

## Verification

Produce a short report and **append it to [log.md](../log.md)** as a `lint` entry:

```markdown
## [YYYY-MM-DD] lint | Wiki health check

Overall: 🟢 Green | 🟡 Yellow | 🔴 Red
- Freshness: ...
- Contradictions: ...
- Orphans: ...
- Coverage gaps: ...
- Index/log integrity: ...
- Ticket/wiki consistency: ...
Next steps: <numbered; note which need user approval>
```

## Rollback

Lint is read-and-report by default; the only writes are the log entry and any
frontmatter/link fixes you explicitly make. Revert via git if needed.

## Hard Rules

- **Never delete pages unilaterally.** Flag orphans/duplicates; act only on approval.
- **Never rewrite raw sources** in [sources/](../sources/README.md).
- **Do** fix broken cross-links and register missing pages in `index.md`.

## Related

- [AGENTS.md → Project as an LLM Wiki](../../AGENTS.md#project-as-an-llm-wiki)
- [index.md](../index.md) · [log.md](../log.md) · [status.md](../status.md)
