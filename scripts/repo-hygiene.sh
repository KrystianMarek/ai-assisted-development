#!/usr/bin/env bash
# scripts/repo-hygiene.sh — read-only repository sanity report.
# See doc/runbooks/repo-hygiene.md for what each check means and how to fix it.
# This script never changes anything; it prints findings and exits 1 if any.
set -euo pipefail

QUICK=0

usage() {
  cat <<'EOF'
Usage: scripts/repo-hygiene.sh [--quick] [--help]

  --quick   Session-end subset: worktrees, merged/gone branches, stashes.
  --help    Show this message.

Exit status: 0 = clean, 1 = findings, 2 = usage error.
Accepted exceptions for the .gitignore check go in .repo-hygiene-allow at the
repo root (one .gitignore entry per line, '#' comments allowed).
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quick)   QUICK=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "unknown flag: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# Always report against the MAIN checkout, even when run from a worktree.
common_dir="$(git rev-parse --path-format=absolute --git-common-dir)"
ROOT="$(dirname "$common_dir")"
cd "$ROOT"

findings=0
finding() { printf 'FINDING [%s] %s\n' "$1" "$2"; findings=$((findings + 1)); }
info()    { printf 'info    [%s] %s\n' "$1" "$2"; }

default_branch() {
  local ref
  if ref="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"; then
    echo "${ref#origin/}"
    return
  fi
  local b
  for b in main master; do
    if git show-ref --verify --quiet "refs/heads/$b"; then echo "$b"; return; fi
  done
  git symbolic-ref --short HEAD
}
DEFAULT="$(default_branch)"
# Compare against the local default branch when it exists, else its remote.
if git show-ref --verify --quiet "refs/heads/$DEFAULT"; then
  BASE="$DEFAULT"
else
  BASE="origin/$DEFAULT"
fi

check_worktrees() {
  local path='' branch='' prunable=0 line first=1
  # Porcelain records are blank-line separated; flush on each blank line.
  while IFS= read -r line || [[ -n "$path" ]]; do
    case "$line" in
      "worktree "*) path="${line#worktree }" ;;
      "branch "*)   branch="${line#branch refs/heads/}" ;;
      prunable*)    prunable=1 ;;
      "")
        if [[ -n "$path" ]]; then
          if (( first )); then
            first=0
          else
            if (( prunable )); then
              finding worktrees "$path is prunable (directory gone) — run: git worktree prune"
            elif [[ "$path" != "$ROOT/.worktrees/"* ]]; then
              finding worktrees "$path is outside .worktrees/ — recreate under .worktrees/<name>"
            fi
            if [[ -n "$branch" ]] && git merge-base --is-ancestor "refs/heads/$branch" "$BASE" 2>/dev/null; then
              finding worktrees "$path: branch '$branch' has no commits beyond $BASE (merged or unused) — remove the worktree"
            fi
          fi
        fi
        path='' branch='' prunable=0
        ;;
    esac
  done < <(git worktree list --porcelain; echo)
}

check_branches() {
  local b track
  while IFS=' ' read -r b track; do
    [[ "$b" == "$DEFAULT" ]] && continue
    if git merge-base --is-ancestor "refs/heads/$b" "$BASE" 2>/dev/null; then
      finding branches "'$b' has no commits beyond $BASE (merged or unused) — delete it: git branch -d $b"
    elif [[ "$track" == *gone* ]]; then
      finding branches "'$b' tracks a deleted upstream — confirm it was merged (e.g. squash), then delete it"
    fi
  done < <(git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads)
}

check_stashes() {
  local n
  n="$(git stash list | wc -l | tr -d ' ')"
  if [[ "$n" != 0 ]]; then
    finding stashes "$n stash entr$( [[ "$n" == 1 ]] && echo y || echo ies) — no stash should outlive a session (git stash list)"
  fi
}

check_untracked() {
  local line
  while IFS= read -r line; do
    finding untracked "${line#?? } is untracked — commit it, move it under .worktrees/, or delete it"
  done < <(git status --porcelain --untracked-files=normal | grep '^?? ' || true)
}

allowed() {
  [[ -f .repo-hygiene-allow ]] || return 1
  grep -v '^[[:space:]]*#' .repo-hygiene-allow | grep -qxF -- "$1"
}

check_gitignore() {
  [[ -f .gitignore ]] || return 0
  local raw entry
  while IFS= read -r raw || [[ -n "$raw" ]]; do
    entry="${raw%%[[:space:]]}"
    case "$entry" in
      ''|'#'*|'!'*) continue ;;          # blank, comment, negation
      *'*'*|*'?'*|*'['*) continue ;;     # glob patterns match by design
    esac
    local path="${entry#/}"
    path="${path%/}"
    # Only path-like entries are checked: anchored (/x), directories (x/), or
    # nested (a/b). Bare names like `coverage.txt` match anywhere in the tree.
    [[ "$entry" == /* || "$entry" == */ || "$path" == */* ]] || continue
    case "$path" in .*) continue ;; esac   # tool state dirs (.beads, .dolt, …)
    allowed "$entry" && continue
    if [[ ! -e "$path" ]]; then
      finding gitignore "'$entry' matches nothing on disk — remove it (or list it in .repo-hygiene-allow)"
    fi
  done < .gitignore
}

check_external() {
  [[ -d external ]] || return 0
  local index=external/README.md d name
  [[ -f "$index" ]] || index=external/readme.md
  if [[ ! -f "$index" ]]; then
    finding external "external/ exists but external/README.md (the clone index) is missing"
    return 0
  fi
  for d in external/*/; do
    [[ -d "$d" ]] || continue
    name="$(basename "$d")"
    if ! grep -qE "^\| *\`$name/?\`" "$index"; then
      finding external "external/$name/ is not in the external/README.md index"
    fi
  done
  # Rows whose clone is absent are normal on a fresh checkout — report only.
  # shellcheck disable=SC2016  # backticks are literal markdown, not expansion
  while IFS= read -r name; do
    [[ -d "external/$name" ]] || info external "external/$name/ is indexed but not cloned here"
  done < <(sed -nE 's/^\| *`([^`/]+)\/?`.*/\1/p' "$index")
}

check_worktrees
check_branches
check_stashes
if (( ! QUICK )); then
  check_untracked
  check_gitignore
  check_external
fi

if (( findings )); then
  printf '\n%d finding(s). See doc/runbooks/repo-hygiene.md.\n' "$findings"
  exit 1
fi
echo "repo hygiene: clean"
