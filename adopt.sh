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
  --force        Overwrite existing AGENTS.md in the target.
                 (README.md is never overwritten; a placeholder is only
                 written when the target has no README.md.)
  --help         Show this message.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)  [[ $# -ge 2 ]] || { echo "--target requires DIR" >&2; exit 2; }
               TARGET="$2"; shift 2 ;;
    --role)    [[ $# -ge 2 ]] || { echo "--role requires ROLE" >&2; exit 2; }
               ROLE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1;    shift ;;
    --force)   FORCE=1;      shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown flag: $1" >&2; usage; exit 2 ;;
  esac
done

run() {
  if [[ "$DRY_RUN" == 1 ]]; then
    printf 'DRY:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

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

validate_target() {
  [[ -d "$TARGET" ]] || { echo "target is not a directory: $TARGET" >&2; exit 1; }
  git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1 \
    || { echo "target is not a git repo: $TARGET (run 'git init' first)" >&2; exit 1; }
}

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

# Template-about-template paths that adopted projects must NOT receive.
# The GNU path renders these as anchored tar --exclude globs; the BSD path
# deletes them by exact name from a staging dir. Keep this list in sync with
# doc/development/adopting-with-script.md.
#
# README.md is paired with write_placeholder_readme(); the wiki core pages
# (overview/goals/status/log) are paired with write_wiki_placeholders() —
# removing either from this list leaks THIS repo's own content downstream.
TEMPLATE_EXCLUDE_PATHS=(
  README.md
  adopt.sh
  doc/development/adopting-with-script.md
  doc/plans/2026-04-17-adopt-script.md
  doc/plans/2026-04-20-adopt-sh-feedback.md
  doc/plans/2026-07-10-llm-wiki-migration.md
  doc/inbox/2026-04-20-blog-project-adopt-sh-feedback.md
  doc/overview.md
  doc/goals.md
  doc/status.md
  doc/log.md
  test
)

detect_toolchain() {
  # GNU and BSD tar differ on the flags we rely on (--skip-old-files,
  # --anchored). Rather than trust the vendor string (uname is the OS, not the
  # tool; tar --version text varies across busybox/bsdarchive/GNU), we PROBE the
  # capability: build a throwaway empty archive, then attempt to extract it with
  # the GNU-only flags. Success => GNU fast path; failure => portable BSD path.
  # Bash has no try/catch, so the attempt is wrapped in `if …; then` (a failing
  # command there does not trip `set -e`).
  if command -v gtar >/dev/null 2>&1; then
    TAR_BIN="gtar"
  else
    TAR_BIN="tar"
  fi
  local d
  d="$(mktemp -d)"
  if "$TAR_BIN" -cf "$d/empty.tar" -C "$d" . 2>/dev/null \
     && "$TAR_BIN" -xf "$d/empty.tar" --skip-old-files --anchored -C "$d" 2>/dev/null; then
    TAR_IS_GNU=1
  else
    TAR_IS_GNU=0
  fi
  rm -rf "$d"
}

copy_template_files() {
  # git archive HEAD emits only tracked files and preserves the CLAUDE.md
  # symlink. We filter out template-about-template artefacts (see
  # TEMPLATE_EXCLUDE_PATHS) and never clobber files the target already has
  # (unless --force). The mechanism differs by tar flavor.
  detect_toolchain
  if [[ "$TAR_IS_GNU" == 1 ]]; then
    copy_template_files_gnu
  else
    copy_template_files_bsd
  fi
}

copy_template_files_gnu() {
  # GNU tar: extract straight into TARGET.
  #   --anchored           match --exclude from the path root, so README.md drops
  #                        the root file but not doc/*/README.md index files.
  #   --exclude=$p/*       companion glob that drops directory contents (test/*).
  #   --skip-old-files     silently keep existing files (re-run safe, exits 0);
  #                        --force (FORCE=1) drops it to resync with upstream.
  local -a tar_cmd=("$TAR_BIN" -x --anchored)
  [[ "$FORCE" == 1 ]] || tar_cmd+=(--skip-old-files)
  local p
  for p in "${TEMPLATE_EXCLUDE_PATHS[@]}"; do
    tar_cmd+=(--exclude="$p" --exclude="$p/*")
  done
  tar_cmd+=(-C "$TARGET")
  if [[ "$DRY_RUN" == 1 ]]; then
    printf 'DRY: git -C %q archive HEAD |' "$SCRIPT_DIR"
    printf ' %q' "${tar_cmd[@]}"
    printf '\n'
    return 0
  fi
  git -C "$SCRIPT_DIR" archive HEAD | "${tar_cmd[@]}"
}

copy_template_files_bsd() {
  # BSD/libarchive tar lacks --skip-old-files and --anchored, and its exclude
  # matching is not path-anchored. So extract into a clean staging dir (no
  # clobber concerns there), delete the excluded paths by exact name, then copy
  # into TARGET with a portable, symlink-preserving, skip-existing copy.
  if [[ "$DRY_RUN" == 1 ]]; then
    printf 'DRY: git -C %q archive HEAD | %s -x -C <staging>\n' "$SCRIPT_DIR" "$TAR_BIN"
    printf 'DRY: rm -rf from <staging>:'; printf ' %q' "${TEMPLATE_EXCLUDE_PATHS[@]}"; printf '\n'
    printf 'DRY: copy <staging> -> %q (skip existing files' "$TARGET"
    [[ "$FORCE" == 1 ]] && printf ', --force overwrites'
    printf ')\n'
    return 0
  fi
  local staging
  staging="$(mktemp -d)"
  # shellcheck disable=SC2064  # expand $staging now so the trap targets this dir
  trap "rm -rf '$staging'" RETURN
  git -C "$SCRIPT_DIR" archive HEAD | "$TAR_BIN" -x -C "$staging"
  local p
  for p in "${TEMPLATE_EXCLUDE_PATHS[@]}"; do
    rm -rf "${staging:?}/$p"
  done
  copy_skip_existing "$staging" "$TARGET"
}

copy_skip_existing() {
  # Copy every entry from src into dst: recreate directories, preserve symlinks,
  # and skip files that already exist unless FORCE=1. Uses only cp flags common
  # to GNU and BSD cp (-P preserve symlinks, -f force when we do overwrite);
  # existence is checked in bash so we never depend on cp's -n/--skip-old-files.
  local src="$1" dst="$2" path rel target
  while IFS= read -r -d '' path; do
    [[ "$path" == "$src" ]] && continue
    rel="${path#"$src"/}"
    target="$dst/$rel"
    if [[ -d "$path" && ! -L "$path" ]]; then
      mkdir -p "$target"
      continue
    fi
    if [[ ( -e "$target" || -L "$target" ) && "$FORCE" != 1 ]]; then
      continue
    fi
    mkdir -p "$(dirname "$target")"
    cp -Pf "$path" "$target"
  done < <(find "$src" -print0)
}

write_placeholder_readme() {
  # README.md is adopted-project content, not template content — we do NOT
  # check $FORCE here because --force means "resync template-owned files".
  # Pairs with copy_template_files --exclude=README.md. If that exclusion is
  # removed, this function no-ops and the template's self-description leaks.
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

write_wiki_placeholders() {
  # The wiki core pages (overview/goals/status/log) are adopted-project
  # content, not template content — the template's own copies are excluded
  # from copy_template_files (see TEMPLATE_EXCLUDES) and fresh placeholders
  # are written here so doc/index.md's links resolve. Like the README
  # placeholder, we do NOT honour $FORCE (that means "resync template-owned
  # files") and we never clobber a page the user already filled in.
  local doc="$TARGET/doc"
  local -a pages=(overview.md goals.md status.md log.md)
  local page path
  for page in "${pages[@]}"; do
    path="$doc/$page"
    if [[ -f "$path" ]]; then
      echo "doc/$page already exists in $TARGET, leaving it alone"
      continue
    fi
    if [[ "$DRY_RUN" == 1 ]]; then
      printf 'DRY: write placeholder doc/%s to %q\n' "$page" "$path"
      continue
    fi
    mkdir -p "$doc"
    case "$page" in
      overview.md) cat > "$path" <<'EOF'
# Overview

The synthesis front page of this wiki — the high-level idea, kept current as the
project evolves. Start here, then follow the links.

## What this is

TODO: what this project does, who uses it, and the headline technology.

**Primary language / runtime:** TODO
**Package manager:** TODO

## The core idea

This project's `doc/` tree is maintained as a development-focused LLM Wiki — a
persistent, compounding, interlinked knowledge base that agents keep current.
See [AGENTS.md → Project as an LLM Wiki](../AGENTS.md#project-as-an-llm-wiki).

## Related

- [goals.md](goals.md) · [status.md](status.md) · [index.md](index.md)
- [../README.md](../README.md) · [../AGENTS.md](../AGENTS.md)
EOF
        ;;
      goals.md) cat > "$path" <<'EOF'
# Goals

Long-horizon (north star) and short-horizon (current cycle) goals. When a goal
is met, move it to "Achieved"; when direction changes, revise it and note the
change in [log.md](log.md).

## North star (long horizon)

- TODO: the durable direction that rarely changes.

## Current cycle (short horizon)

- [ ] TODO: concrete goals for the active cycle (link `bd` tickets).

## Achieved

- _nothing yet_

## Related

- [overview.md](overview.md) · [status.md](status.md)
- [vision/](vision/README.md) · [plans/](plans/README.md)
EOF
        ;;
      status.md) cat > "$path" <<'EOF'
# Status

Current progress snapshot — the narrative complement to `bd status`. Refresh on
any status change and during each [wiki-lint](runbooks/wiki-lint.md) pass. For
the live work queue, run `bd ready` and `bd status`.

_Last updated: TODO_

## In progress

- TODO

## Done recently

- TODO

## Blocked / waiting

- _none_

## Next up

- TODO

## Related

- [goals.md](goals.md) · [log.md](log.md) · [index.md](index.md)
EOF
        ;;
      log.md) cat > "$path" <<'EOF'
# Wiki Log

Append-only chronological record of wiki activity. **Newest entries at the top.**

Each entry starts with a consistent prefix so the log is greppable:

```
## [YYYY-MM-DD] <type> | <title>
```

Types: `ingest`, `decision`, `progress`, `lint`.
Timeline: `grep "^## \[" doc/log.md | head`.

---

## [YYYY-MM-DD] progress | Project bootstrapped from ai-assisted-development template

TODO: replace with the first real log entry.
EOF
        ;;
    esac
  done
}

install_precommit() {
  if [[ "$DRY_RUN" == 1 ]]; then
    printf 'DRY: (cd %q && pre-commit install)\n' "$TARGET"
    return 0
  fi
  [[ -f "$TARGET/.pre-commit-config.yaml" ]] \
    || { echo "no .pre-commit-config.yaml in $TARGET — copy_template_files must run first" >&2; return 1; }
  # Skip if the hook already has the BEADS merge (wire_bd_hook ran in a prior
  # adopt.sh invocation). Without this guard, pre-commit install would clobber
  # the merged hook with the plain framework template, forcing wire_bd_hook to
  # re-merge on every re-run.
  if [[ -f "$TARGET/.git/hooks/pre-commit" ]] \
    && grep -q "BEGIN BEADS INTEGRATION" "$TARGET/.git/hooks/pre-commit"; then
    echo "pre-commit hook already merged with BEADS in $TARGET, skipping pre-commit install"
    return 0
  fi
  (cd "$TARGET" && pre-commit install)
}

wire_bd_hook() {
  local hook="$TARGET/.git/hooks/pre-commit"
  if [[ -f "$hook" ]] && grep -q "BEGIN BEADS INTEGRATION" "$hook"; then
    echo "BEADS block already present in $hook, skipping"
    return 0
  fi
  if [[ "$DRY_RUN" == 1 ]]; then
    printf 'DRY: would prepend BEADS block to %s\n' "$hook"
    return 0
  fi
  local source="$TARGET/.beads/hooks/pre-commit"
  [[ -f "$source" ]] || { echo "expected $source after bd init, not found" >&2; return 1; }
  local beads_block
  beads_block="$(sed -n '/BEGIN BEADS INTEGRATION/,/END BEADS INTEGRATION/p' "$source")"
  [[ -n "$beads_block" ]] || { echo "could not extract BEADS block from $source" >&2; return 1; }
  local current
  current="$(cat "$hook")"
  # Strip the existing shebang (if any) with pure bash — the GNU-only sed
  # address form `sed '1{/^#!/d}'` is rejected by BSD sed on macOS.
  if [[ "$current" == '#!'*$'\n'* ]]; then
    current="${current#*$'\n'}"
  fi
  {
    printf '#!/usr/bin/env bash\n'
    printf '%s\n\n' "$beads_block"
    printf '%s\n' "$current"
  } > "$hook.new"
  mv "$hook.new" "$hook"
  chmod +x "$hook"
  # Unset core.hooksPath so git uses .git/hooks/pre-commit instead of
  # .beads/hooks/pre-commit (which bd init sets). The merged hook now lives
  # at the standard location that pre-commit install expects.
  git -C "$TARGET" config --unset core.hooksPath 2>/dev/null || true
}

set_role() {
  run git -C "$TARGET" config beads.role "$ROLE"
}

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

bd_init() {
  # bd init on a template-fresh AGENTS.md may panic in updateAgentFile while
  # injecting the BEADS-INTEGRATION marker region (upstream bug). We accept
  # partial success: .beads/config.yaml + .beads/hooks/pre-commit must exist.
  if [[ -f "$TARGET/.beads/config.yaml" ]]; then
    echo "bd already initialised in $TARGET, skipping bd init"
    return 0
  fi
  if [[ "$DRY_RUN" == 1 ]]; then
    printf 'DRY: (cd %q && bd init)\n' "$TARGET"
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

ensure_beads_markers() {
  # Safety net for the upstream 'bd init' updateAgentFile panic: if bd did
  # not inject its HTML-comment markers into AGENTS.md, reserve the region
  # ourselves so agents honour the "don't edit inside" contract. A future
  # successful 'bd init' (or upstream fix) will find the markers and fill
  # the region in; until then, the block is intentionally near-empty.
  local agents="$TARGET/AGENTS.md"
  [[ -f "$agents" ]] || return 0
  if grep -q 'BEADS-INTEGRATION:BEGIN' "$agents"; then
    return 0
  fi
  if [[ "$DRY_RUN" == 1 ]]; then
    printf 'DRY: append BEADS-INTEGRATION marker block to %q\n' "$agents"
    return 0
  fi
  local tmp
  tmp="$(mktemp "$agents.adopt.XXXXXX")"
  cat "$agents" > "$tmp"
  cat >> "$tmp" <<'EOF'

<!-- BEADS-INTEGRATION:BEGIN -->
<!-- Managed by bd (beads). Do not hand-edit between these markers. -->
<!-- Region reserved by adopt.sh because 'bd init' updateAgentFile panicked; -->
<!-- a subsequent successful 'bd init' will populate this block. -->
<!-- BEADS-INTEGRATION:END -->
EOF
  mv -f "$tmp" "$agents"
}

main() {
  require_prereqs
  validate_target
  check_git_writable
  copy_template_files
  write_placeholder_readme
  write_wiki_placeholders
  install_precommit
  bd_init
  ensure_beads_markers
  wire_bd_hook
  set_role
  report_next_steps
}

main
