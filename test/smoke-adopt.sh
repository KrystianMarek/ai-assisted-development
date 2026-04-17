#!/usr/bin/env bash
# test/smoke-adopt.sh — end-to-end sanity check for adopt.sh.
# Creates a throwaway git repo, runs adopt.sh, asserts the end state,
# and cleans up. Not wired into pre-commit (too slow); run on demand.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

git -C "$WORKDIR" init -q
git -C "$WORKDIR" remote add origin "ssh://git@example.invalid/smoke.git"

"$TEMPLATE/adopt.sh" --target "$WORKDIR" --role maintainer

fail=0
check() { if eval "$2"; then echo "  OK  $1"; else echo "  FAIL $1"; fail=1; fi }

check "AGENTS.md copied"                    "[[ -f '$WORKDIR/AGENTS.md' ]]"
check "CLAUDE.md is a symlink"              "[[ -L '$WORKDIR/CLAUDE.md' ]]"
check "doc/plans/README.md copied"          "[[ -f '$WORKDIR/doc/plans/README.md' ]]"
check ".beads/config.yaml present"          "[[ -f '$WORKDIR/.beads/config.yaml' ]]"
check "pre-commit hook exists"              "[[ -x '$WORKDIR/.git/hooks/pre-commit' ]]"
check "BEADS block present in hook"         "grep -q 'BEGIN BEADS INTEGRATION' '$WORKDIR/.git/hooks/pre-commit'"
check "BEADS block is ABOVE pre-commit exec" "awk '/BEGIN BEADS INTEGRATION/{b=NR} /^if \\[ -x \"\\\$INSTALL_PYTHON\" \\]/{if(b && NR>b) exit 0; exit 1}' '$WORKDIR/.git/hooks/pre-commit'"
check "beads.role configured"               "[[ \"\$(git -C '$WORKDIR' config beads.role)\" == 'maintainer' ]]"

# Simulate a user filling in Project Overview, then re-run without --force.
# The edited AGENTS.md must survive.
printf '\n# SMOKE-SENTINEL do-not-clobber\n' >> "$WORKDIR/AGENTS.md"
"$TEMPLATE/adopt.sh" --target "$WORKDIR" --role maintainer >/dev/null
check "re-run preserves user edits to AGENTS.md" "grep -q 'SMOKE-SENTINEL' '$WORKDIR/AGENTS.md'"

if (( fail )); then echo "smoke test FAILED"; exit 1; else echo "smoke test passed"; fi
