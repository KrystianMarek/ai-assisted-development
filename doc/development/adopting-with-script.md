# Adopting the Template with `adopt.sh`

`adopt.sh` is a convenience script that automates the most mechanical parts of bootstrapping a new project from the `ai-assisted-development` template. It is optional — the manual [Project Initialization Checklist](../../AGENTS.md#-project-initialization-checklist--remove-this-section-after-completion) in `AGENTS.md` is always authoritative.

## What `adopt.sh` does

- Runs a **writability preflight** on `.git/hooks/` and `.git/config` so sandboxed agent environments (Claude Code, Codex, Gemini) fail fast with an actionable error instead of exiting silently.
- Copies the **essential template skeleton** to your target (via `git archive HEAD` piped to `tar`): `AGENTS.md`, `CLAUDE.md` symlink, `.pre-commit-config.yaml`, `.claude/settings.json`, `.gitignore`, `.markdownlint.yaml`, `LICENSE`, the per-directory `README.md` index files under `doc/`, the wiki catalog `doc/index.md`, the reusable runbooks `doc/runbooks/wiki-lint.md` and `doc/runbooks/repo-hygiene.md`, `scripts/repo-hygiene.sh`, `.gitattributes` (union merge for the monthly log), and the `external/` scaffold (`external/.gitignore` + `external/README.md`). The copy step **probes the `tar` capability** rather than trusting the OS or the tool's version string: it attempts a throwaway extract with the GNU-only flags (`--skip-old-files`, `--anchored`) and, on success, uses the GNU fast path (direct anchored extraction); on failure it uses a portable path (extract to a staging dir, drop excluded paths, copy in without clobbering). `gtar` is preferred when present. This works natively on macOS (`bsdtar`), Linux (GNU tar), and busybox/Alpine.
- Writes a **placeholder `README.md`** if the target has none; never overwrites a pre-existing `README.md`.
- Writes **placeholder wiki core pages** (`doc/overview.md`, `doc/goals.md`, `doc/status.md`, `doc/log.md`) if the target lacks them — for a fresh `doc/log.md` also the first monthly file `doc/log/YYYY-MM.md`; never overwrites pages you have filled in. These are project content, so the template's own filled-in copies are excluded and fresh scaffolds are written instead (same pattern as `README.md`).
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
- `doc/plans/2026-09-28-log-external-hygiene.md` (plan that produced the one-line log, `external/`, and repo hygiene)
- `doc/inbox/2026-04-20-blog-project-adopt-sh-feedback.md` (the feedback that drove the follow-up)
- `doc/overview.md`, `doc/goals.md`, `doc/status.md`, `doc/log.md`, `doc/log/` (this repo's own wiki content and log entries — placeholders are written instead)
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

## Upgrading an existing adoption

Projects adopted from an older template pick up **new** files on a plain re-run (they are copied because the target lacks them), but every file the target already has is **skipped** — and `--force` overwrites all of them, including your project-specific `AGENTS.md`. So upgrade in three steps:

1. **Report** — nothing is written:
   ```bash
   /path/to/ai-assisted-development/adopt.sh --target /path/to/your/repo --diff
   ```
   It lists files that are `new` (the re-run adds them) and files that `differ` (merge by hand), and flags a legacy `doc/log.md`.
2. **Re-run** without `--force` to add the new files:
   ```bash
   /path/to/ai-assisted-development/adopt.sh --target /path/to/your/repo
   ```
3. **Merge the differing files by hand**, using `diff /path/to/ai-assisted-development/<file> <file>`. Most will differ simply because you customised them; take only the template changes.

### Merge checklist for the 2026-09 change (log, `external/`, hygiene)

| File | Take from the template |
|---|---|
| `AGENTS.md` | *Documentation Structure* (`log/` entry, `external/` note), the new *Placement Rules* rows, the *Ingest*/*Lint* wording under *Three operations*, the log bullets under *index.md and log.md*, the `bd worktree create .worktrees/<name>` lines (Quick Reference + Multi-Agent workflow steps 2, 3, 5 and the new rule), *Landing the Plane* steps 7–8, and the two new sections *Reference Clones (`external/`)* and *Repository Hygiene*. |
| `.gitignore` | Add `.worktrees/`, `*.gate.lock*`, `.beads/proxieddb/`, `.DS_Store`. Then run `scripts/repo-hygiene.sh` and delete the one-off entries it reports. |
| `.pre-commit-config.yaml` | Append the `repo: local` block with the `wiki-log-format` and `wiki-log-no-entries-in-index` hooks. |
| `doc/runbooks/README.md` | Add the `repo-hygiene.md` row. |
| `doc/runbooks/wiki-lint.md` | Take the template version unless you customised it (new log checks and the *Reference clones* step). |
| `external/` (if you already have one) | Rename a lowercase `readme.md` index to `README.md`; move ignore rules into `external/.gitignore`; add *Origin URL* and *Ref* columns to the index so a fresh checkout can re-clone; list every clone on disk. |

### Migrating a legacy `doc/log.md`

A legacy log keeps multi-line `## [YYYY-MM-DD] type | title` entries in `doc/log.md` itself — the merge hotspot this change removes. Migrate in one small commit, ideally when no agent branch has pending log edits:

1. Freeze the old log as an archive (its name does not match the monthly pattern, so the format hook and union merge leave it alone; nobody appends to it again):
   ```bash
   mkdir -p doc/log
   git mv doc/log.md doc/log/archive-pre-$(date +%Y-%m).md
   ```
2. Recreate `doc/log.md` from the template's entry page (format, rationale, timeline commands) and list the months: the current month plus `- [archive (before YYYY-MM)](log/archive-pre-YYYY-MM.md)`.
3. Create `doc/log/$(date +%Y-%m).md` starting with `# Log: YYYY-MM` and a first entry, e.g. `- YYYY-MM-DD decision | Log migrated to one-line monthly files → [log.md](../log.md)`.
4. Tell agents with open branches: their pending edits to the old `doc/log.md` will conflict with the move once — on rebase, drop that hunk and re-add the entry as one line in the monthly file.

Links to `doc/log.md` keep working because the entry page stays at the same path.

## Extending `adopt.sh` when the template grows

New tracked files in the template are automatically copied by `git archive HEAD` on the next adoption run — **no edit to `adopt.sh` is needed** for generic scaffolds (READMEs, reusable runbooks). Editing `adopt.sh` is only required in two cases:

1. **A new *setup step*** (not just a file): write a new function and call it from `main()` in the appropriate order.
2. **A file that carries this repo's own content** (e.g., a filled-in wiki page or a template-about-template plan): add it to `TEMPLATE_EXCLUDES` so it is not leaked into adopted projects, and — if the wiki structure needs the page to exist — write a fresh placeholder in `write_wiki_placeholders()` (mirroring `write_placeholder_readme()`).
