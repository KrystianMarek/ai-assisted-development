# Feature Request: `adopt.sh` — quality-of-life fixes from a fresh adoption

## Source

Agent (Claude Code, Opus 4.7) bootstrapping a new project (`~/Development/blog`) for Krystian Marek on 2026-04-20. Submitted per the owner's request after the adoption completed successfully.

## Priority

Medium — `adopt.sh` **worked** and produced a correct final state. The items below are friction points and a few latent bugs that would have become release-blockers under slightly different conditions.

## Summary

`adopt.sh` completed the adoption cleanly in one run (after the sandbox was disabled). The Dolt remote, pre-commit hook ordering, BEADS integration block, `beads.role`, and file copy all landed correctly. During the run I observed:

1. An **upstream `bd init` panic** (already documented in the script's own comments) that the script tolerates. Worth tracking an upstream fix and/or post-processing to inject the BEADS-INTEGRATION markers into `AGENTS.md` ourselves if the bug persists.
2. **Silent failure when `.git/hooks/` is on a read-only mount** (sandboxed agent environments) — the script exited 3 with no output, making the failure hard to diagnose.
3. **Template-authored reference docs** survive adoption and clutter a new project's `doc/` tree (`doc/development/adopting-with-script.md`, `doc/plans/2026-04-17-adopt-script.md`). These are *about the template*, not about the new project.
4. **`README.md` is the template's own README** after adoption. The `--skip-old-files` guard doesn't help because there was no prior `README.md`. The script advises the user to replace it, but a fresh project would benefit from the template shipping a **placeholder `README.md`** instead of its self-description.

Each expanded below with concrete asks.

## Problem Statement

### P1 — Opaque failure on read-only `.git/hooks/`

When run from inside a sandboxed agent harness that mounts `.git/hooks/` and `.git/config` read-only, the script exits 3 with **no stderr output**. The failure originates inside `pre-commit install` (the OSError surfaces there), but `set -euo pipefail` + `>/dev/null` in `install_precommit` swallows it. Diagnosis required re-running under `bash -x` and then running `pre-commit install` by hand.

Affected users: anyone running the script from a sandboxed Claude Code / Codex / Gemini session that restricts writes to `.git/`. This is a growing population.

### P2 — `bd init` panic tolerance is right, but leaves a partial state

The script already documents and tolerates the `updateAgentFile` panic (`init_agent.go:82`). The consequence is that `AGENTS.md` never receives its `BEADS-INTEGRATION` comment block. The template's own AGENTS.md tells agents "do not hand-edit inside the markers" — but the markers aren't there. Users and agents have no signal that the block is missing, and no guidance on how to add it.

### P3 — Template reference docs bleed into new projects

After adoption, the following template-authored files exist in the new project:

- `doc/development/adopting-with-script.md` (guide for `adopt.sh` itself)
- `doc/plans/2026-04-17-adopt-script.md` (implementation plan for the adopt script)
- `adopt.sh` itself in the new project's root

These are useful for **template maintainers** re-running `adopt.sh --force` to pull in upstream updates. They are noise for **new-project consumers**, who have to decide whether to delete them or curate them. The template's README claims these files stay so users can re-sync — but this contract is implicit and there's no marker distinguishing "template-owned, safe to update" from "project-owned, don't overwrite".

### P4 — `README.md` is the template's self-description

Once `adopt.sh` completes, the new project's `README.md` is a description of `ai-assisted-development` — not of the new project. The script's closing instructions tell the user to replace it, but:

- It's the very first file a human or bot opens. First impressions matter.
- The template's README mentions `adopt.sh --target .` and refers to the template project by name — so it actively misleads readers during the period between adoption and rewrite.

## Proposed Solution

### For P1 (opaque hook-install failure)

In `install_precommit` and `wire_bd_hook`, add an explicit writability check before invoking the subprocess that would write to `.git/hooks/`:

```bash
if ! (touch "$TARGET/.git/hooks/.adopt-write-test" 2>/dev/null && rm -f "$TARGET/.git/hooks/.adopt-write-test"); then
  cat >&2 <<EOF
adopt.sh: .git/hooks/ is not writable in $TARGET.
This usually happens inside sandboxed agent environments (Claude Code, Codex,
Gemini) that mount git internals read-only. Re-run this script outside the
sandbox, or grant the sandbox write access to .git/ in your host config.
EOF
  return 1
fi
```

Do the same for `.git/config` in `set_role`. Also remove the `>/dev/null` redirect from the `pre-commit install` call (or tee it to a log file) so the upstream OSError isn't silenced.

### For P2 (`bd init` panic aftermath)

Two options, not mutually exclusive:

1. **Inject the markers ourselves.** If `bd init` exits non-zero but the critical files exist, append the canonical `BEADS-INTEGRATION` marker region to `AGENTS.md` from a template literal in `adopt.sh`. That way the markers are always present and agents honour the "don't edit inside" contract from day one.
2. **File an upstream issue** against `gastownhall/beads` for the `updateAgentFile` panic with a minimal reproducer (a template-fresh `AGENTS.md` with no existing marker). Link it in the `adopt.sh` comment so the workaround can be removed when fixed.

### For P3 (template reference files leaking)

Add an opt-in flag to `adopt.sh`:

```
--exclude-template-docs   Omit template-authored reference files that are
                          about the template itself, not the new project.
                          (default: include, preserving re-sync ergonomics)
```

When set, the file copy excludes a known list (e.g. `doc/development/adopting-with-script.md`, `doc/plans/2026-04-17-adopt-script.md`, and `adopt.sh` itself). Document this in `AGENTS.md`'s initialization checklist so users know the choice exists.

### For P4 (template README survives)

Ship a **`README.md.new-project-template`** in the template repo containing a minimal placeholder README. During `adopt.sh`, if the target has no `README.md`, install the placeholder instead of the template's own `README.md`. The template's self-description stays on the template's git remote, not in the adopted repo.

Placeholder content can be as small as:

```markdown
# <project name>

TODO: one-paragraph description of this project.

This repository was bootstrapped from
[`ai-assisted-development`](https://github.com/krystianmarek/ai-assisted-development).
See [`AGENTS.md`](./AGENTS.md) for agent workflow and conventions.
```

## Requirements

- [ ] `adopt.sh` detects read-only `.git/hooks/` and `.git/config` before invoking commands that write to them, and prints an actionable error.
- [ ] Remove unconditional `>/dev/null` suppression on `pre-commit install` so failures are visible.
- [ ] When `bd init` panics but leaves critical files, `adopt.sh` injects the canonical `BEADS-INTEGRATION` marker block into `AGENTS.md` (or documents the upstream fix when one lands).
- [ ] `adopt.sh` grows a `--exclude-template-docs` flag that omits template-about-template files.
- [ ] The template ships a separate minimal placeholder README that `adopt.sh` uses instead of the self-describing one when the target has no `README.md`.

## Acceptance Criteria

- [ ] Running `adopt.sh` in a sandbox that read-only-mounts `.git/hooks/` produces a clear error message identifying the root cause and suggesting a fix, instead of exiting 3 silently.
- [ ] After a successful adoption, `AGENTS.md` in the new project contains the `BEADS-INTEGRATION` marker block, regardless of whether `bd init` panicked.
- [ ] `adopt.sh --exclude-template-docs` leaves the new project with no template-about-template documents.
- [ ] After a successful adoption with no `--force` and no pre-existing `README.md`, the target's `README.md` is a placeholder with a TODO and a link to `AGENTS.md`, not a description of `ai-assisted-development` itself.

## Dependencies

- P2 improvement depends on either an upstream `bd` fix or on the template taking ownership of the marker block. The workaround (inject-from-template) is strictly inside `adopt.sh`'s control.
- P1 and P4 have no external dependencies.
- P3 depends on cataloguing the template-about-template files and keeping that list maintained.

## Timeline

No hard deadline from this submitter. P1 is the most user-visible and would have the biggest agent-experience payoff. P4 is a cheap polish item. P2/P3 can ride a later revision.

## Notes from the adoption that produced this report

- Target: `/home/krystian/Development/blog` (git repo already initialised, no commits).
- Sequence that revealed P1: script first run inside a Claude Code sandbox → exit 3 silently. Second run with sandbox disabled → completed successfully.
- Sequence that revealed P2: observed the `panic: runtime error: slice bounds out of range [-1:]` in `main.updateAgentFile` exactly as documented in `adopt.sh`'s own comments (lines 156–177). Handler worked correctly; only the aftermath (missing markers in `AGENTS.md`) is the remaining issue.
- All P3 and P4 observations came from inspecting the target after a clean run.
