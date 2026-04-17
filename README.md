# ai-assisted-development

A **project template** for starting new repositories that will be built collaboratively with AI coding agents (Claude Code, Codex, OpenCode, Cursor, Aider, …). Cloning this template gives a new project the documentation layout, issue-tracker wiring, quality gates, and agent instructions already in place — no more hand-copying from reference repos.

## What you get

- **`doc/` tree** with nine canonical subdirectories, each seeded with a `README.md` that explains its purpose, naming rules, template for new entries, and an index of its contents.
- **`AGENTS.md`** — the single source of truth for agent behaviour, covering documentation placement, `bd` (beads) issue tracking with semantic IDs, multi-agent worktree workflow, and the eight-step *Landing the Plane* session-completion protocol. `CLAUDE.md` is a symlink to it so Claude Code reads the same instructions as every other agent.
- **`bd` issue-tracking ready-to-provision** — dependency-aware, AI-native ticket tracker with git-native merge semantics via Dolt. The template does not ship a pre-initialised `.beads/` database (that directory is per-project and contains your own sync-remote URL); the `AGENTS.md` initialization checklist walks you through `bd init`, Dolt remote setup, and the hook-ordering fix. `.claude/settings.json` pre-wires `bd prime` as a `SessionStart`/`PreCompact` hook so workflow context auto-injects once bd is initialised.
- **Pre-commit quality gates** (`.pre-commit-config.yaml` + `.markdownlint.yaml`) — language-agnostic defaults (whitespace, EOF, merge-conflict, YAML, markdown) that enforce the *"work is not complete until `git push` succeeds"* rule before a commit can land.
- **Multi-agent-friendly workflow** — embraces `bd worktree create` so several agents can work in parallel on independent tickets without stomping on each other's working tree.

## Bootstrapping a new project from this template

1. Copy this repository (either as a GitHub template, or `git clone` + `rm -rf .git && git init`).
2. Open `AGENTS.md` and work through the **Project Initialization Checklist** at the top:
   - Install `pre-commit` and register hooks.
   - Install `bd` and run `bd init` + `bd hooks install`.
   - Fix the `.beads/hooks/pre-commit` ordering so bd runs before the pre-commit framework `exec`s (documented inline).
   - Fill in the Project Overview and Development Conventions sections.
3. **Delete the Project Initialization Checklist section from `AGENTS.md`** once everything is green — its job is done.

## Layout at a glance

```
.
├── AGENTS.md              # Canonical agent instructions (see file for full detail)
├── CLAUDE.md              # -> AGENTS.md (symlink)
├── .pre-commit-config.yaml
├── .markdownlint.yaml
├── .claude/settings.json  # SessionStart/PreCompact hooks running `bd prime`
├── .gitignore             # Excludes .beads/, .remember/, local Claude settings, Dolt blobs
# .beads/                  # NOT in template — created locally by `bd init` during bootstrap
└── doc/
    ├── architecture/      # System design and component diagrams
    ├── benchmarks/        # E2E verification scenarios, benchmark results
    ├── decisions/         # Architecture Decision Records (ADR)
    ├── development/       # Developer guides, setup, progress tracking
    ├── guidance/          # External expert consultations (requests + responses)
    ├── inbox/             # Untriaged feature requests from external teams/agents
    ├── plans/             # Implementation plans and task tracking
    ├── runbooks/          # Operational procedures
    └── vision/            # Product ideas, future concepts
```

## Deliberate conventions

- **`AGENTS.md` is canonical, `CLAUDE.md` is the symlink** — aligns with the emerging cross-agent standard.
- **Worktrees are embraced, not forbidden** — parallel multi-agent development is a first-class goal.
- **Semantic `bd` IDs** (`<prefix>-<epic>[-<task>]`) are preferred over auto-generated hashes.
- **All implementation plans live in `doc/plans/` before coding starts**, with user approval.
- **Guidance response documents are authored by the user, never by an agent.**

See `AGENTS.md` for the operational rules behind each of these.

## License

See [`LICENSE`](./LICENSE).
