# `adopt.sh` Feedback (P1–P4) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix four friction points in `adopt.sh` surfaced by the 2026-04-20 blog-project adoption: opaque failure on read-only `.git/` mounts (P1), missing BEADS-INTEGRATION markers after `bd init` panic (P2), template-about-template files leaking into adopted projects (P3), and the template's own README surviving as the adopted project's README (P4).

**Architecture:** All changes land in `adopt.sh` and the smoke test. Two new functions (`check_git_writable`, `write_placeholder_readme`, `ensure_beads_markers`) slot into `main()`. The copy step gains a fixed exclusion list so adoption reproduces *essential skeleton only* (per-directory index `README.md`s + configs + `AGENTS.md` + `CLAUDE.md` symlink), never the template-about-template artefacts. No new flags; new behaviour is the default.

**Tech Stack:** Bash 4+, `git archive | tar`, `pre-commit`, `bd` (beads), markdown.

**Source feedback doc:** `doc/inbox/2026-04-20-blog-project-adopt-sh-feedback.md`

---

## File Structure

| Path | Change | Responsibility |
|------|--------|---------------|
| `adopt.sh` | Modify | Add preflight, exclusions, placeholder README, marker injection; update `main()` + `report_next_steps`. |
| `test/smoke-adopt.sh` | Modify | Extend with assertions for P1–P4 end-state. |
| `doc/development/adopting-with-script.md` | Modify | Document new defaults (exclusion list, placeholder README, writability check). |
| `AGENTS.md` | Modify | Adjust initialization-checklist step 6 to reflect placeholder-README behaviour. |
| `doc/inbox/README.md` | Modify | Update triage table: mark feedback doc **Triaged → Plan filed**. |
| `doc/inbox/2026-04-20-blog-project-adopt-sh-feedback.md` | Keep | Stays in inbox until this plan merges; then archive. |

**Exclusion list** (files the template owns but adopted projects should not receive):

- `README.md` — template's self-description; replaced by a placeholder when target has none.
- `adopt.sh` — the convenience script itself; adopted projects don't re-run it.
- `doc/development/adopting-with-script.md` — reference doc about `adopt.sh`.
- `doc/plans/2026-04-17-adopt-script.md` — plan that produced `adopt.sh`.
- `test/*` — smoke test and anything added later under `test/`.

---

## Task 1: P1 — Writability preflight for `.git/hooks` and `.git/config`

**Files:**

- Modify: `adopt.sh` (add new function `check_git_writable` near `validate_target`, wire into `main`)

- [ ] **Step 1: Add `check_git_writable` function**

Open `adopt.sh` and insert the following function directly after `validate_target` (currently ends at line 64):

```bash
check_git_writable() {
  local hooks_dir="$TARGET/.git/hooks"
  local config_file="$TARGET/.git/config"
  local probe
  if ! probe="$(mktemp "$hooks_dir/.adopt-write-test-XXXXXX" 2>/dev/null)"; then
    cat >&2 <<EOF
adopt.sh: $hooks_dir is not writable.

This commonly happens inside sandboxed agent harnesses (Claude Code, Codex,
Gemini) that mount .git/ read-only. Re-run this script outside the sandbox,
or grant the sandbox write access to .git/ in your host configuration.
EOF
    return 1
  fi
  rm -f "$probe"
  if [[ ! -w "$config_file" ]]; then
    cat >&2 <<EOF
adopt.sh: $config_file is not writable.

Same cause as the hooks case above — re-run outside the sandbox or fix
sandbox permissions so 'git config' can write to .git/config.
EOF
    return 1
  fi
}
```

- [ ] **Step 2: Wire `check_git_writable` into `main()`**

Find `main()` (currently at line 179) and insert the call between `validate_target` and `copy_template_files`:

```bash
main() {
  require_prereqs
  validate_target
  check_git_writable
  copy_template_files
  install_precommit
  bd_init
  wire_bd_hook
  set_role
  report_next_steps
}
```

