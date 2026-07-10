# Adopting the Template with `adopt.sh`

`adopt.sh` is a convenience script that automates the most mechanical parts of bootstrapping a new project from the `ai-assisted-development` template. It is optional — the manual [Project Initialization Checklist](../../AGENTS.md#-project-initialization-checklist--remove-this-section-after-completion) in `AGENTS.md` is always authoritative.

## What `adopt.sh` does

- Runs a **writability preflight** on `.git/hooks/` and `.git/config` so sandboxed agent environments (Claude Code, Codex, Gemini) fail fast with an actionable error instead of exiting silently.
- Copies the **essential template skeleton** to your target (via `git archive HEAD` piped to `tar`): `AGENTS.md`, `CLAUDE.md` symlink, `.pre-commit-config.yaml`, `.claude/settings.json`, `.gitignore`, `.markdownlint.yaml`, `LICENSE`, the per-directory `README.md` index files under `doc/`, the wiki catalog `doc/index.md`, and the reusable `doc/runbooks/wiki-lint.md`. The copy step **auto-detects the tar flavor** (GNU vs BSD/libarchive): GNU tar extracts directly with anchored `--exclude`/`--skip-old-files`, while BSD tar (default on macOS) extracts to a staging dir, drops the excluded paths, and copies in without clobbering existing files. `gtar` is preferred when installed.
- Writes a **placeholder `README.md`** if the target has none; never overwrites a pre-existing `README.md`.
- Writes **placeholder wiki core pages** (`doc/overview.md`, `doc/goals.md`, `doc/status.md`, `doc/log.md`) if the target lacks them; never overwrites pages you have filled in. These are project content, so the template's own filled-in copies are excluded and fresh scaffolds are written instead (same pattern as `README.md`).
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
- `doc/plans/2026-04-20-adopt-sh-feedback.md` (follow-up plan addressing real-adoption feedback)
- `doc/plans/2026-07-10-llm-wiki-migration.md` (plan that produced the LLM Wiki layout)
- `doc/inbox/2026-04-20-blog-project-adopt-sh-feedback.md` (the feedback that drove the follow-up)
- `doc/overview.md`, `doc/goals.md`, `doc/status.md`, `doc/log.md` (this repo's own wiki content — placeholders are written instead)
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

New tracked files in the template are automatically copied by `git archive HEAD` on the next adoption run — **no edit to `adopt.sh` is needed** for generic scaffolds (READMEs, reusable runbooks). Editing `adopt.sh` is only required in two cases:

1. **A new *setup step*** (not just a file): write a new function and call it from `main()` in the appropriate order.
2. **A file that carries this repo's own content** (e.g., a filled-in wiki page or a template-about-template plan): add it to `TEMPLATE_EXCLUDES` so it is not leaked into adopted projects, and — if the wiki structure needs the page to exist — write a fresh placeholder in `write_wiki_placeholders()` (mirroring `write_placeholder_readme()`).
