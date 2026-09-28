#!/usr/bin/env bash
# test/smoke-adopt.sh — end-to-end sanity check for adopt.sh.
# Creates a throwaway git repo, runs adopt.sh, asserts the end state,
# and cleans up. Not wired into pre-commit (too slow); run on demand.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$(cd "$SCRIPT_DIR/.." && pwd)"

WORKDIR='' WORKDIR2='' WORKDIR3='' WORKDIR4='' WORKDIR5='' SHIMDIR=''
cleanup() {
  if [[ -n "$WORKDIR3" && -d "$WORKDIR3/.git/hooks" ]]; then
    chmod 755 "$WORKDIR3/.git/hooks" 2>/dev/null || true
  fi
  rm -rf "${WORKDIR:-}" "${WORKDIR2:-}" "${WORKDIR3:-}" "${WORKDIR4:-}" "${WORKDIR5:-}" "${SHIMDIR:-}"
}
trap cleanup EXIT

WORKDIR="$(mktemp -d)"

git -C "$WORKDIR" init -q
git -C "$WORKDIR" remote add origin "ssh://git@example.invalid/smoke.git"

"$TEMPLATE/adopt.sh" --target "$WORKDIR" --role maintainer

MONTH="$(date +%Y-%m)"
# Commits in throwaway repos: fixed identity, no hooks (bd/pre-commit are
# exercised separately and are not what these commits test).
gitc() { git -C "$1" -c user.name=smoke -c user.email=smoke@example.invalid "${@:2}"; }

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
check "adopt-sh feedback plan NOT copied"    "[[ ! -e '$WORKDIR/doc/plans/2026-04-20-adopt-sh-feedback.md' ]]"
check "llm-wiki migration plan NOT copied"   "[[ ! -e '$WORKDIR/doc/plans/2026-07-10-llm-wiki-migration.md' ]]"
check "blog-project feedback inbox NOT copied" "[[ ! -e '$WORKDIR/doc/inbox/2026-04-20-blog-project-adopt-sh-feedback.md' ]]"
check "test/ directory NOT copied"           "[[ ! -e '$WORKDIR/test' ]]"
check "placeholder README written"           "grep -q 'TODO: one-paragraph description' '$WORKDIR/README.md'"
check "template README NOT leaked"           "! grep -q 'project template' '$WORKDIR/README.md'"
check "BEADS-INTEGRATION markers in AGENTS.md" "grep -q 'BEADS-INTEGRATION:BEGIN' '$WORKDIR/AGENTS.md'"

# LLM Wiki: generic scaffolds ARE copied; the wiki catalog + lint runbook too.
check "doc/index.md copied"                  "[[ -f '$WORKDIR/doc/index.md' ]]"
check "doc/sources/README.md copied"         "[[ -f '$WORKDIR/doc/sources/README.md' ]]"
check "doc/considerations/README.md copied"  "[[ -f '$WORKDIR/doc/considerations/README.md' ]]"
check "doc/runbooks/wiki-lint.md copied"     "[[ -f '$WORKDIR/doc/runbooks/wiki-lint.md' ]]"
check "AGENTS.md has LLM Wiki schema section" "grep -q 'Project as an LLM Wiki' '$WORKDIR/AGENTS.md'"

# LLM Wiki: core pages are written as placeholders, not the template's own copies.
check "placeholder overview.md written"      "grep -q 'TODO: what this project does' '$WORKDIR/doc/overview.md'"
check "placeholder goals.md written"         "[[ -f '$WORKDIR/doc/goals.md' ]] && grep -q 'North star' '$WORKDIR/doc/goals.md'"
check "placeholder status.md written"        "[[ -f '$WORKDIR/doc/status.md' ]] && grep -q 'Last updated: TODO' '$WORKDIR/doc/status.md'"
check "placeholder log.md written"           "grep -q '^# Wiki Log' '$WORKDIR/doc/log.md'"
check "overview.md template content NOT leaked" "! grep -q 'is a project template for starting new repositories' '$WORKDIR/doc/overview.md'"
check "goals.md template content NOT leaked"  "! grep -q 'Zero-friction adoption' '$WORKDIR/doc/goals.md'"
check "status.md template content NOT leaked" "! grep -q 'v0.0.1' '$WORKDIR/doc/status.md'"
check "log.md template content NOT leaked"    "! grep -q 'LLM Wiki migration' '$WORKDIR/doc/log.md'"

