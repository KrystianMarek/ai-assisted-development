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

copy_template_files() {
  # git archive HEAD emits only tracked files and preserves the CLAUDE.md
  # symlink. We pipe through tar -x so we can apply --exclude filters for
  # template-about-template artefacts that adopted projects should not
  # receive (see TEMPLATE_EXCLUDES below).
  #
  # --skip-old-files silently skips existing files and exits 0, so re-runs
  # do not clobber a filled-in AGENTS.md and do not trip set -euo pipefail.
  # --force (FORCE=1) drops the flag to resync with upstream template changes.
  #
  # --anchored makes --exclude match only against the leading path component,
  # so --exclude=README.md drops the root README.md without also dropping
  # doc/*/README.md index files that adopted projects need.
  local -a TEMPLATE_EXCLUDES=(
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
  {
    printf '#!/usr/bin/env bash\n'
    printf '%s\n\n' "$beads_block"
    # Strip the existing shebang (if any) from the current file.
    printf '%s\n' "$current" | sed '1{/^#!/d}'
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
  2. Replace $TARGET/README.md with a README describing the new project
     (the template's README is about the template itself).
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
  install_precommit
  bd_init
  ensure_beads_markers
  wire_bd_hook
  set_role
  report_next_steps
}

main
