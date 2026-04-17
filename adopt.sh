#!/usr/bin/env bash
# adopt.sh — copy this template into TARGET and wire up pre-commit + bd.
# See ./AGENTS.md → "Project Initialization Checklist" for the manual equivalent.
set -euo pipefail

# shellcheck disable=SC2034  # used by copy_template_files (Task 5)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034  # used by validate_target (Task 4)
TARGET="${PWD}"
# shellcheck disable=SC2034  # used by set_role (Task 9)
ROLE="maintainer"
DRY_RUN=0
# shellcheck disable=SC2034  # used by copy_template_files (Task 5)
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
               # shellcheck disable=SC2034  # used by validate_target (Task 4)
               TARGET="$2"; shift 2 ;;
    --role)    [[ $# -ge 2 ]] || { echo "--role requires ROLE" >&2; exit 2; }
               # shellcheck disable=SC2034  # used by set_role (Task 9)
               ROLE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1;    shift ;;
    --force)   # shellcheck disable=SC2034  # used by copy_template_files (Task 5)
               FORCE=1;      shift ;;
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

main() {
  require_prereqs
  echo "TODO: remaining steps"
}

main