- [ ] **Step 3: Verify preflight succeeds on a normal repo**

Run:

```bash
cd /tmp && rm -rf adopt-p1-ok && mkdir adopt-p1-ok && cd adopt-p1-ok && git init -q
/home/krystian/Development/ai-assisted-development/adopt.sh --target "$PWD" --dry-run
```

Expected: script prints `DRY:` lines and exits 0. No writability error.

- [ ] **Step 4: Verify preflight fails cleanly on read-only hooks**

Run:

```bash
cd /tmp && rm -rf adopt-p1-ro && mkdir adopt-p1-ro && cd adopt-p1-ro && git init -q
chmod 555 .git/hooks
set +e
/home/krystian/Development/ai-assisted-development/adopt.sh --target "$PWD"
rc=$?
chmod 755 .git/hooks
set -e
echo "exit code: $rc"
```

Expected: stderr contains `.git/hooks is not writable` and the actionable "sandboxed agent harnesses" explanation; exit code `1`.

- [ ] **Step 5: Commit**

```bash
git add adopt.sh
git commit -m "feat(adopt): preflight .git/ writability with actionable error"
```

---

## Task 2: P1 — Stop swallowing `pre-commit install` stderr

**Files:**

- Modify: `adopt.sh:99` — remove `>/dev/null` from the `pre-commit install` call.

- [ ] **Step 1: Remove the output suppression**

In `install_precommit()`, change:

```bash
  (cd "$TARGET" && pre-commit install >/dev/null)
```

to:

```bash
  (cd "$TARGET" && pre-commit install)
```

(Unchanged: the surrounding function body. The `BEADS INTEGRATION` guard above this line stays.)

- [ ] **Step 2: Verify normal-case output is tolerable**

Run:

```bash
cd /tmp && rm -rf adopt-p1-verbose && mkdir adopt-p1-verbose && cd adopt-p1-verbose && git init -q
/home/krystian/Development/ai-assisted-development/adopt.sh --target "$PWD" 2>&1 | tail -20
```

Expected: one-line `pre-commit installed at .git/hooks/pre-commit` is now visible. No regressions.

- [ ] **Step 3: Commit**

```bash
git add adopt.sh
git commit -m "fix(adopt): unsuppress pre-commit install so failures surface"
```

---

## Task 3: P3 — Exclude template-about-template files from copy

**Files:**

- Modify: `adopt.sh:66-81` — `copy_template_files`.

- [ ] **Step 1: Add exclusion list to tar command**

Replace the entire body of `copy_template_files()` (lines 66-81) with:

```bash
copy_template_files() {
  # git archive HEAD emits only tracked files and preserves the CLAUDE.md
  # symlink. We pipe through tar -x so we can apply --exclude filters for
  # template-about-template artefacts that adopted projects should not
  # receive (see TEMPLATE_EXCLUDES below).
  #
  # --skip-old-files silently skips existing files and exits 0, so re-runs
  # do not clobber a filled-in AGENTS.md and do not trip set -euo pipefail.
  # --force (FORCE=1) drops the flag to resync with upstream template changes.
  local -a TEMPLATE_EXCLUDES=(
    # --anchored makes --exclude match the leading path component only, so
    # --exclude=README.md drops root README.md without wiping the nine
    # doc/*/README.md index files the adopted project needs.
    --anchored
    --exclude=README.md
    --exclude=adopt.sh
    --exclude=doc/development/adopting-with-script.md
    --exclude=doc/plans/2026-04-17-adopt-script.md
    --exclude=test
    --exclude='test/*'
  )
  local -a tar_cmd=(tar -x)
  [[ "$FORCE" == 1 ]] || tar_cmd+=(--skip-old-files)
  tar_cmd+=("${TEMPLATE_EXCLUDES[@]}")
  tar_cmd+=(-C "$TARGET")
  if [[ "$DRY_RUN" == 1 ]]; then
    printf 'DRY: git -C %q archive HEAD |' "$SCRIPT_DIR"
    printf ' %q' "${tar_cmd[@]}"
    printf '\n'
    return 0
  fi
  git -C "$SCRIPT_DIR" archive HEAD | "${tar_cmd[@]}"
}
```

