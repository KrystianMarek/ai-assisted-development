# Plan: `adopt.sh` — Automate Template Adoption

**Status:** Planning
**Owner:** @krystian (with Claude Code)
**Branch:** `feat/adopt-script` (to be created)

> **For agentic workers:** Steps use checkbox (`- [ ]`) syntax for tracking. Pair with `superpowers:executing-plans` when executing in one session, or `superpowers:subagent-driven-development` for fresh subagent per task.

---

## Objective

Provide a single entrypoint — `adopt.sh` in the template root — that automates every mechanical step of the existing "Project Initialization Checklist" in `AGENTS.md`. Manual intervention is reserved for the three judgment calls: Project Overview, Development Conventions, and project-specific README.

## Scope

**Included:**

- `adopt.sh` with `--help`, `--target DIR`, `--role ROLE`, `--dry-run`, `--force` flags.
- Prereq detection for `git`, `pre-commit`, `dolt`, `bd`.
- Target-repo validation (must be a git repo; warns on existing `AGENTS.md`).
- File copy via `git archive | tar -x` (preserves symlinks, respects `.gitignore`).
- `pre-commit install` inside the target.
- `bd init` with tolerance for the known upstream panic during `AGENTS.md` marker injection.
- Merged `.git/hooks/pre-commit` with BEADS block **above** the pre-commit framework `exec`.
- `git config beads.role <role>` (default `maintainer`).
- Idempotent re-runs (detect prior-adoption markers, skip completed steps).
- Final "next steps" banner covering the three manual tasks.
- A smoke test (`test/smoke-adopt.sh`) that provisions a throwaway git repo and asserts the end state.
- `shellcheck` added to `.pre-commit-config.yaml` for `*.sh` files.
- Updates to `AGENTS.md` checklist and `README.md` so they reference `adopt.sh` as the short path.

**Excluded:**

- Automating Project Overview / Dev Conventions text (needs human context).
- Automating `bd dolt push` (requires the target's remote to have a first branch, which is downstream of the user's initial commit + push).
- Auto-installation of missing prereqs (too invasive — we print install commands and exit).
- Upstream fix for the `bd init` `updateAgentFile` panic (out of scope; document it as a known issue and file a bd bug as a follow-up).

## Architecture

**Shape:** Single bash script, ~250 lines, structured as a sequence of named functions (`require_prereqs`, `validate_target`, `copy_template_files`, …). Each function is guarded by an idempotency check so the whole script can be re-run safely.

A `run()` wrapper routes all mutating commands through a single chokepoint that prints the command and — if `--dry-run` is set — skips execution. This keeps the dry-run implementation trivial and uniform.

**Known gotcha it has to handle:** when `pre-commit` is installed *before* `bd hooks install`, bd does not overwrite `.git/hooks/pre-commit` and the BEADS integration is left in `.beads/hooks/pre-commit` only. The script sidesteps the race by writing the combined hook itself after both tools have run — that is also what the checklist already documents.

## Tech Stack

- Bash 4+ with `set -euo pipefail`.
- Standard unix tools: `git`, `tar`, `sed`, `mktemp`.
- `pre-commit` framework, `dolt`, `bd` (external prereqs — not installed by the script).
- `shellcheck` for lint (added to `.pre-commit-config.yaml`).

---

## File Structure

| Path | Role |
|------|------|
| `adopt.sh` | **NEW** — top-level adoption script. |
| `test/smoke-adopt.sh` | **NEW** — end-to-end smoke test (runs `adopt.sh` against a disposable git repo). |
| `doc/development/adopting-with-script.md` | **NEW** — a one-page developer-facing note explaining when to use `adopt.sh` vs the manual checklist. |
| `.pre-commit-config.yaml` | **MODIFY** — add `shellcheck` hook. |
| `AGENTS.md` | **MODIFY** — top of Project Initialization Checklist references `adopt.sh` as the shortcut. |
| `README.md` | **MODIFY** — "Bootstrapping" and "Adopting into existing repo" sections reference `adopt.sh`. |
| `doc/plans/README.md` | **MODIFY** — index row for this plan. |

