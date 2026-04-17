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
    --target)  TARGET="$2";  shift 2 ;;
    --role)    ROLE="$2";    shift 2 ;;
    --dry-run) DRY_RUN=1;    shift ;;
    --force)   FORCE=1;      shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown flag: $1" >&2; usage; exit 2 ;;
  esac
done

run() {
  if [[ "$DRY_RUN" == 1 ]]; then
    printf 'DRY: %s\n' "$*"
  else
    "$@"
  fi
}

main() {
  echo "TODO: adoption steps"
}

main