(Both `--exclude=test` and `--exclude='test/*'` are included because GNU tar and BSD tar differ on whether a directory `--exclude` also prunes contents during extraction. Listing both is safe and portable.)

- [ ] **Step 2: Verify excludes in a clean adoption**

Run:

```bash
cd /tmp && rm -rf adopt-p3 && mkdir adopt-p3 && cd adopt-p3 && git init -q
/home/krystian/Development/ai-assisted-development/adopt.sh --target "$PWD"
for f in adopt.sh test/smoke-adopt.sh doc/development/adopting-with-script.md doc/plans/2026-04-17-adopt-script.md; do
  if [[ -e "$PWD/$f" ]]; then echo "LEAKED: $f"; else echo "excluded OK: $f"; fi
done
```

Expected: all four listed as `excluded OK`.

- [ ] **Step 3: Verify essential skeleton still arrives**

Run (in the same `/tmp/adopt-p3`):

```bash
for f in AGENTS.md CLAUDE.md .pre-commit-config.yaml .claude/settings.json \
         doc/plans/README.md doc/inbox/README.md doc/architecture/README.md \
         doc/benchmarks/README.md doc/decisions/README.md doc/development/README.md \
         doc/guidance/README.md doc/runbooks/README.md doc/vision/README.md; do
  if [[ -e "$PWD/$f" ]]; then echo "present OK: $f"; else echo "MISSING: $f"; fi
done
```

Expected: every line is `present OK`.

- [ ] **Step 4: Commit**

```bash
git add adopt.sh
git commit -m "feat(adopt): exclude template-about-template files from adopted projects"
```

---

## Task 4: P4 — Placeholder README when target has none; never overwrite

**Files:**

- Modify: `adopt.sh` — add `write_placeholder_readme` function, wire into `main`, update `report_next_steps`.

- [ ] **Step 1: Add `write_placeholder_readme` function**

Insert the following function immediately after `copy_template_files()` (after the closing brace of the function edited in Task 3):

```bash
write_placeholder_readme() {
  local readme="$TARGET/README.md"
  if [[ -f "$readme" ]]; then
    echo "README.md already exists in $TARGET, leaving it alone"
    return 0
  fi
  if [[ "$DRY_RUN" == 1 ]]; then
    printf 'DRY: write placeholder README.md to %q\n' "$readme"
    return 0
  fi
  cat > "$readme" <<'EOF'
# <project name>

TODO: one-paragraph description of this project.

This repository was bootstrapped from
[`ai-assisted-development`](https://github.com/krystianmarek/ai-assisted-development).
See [`AGENTS.md`](./AGENTS.md) for agent workflow and conventions.
EOF
}
```

- [ ] **Step 2: Wire `write_placeholder_readme` into `main()`**

Update `main()` so it now reads:

```bash
main() {
  require_prereqs
  validate_target
  check_git_writable
  copy_template_files
  write_placeholder_readme
  install_precommit
  bd_init
  wire_bd_hook
  set_role
  report_next_steps
}
```

- [ ] **Step 3: Update `report_next_steps` to reflect the placeholder**

Replace the existing `report_next_steps` body (currently lines 137-153) with:

```bash
report_next_steps() {
  cat <<EOF

Adoption complete. Manual follow-ups:

  1. Edit $TARGET/AGENTS.md — replace the Project Overview placeholder and
     populate Development Conventions. Delete the Project Initialization
     Checklist section when you are done.
  2. Edit $TARGET/README.md — replace the TODO placeholder with a real
     project description (or, if you kept a pre-existing README, leave it).
  3. Commit, then:
       git -C $TARGET push -u origin main
       (cd $TARGET && bd dolt push)

Run ./adopt.sh --help to see all flags.
EOF
}
```