# Conflict-free log: entry page + first monthly file; template's own log not leaked.
check "log.md is the entry page (no entries)"  "grep -q 'This page holds \*\*no' '$WORKDIR/doc/log.md'"
check "log.md lists the first month"           "grep -qF '[$MONTH](log/$MONTH.md)' '$WORKDIR/doc/log.md'"
check "first monthly log file written"         "grep -q 'bootstrapped from the ai-assisted-development template' '$WORKDIR/doc/log/$MONTH.md'"
check "template monthly log NOT leaked"        "! grep -rqs 'odin adoption review' '$WORKDIR/doc/log/' && [[ ! -e '$WORKDIR/doc/log/2026-07.md' ]]"
check "log-hygiene plan NOT copied"            "[[ ! -e '$WORKDIR/doc/plans/2026-09-28-log-external-hygiene.md' ]]"
check ".gitattributes sets union merge for log" "grep -q 'merge=union' '$WORKDIR/.gitattributes'"
check "wiki-log hook accepts placeholder log"  "(cd '$WORKDIR' && pre-commit run wiki-log-format --files 'doc/log/$MONTH.md' >/dev/null)"
cp "$WORKDIR/doc/log/$MONTH.md" "$WORKDIR/log.bak"
printf -- '- %s-01 progress | first line\n  wrapped continuation\n' "$MONTH" >> "$WORKDIR/doc/log/$MONTH.md"
check "wiki-log hook rejects multi-line entry" "! (cd '$WORKDIR' && pre-commit run wiki-log-format --files 'doc/log/$MONTH.md' >/dev/null)"
cp "$WORKDIR/log.bak" "$WORKDIR/doc/log/$MONTH.md"
printf -- '- %s-01 progress | %s\n' "$MONTH" "$(printf 'x%.0s' $(seq 1 240))" >> "$WORKDIR/doc/log/$MONTH.md"
check "wiki-log hook rejects over-long entry"  "! (cd '$WORKDIR' && pre-commit run wiki-log-format --files 'doc/log/$MONTH.md' >/dev/null)"
cp "$WORKDIR/log.bak" "$WORKDIR/doc/log/$MONTH.md"
printf '## [%s-01] progress | legacy entry\n' "$MONTH" >> "$WORKDIR/doc/log.md"
check "wiki-log hook rejects entry in log.md"  "! (cd '$WORKDIR' && pre-commit run wiki-log-no-entries-in-index --files doc/log.md >/dev/null)"
sed -i.bak '$d' "$WORKDIR/doc/log.md" && rm -f "$WORKDIR/doc/log.md.bak" "$WORKDIR/log.bak"

# external/ scaffold + repo-hygiene tooling ship to adopters.
check "external/.gitignore copied"             "[[ -f '$WORKDIR/external/.gitignore' ]]"
check "external/README.md index copied"        "grep -q 'Index of clones' '$WORKDIR/external/README.md'"
check "repo-hygiene runbook copied"            "[[ -f '$WORKDIR/doc/runbooks/repo-hygiene.md' ]]"
check "repo-hygiene runbook indexed"           "grep -q 'repo-hygiene.md' '$WORKDIR/doc/runbooks/README.md'"
check "repo-hygiene script executable"         "[[ -x '$WORKDIR/scripts/repo-hygiene.sh' ]]"
check ".worktrees/ ignored"                    "grep -qx '.worktrees/' '$WORKDIR/.gitignore'"
check "AGENTS.md has Repository Hygiene"       "grep -q '^## Repository Hygiene' '$WORKDIR/AGENTS.md'"

# Simulate a user filling in Project Overview and a wiki page, then re-run
# without --force. The edited AGENTS.md and wiki page must survive.
printf '\n# SMOKE-SENTINEL do-not-clobber\n' >> "$WORKDIR/AGENTS.md"
printf '\n# SMOKE-SENTINEL-OVERVIEW\n' >> "$WORKDIR/doc/overview.md"
"$TEMPLATE/adopt.sh" --target "$WORKDIR" --role maintainer >/dev/null
check "re-run preserves user edits to AGENTS.md" "grep -q 'SMOKE-SENTINEL' '$WORKDIR/AGENTS.md'"
check "re-run preserves user edits to overview.md" "grep -q 'SMOKE-SENTINEL-OVERVIEW' '$WORKDIR/doc/overview.md'"

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