---

## Tasks

### Task 0: Branch and track

**Files:** n/a (git state)

- [ ] **Step 1: Create a feature branch from `main`**

  ```bash
  cd /home/krystian/Development/ai-assisted-development
  git checkout -b feat/adopt-script
  ```

- [ ] **Step 2: File the epic in bd and claim it**

  ```bash
  bd create "Automate template adoption with adopt.sh" \
    --id ai-assisted-development-adopt --type epic --priority 1 \
    --description "See doc/plans/2026-04-17-adopt-script.md"
  bd update ai-assisted-development-adopt --claim
  bd dolt push
  ```

- [ ] **Step 3: Add a row for this plan in `doc/plans/README.md`**

  Replace the `_none yet_` placeholder row with:

  ```markdown
  | [adopt.sh](2026-04-17-adopt-script.md) | Automate template adoption | Approved | 2026-04-17 |
  ```

- [ ] **Step 4: Commit**

  ```bash
  git add doc/plans/2026-04-17-adopt-script.md doc/plans/README.md
  git commit -m "plan: automate template adoption with adopt.sh (ai-assisted-development-adopt)"
  ```

---

### Task 1: Scaffold `adopt.sh`

**Files:** Create `adopt.sh`

- [ ] **Step 1: Write the minimal skeleton**

  ```bash
  #!/usr/bin/env bash
  # adopt.sh — copy this template into TARGET and wire up pre-commit + bd.
  # See ./AGENTS.md → "Project Initialization Checklist" for the manual equivalent.
  set -euo pipefail

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  TARGET="${PWD}"
  ROLE="maintainer"
  DRY_RUN=0
  FORCE=0

  usage() {
    cat <<'EOF'
  Usage: adopt.sh [--target DIR] [--role ROLE] [--dry-run] [--force] [--help]

    --target DIR   Repo to adopt the template into (default: $PWD).
    --role ROLE    Value for `git config beads.role` (default: maintainer).
    --dry-run      Print the commands that would run; make no changes.
    --force        Overwrite existing AGENTS.md / README.md in the target.
    --help         Show this message.
  EOF
  }

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --target)  TARGET="$2";  shift 2 ;;
      --role)    ROLE="$2";    shift 2 ;;
      --dry-run) DRY_RUN=1;    shift ;;
      --force)   FORCE=1;      shift ;;
      --help|-h) usage; exit 0 ;;
      *) echo "unknown flag: $1" >&2; usage; exit 2 ;;
    esac
  done

  run() {
    if [[ "$DRY_RUN" == 1 ]]; then
      printf 'DRY: %s\n' "$*"
    else
      "$@"
    fi
  }

  main() {
    echo "TODO: adoption steps"
  }

  main
  ```

- [ ] **Step 2: Make it executable and sanity-check**

  ```bash
  chmod +x adopt.sh
  bash -n adopt.sh             # syntax check
  ./adopt.sh --help            # should print usage
  ./adopt.sh --dry-run         # should print "TODO: adoption steps"
  ```

- [ ] **Step 3: Commit**

  ```bash
  git add adopt.sh
  git commit -m "feat(adopt): scaffold adopt.sh entrypoint"
  ```

---

### Task 2: Add `shellcheck` to pre-commit

**Files:** Modify `.pre-commit-config.yaml`

- [ ] **Step 1: Add the hook**

  Append to `.pre-commit-config.yaml` (after the `markdownlint-cli` block):

  ```yaml
    - repo: https://github.com/koalaman/shellcheck-precommit
      rev: v0.10.0
      hooks:
        - id: shellcheck
  ```

- [ ] **Step 2: Run it and verify it passes**

  ```bash
  pre-commit run shellcheck --all-files
  ```

  Expected: pass (the scaffold is shellcheck-clean).

- [ ] **Step 3: Commit**

  ```bash
  git add .pre-commit-config.yaml
  git commit -m "chore(pre-commit): add shellcheck for *.sh"
  ```

---

### Task 3: Prereq detection

