# Plan: Conflict-free log, `external/` scaffold, repo hygiene

Status: Complete

## Objective

Fold three lessons from the first long-running adopter (`odin`, ~6 weeks,
1,094 commits, 574 `bd` issues, ~210 wiki pages) back into the template:

1. **`doc/log.md` is a merge hotspot.** 166 commits touch it; every parallel
   worktree edits the same spot, so concurrent agents conflict constantly. It
   has also grown to 181 KB (~45k tokens, median entry 827 chars) and mostly
   duplicates `bd` close reasons.
2. **`external/` is a useful pattern the template lacks** — read-only reference
   clones of similar / integrated projects, each paired with an analysis page
   in `doc/sources/`. odin's version drifted (unindexed clones, no recorded
   origin/commit, stale `AGENTS.md` list, not reproducible on a fresh checkout).
3. **Repo cruft accumulates with no maintenance duty.** odin's root
   `.gitignore` carries 11 one-off worktree/scratch paths whose directories no
   longer exist; `bd worktree create <name>` appends `./<name>` to `.gitignore`
   automatically, so every root-level worktree leaves a permanent line behind.
   Merged branches are not deleted (4 of 7 local branches in odin).

## Scope

**In:** template files (`AGENTS.md`, `.gitignore`, `.gitattributes`,
`.pre-commit-config.yaml`, `doc/log*`, `doc/runbooks/`, `external/`),
`adopt.sh` placeholders/exclusions, `test/smoke-adopt.sh`, README, and a
migration note for existing adopters.

**Out:** changing odin itself (odin's owner migrates using the note this plan
produces); `doc/index.md` scaling (116 of 208 odin pages unlisted — separate
follow-up); CI for the template.

## Design

### 1. Log: one line per event, monthly files, union merge

- `doc/log.md` stays the fixed entry point but holds **no entries**: purpose,
  format, the conflict rule, and a list of month files.
- Entries live in `doc/log/YYYY-MM.md`, **appended at the bottom** (true
  append-only, chronological). A new month means a new file — no rollover step.
- Entry format, one line, ≤ 200 chars, detail lives elsewhere:
  `- YYYY-MM-DD <type> | <title> → <bd-id | page link>`
  Types unchanged: `ingest`, `decision`, `progress`, `lint`.
- Where detail goes instead of the log:

  | Type | Detail lives in |
  |---|---|
  | `progress` | `bd` issue: close reason / `bd note`; commit/MR via `bd provenance` or `--external-ref` |
  | `decision` | ADR in `doc/decisions/` (significant) or `bd` issue of type `decision` (small) |
  | `ingest` | the dated page in `doc/sources/` (+ its README index row) |
  | `lint` | a `bd` chore per sweep; findings in its close reason |

- **Conflict elimination:** `.gitattributes` sets
  `doc/log/*.md merge=union`. With one-line entries, git's built-in union
  driver keeps both sides' appended lines instead of conflicting. This only
  works *because* entries are single lines — hence enforcement below.
- **Enforcement (machine-checked, not just lint):** a `repo: local` pre-commit
  hook (`language: pygrep`, `files: ^doc/log/\d{4}-\d{2}\.md$`) rejects any
  line that is not the month heading, blank, or a well-formed entry within the
  length cap. `wiki-lint` step 5 is updated to match.
- Timeline query becomes: `cat doc/log/*.md | grep '^- ' | tail -20`.

### 2. `external/` scaffold

- Ship `external/.gitignore` (`*`, `!.gitignore`, `!readme.md`) — self-contained;
  no duplicate rule in the root `.gitignore`.
- Ship `external/readme.md`: rules (read-only, never a dependency, never
  vendored/copied, never committed) and an index table with columns
  **Directory · Origin URL · Ref (commit/tag) · Cloned · Why · Analysis page**.
  The table is the manifest that makes a fresh checkout reproducible.
- `AGENTS.md`: short `external/` section pointing at `external/readme.md`
  (never enumerating clones inline); every clone gets a
  `doc/sources/YYYY-MM-DD-<repo>-analysis.md`. Note it as the one sanctioned
  non-`doc/` markdown file.
- `wiki-lint`: new check — `ls external/` vs the index table, and every row has
  origin + ref + analysis link.

### 3. Repo hygiene duty

- **Hard rules in `AGENTS.md`** (new "Repository Hygiene" section):
  - Worktrees live **only** under `.worktrees/` (pre-ignored in the template
    `.gitignore`): `bd worktree create .worktrees/<name> --branch <name>`.
  - Never add one-off paths to `.gitignore`. Scratch goes under `.worktrees/`
    or the system temp dir. If a tool appends an entry, remove it before
    committing.
  - Anyone who finds cruft files a `bd` chore rather than ignoring it.
