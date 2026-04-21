#!/usr/bin/env bash
# test/smoke-adopt.sh — end-to-end sanity check for adopt.sh.
# Creates a throwaway git repo, runs adopt.sh, asserts the end state,
# and cleans up. Not wired into pre-commit (too slow); run on demand.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$(cd "$SCRIPT_DIR/.." && pwd)"

WORKDIR='' WORKDIR2='' WORKDIR3=''
cleanup() {
  [[ -n "$WORKDIR3" && -d "$WORKDIR3/.git/hooks" ]] && chmod 755 "$WORKDIR3/.git/hooks" 2>/dev/null || true
  rm -rf "${WORKDIR:-}" "${WORKDIR2:-}" "${WORKDIR3:-}"
}
trap cleanup EXIT

WORKDIR="$(mktemp -d)"

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
check "BEADS block is ABOVE pre-commit exec" "awk '
  /BEGIN BEADS INTEGRATION/ { beads=NR }
  /END BEADS INTEGRATION/   { beads_end=NR }
  /^if \[/ { if (beads_end && beads_end < NR) { print \"ok\"; exit 0 } exit 1 }
' '$WORKDIR/.git/hooks/pre-commit' | grep -q ok"
check "beads.role configured"               "[[ \"\$(git -C '$WORKDIR' config beads.role)\" == 'maintainer' ]]"
check "adopt.sh NOT copied to target"        "[[ ! -e '$WORKDIR/adopt.sh' ]]"
check "adopting-with-script.md NOT copied"   "[[ ! -e '$WORKDIR/doc/development/adopting-with-script.md' ]]"
check "adopt-script plan NOT copied"         "[[ ! -e '$WORKDIR/doc/plans/2026-04-17-adopt-script.md' ]]"
check "test/ directory NOT copied"           "[[ ! -e '$WORKDIR/test' ]]"
check "placeholder README written"           "grep -q 'TODO: one-paragraph description' '$WORKDIR/README.md'"
check "template README NOT leaked"           "! grep -q 'ai-assisted-development template' '$WORKDIR/README.md'"
check "BEADS-INTEGRATION markers in AGENTS.md" "grep -q 'BEADS-INTEGRATION:BEGIN' '$WORKDIR/AGENTS.md'"

# Simulate a user filling in Project Overview, then re-run without --force.
# The edited AGENTS.md must survive.
printf '\n# SMOKE-SENTINEL do-not-clobber\n' >> "$WORKDIR/AGENTS.md"
"$TEMPLATE/adopt.sh" --target "$WORKDIR" --role maintainer >/dev/null
check "re-run preserves user edits to AGENTS.md" "grep -q 'SMOKE-SENTINEL' '$WORKDIR/AGENTS.md'"

# Scenario 2: target already has a README — adopt.sh must leave it alone.
WORKDIR2="$(mktemp -d)"
git -C "$WORKDIR2" init -q
git -C "$WORKDIR2" remote add origin "ssh://git@example.invalid/smoke2.git"
printf '# real project\n\nkeep me\n' > "$WORKDIR2/README.md"
"$TEMPLATE/adopt.sh" --target "$WORKDIR2" --role maintainer >/dev/null
check "pre-existing README.md preserved" "grep -q 'keep me' '$WORKDIR2/README.md'"
check "no placeholder appended to pre-existing README" "! grep -q 'TODO: one-paragraph description' '$WORKDIR2/README.md'"

# Scenario 3: .git/hooks/ is read-only — adopt.sh must exit non-zero with
# an actionable error message mentioning the sandbox cause.
WORKDIR3="$(mktemp -d)"
git -C "$WORKDIR3" init -q
chmod 555 "$WORKDIR3/.git/hooks"
set +e
# shellcheck disable=SC2034  # err_output is consumed via eval inside check()
err_output="$("$TEMPLATE/adopt.sh" --target "$WORKDIR3" --role maintainer 2>&1)"
rc=$?
set -e
chmod 755 "$WORKDIR3/.git/hooks"
check "read-only .git/hooks aborts with non-zero exit" "[[ $rc -ne 0 ]]"
check "read-only error mentions sandbox"               "grep -q 'sandboxed agent harnesses' <<<\"\$err_output\""

if (( fail )); then echo "smoke test FAILED"; exit 1; else echo "smoke test passed"; fi