**Files:** Modify `adopt.sh`

- [ ] **Step 1: Add `require_prereqs` above `main`**

  ```bash
  require_prereqs() {
    local missing=()
    command -v git         >/dev/null 2>&1 || missing+=("git")
    command -v pre-commit  >/dev/null 2>&1 || missing+=("pre-commit (install: pip install pre-commit  OR  uv tool install pre-commit)")
    command -v dolt        >/dev/null 2>&1 || missing+=("dolt (install: see https://docs.dolthub.com/introduction/installation)")
    command -v bd          >/dev/null 2>&1 || missing+=("bd (install: curl -fsSL https://raw.githubusercontent.com/gastownhall/beads/main/scripts/install.sh | bash)")
    if (( ${#missing[@]} > 0 )); then
      printf 'Missing prerequisites:\n' >&2
      printf '  - %s\n' "${missing[@]}" >&2
      exit 1
    fi
  }
  ```

- [ ] **Step 2: Call it from `main`**

  ```bash
  main() {
    require_prereqs
    echo "TODO: remaining steps"
  }
  ```

- [ ] **Step 3: Verify by hand**

  ```bash
  ./adopt.sh --dry-run    # should print "TODO: remaining steps" (all prereqs present locally)
  PATH= ./adopt.sh --dry-run 2>&1 || true   # should list missing tools and exit 1
  ```

- [ ] **Step 4: Commit**

  ```bash
  git add adopt.sh
  git commit -m "feat(adopt): detect missing prerequisites"
  ```

---

### Task 4: Target validation

**Files:** Modify `adopt.sh`

- [ ] **Step 1: Add `validate_target`**

  ```bash
  validate_target() {
    [[ -d "$TARGET" ]] || { echo "target is not a directory: $TARGET" >&2; exit 1; }
    git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1 \
      || { echo "target is not a git repo: $TARGET (run 'git init' first)" >&2; exit 1; }
  }
  ```

  Note: we intentionally do **not** abort on an existing `AGENTS.md`. `copy_template_files` (Task 5) uses `tar -k` so existing files are preserved on a re-run; `--force` switches to overwrite mode for intentional resync with upstream template changes.

- [ ] **Step 2: Call it**

  ```bash
  main() {
    require_prereqs
    validate_target
    echo "TODO: copy + init"
  }
  ```

- [ ] **Step 3: Commit**

  ```bash
  git add adopt.sh
  git commit -m "feat(adopt): validate target repo before mutating"
  ```

---

### Task 5: Copy template files

**Files:** Modify `adopt.sh`

- [ ] **Step 1: Add `copy_template_files`**

  ```bash
  copy_template_files() {
    # git archive only includes tracked files and preserves the CLAUDE.md symlink.
    # tar -k keeps existing files so a re-run does not clobber a filled-in AGENTS.md.
    # --force (FORCE=1) drops -k to pick up upstream template updates.
    local keep="-k"
    [[ "$FORCE" == 1 ]] && keep=""
    run bash -c "git -C '$SCRIPT_DIR' archive HEAD | tar -x $keep -C '$TARGET'"
  }
  ```

- [ ] **Step 2: Call it, commit**

  ```bash
  main() {
    require_prereqs
    validate_target
    copy_template_files
    echo "TODO: pre-commit + bd"
  }
  ```

  ```bash
  git add adopt.sh
  git commit -m "feat(adopt): copy template files into target"
  ```

---

### Task 6: `pre-commit install` in target

**Files:** Modify `adopt.sh`

- [ ] **Step 1: Add `install_precommit`**

  ```bash
  install_precommit() {
    run pre-commit install --config "$TARGET/.pre-commit-config.yaml" \
        --hook-type pre-commit \
        --overwrite \
        --allow-missing-config >/dev/null
    # pre-commit install needs to run in the repo; set cwd via --hook-type semantics:
    # the --config path above does the trick without changing cwd in dry-run.
  }
  ```

  Actually simpler — run in a subshell that `cd`s:

  ```bash
  install_precommit() {
    run bash -c "cd '$TARGET' && pre-commit install >/dev/null"
  }
  ```

  Keep the second form in the script.