- **New runbook `doc/runbooks/repo-hygiene.md`**, read-and-report first, then
  fix with approval for anything destructive. Checks:
  1. Worktrees: `git worktree list`, `bd worktree list`, `git worktree prune`;
     any worktree outside `.worktrees/`, or whose branch is merged.
  2. Branches: merged local branches, `[gone]` upstreams after
     `git fetch --prune`.
  3. Stashes: `git stash list` (none should survive a session).
  4. Stray top-level entries: untracked/ignored paths not in an allowlist.
  5. `.gitignore` cruft: literal path entries that match nothing on disk.
  6. `bd`: `bd stale`, stale leases (`bd reclaim`), `in_progress` with no
     live worktree, `bd doctor`.
  7. `external/` index drift (shared with wiki-lint).
- **Cadence:** a quick subset (1–3) in *Landing the Plane* step 7; the full
  runbook weekly and alongside every wiki-lint pass; result logged as a one-line
  `lint` entry → `bd` chore.
- **Helper script** `scripts/repo-hygiene.sh` (read-only report, non-zero exit
  on findings, shellchecked) so agents run one command instead of transcribing
  the runbook. Shipped to adopters.

## Tasks

`bd` tickets are created on approval (this repo first needs `bd bootstrap`;
no local `.beads/` exists yet). Epic `tmpl-hygiene`.

- [ ] `tmpl-hygiene-log` — `doc/log.md` entry-point rewrite, `doc/log/` month
      files, migrate this repo's two entries, `.gitattributes` union merge,
      pygrep hook, `adopt.sh` placeholder + exclusions, AGENTS.md wiki section,
      wiki-lint step 5.
- [ ] `tmpl-hygiene-external` — `external/.gitignore` + `readme.md`, AGENTS.md
      section, wiki-lint check.
- [ ] `tmpl-hygiene-repo` — AGENTS.md hygiene rules + Landing-the-Plane step 7,
      `.worktrees/` in `.gitignore`, runbook, `scripts/repo-hygiene.sh`;
      verify how `bd worktree create .worktrees/<name>` touches `.gitignore`.
- [ ] `tmpl-hygiene-smoke` — smoke-test coverage (below).
- [ ] `tmpl-hygiene-upgrade` — upgrade path for **existing** adopters.
      `adopt.sh` ships every tracked, non-excluded file via `git archive HEAD`,
      so new files (runbook, script, `external/`, `.gitattributes`, month file)
      reach a re-run target automatically. But files the target already has —
      `AGENTS.md`, `.gitignore`, `.pre-commit-config.yaml`,
      `doc/runbooks/README.md`, `doc/runbooks/wiki-lint.md` — are skipped, and
      `--force` overwrites *all* of them, wiping project-specific `AGENTS.md`
      content. Add a report of template files that differ from the target
      (e.g. `adopt.sh --diff`), plus a per-file merge checklist in the
      migration note, so adopters pull the rule changes without clobbering.
- [ ] `tmpl-hygiene-docs` — README, `doc/development/adopting-with-script.md`,
      runbooks/plans indexes, migration note for existing adopters (freeze old
      `log.md` as `doc/log/archive-pre-YYYY-MM.md`, start month files).

## Acceptance (machine-checkable)

- Smoke test: two branches each append a line to the same month file →
  `git merge` succeeds with no conflict and both lines present.
- Smoke test: a multi-line / over-cap / malformed entry → pre-commit hook fails.
- Smoke test: adopted target gets `external/.gitignore`, `external/readme.md`,
  `.gitattributes`, `doc/log.md` (entry point), a month file, the hygiene
  runbook (listed in the target's `doc/runbooks/README.md`) and script;
  template's own log entries NOT leaked.
- Smoke test: re-running `adopt.sh` on a target adopted *before* this change
  adds the new files without touching its `AGENTS.md`, and the diff report
  lists `AGENTS.md`, `.gitignore`, `.pre-commit-config.yaml`,
  `doc/runbooks/README.md`, and `doc/runbooks/wiki-lint.md` as differing.
- `scripts/repo-hygiene.sh` exits 0 on a clean adopted repo and non-zero after
  planting a stray dir, a stash, and a dead `.gitignore` path.
- `pre-commit run --all-files` green.

## Risks

- **Server-side merges may ignore `merge=union`.** Forge "merge"/"rebase"
  buttons may not honour `.gitattributes` drivers. Mitigation: the fleet
  rebases locally before push (where the driver applies); to verify on GitHub
  and GitLab during implementation and record the result in the runbook.
- **Union merge interleaves lines** — acceptable, since each line is dated; the
  lint sorts nothing and never rewrites history.
- **Lost narrative** — mitigated by pointing every entry at its `bd` issue or
  page; `bd` data is itself pushed via `bd dolt push`.

## Related

- [plans/README.md](README.md) · [status.md](../status.md) · [log.md](../log.md)
- [runbooks/wiki-lint.md](../runbooks/wiki-lint.md)
- [development/adopting-with-script.md](../development/adopting-with-script.md)
