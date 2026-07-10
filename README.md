# ai-assisted-development

A **project template** for starting new repositories that will be built collaboratively with AI coding agents (Claude Code, Codex, OpenCode, Cursor, Aider, …). Cloning this template gives a new project the documentation layout, issue-tracker wiring, quality gates, and agent instructions already in place — no more hand-copying from reference repos.

## What you get

- **A development-focused LLM Wiki.** The `doc/` tree is maintained as a persistent, compounding, interlinked knowledge base ([Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)) rather than write-once files. Agents *ingest* new information into it, *query* it with citations, and *lint* it for rot. Root files `doc/overview.md` (high-level idea), `doc/index.md` (master catalog), `doc/log.md` (chronological log), `doc/goals.md` (long/short-horizon goals), and `doc/status.md` (progress) sit above the topical subdirs. See [AGENTS.md → Project as an LLM Wiki](./AGENTS.md#project-as-an-llm-wiki).
- **`doc/` tree** with canonical subdirectories, each seeded with a `README.md` that explains its purpose, naming rules, template for new entries, and an index of its contents. Includes `sources/` (immutable raw source-of-truth layer) and `considerations/` (open trade-offs and risks).
- **`AGENTS.md`** — the single source of truth for agent behaviour, covering documentation placement, `bd` (beads) issue tracking with semantic IDs, multi-agent worktree workflow, and the eight-step *Landing the Plane* session-completion protocol. `CLAUDE.md` is a symlink to it so Claude Code reads the same instructions as every other agent.
- **`bd` issue-tracking ready-to-provision** — dependency-aware, AI-native ticket tracker with git-native merge semantics via [Dolt](https://docs.dolthub.com/). The template does not ship a pre-initialised `.beads/` database (that directory is per-project and contains your own sync-remote URL); the `AGENTS.md` initialization checklist walks you through Dolt installation, `bd init` / `bd bootstrap`, hook ordering, and `bd doctor`. `.claude/settings.json` pre-wires `bd prime` as a `SessionStart`/`PreCompact` hook so workflow context auto-injects once bd is initialised.
- **Pre-commit quality gates** (`.pre-commit-config.yaml` + `.markdownlint.yaml`) — language-agnostic defaults (whitespace, EOF, merge-conflict, YAML, markdown) that enforce the *"work is not complete until `git push` succeeds"* rule before a commit can land.
- **Multi-agent-friendly workflow** — embraces `bd worktree create` so several agents can work in parallel on independent tickets without stomping on each other's working tree.

## Adopting this template

There are three ways to adopt the template, depending on how much you want to drive yourself.

### Option A — ask an agent to do it

Clone this repo somewhere local, then in your target project's agent session say:

> **adopt /absolute/path/to/ai-assisted-development**

Any agent that reads this `README.md` (or `AGENTS.md`) will understand "adopt" as: run `adopt.sh` against the current repo if prerequisites are present, otherwise walk the **Project Initialization Checklist** at the top of `AGENTS.md` by hand. The agent should:

1. `cd` into the target repo (or pass `--target`).
2. Run `bash /absolute/path/to/ai-assisted-development/adopt.sh --target . --dry-run` and show you the plan.
3. Re-run without `--dry-run` once you approve.
4. Walk you through the manual follow-ups `adopt.sh` cannot automate (Project Overview, Development Conventions, replacing the placeholder `README.md`, deleting the Initialization Checklist section).

### Option B — run `adopt.sh` yourself

From a checkout of this template, run the script against your target repo:

```bash
# Preview only — no changes:
bash /path/to/ai-assisted-development/adopt.sh --target /path/to/your/repo --dry-run

# Execute:
bash /path/to/ai-assisted-development/adopt.sh --target /path/to/your/repo
```

Flags:

| Flag | Purpose |
|---|---|
| `--target DIR` | Repo to adopt into (default: current working directory). Must already be a git repo — run `git init` first if not. |
| `--role ROLE` | Sets `git config beads.role` (default: `maintainer`). |
| `--dry-run` | Print the commands that would run; make no changes. Always preview first. |
| `--force` | Resync template-owned files (overwrite existing ones). `README.md` and the wiki core pages (`overview.md`, `goals.md`, `status.md`, `log.md`) are **never** overwritten — placeholders are only written when the target lacks them. |
| `--help` | Show usage. |

Prerequisites the script checks for upfront: `git`, `pre-commit`, `dolt`, `bd`. It will list any missing tool with an install hint and exit before touching the target.

What `adopt.sh` does:

- Copies the template skeleton (`AGENTS.md`, `CLAUDE.md` symlink, `.pre-commit-config.yaml`, `.markdownlint.yaml`, `.claude/settings.json`, `.gitignore`, `LICENSE`, the per-directory `doc/**/README.md` index files, the wiki catalog `doc/index.md`, and the reusable `doc/runbooks/wiki-lint.md`). It **auto-detects the `tar` capability** (probes the GNU-only flags; falls back to a portable path on BSD/libarchive/busybox) so it works natively on macOS, Linux, and Alpine.
- Writes a placeholder `README.md` if the target has none, and placeholder **wiki core pages** (`doc/overview.md`, `doc/goals.md`, `doc/status.md`, `doc/log.md`) if the target lacks them — never overwriting pages you have filled in.
- Runs `pre-commit install`, `bd init`, and merges the BEADS pre-commit hook block above the framework `exec` so both run.
- Sets `git config beads.role` and unsets `core.hooksPath` so the merged hook fires.

What `adopt.sh` does **not** do — you still have to:

- Pin `.pre-commit-config.yaml` revisions to the latest at adoption time.
- Fill in **Project Overview** and **Development Conventions** in `AGENTS.md`.
- Replace the placeholder `README.md` with real project content.
- Fill in the placeholder wiki core pages (`overview.md`, `goals.md`, `status.md`, `log.md`) with real project content.
- **Delete the Project Initialization Checklist section** from `AGENTS.md` once everything is green.

See [`doc/development/adopting-with-script.md`](./doc/development/adopting-with-script.md) for the full design notes and the list of template-about-template files that are deliberately excluded.

### Option C — fully manual

Skip `adopt.sh` entirely and walk the **Project Initialization Checklist** at the top of `AGENTS.md`. The checklist is always authoritative; it covers the same steps `adopt.sh` automates plus the manual follow-ups.

### Adopting into an existing repository

`adopt.sh` is safe to run against repositories that already have content. Things to know:

- `adopt.sh` refuses to overwrite an existing `AGENTS.md` without `--force`. If the repo already has a substantial `CLAUDE.md`, merge its project-specific content into `AGENTS.md` **before** replacing `CLAUDE.md` with the symlink.
- If the repo already has Dolt refs in its git remote, use `bd bootstrap` (not `bd init`) and **restart the Dolt server** afterwards: `bd dolt stop && bd dolt start`.
- The first `pre-commit run --all-files` will flag pre-existing lint violations — fix them in a dedicated cleanup commit, or use `git commit --no-verify` for the adoption commit and clean up in a follow-up.
- Existing `doc/` READMEs with richer content than the template scaffolds are preserved by default (existing files are skipped on both the GNU and BSD copy paths); pass `--force` only when you want to resync from upstream. `README.md` and the wiki core pages (`overview.md`, `goals.md`, `status.md`, `log.md`) are **never** overwritten, even with `--force`.

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
    ├── overview.md        # Synthesis front page: the high-level idea
    ├── index.md           # Master catalog of every wiki page
    ├── log.md             # Append-only chronological log
    ├── goals.md           # Long-horizon + short-horizon goals
    ├── status.md          # Current progress snapshot (cross-linked to bd)
    ├── architecture/      # System design and component diagrams
    ├── benchmarks/        # E2E verification scenarios, benchmark results
    ├── considerations/    # Open trade-offs, risks, unresolved questions
    ├── decisions/         # Architecture Decision Records (ADR)
    ├── development/       # Developer guides, setup, post-mortems
    ├── guidance/          # External expert consultations (requests + responses)
    ├── inbox/             # Untriaged feature requests from external teams/agents
    ├── plans/             # Implementation plans and task tracking
    ├── runbooks/          # Operational procedures (incl. wiki-lint)
    ├── sources/           # Immutable raw sources (requirements, transcripts, research)
    └── vision/            # Product ideas, future concepts
```

## Deliberate conventions

- **`doc/` is a living LLM Wiki, not a doc dump** — agents ingest/query/lint it so project context compounds instead of scattering. `bd` tracks discrete work items; the wiki holds the synthesized narrative.
- **`AGENTS.md` is canonical, `CLAUDE.md` is the symlink** — aligns with the emerging cross-agent standard.
- **Worktrees are embraced, not forbidden** — parallel multi-agent development is a first-class goal.
- **Semantic `bd` IDs** (`<prefix>-<epic>[-<task>]`) are preferred over auto-generated hashes.
- **All implementation plans live in `doc/plans/` before coding starts**, with user approval.
- **Guidance response documents are authored by the user, never by an agent.**

See `AGENTS.md` for the operational rules behind each of these.

## License

See [`LICENSE`](./LICENSE).
