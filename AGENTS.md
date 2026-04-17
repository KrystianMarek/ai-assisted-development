# AGENTS.md

This file provides guidance to any agent working in this repository — Claude Code, Codex, OpenCode, Cursor, Aider, and others.

> `AGENTS.md` is the canonical source. `CLAUDE.md` is a symbolic link to this file so Claude Code reads the same instructions. Edits to either path land in the same content — prefer editing `AGENTS.md` directly.

---

## ⏱️ Project Initialization Checklist — REMOVE THIS SECTION AFTER COMPLETION

This section is **temporal**: it runs once, when the project is first cloned or scaffolded from this template. Work through it with the user, tick each box, and **delete this whole section from AGENTS.md** when finished so it does not nag every subsequent session.

### 1. Install git pre-commit hooks

The rule *"Work is NOT complete until `git push` succeeds"* (see Session Completion below) relies on local hooks that catch lint/format/test failures **before** a commit is created. Without hooks, broken code reaches the remote and the rule becomes aspirational.

**Action:**

- [ ] Confirm `pre-commit` is available:
  ```bash
  pre-commit --version || pip install pre-commit   # or: uv tool install pre-commit
  ```
- [ ] Create `.pre-commit-config.yaml` with at minimum:
  - `trailing-whitespace`, `end-of-file-fixer`, `check-merge-conflict`, `check-yaml`
  - a language-appropriate linter (`ruff` for Python, `golangci-lint` for Go, `eslint`/`biome` for JS/TS, etc.)
  - **Pin revisions to the latest at adoption time.** The template ships reasonable defaults but they may be months behind — check each repo for the current tag.
- [ ] Register the hook: `pre-commit install`
- [ ] Verify it fires: `pre-commit run --all-files`

If the user prefers another runner (`prek`, `husky`, `lefthook`), swap it in — but keep the guarantee: **no commit lands without passing lint/format checks.**

> **Adopting into an existing codebase?** The first `pre-commit run --all-files` will likely find pre-existing lint violations (trailing whitespace, formatting, etc.). This is expected. Fix them in a dedicated cleanup commit, or use `git commit --no-verify` for your initial adoption commit and address lint in a follow-up.

### 2. Install Dolt (database engine for bd)

