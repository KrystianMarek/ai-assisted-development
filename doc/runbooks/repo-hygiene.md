# Repo Hygiene

## Purpose

Keep the repository free of the cruft that parallel agent work leaves behind:
worktrees outside `.worktrees/`, merged branches, surviving stashes, stray
untracked files, one-off `.gitignore` entries, stale `bd` claims, and an
`external/` index that no longer matches the clones on disk. None of these
break a build, which is why they accumulate — and each one misleads the next
agent that reads the repo.

## When to Use

- **Every session end** — the quick subset, as step 7 of *Landing the Plane*
  in [AGENTS.md](../../AGENTS.md#session-completion--landing-the-plane).
- **Weekly, and alongside every [wiki-lint](wiki-lint.md) pass** — the full run.
- **Whenever you notice cruft** — file a `bd` chore instead of stepping around it.

## Prerequisites

- A checkout of the repo (the script reports against the main checkout even
  when run from inside a worktree).
- `bd` with a reachable database for step 3.

## Procedure

### Step 1 — Run the report

```shell
scripts/repo-hygiene.sh --quick   # session end: worktrees, branches, stashes
scripts/repo-hygiene.sh           # full: + untracked files, .gitignore, external/
```

Expected output on a clean repo:

```text
repo hygiene: clean
```

The script is **read-only**. It prints one `FINDING [check] …` line per problem
and exits `1` if there are any.

### Step 2 — Fix each finding

| Check | Finding | Fix |
|---|---|---|
| `worktrees` | prunable (directory gone) | `git worktree prune` |
| `worktrees` | outside `.worktrees/` | finish or park the work, `bd worktree remove <path> --merged-into main` (or `--force` only after confirming nothing unmerged is lost), recreate as `bd worktree create .worktrees/<name> --branch <name>` |
| `worktrees` | branch has no commits beyond the default branch | merged or never used: `bd worktree remove .worktrees/<name> --merged-into main` then `git branch -d <name>` |
| `branches` | no commits beyond the default branch | `git branch -d <name>` |
| `branches` | tracks a deleted upstream | usually squash-merged: confirm the MR/PR landed, then `git branch -D <name>` (**destructive — confirm first**) |
| `stashes` | any entry | apply it to its branch and commit, or drop it once you have confirmed it is obsolete (**destructive — confirm first**) |
| `untracked` | untracked file | commit it, move scratch under `.worktrees/` or the system temp dir, or delete it |
| `gitignore` | entry matches nothing on disk | delete the line. If it guards a build artifact that only appears after a build, add the exact entry to `.repo-hygiene-allow` |
| `external` | clone not in the index | add its row to `external/README.md` (origin, ref, date, why, analysis page) or delete the clone |
| `external` | indexed but not cloned (info) | normal on a fresh checkout; re-clone only if you need it |

The `.gitignore` check is a heuristic: it only examines path-like literal
entries (`/x`, `x/`, `a/b`), and skips globs, negations, bare file names, and
dot-directories such as `.beads/` or `.dolt/`.

### Step 3 — Tracker hygiene (`bd`)

```shell
bd stale --days 14                 # issues not updated recently
bd list --status in_progress       # every one should have a live worktree/owner
bd reclaim --older-than 1h         # return EXPIRED leases (dead workers) to ready
bd doctor                          # installation + database health
```

`bd reclaim` acts immediately (there is no preview) and only on leases that
have already expired, so live agents are unaffected; never pass
`--any-replica` without `--id`. An `in_progress` issue whose worktree is gone is either finished (close it
with a reason) or abandoned (unclaim it with a handoff comment).

### Step 4 — Record the run

For the full run, append one line to the current month's log (see
[log.md](../log.md)):

```text
- YYYY-MM-DD lint | repo hygiene: <n> findings fixed, <m> filed → <bd-id>
```

Anything you could not fix in the session becomes a `bd` chore.

## Verification

`scripts/repo-hygiene.sh` exits `0`, and `git status` in the main checkout is
clean apart from work in progress that is committed on a branch.

## Rollback

The report changes nothing. Fixes are ordinary git operations: a deleted
branch can be restored from `git reflog` for as long as the reflog keeps it; a
dropped stash is recoverable only via `git fsck --unreachable` — hence the
confirm-first rule.

## Hard Rules

- **Worktrees live only under `.worktrees/`.** It is ignored once in
  `.gitignore`; nothing else is ever added for a worktree.
- **Never add one-off paths to `.gitignore`.** If a tool appends one (for
  example `bd worktree create` with a root-level name), remove it before
  committing.
- **Never delete unmerged work, stashes, or branches without confirmation.**
- **Never touch files inside `.beads/` or Dolt's data directories** as a
  cleanup step — use `bd doctor` / `bd` commands.

## Related

- [wiki-lint.md](wiki-lint.md) — the wiki's own health check (run together)
- [AGENTS.md → Repository Hygiene](../../AGENTS.md#repository-hygiene)
- [external/README.md](../../external/README.md) — reference-clone index
- [runbooks/README.md](README.md) — runbook index