# Scenario 4: force the BSD copy path (staging + rm-excludes + skip-copy) even
# on GNU-only hosts. adopt.sh decides GNU-vs-BSD by a capability probe: it
# attempts `tar -xf … --skip-old-files --anchored` and treats failure as "not
# GNU". We shadow `gtar` with a wrapper that rejects those GNU-only flags (so
# the probe fails) but delegates plain -c/-x to the real tar (so the BSD path's
# extraction still works). This exercises the portable path on Linux CI.
SHIMDIR="$(mktemp -d)"
cat > "$SHIMDIR/gtar" <<'SHIM'
#!/usr/bin/env bash
# Fake gtar: reject GNU-only flags so adopt.sh's capability probe selects the
# BSD path. Plain -c/-x (no GNU flags) delegate to the real tar.
for a in "$@"; do
  case "$a" in
    --skip-old-files|--anchored) exit 2 ;;
  esac
done
exec tar "$@"
SHIM
chmod +x "$SHIMDIR/gtar"
WORKDIR4="$(mktemp -d)"
git -C "$WORKDIR4" init -q
git -C "$WORKDIR4" remote add origin "ssh://git@example.invalid/smoke4.git"
PATH="$SHIMDIR:$PATH" "$TEMPLATE/adopt.sh" --target "$WORKDIR4" --role maintainer >/dev/null
check "BSD path: AGENTS.md copied"          "[[ -f '$WORKDIR4/AGENTS.md' ]]"
check "BSD path: CLAUDE.md symlink preserved" "[[ -L '$WORKDIR4/CLAUDE.md' ]]"
check "BSD path: doc/index.md copied"       "[[ -f '$WORKDIR4/doc/index.md' ]]"
check "BSD path: adopt.sh excluded"         "[[ ! -e '$WORKDIR4/adopt.sh' ]]"
check "BSD path: test/ excluded"            "[[ ! -e '$WORKDIR4/test' ]]"
check "BSD path: placeholder README written" "grep -q 'TODO: one-paragraph description' '$WORKDIR4/README.md'"
check "BSD path: overview placeholder written" "grep -q 'TODO: what this project does' '$WORKDIR4/doc/overview.md'"
# Re-run must not clobber a filled-in page (skip-existing).
printf '\n# SMOKE-SENTINEL-BSD\n' >> "$WORKDIR4/doc/overview.md"
PATH="$SHIMDIR:$PATH" "$TEMPLATE/adopt.sh" --target "$WORKDIR4" --role maintainer >/dev/null
check "BSD path: re-run preserves user edits" "grep -q 'SMOKE-SENTINEL-BSD' '$WORKDIR4/doc/overview.md'"

# Scenario 5: parallel log appends merge without conflict (union driver), and
# repo-hygiene reports clean, then flags planted cruft.
gitc "$WORKDIR" add -A
gitc "$WORKDIR" commit -q --no-verify -m adopted
base="$(git -C "$WORKDIR" symbolic-ref --short HEAD)"
for side in a b; do
  gitc "$WORKDIR" checkout -q -b "log-$side" "$base"
  printf -- '- %s-02 progress | agent %s entry\n' "$MONTH" "$side" >> "$WORKDIR/doc/log/$MONTH.md"
  gitc "$WORKDIR" commit -q --no-verify -am "log $side"
