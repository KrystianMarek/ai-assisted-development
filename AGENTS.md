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
- [ ] Register the hook: `pre-commit install`
- [ ] Verify it fires: `pre-commit run --all-files`

If the user prefers another runner (`prek`, `husky`, `lefthook`), swap it in — but keep the guarantee: **no commit lands without passing lint/format checks.**

### 2. Install and initialize `bd` (beads)

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
- [ ] Initialize the project database:
  ```bash
  bd init
  ```
  This scaffolds `.beads/` and injects a BEADS-INTEGRATION comment block into this file (the canonical `AGENTS.md`; `CLAUDE.md` symlinks to it). If `bd init` detects existing bd content it will preserve it rather than overwriting.
- [ ] (Recommended) Install bd git hooks so `bd prime` context auto-injects at session start:
  ```bash
  bd hooks install
  ```
- [ ] **Fix hook ordering** in `.beads/hooks/pre-commit`. If `pre-commit install` ran first (step 1), `bd init` preserved the pre-commit framework body in `.beads/hooks/pre-commit` and appended its own integration block — but the framework body ends in `exec`, so the bd block is unreachable. Move the `# --- BEGIN BEADS INTEGRATION --- ... # --- END BEADS INTEGRATION ---` block to sit **above** the `# start templated` line so bd runs first, then `exec`s into the pre-commit framework. Without this fix, `bd hooks run pre-commit` (which exports `.beads/issues.jsonl` for git-tracking) never fires on commit.
- [ ] Confirm: `bd status` should report the fresh database.

### 3. Set project identity

- [ ] Replace the **Project Overview** placeholder below with the real project name, purpose, primary language, and package manager.
- [ ] Populate the **Development Conventions** section with the stack's rules (test runner, linter, branch strategy, etc.).
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

# Task under epic
bd create "Phase 1: enable log subresource" \
  --id infra-tferrors-logsub --type task --parent infra-tferrors

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
- **Never close a ticket with incomplete work** unless the deferred items are captured in NEW tickets with full context (what was learned, what remains, why deferred, acceptance criteria). Vague "deferred" comments with no follow-up ticket are how work gets lost.
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