- [ ] **Step 4: Verify placeholder written when target has no README**

Run:

```bash
cd /tmp && rm -rf adopt-p4-new && mkdir adopt-p4-new && cd adopt-p4-new && git init -q
/home/krystian/Development/ai-assisted-development/adopt.sh --target "$PWD"
cat README.md
```

Expected output (trimmed):

```
# <project name>

TODO: one-paragraph description of this project.

This repository was bootstrapped from
...
```

- [ ] **Step 5: Verify pre-existing README is preserved**

Run:

```bash
cd /tmp && rm -rf adopt-p4-keep && mkdir adopt-p4-keep && cd adopt-p4-keep && git init -q
printf '# my real project\n\nkeep me\n' > README.md
/home/krystian/Development/ai-assisted-development/adopt.sh --target "$PWD"
cat README.md
```

Expected: `README.md` still says `# my real project` and `keep me` — unchanged.

- [ ] **Step 6: Commit**

```bash
git add adopt.sh
git commit -m "feat(adopt): write placeholder README when target has none"
```

---

## Task 5: P2 — Ensure BEADS-INTEGRATION markers in `AGENTS.md`

Upstream `bd init` panics (`main.updateAgentFile`, `init_agent.go:82`) when injecting markers into a template-fresh `AGENTS.md`. We keep the existing tolerance (`bd_init` already accepts partial success) and *always* make sure the marker region exists afterwards, so the "do not hand-edit inside the markers" contract in `AGENTS.md` is honoured from day one.

**Files:**

- Modify: `adopt.sh` — add `ensure_beads_markers` function, wire into `main` after `bd_init`.

- [ ] **Step 1: Add `ensure_beads_markers` function**

Insert the following function immediately after `bd_init()` (which currently ends at line 177):

```bash
ensure_beads_markers() {
  # Safety net for the upstream 'bd init' updateAgentFile panic: if bd did
  # not inject its HTML-comment markers into AGENTS.md, reserve the region
  # ourselves so agents honour the "don't edit inside" contract. A future
  # successful 'bd init' (or upstream fix) will find the markers and fill
  # the region in; until then, the block is intentionally near-empty.
  local agents="$TARGET/AGENTS.md"
  [[ -f "$agents" ]] || return 0
  if grep -q 'BEADS-INTEGRATION:BEGIN' "$agents" 2>/dev/null; then
    return 0
  fi
  if [[ "$DRY_RUN" == 1 ]]; then
    printf 'DRY: append BEADS-INTEGRATION marker block to %q\n' "$agents"
    return 0
  fi
  cat >> "$agents" <<'EOF'

<!-- BEADS-INTEGRATION:BEGIN -->
<!-- Managed by bd (beads). Do not hand-edit between these markers. -->
<!-- Region reserved by adopt.sh because 'bd init' updateAgentFile panicked; -->
<!-- a subsequent successful 'bd init' will populate this block. -->
<!-- BEADS-INTEGRATION:END -->
EOF
}
```

- [ ] **Step 2: Wire `ensure_beads_markers` into `main()`**

Update `main()` so it now reads:

```bash
main() {
  require_prereqs
  validate_target
  check_git_writable
  copy_template_files
  write_placeholder_readme
  install_precommit
  bd_init
  ensure_beads_markers
  wire_bd_hook
  set_role
  report_next_steps
}
```

- [ ] **Step 3: Verify markers land even when `bd init` panics**

Run:

```bash
cd /tmp && rm -rf adopt-p2 && mkdir adopt-p2 && cd adopt-p2 && git init -q
/home/krystian/Development/ai-assisted-development/adopt.sh --target "$PWD"
grep -n 'BEADS-INTEGRATION' AGENTS.md
```