done
gitc "$WORKDIR" checkout -q "$base"
gitc "$WORKDIR" merge -q --no-edit log-a
merge_rc=0
gitc "$WORKDIR" merge -q --no-edit log-b >/dev/null 2>&1 || merge_rc=$?
check "parallel log appends merge cleanly"     "[[ $merge_rc -eq 0 ]]"
check "both appended entries survive merge"    "grep -q 'agent a entry' '$WORKDIR/doc/log/$MONTH.md' && grep -q 'agent b entry' '$WORKDIR/doc/log/$MONTH.md'"
gitc "$WORKDIR" branch -q -D log-a log-b
check "repo-hygiene clean on adopted repo"     "(cd '$WORKDIR' && scripts/repo-hygiene.sh >/dev/null)"
mkdir -p "$WORKDIR/scratch-dir" && touch "$WORKDIR/scratch-dir/notes.txt"
printf 'old-worktree/\n' >> "$WORKDIR/.gitignore"
printf 'stash me\n' >> "$WORKDIR/LICENSE"
gitc "$WORKDIR" stash push -q -m smoke-stash -- LICENSE
# shellcheck disable=SC2034  # hyg_out is consumed via eval inside check()
hyg_out="$(cd "$WORKDIR" && scripts/repo-hygiene.sh 2>&1)" && hyg_rc=0 || hyg_rc=$?
check "repo-hygiene exits non-zero on cruft"   "[[ $hyg_rc -eq 1 ]]"
check "repo-hygiene flags stray untracked dir" "grep -q 'FINDING \[untracked\] scratch-dir/' <<<\"\$hyg_out\""
check "repo-hygiene flags dead .gitignore line" "grep -q \"FINDING \[gitignore\] 'old-worktree/'\" <<<\"\$hyg_out\""
check "repo-hygiene flags stash"               "grep -q 'FINDING \[stashes\]' <<<\"\$hyg_out\""

# Scenario 6: upgrade path. Simulate a target adopted from the pre-change
# template: legacy log.md, none of the new files, older copies of the files
# the change touched. --diff must report both groups without writing; a plain
# re-run must add the new files and leave AGENTS.md + the legacy log alone.
WORKDIR5="$(mktemp -d)"
git -C "$WORKDIR5" init -q
git -C "$WORKDIR5" remote add origin "ssh://git@example.invalid/smoke5.git"
"$TEMPLATE/adopt.sh" --target "$WORKDIR5" --role maintainer >/dev/null
rm -rf "$WORKDIR5/external" "$WORKDIR5/scripts" "$WORKDIR5/.gitattributes" \
       "$WORKDIR5/doc/runbooks/repo-hygiene.md" "$WORKDIR5/doc/log"
for f in AGENTS.md .gitignore .pre-commit-config.yaml doc/runbooks/README.md doc/runbooks/wiki-lint.md; do
  printf '\n# SMOKE-OLD-%s\n' "$(basename "$f")" >> "$WORKDIR5/$f"
done
printf '# Wiki Log\n\n## [2026-08-01] progress | legacy entry\n\nNarrative body.\n' > "$WORKDIR5/doc/log.md"
# shellcheck disable=SC2034  # diff_out is consumed via eval inside check()
diff_out="$("$TEMPLATE/adopt.sh" --target "$WORKDIR5" --diff)"
check "--diff lists new external/README.md"   "grep -q 'new      external/README.md' <<<\"\$diff_out\""
check "--diff lists new repo-hygiene runbook" "grep -q 'new      doc/runbooks/repo-hygiene.md' <<<\"\$diff_out\""
check "--diff lists new hygiene script"       "grep -q 'new      scripts/repo-hygiene.sh' <<<\"\$diff_out\""
for f in AGENTS.md .gitignore .pre-commit-config.yaml doc/runbooks/README.md doc/runbooks/wiki-lint.md; do
  check "--diff lists $f as differing"        "grep -qxF '  differs  $f' <<<\"\$diff_out\""
done
check "--diff flags the legacy log format"    "grep -q 'legacy multi-line log format' <<<\"\$diff_out\""
check "--diff writes nothing"                 "[[ ! -e '$WORKDIR5/external' ]]"
"$TEMPLATE/adopt.sh" --target "$WORKDIR5" --role maintainer >/dev/null
check "upgrade re-run adds external/"         "[[ -f '$WORKDIR5/external/README.md' ]]"
check "upgrade re-run adds hygiene runbook"   "[[ -f '$WORKDIR5/doc/runbooks/repo-hygiene.md' ]]"
check "upgrade re-run adds .gitattributes"    "[[ -f '$WORKDIR5/.gitattributes' ]]"
check "upgrade re-run keeps AGENTS.md"        "grep -q 'SMOKE-OLD-AGENTS.md' '$WORKDIR5/AGENTS.md'"
check "upgrade re-run keeps legacy log.md"    "grep -q 'legacy entry' '$WORKDIR5/doc/log.md'"

if (( fail )); then echo "smoke test FAILED"; exit 1; else echo "smoke test passed"; fi
