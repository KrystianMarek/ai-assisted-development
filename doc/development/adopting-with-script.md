# Adopting the Template with `adopt.sh`

`adopt.sh` is a convenience script that automates the most mechanical parts of bootstrapping a new project from the `ai-assisted-development` template. It is optional — the manual [Project Initialization Checklist](../../AGENTS.md#-project-initialization-checklist--remove-this-section-after-completion) in `AGENTS.md` is always authoritative.

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

## When to use `adopt.sh`

- Bootstrapping a brand-new project from a fresh checkout of the template.
- Retrofitting an existing repository that does not yet have an `AGENTS.md`.

Run it with `--dry-run` first to see exactly what it will do:

```bash
./adopt.sh --target /path/to/your/repo --dry-run
```

If the output looks correct, run without `--dry-run` to execute.

## When to use the manual checklist

- The template is being adopted into a repository that already has an `AGENTS.md` (merge project-specific content first; use `--force` with `adopt.sh` if you want to overwrite).
- You need fine-grained control over which files to copy or which hooks to wire.
- `adopt.sh` fails — the manual walkthrough is always the fallback.

## Extending `adopt.sh` when the template grows

New tracked files in the template are automatically copied by `git archive HEAD` on the next adoption run — **no edit to `adopt.sh` is needed**. Changes to `adopt.sh` are only required when introducing a new *setup step* (not a new file). In that case, write a new function and call it from `main()` in the appropriate order.