`bd` stores issues in a [Dolt](https://docs.dolthub.com/) database — a version-controlled SQL database with git-like merge semantics. Dolt must be installed before `bd init`.

**Action:**

- [ ] Check if Dolt is already installed:
  ```bash
  dolt version
  ```
- [ ] If not installed:

  **Linux:**
  ```bash
  sudo bash -c 'curl -L https://github.com/dolthub/dolt/releases/latest/download/install.sh | sudo bash'
  ```

  **macOS:**
  ```bash
  brew install dolt
  ```

  Reference: <https://docs.dolthub.com/introduction/installation>

- [ ] Verify: `dolt version` should print the installed version.

### 3. Install and initialize `bd` (beads)

Issue tracking in this template is done with [`bd`](https://github.com/steveyegge/beads). It must be on `PATH` before any issues are created.

**Action:**

- [ ] Check for `bd`:
  ```bash
  command -v bd
  ```
- [ ] If the command is empty, **ask the user for permission to install**, then run:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash
  ```
  Reference: <https://github.com/steveyegge/beads>
- [ ] **Initialize the database** — choose the right command for your situation:

  **New project (no existing Dolt data in the git remote):**
  ```bash
  bd init
  ```
  This scaffolds `.beads/` (local only — `.beads/` is git-ignored by the template) and injects a BEADS-INTEGRATION comment block into this file.

  **Existing project (cloned from a repo that already has Dolt refs):**
  ```bash
  bd bootstrap
  ```
  This clones the existing Dolt database from the git remote. Use `bd bootstrap --dry-run` first to confirm the plan. After bootstrap, **restart the Dolt server** — it won't pick up the new database automatically:
  ```bash
  bd dolt stop && bd dolt start
  ```

- [ ] **Configure the Dolt sync remote** (skip if `bd bootstrap` already set this up). `bd init` auto-detects a git remote if one is already configured on the repo and wires it as the Dolt `origin` remote (this is what makes `bd dolt push` work). Verify or fix:
  ```bash
  bd dolt remote list                                  # should show 'origin' with your repo URL
  # If empty or wrong, add/replace it:
  bd dolt remote add origin <your-git-url-here>        # e.g. git+ssh://git@github.com/<you>/<repo>.git
  ```
- [ ] Verify the push works:
  ```bash
  bd dolt push
  ```
  This catches auth or remote-URL issues early. If it fails, fix the remote config now.

### 4. Install bd hooks and fix ordering

- [ ] Install bd git hooks:
  ```bash
  bd hooks install
  ```
- [ ] **Fix hook ordering.** Both `pre-commit install` (step 1) and `bd hooks install` write to `.git/hooks/pre-commit`. The result is the bd integration block sitting **after** the pre-commit framework's `exec` — making it unreachable. You must move the bd block above the `exec`.

  Open `.git/hooks/pre-commit` and move the entire `# --- BEGIN BEADS INTEGRATION --- ... # --- END BEADS INTEGRATION ---` block to sit **above** the `# start templated` line. The file should look like:
  ```bash
  #!/usr/bin/env bash
  # --- BEGIN BEADS INTEGRATION ---
  # ... (bd hook block)
  # --- END BEADS INTEGRATION ---

  # File generated by pre-commit: https://pre-commit.com
  # start templated
  # ... (pre-commit framework, ending in exec)
  ```
  Without this fix, `bd hooks run pre-commit` (which exports `.beads/issues.jsonl`) never fires on commit.

### 5. Run bd doctor

- [ ] Run the doctor and auto-fix detected issues:
  ```bash
  bd doctor --fix --yes
  ```
  This catches gitignore gaps, tracked runtime files, database version mismatches, and other issues the manual steps might miss.
- [ ] Set your role (required for routing):
  ```bash
  git config beads.role maintainer
  ```
- [ ] Confirm: `bd status` should report the database with zero errors.

### 6. Set project identity

- [ ] Replace the **Project Overview** placeholder below with the real project name, purpose, primary language, and package manager.
- [ ] Populate the **Development Conventions** section with the stack's rules (test runner, linter, branch strategy, etc.).
- [ ] If adopting into an existing repo with a substantial `CLAUDE.md`, merge its project-specific content into the appropriate sections of this file before replacing `CLAUDE.md` with the symlink.
- [ ] **Delete this entire "Project Initialization Checklist" section.** Its job is done.

---

## Project Overview

<!-- Replace this placeholder during project initialization (step 3 above). -->

_State in 2–3 sentences what this project does, who uses it, and the headline technology._

**Primary language / runtime:** _TBD_
**Package manager:** _TBD_

## Documentation Structure

All project documentation lives under `doc/`. Each subdirectory has a `README.md` that explains its purpose, naming convention, and contains an index of its contents and a template for new entries.

```
doc/
├── architecture/    # System design and component diagrams
├── benchmarks/      # E2E verification scenarios, benchmark results
├── decisions/       # Architecture Decision Records (ADR)
├── development/     # Developer guides, setup, progress tracking
├── guidance/        # External expert consultations (requests + responses)
├── inbox/           # Untriaged feature requests from external teams/agents
├── plans/           # Implementation plans and task tracking
├── runbooks/        # Operational procedures
└── vision/          # Product ideas, future concepts
```

### Placement Rules

| Content Type | Directory | Naming |
|---|---|---|
| System design, component diagrams | `doc/architecture/` | `<component>.md` |
| Significant architectural decisions | `doc/decisions/` | `ADR-NNNN-<short-title>.md` |
| Developer setup, progress, guides | `doc/development/` | descriptive `.md` |
| External expert advice (requests + responses) | `doc/guidance/` | `NNN-request-<topic>.md`, `NNN-response-<topic>.md` |
| Incoming feature requests (untriaged) | `doc/inbox/` | `YYYY-MM-DD-<source>-<topic>.md` |
| Implementation plans | `doc/plans/` | `YYYY-MM-DD-<description>.md` |
| Operational runbooks | `doc/runbooks/` | `<procedure-name>.md` |
| Benchmarks, E2E verification | `doc/benchmarks/` | `<component>-<test-type>.md` or `YYYY-MM-DD-<description>.md` |
| Product vision | `doc/vision/` | `<concept-name>.md` |

### When Creating Documentation

1. Check the target directory's `README.md` for the template and naming convention.
2. Add an entry to that directory's index table in its `README.md`.
3. Use Markdown with tables for structured information.
4. Link to related documents across directories.
5. **Never create docs outside `doc/`** — keep the tree clean.

### Hard Rules

- **All implementation plans MUST be saved to `doc/plans/` before implementation begins.** Naming: `YYYY-MM-DD-<feature-name>.md`. Agents must save the plan file and get user approval before writing any implementation code.
- **Guidance response documents must be authored by the user**, not generated by AI. Agents may draft guidance **request** documents.

## Issue Tracking with `bd` (beads)

This project uses [`bd`](https://github.com/steveyegge/beads) for issue tracking — a dependency-aware, AI-native tracker where issues live in a Dolt database in `.beads/` at the project root.

### Quick Reference

```bash
# Context & status
bd status                          # Database overview
bd prime                           # AI-optimized workflow context (run at session start)
bd ready                           # Unblocked issues (tree view is default)
bd ready --plain                   # Plain numbered list instead of tree
bd ready --explain                 # Show why each issue is ready or blocked

# Worktrees (see "Multi-Agent Development" below)
bd worktree create <branch-name>   # creates ./<branch-name>, auto-gitignored
bd worktree list
bd worktree info                   # info about the current worktree

# Creating issues (see "Semantic IDs" below — prefer `--id` over auto-generated)
bd create "Title" --id <prefix>-<epic>-<task> --type task --priority 2
bd create "Title" --id <prefix>-<epic> --type epic -p 1 --description "Details..."
bd q "Quick capture title"         # Create + output only ID (auto ID, for throwaways)

# Epics & hierarchy
bd create "Epic title" --type epic
bd dep add CHILD-id EPIC-id --type parent-child
bd epic status EPIC-id
bd children EPIC-id

# Dependencies
bd dep add TASK-id BLOCKER-id      # BLOCKER blocks TASK
bd dep tree ISSUE-id

# Working with issues
bd show ISSUE-id                   # Full details
bd list --status open
bd list --type epic
bd update ISSUE-id --claim         # Claim for yourself
bd close ISSUE-id --reason "Done"
bd comments add ISSUE-id "Progress note"

# Bulk creation from structured markdown
bd create --file plan.md

# Search & query
bd search "keyword"
bd query "status=open AND priority<=2"

# Dolt sync — REQUIRED after every write
bd dolt push                       # pushes to the configured remote; no positional args
```

### Semantic IDs

Prefer human-readable IDs over auto-generated ones. Pattern: `<prefix>-<epic>[-<task>]`.

- **prefix** — domain area (e.g., `infra`, `api`, `ui`, `docs`, `ci`)
- **epic** — one or two keywords naming the initiative (e.g., `blueprint`, `tferrors`)
- **task** — optional single keyword for the child task (e.g., `planonly`, `logsub`)

Examples:

```bash
# Epic
bd create "Expose Terraform errors to conditions" --id infra-tferrors --type epic

# Task under epic (--id and --parent cannot be combined; create then link)
bd create "Phase 1: enable log subresource" \
  --id infra-tferrors-logsub --type task
bd dep add infra-tferrors-logsub infra-tferrors --type parent-child

# Standalone task
bd create "Allow blueprints to run in plan-only mode" \
  --id infra-blueprint-planonly --type task
```

Why: semantic IDs give agents and humans instant context without a `bd show`, and keep related work visually grouped in `bd list` / `bd ready` output. Auto-IDs (`bd q "..."`) are fine for throwaway captures, but anything worth tracking across sessions should be named.

### Usage Patterns for AI Agents

- **Before starting work:** `bd ready` to find unblocked tasks, or `bd prime` for full context.
- **Creating epics with tasks:** Create the epic first, then child tasks with `bd dep add CHILD EPIC --type parent-child`.
- **Tracking progress:** `bd update ID --claim` when starting, `bd close ID --reason "..."` when done.
- **Discovered work:** `bd create ... --deps discovered-from:<parent-id>` links new issues to the parent that revealed them.
- **JSON output:** Add `--json` to any command for machine-readable output.
- **After every bd write** (create / update / close / dep / edit): run `bd dolt push`. Auto-push is not yet available.

### Gotchas

- Both `bd comment <id> "text"` (shorthand) and `bd comments add <id> "text"` (full form) work in bd ≥ 1.0 — pick either. `bd comments <id>` with no subcommand **lists** comments.
- `bd tag <id> <label>` is shorthand for `bd update <id> --add-label <label>`.
- Descriptions on `bd create` and `bd update` use `--description "..."` — not positional.
- `bd edit <id>` edits the description in `$EDITOR` by default; use `--title`, `--design`, `--notes`, `--acceptance` to edit other fields.
- `bd ready` shows a tree by default (`--pretty` is the default); pass `--plain` for a numbered list.
- `bd dolt push` takes **no positional args** — the remote is configured once via `bd dolt remote add`.
- **`bd prime` requires the Dolt server running.** The `.claude/settings.json` hooks fire `bd prime` on SessionStart and PreCompact. If the Dolt server isn't up, the hook will error. Start it with `bd dolt start` if you see "Dolt server unreachable" errors at session start.
- **After `bd bootstrap`, restart the Dolt server.** The server doesn't detect newly cloned databases — run `bd dolt stop && bd dolt start` after bootstrap.
- **Never close a ticket with incomplete work** unless the deferred items are captured in NEW tickets with full context (what was learned, what remains, why deferred, acceptance criteria). Vague "deferred" comments with no follow-up ticket are how work gets lost.
- **`--id` and `--parent` cannot be combined** on `bd create`. Create the task with `--id` first, then link it: `bd dep add CHILD EPIC --type parent-child`.
- If the Dolt server is stuck: `bd dolt set port <new_port>` then `bd dolt start`. Check with `lsof -i :<port>`.

### Integration Rules

- Use `bd` for ALL task tracking — do NOT use Claude's TodoWrite / TaskCreate, markdown TODO lists, or external trackers.
- `bd init` injects a BEADS-INTEGRATION comment block into this file (HTML-comment markers bracketing the region). Do not hand-edit inside the markers; `bd` manages that region.

## Multi-Agent Development with Worktrees

This project **embraces git worktrees** to enable parallel agent work on independent tickets. Each epic or independent task runs in its own worktree so agents do not stomp on each other's working tree, branches, or uncommitted changes.

### Workflow

1. **Claim the ticket first** — `bd update <id> --claim` is atomic and prevents two agents grabbing the same issue.
2. **Create a worktree for the epic:**
   ```bash
   bd worktree create <branch-name>
   # or:  bd worktree create <branch-name> --branch <different-branch>
   ```
   This provisions an isolated checkout at `./<branch-name>/` on a new branch. bd auto-appends the path to `.gitignore` if it lands inside the repo root. The worktree automatically shares the same beads database as the main repo.
3. **Work inside the worktree** — `cd <branch-name>` and proceed normally (tests, commits, pushes all scope to the worktree's branch).
4. **Cross-link the worktree branch and the ticket** — include the ticket ID in commit messages and the MR description; label the ticket with the MR URL at session end (see Landing the Plane below).
5. **Tear down on merge** — after the MR lands, remove the worktree (bd adds safety checks over raw `git worktree remove`):
   ```bash
   bd worktree remove <branch-name>
   git branch -d <branch-name>
   ```

### Rules

- **One ticket ↔ one worktree.** Two agents MUST NOT share a worktree; claims prevent ticket collisions, worktrees prevent code collisions.
- **Never cross-edit from the main checkout while an agent is working in a worktree** — that re-creates the collision worktrees are meant to prevent.
- **Every worktree eventually merges or gets removed.** Stale worktrees accumulate and confuse future agents; treat abandoned worktrees as follow-up tickets, not carry-over state.

## Session Completion — "Landing the Plane"

**When ending a work session, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.**

### Mandatory workflow

1. **File issues for remaining work** — any follow-up gets its own ticket.
2. **Run quality gates** (if code changed) — tests, linters, builds must pass. Pre-commit hooks (set up in the initialization checklist) enforce this automatically at commit time.
3. **Update issue status** — close finished work, update in-progress items.
4. **Push to remote** — mandatory:
   ```bash
   git pull --rebase
   bd dolt push
   git push
   git status   # must show "up to date with origin"
   ```
5. **Cross-link the ticket with the PR/MR** once the request exists, so code ↔ issue is discoverable from either side. Prefer `--external-ref` for a single canonical pointer; use a label when you need multiple:
   ```bash
   bd update <id> --external-ref "gh-1234"            # or "gl-!567", "jira-ABC-42"
   # or:
   bd tag <id> "mr:<url>"                              # shorthand for --add-label
   ```
6. **Record a handoff comment on each active ticket** — write what the next agent needs to know (current state, blockers, next step), using `bd comments add`:
   ```bash
   bd comments add <id> "Handoff: <current state> / <blockers> / <next step>"
   ```
   This is the durable, discoverable form of "hand off" — a fresh agent runs `bd show <id>` and sees it.
7. **Clean up** — remove merged worktrees (`git worktree remove ...`), clear stashes, prune remote branches.
8. **Verify** — all changes committed AND pushed AND tickets updated with MR URL + handoff comment.

### Critical rules

- Work is NOT complete until `git push` succeeds.
- NEVER stop before pushing — that leaves work stranded locally.
- NEVER say "ready to push when you are" — the agent must push.
- If push fails, resolve the underlying problem and retry until it succeeds.

## Development Conventions

<!-- Populate during project initialization (step 3). Suggested subsections:
- Language version + package-manager rule (e.g., "uv only, never pip")
- Testing: framework, TDD loop (failing test → implement → verify → commit)
- Linter / formatter
- Git workflow (main-first? feature branches? PRs? direct push to main restricted?)
- Any "no git worktrees" / "no local merges" rules
-->

## Non-Interactive Shell Commands

**Always use non-interactive flags** with file and shell operations. Shell aliases (`cp -i`, `rm -i`, `mv -i`) can cause agents to hang indefinitely waiting for y/n input.

```bash
cp -f source dest           # NOT: cp source dest
mv -f source dest           # NOT: mv source dest
rm -f file                  # NOT: rm file
rm -rf directory            # NOT: rm -r directory
cp -rf source dest          # NOT: cp -r source dest

# Remote / package commands that may prompt
scp -o BatchMode=yes ...
ssh -o BatchMode=yes ...
apt-get -y ...
HOMEBREW_NO_AUTO_UPDATE=1 brew ...
```