- [ ] **Step 2: Call + commit**

  ```bash
  git add adopt.sh
  git commit -m "feat(adopt): install pre-commit hooks in target"
  ```

---

### Task 7: `bd init` with panic tolerance

**Files:** Modify `adopt.sh`

- [ ] **Step 1: Add `bd_init` that tolerates the known `updateAgentFile` panic**

  ```bash
  bd_init() {
    # bd init on a template-fresh AGENTS.md may panic in updateAgentFile while
    # injecting the BEADS-INTEGRATION marker region (upstream bug). We accept
    # partial success: .beads/config.yaml + .beads/hooks/pre-commit must exist.
    if [[ -f "$TARGET/.beads/config.yaml" ]]; then
      echo "bd already initialised in $TARGET, skipping bd init"
      return 0
    fi
    if [[ "$DRY_RUN" == 1 ]]; then
      printf 'DRY: (cd %s && bd init)\n' "$TARGET"
      return 0
    fi
    local rc=0
    (cd "$TARGET" && bd init) || rc=$?
    if [[ $rc -ne 0 ]]; then
      if [[ -f "$TARGET/.beads/config.yaml" && -f "$TARGET/.beads/hooks/pre-commit" ]]; then
        echo "WARN: 'bd init' exited $rc but critical files are in place. Known bug: updateAgentFile panic on template-fresh AGENTS.md." >&2
      else
        echo "bd init failed ($rc) and no .beads state was produced — aborting." >&2
        return $rc
      fi
    fi
  }
  ```

- [ ] **Step 2: Call + commit**

  ```bash
  git add adopt.sh
  git commit -m "feat(adopt): run bd init with tolerance for upstream panic"
  ```

---

### Task 8: Merged pre-commit hook with BEADS block above exec

**Files:** Modify `adopt.sh`

- [ ] **Step 1: Add `wire_bd_hook`**

  ```bash
  wire_bd_hook() {
    local hook="$TARGET/.git/hooks/pre-commit"
    if [[ -f "$hook" ]] && grep -q "BEGIN BEADS INTEGRATION" "$hook"; then
      echo "BEADS block already present in $hook, skipping"
      return 0
    fi
    # Extract the BEADS block from the one bd just wrote.
    local source="$TARGET/.beads/hooks/pre-commit"
    [[ -f "$source" ]] || { echo "expected $source after bd init, not found" >&2; return 1; }
    local beads_block
    beads_block="$(sed -n '/BEGIN BEADS INTEGRATION/,/END BEADS INTEGRATION/p' "$source")"
    [[ -n "$beads_block" ]] || { echo "could not extract BEADS block from $source" >&2; return 1; }
    # Prepend the BEADS block (above the pre-commit framework's exec) and preserve the rest.
    local current
    current="$(cat "$hook")"
    if [[ "$DRY_RUN" == 1 ]]; then
      printf 'DRY: would prepend BEADS block to %s\n' "$hook"
      return 0
    fi
    {
      printf '#!/usr/bin/env bash\n'
      printf '%s\n\n' "$beads_block"
      # Strip the existing shebang (if any) from the current file.
      printf '%s\n' "$current" | sed '1{/^#!/d}'
    } > "$hook.new"
    mv "$hook.new" "$hook"
    chmod +x "$hook"
  }
  ```

- [ ] **Step 2: Call + commit**

  ```bash
  git add adopt.sh
  git commit -m "feat(adopt): merge BEADS block above pre-commit exec"
  ```

---

### Task 9: Configure bd role + final report

**Files:** Modify `adopt.sh`