Expected: two lines, one containing `BEADS-INTEGRATION:BEGIN` and one containing `BEADS-INTEGRATION:END`.

- [ ] **Step 4: Verify idempotence**

Re-run in the same `/tmp/adopt-p2`:

```bash
/home/krystian/Development/ai-assisted-development/adopt.sh --target "$PWD"
grep -c 'BEADS-INTEGRATION:BEGIN' AGENTS.md
```

Expected: `1` — the function noticed the existing marker and did not append a second block.

- [ ] **Step 5: Commit**

```bash
git add adopt.sh
git commit -m "feat(adopt): inject BEADS-INTEGRATION markers when bd init panics"
```

---

## Task 6: Extend `test/smoke-adopt.sh`

**Files:**

- Modify: `test/smoke-adopt.sh` — add assertions covering Tasks 1–5 end-state; keep the existing SMOKE-SENTINEL re-run test.

- [ ] **Step 1: Add exclusion and README assertions**

Open `test/smoke-adopt.sh` and, directly after the existing `check "beads.role configured"` line (currently line 27), insert:

```bash
check "adopt.sh NOT copied to target"        "[[ ! -e '$WORKDIR/adopt.sh' ]]"
check "adopting-with-script.md NOT copied"   "[[ ! -e '$WORKDIR/doc/development/adopting-with-script.md' ]]"
check "adopt-script plan NOT copied"         "[[ ! -e '$WORKDIR/doc/plans/2026-04-17-adopt-script.md' ]]"
check "test/ directory NOT copied"           "[[ ! -e '$WORKDIR/test' ]]"
check "placeholder README written"           "grep -q 'TODO: one-paragraph description' '$WORKDIR/README.md'"
check "template README NOT leaked"           "! grep -q 'ai-assisted-development template' '$WORKDIR/README.md'"
check "BEADS-INTEGRATION markers in AGENTS.md" "grep -q 'BEADS-INTEGRATION:BEGIN' '$WORKDIR/AGENTS.md'"
```

- [ ] **Step 2: Add a separate scenario for pre-existing README preservation**

Directly before the `if (( fail )); then` line at the end of the script, insert:

```bash
# Scenario 2: target already has a README — adopt.sh must leave it alone.
WORKDIR2="$(mktemp -d)"
trap 'rm -rf "$WORKDIR" "$WORKDIR2"' EXIT
git -C "$WORKDIR2" init -q
git -C "$WORKDIR2" remote add origin "ssh://git@example.invalid/smoke2.git"
printf '# real project\n\nkeep me\n' > "$WORKDIR2/README.md"
"$TEMPLATE/adopt.sh" --target "$WORKDIR2" --role maintainer >/dev/null
check "pre-existing README.md preserved" "grep -q 'keep me' '$WORKDIR2/README.md'"
```

- [ ] **Step 3: Add a separate scenario for read-only `.git/hooks`**

Directly after the Scenario 2 block, insert:

```bash
# Scenario 3: .git/hooks/ is read-only — adopt.sh must exit non-zero with
# an actionable error message mentioning the sandbox cause.
WORKDIR3="$(mktemp -d)"
trap 'chmod 755 "$WORKDIR3/.git/hooks" 2>/dev/null; rm -rf "$WORKDIR" "$WORKDIR2" "$WORKDIR3"' EXIT
git -C "$WORKDIR3" init -q
chmod 555 "$WORKDIR3/.git/hooks"
set +e
err_output="$("$TEMPLATE/adopt.sh" --target "$WORKDIR3" --role maintainer 2>&1)"
rc=$?
set -e
chmod 755 "$WORKDIR3/.git/hooks"
check "read-only .git/hooks aborts with non-zero exit" "[[ $rc -ne 0 ]]"
check "read-only error mentions sandbox"               "grep -q 'sandboxed agent harnesses' <<<\"\$err_output\""
```

