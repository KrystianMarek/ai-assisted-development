# Adopting the Template with `adopt.sh`

`adopt.sh` is a convenience script that automates the most mechanical parts of bootstrapping a new project from the `ai-assisted-development` template. It is optional — the manual [Project Initialization Checklist](../../AGENTS.md#-project-initialization-checklist--remove-this-section-after-completion) in `AGENTS.md` is always authoritative.

## What `adopt.sh` does

- Copies `AGENTS.md`, `.pre-commit-config.yaml`, `CLAUDE.md` symlink, and `doc/` scaffolding to your target repository.
- Installs and registers pre-commit hooks (with verification).
- Initializes the Dolt database for `bd` issue tracking and runs `bd init`.
- Wires `bd` hooks into `.git/hooks/pre-commit` and configures `.claude/settings.json` with `bd prime`.

## What it skips (manual steps)

- Pinning pre-commit revisions to the latest versions at adoption time.
- Filling in the **Project Overview** and **Development Conventions** sections in `AGENTS.md`.
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

If new files or directories are added to the template that should be copied during adoption, edit `adopt.sh` and add them to the `FILES_TO_COPY` list near the top of the script. Follow the pattern already in place: local path relative to the template root, and target path (usually the same).

All other wiring (pre-commit, `bd`, hooks) is driven by the same logic — no changes needed unless the bootstrap ceremony itself changes.