- [ ] **Step 1: Add `set_role` and `report_next_steps`**

  ```bash
  set_role() {
    run git -C "$TARGET" config beads.role "$ROLE"
  }

  report_next_steps() {
    cat <<EOF

Adoption complete. Manual follow-ups:

  1. Edit $TARGET/AGENTS.md — replace the Project Overview placeholder and
     populate Development Conventions. Delete the Project Initialization
     Checklist section when you are done.
  2. Replace $TARGET/README.md with a README describing the new project
     (the template's README is about the template itself).
  3. Commit, then:
       git -C $TARGET push -u origin main
       (cd $TARGET && bd dolt push)

Run ./adopt.sh --help to see all flags.
EOF
  }

  main() {
    require_prereqs
    validate_target
    copy_template_files
    install_precommit
    bd_init
    wire_bd_hook
    set_role
    report_next_steps
  }
  ```

- [ ] **Step 2: End-to-end dry-run**

  ```bash
  ./adopt.sh --target /tmp/does-not-exist --dry-run || true
  ./adopt.sh --dry-run    # from the template root — should print DRY: lines for each step
  ```

- [ ] **Step 3: Commit**

  ```bash
  git add adopt.sh
  git commit -m "feat(adopt): set role and print manual follow-ups"
  ```

---

### Task 10: Smoke test

**Files:** Create `test/smoke-adopt.sh`

- [ ] **Step 1: Write the smoke test**

  ```bash
  #!/usr/bin/env bash
  # test/smoke-adopt.sh — end-to-end sanity check for adopt.sh.
  # Creates a throwaway git repo, runs adopt.sh, asserts the end state,
  # and cleans up. Not wired into pre-commit (too slow); run on demand.
  set -euo pipefail

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  TEMPLATE="$(cd "$SCRIPT_DIR/.." && pwd)"
  WORKDIR="$(mktemp -d)"
  trap 'rm -rf "$WORKDIR"' EXIT

  git -C "$WORKDIR" init -q
  git -C "$WORKDIR" remote add origin "ssh://git@example.invalid/smoke.git"

  "$TEMPLATE/adopt.sh" --target "$WORKDIR" --role maintainer

  fail=0
  check() { if eval "$2"; then echo "  OK  $1"; else echo "  FAIL $1"; fail=1; fi }

  check "AGENTS.md copied"                    "[[ -f '$WORKDIR/AGENTS.md' ]]"
  check "CLAUDE.md is a symlink"              "[[ -L '$WORKDIR/CLAUDE.md' ]]"
  check "doc/plans/README.md copied"          "[[ -f '$WORKDIR/doc/plans/README.md' ]]"
  check ".beads/config.yaml present"          "[[ -f '$WORKDIR/.beads/config.yaml' ]]"
  check "pre-commit hook exists"              "[[ -x '$WORKDIR/.git/hooks/pre-commit' ]]"
  check "BEADS block present in hook"         "grep -q 'BEGIN BEADS INTEGRATION' '$WORKDIR/.git/hooks/pre-commit'"
  check "BEADS block is ABOVE pre-commit exec" "awk '/BEGIN BEADS INTEGRATION/{b=NR} /^if \\[ -x \"\\\$INSTALL_PYTHON\" \\]/{if(b && NR>b) exit 0; exit 1}' '$WORKDIR/.git/hooks/pre-commit'"
  check "beads.role configured"               "[[ \"\$(git -C '$WORKDIR' config beads.role)\" == 'maintainer' ]]"

  # Simulate a user filling in Project Overview, then re-run without --force.
  # The edited AGENTS.md must survive.
  printf '\n# SMOKE-SENTINEL do-not-clobber\n' >> "$WORKDIR/AGENTS.md"
  "$TEMPLATE/adopt.sh" --target "$WORKDIR" --role maintainer >/dev/null
  check "re-run preserves user edits to AGENTS.md" "grep -q 'SMOKE-SENTINEL' '$WORKDIR/AGENTS.md'"

  if (( fail )); then echo "smoke test FAILED"; exit 1; else echo "smoke test passed"; fi
  ```

- [ ] **Step 2: Make executable, run once, fix anything that fails**

  ```bash
  chmod +x test/smoke-adopt.sh
  ./test/smoke-adopt.sh
  ```

  Expected: all `OK`, exit 0. Fix any `FAIL` before proceeding.