- [ ] **Step 4: Run the smoke test end-to-end**

```bash
bash /home/krystian/Development/ai-assisted-development/test/smoke-adopt.sh
```

Expected: every `OK` line printed; final line `smoke test passed`; exit code 0.

- [ ] **Step 5: Commit**

```bash
git add test/smoke-adopt.sh
git commit -m "test(adopt): cover exclusions, placeholder README, marker injection, preflight"
```

---

## Task 7: Update `doc/development/adopting-with-script.md`

**Files:**

- Modify: `doc/development/adopting-with-script.md` — document the new defaults.

- [ ] **Step 1: Rewrite the "What `adopt.sh` does" and "What it skips" sections**

Replace the content under `## What adopt.sh does` (currently lines 5-11) and `## What it skips (manual steps)` (currently lines 12-17) with:

```markdown
## What `adopt.sh` does

- Runs a **writability preflight** on `.git/hooks/` and `.git/config` so sandboxed agent environments (Claude Code, Codex, Gemini) fail fast with an actionable error instead of exiting silently.
- Copies the **essential template skeleton** to your target (via `git archive HEAD | tar -x`): `AGENTS.md`, `CLAUDE.md` symlink, `.pre-commit-config.yaml`, `.claude/settings.json`, `.gitignore`, `.markdownlint.yaml`, `LICENSE`, and the per-directory `README.md` index files under `doc/`.
- Writes a **placeholder `README.md`** if the target has none; never overwrites a pre-existing `README.md`.
- Installs and registers pre-commit hooks.
- Initializes the Dolt database for `bd` issue tracking and runs `bd init`.
- Wires `bd` hooks into `.git/hooks/pre-commit` by merging the BEADS integration block from `.beads/hooks/pre-commit`.
- Ensures the `BEADS-INTEGRATION` marker region exists in `AGENTS.md` as a safety net for the upstream `bd init` `updateAgentFile` panic.

## What `adopt.sh` does **not** copy

These files exist in the template but are about the template itself, and are deliberately excluded from adopted projects:

- `README.md` (template's self-description — a placeholder is written instead)
- `adopt.sh` (this convenience script)
- `doc/development/adopting-with-script.md` (this document)
- `doc/plans/2026-04-17-adopt-script.md` (plan that produced `adopt.sh`)
- `test/` (smoke test for `adopt.sh`)

## What it skips (manual steps)

- Pinning pre-commit revisions to the latest versions at adoption time.
- Filling in the **Project Overview** and **Development Conventions** sections in `AGENTS.md`.
- Replacing the placeholder `README.md` with a real project description.
- Deleting the **Project Initialization Checklist** section from `AGENTS.md` (only after manual review and agreement with the user).
```

- [ ] **Step 2: Verify the doc renders cleanly**

Run:

```bash
pre-commit run --files doc/development/adopting-with-script.md
```

Expected: all hooks pass (especially `markdownlint`).

- [ ] **Step 3: Commit**

```bash
git add doc/development/adopting-with-script.md
git commit -m "docs(adopt): document exclusions, placeholder README, preflight"
```

---

## Task 8: Update `AGENTS.md` checklist and inbox triage

**Files:**

- Modify: `AGENTS.md` — adjust step 6 of the Project Initialization Checklist.
- Modify: `doc/inbox/README.md` — mark the feedback doc **Triaged**.

- [ ] **Step 1: Update `AGENTS.md` step 6**

In `AGENTS.md`, find the "6. Set project identity" section inside the Project Initialization Checklist. Replace its bullet list with:

