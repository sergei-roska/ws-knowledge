#!/usr/bin/env bash

# Push current branch, setting upstream tracking automatically if needed.
#
# Usage:
#   feature-push           # push current branch
#   feature-push --force   # force push (with lease)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/wf-common.sh"

require_git_repo

FORCE=false
for arg in "$@"; do
  case "$arg" in
    --force|-f) FORCE=true ;;
    -h|--help) echo "Usage: feature-push [--force]"; exit 0 ;;
    *) wf_die "Unknown option: $arg" ;;
  esac
done

BRANCH=$(current_branch)
MAINLINE=$(detect_mainline)

[[ "$BRANCH" == "$MAINLINE" ]] && wf_die "Refusing to push directly to $MAINLINE."

wf_header "Pushing $BRANCH"

# Check if upstream is already set
if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" &>/dev/null; then
  if [[ "$FORCE" == "true" ]]; then
    wf_run "git push --force-with-lease"
  else
    wf_run "git push"
  fi
else
  wf_info "Setting upstream tracking for $BRANCH..."
  if [[ "$FORCE" == "true" ]]; then
    wf_run "git push --set-upstream --force-with-lease origin $BRANCH"
  else
    wf_run "git push --set-upstream origin $BRANCH"
  fi
fi

wf_ok "Pushed $BRANCH"