- [ ] **Step 3: Commit**

  ```bash
  git add test/smoke-adopt.sh
  git commit -m "test(adopt): add end-to-end smoke test"
  ```

---

### Task 11: Documentation updates

**Files:** Modify `AGENTS.md`, `README.md`. Create `doc/development/adopting-with-script.md`.

- [ ] **Step 1: Patch the top of the Project Initialization Checklist in `AGENTS.md`**

  Immediately under the `## ⏱️ Project Initialization Checklist — REMOVE THIS SECTION AFTER COMPLETION` heading, add:

  ```markdown
  > **Shortcut:** from a checkout of this template, run `./adopt.sh --target /path/to/your/repo` to automate steps 1–5 below. Steps 6 (Project Overview, Dev Conventions, delete this checklist) are still manual. The manual walkthrough remains authoritative if anything in `adopt.sh` fails.
  ```

- [ ] **Step 2: Patch the `README.md` bootstrap section**

  In the "Bootstrapping a new project from this template" list, insert a leading item:

  ```markdown
  0. **Shortcut:** `bash /path/to/ai-assisted-development/adopt.sh --target .` automates steps 1 and the mechanical parts of step 2. Continue below only if you want to walk through the checklist by hand.
  ```

  And in "Adopting into an existing repository" add:

  ```markdown
  `adopt.sh` handles the file copy, pre-commit install, `bd init`, and hook wiring — run it with `--dry-run` first to see exactly what it would do. It will refuse to overwrite an existing `AGENTS.md` without `--force`.
  ```

- [ ] **Step 3: Write `doc/development/adopting-with-script.md`**

  Short note (under 50 lines) covering: what `adopt.sh` does vs skips, when to use it, when to fall back to the manual checklist, how to extend it when the template grows.

- [ ] **Step 4: Run pre-commit on all files**

  ```bash
  pre-commit run --all-files
  ```

- [ ] **Step 5: Commit**

  ```bash
  git add AGENTS.md README.md doc/development/adopting-with-script.md
  git commit -m "docs(adopt): reference adopt.sh from checklist + README"
  ```

---

### Task 12: Land the plane

**Files:** n/a

- [ ] **Step 1: Run the smoke test one more time**

  ```bash
  ./test/smoke-adopt.sh
  ```

- [ ] **Step 2: Push the branch and open a PR**

  ```bash
  git push -u origin feat/adopt-script
  gh pr create --title "adopt.sh: automate template adoption" \
    --body "Implements doc/plans/2026-04-17-adopt-script.md"
  ```

- [ ] **Step 3: Handoff on the epic ticket**

  ```bash
  bd comments add ai-assisted-development-adopt "Handoff: plan complete; smoke test green; PR open at <url>. Next: review + merge, then file an upstream bd issue for the updateAgentFile panic."
  bd update ai-assisted-development-adopt --external-ref "<pr-url>"
  bd dolt push
  git push
  ```

- [ ] **Step 4: Mark this plan `Complete` in `doc/plans/README.md`**

---

## Success Criteria

- `./adopt.sh --target <fresh-repo>` leaves the target in the same state as my manual devbox adoption session (verified by `test/smoke-adopt.sh`).
- `./adopt.sh --dry-run` prints every mutating command without touching the filesystem.
- Re-running `adopt.sh` on an already-adopted target exits cleanly without duplicating hooks or files.
- `pre-commit run --all-files` in the template passes with `shellcheck` enabled.
- `AGENTS.md` and `README.md` point new adopters at `adopt.sh` while keeping the manual checklist as the documented fallback.

## Dependencies

- Upstream `bd` tool — assumed at a version where the `updateAgentFile` panic is a nuisance rather than a blocker (partial success is accepted). Needs a follow-up upstream issue.
- `shellcheck-precommit` hook — adds a network-sourced dependency at `pre-commit` install time, consistent with existing hooks.

## Milestones

1. Plan approved and branch created (Task 0).
2. `adopt.sh` runs end-to-end against a dry-run target (Tasks 1–9).
3. Smoke test green (Task 10).
4. Docs updated, PR open (Tasks 11–12).