```markdown
- [ ] Replace the **Project Overview** placeholder below with the real project name, purpose, primary language, and package manager.
- [ ] Populate the **Development Conventions** section with the stack's rules (test runner, linter, branch strategy, etc.).
- [ ] Replace the placeholder `README.md` (written by `adopt.sh` when no README existed) with a real project description — or leave your pre-existing README as-is.
- [ ] If adopting into an existing repo with a substantial `CLAUDE.md`, merge its project-specific content into the appropriate sections of this file before replacing `CLAUDE.md` with the symlink.
- [ ] **Delete this entire "Project Initialization Checklist" section.** Its job is done.
```

- [ ] **Step 2: Update the inbox triage table**

In `doc/inbox/README.md`, update the row for the feedback doc. Change:

```markdown
| [adopt.sh feedback](2026-04-20-blog-project-adopt-sh-feedback.md) | Claude Code agent (blog project bootstrap) | Untriaged | 2026-04-20 | — |
```

to:

```markdown
| [adopt.sh feedback](2026-04-20-blog-project-adopt-sh-feedback.md) | Claude Code agent (blog project bootstrap) | Triaged | 2026-04-20 | Plan filed: [`doc/plans/2026-04-20-adopt-sh-feedback.md`](../plans/2026-04-20-adopt-sh-feedback.md) |
```

- [ ] **Step 3: Run pre-commit on the changed docs**

```bash
pre-commit run --files AGENTS.md doc/inbox/README.md
```

Expected: hooks pass.

- [ ] **Step 4: Commit**

```bash
git add AGENTS.md doc/inbox/README.md
git commit -m "docs(adopt): update init checklist + mark inbox feedback triaged"
```

---

## Task 9: Full-stack verification

- [ ] **Step 1: Re-run the smoke test**

```bash
bash /home/krystian/Development/ai-assisted-development/test/smoke-adopt.sh
```

Expected: `smoke test passed`.

- [ ] **Step 2: Run pre-commit across all changed files**

```bash
pre-commit run --all-files
```

Expected: all hooks pass.

- [ ] **Step 3: Sanity-check adopt.sh shellcheck-clean (if `shellcheck` is on PATH)**

```bash
command -v shellcheck && shellcheck /home/krystian/Development/ai-assisted-development/adopt.sh
```

Expected: no output (clean) or `shellcheck: not found` (skip). Fix any new warnings introduced by this plan; pre-existing warnings are out of scope.

- [ ] **Step 4: Landing the plane**

Follow the `AGENTS.md` **Session Completion** protocol: close any bd tickets opened for this work, `git pull --rebase`, `bd dolt push`, `git push`, verify `git status` shows *up to date with origin*, and cross-link the PR URL onto the bd ticket (`bd update <id> --external-ref "gh-<pr-number>"`).

---

## Acceptance Criteria (from the feedback doc)

- [x] `adopt.sh` detects read-only `.git/hooks/` and `.git/config` before invoking commands that write to them, and prints an actionable error. **→ Task 1**
- [x] Remove unconditional `>/dev/null` suppression on `pre-commit install` so failures are visible. **→ Task 2**
- [x] When `bd init` panics but leaves critical files, `adopt.sh` injects the canonical `BEADS-INTEGRATION` marker block into `AGENTS.md`. **→ Task 5**
- [x] `adopt.sh` excludes template-about-template files from adopted projects *by default* (user direction on P3 supersedes the feedback doc's `--exclude-template-docs` flag suggestion). **→ Task 3**
- [x] The template no longer copies its self-describing `README.md`; adopted projects get a placeholder when none pre-exists, and a pre-existing README is preserved untouched. **→ Task 4**

## Out of scope

- Filing the upstream `gastownhall/beads` issue for the `updateAgentFile` panic. Tracked separately; the safety net in Task 5 makes adoption robust without blocking on upstream.
- Reproducing bd's *full* AGENTS.md content inside the marker region. The reserved empty region satisfies the "don't edit inside" contract; a future successful `bd init` (or upstream fix) will populate it.
- Introducing a manifest file (`.template-files` or similar) to drive exclusions. User's direction is a hard-coded list; revisit only if the list grows unwieldy.
