#!/usr/bin/env bash
# adopt.sh — copy this template into TARGET and wire up pre-commit + bd.
# See ./AGENTS.md → "Project Initialization Checklist" for the manual equivalent.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${PWD}"
# shellcheck disable=SC2034  # used by set_role (Task 9)
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
               # shellcheck disable=SC2034  # used by set_role (Task 9)
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

copy_template_files() {
  # git archive only includes tracked files and preserves the CLAUDE.md symlink.
  # --skip-old-files silently skips existing files and exits 0, so re-runs do not
  # clobber a filled-in AGENTS.md and do not trip `set -euo pipefail`.
  # --force (FORCE=1) drops the flag to resync with upstream template changes.
  local -a tar_cmd=(tar -x)
  [[ "$FORCE" == 1 ]] || tar_cmd+=(--skip-old-files)
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
  [[ -f "$TARGET/.pre-commit-config.yaml" ]] \
    || { echo "no .pre-commit-config.yaml in $TARGET — copy_template_files must run first" >&2; return 1; }
  if [[ "$DRY_RUN" == 1 ]]; then
    printf 'DRY: (cd %q && pre-commit install)\n' "$TARGET"
    return 0
  fi
  # pre-commit install refuses when core.hooksPath is set (bd init sets it to
  # .beads/hooks on first run). If .beads/hooks/pre-commit is already in place,
  # the hook chain is working — treat the refusal as a successful no-op.
  local rc=0
  (cd "$TARGET" && pre-commit install >/dev/null) || rc=$?
  if [[ $rc -ne 0 && -f "$TARGET/.beads/hooks/pre-commit" ]]; then
    return 0
  fi
  return $rc
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

main() {
  require_prereqs
  validate_target
  copy_template_files
  install_precommit
  bd_init
  echo "TODO: wire bd hook + role"
}

main
