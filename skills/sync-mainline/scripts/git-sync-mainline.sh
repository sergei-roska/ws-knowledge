#!/usr/bin/env bash

set -euo pipefail

REMOTE="${1:-origin}"
MAIN_BRANCH="${2:-}"

if [[ -z "${MAIN_BRANCH}" ]]; then
  detected_head="$(git symbolic-ref --quiet --short "refs/remotes/${REMOTE}/HEAD" 2>/dev/null || true)"
  if [[ -n "${detected_head}" ]]; then
    MAIN_BRANCH="${detected_head#${REMOTE}/}"
  else
    echo "Could not determine mainline branch for remote '${REMOTE}'."
    echo "Pass it explicitly: bash /home/sr/.codex/skills/sync-mainline/scripts/git-sync-mainline.sh ${REMOTE} <main_branch>"
    exit 2
  fi
fi

current_branch="$(git branch --show-current)"
if [[ -z "${current_branch}" ]]; then
  echo "Not on a branch (detached HEAD). Checkout a branch first."
  exit 1
fi

if [[ "${current_branch}" == "${MAIN_BRANCH}" ]]; then
  echo "Current branch is '${MAIN_BRANCH}'. Checkout a feature branch before syncing."
  exit 1
fi

echo "Fetching '${REMOTE}'..."
git fetch "${REMOTE}"

if ! git show-ref --verify --quiet "refs/remotes/${REMOTE}/${MAIN_BRANCH}"; then
  echo "Remote branch '${REMOTE}/${MAIN_BRANCH}' was not found. Pass the correct branch explicitly."
  exit 1
fi

echo "Updating '${MAIN_BRANCH}' from '${REMOTE}/${MAIN_BRANCH}'..."
if git show-ref --verify --quiet "refs/heads/${MAIN_BRANCH}"; then
  git checkout "${MAIN_BRANCH}"
else
  git checkout -b "${MAIN_BRANCH}" --track "${REMOTE}/${MAIN_BRANCH}"
fi

git pull --ff-only "${REMOTE}" "${MAIN_BRANCH}"

echo "Switching back to '${current_branch}'..."
git checkout "${current_branch}"

echo "Merging '${MAIN_BRANCH}' into '${current_branch}'..."
if ! git merge "${MAIN_BRANCH}"; then
  echo
  echo "=== Merge conflicts detected ==="
  conflicted="$(git diff --name-only --diff-filter=U 2>/dev/null || true)"
  if [[ -n "${conflicted}" ]]; then
    echo "Conflicted files:"
    echo "${conflicted}" | sed 's/^/  /'
    echo
    echo "Resolve conflicts, then run:"
    echo -n '  git add'
    while IFS= read -r f; do [[ -n "$f" ]] && printf ' "%s"' "$f"; done <<< "$conflicted"
    echo
  else
    echo "Resolve conflicts, then run:"
    echo "  git add <resolved-files>"
  fi
  echo "  git commit --no-edit"
  exit 1
fi

echo "Sync complete: '${current_branch}' now includes latest '${MAIN_BRANCH}'."
