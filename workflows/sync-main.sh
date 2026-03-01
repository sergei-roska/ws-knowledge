#!/usr/bin/env bash

# Merge the latest mainline (main/master) into the current feature branch.
#
# Usage:
#   sync-main
#
# Automatically stashes uncommitted changes if present.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/wf-common.sh"

require_git_repo

MAINLINE=$(detect_mainline)
FEATURE=$(current_branch)

[[ "$FEATURE" == "$MAINLINE" ]] && wf_die "Already on $MAINLINE — switch to a feature branch first."

wf_header "Syncing $MAINLINE → $FEATURE"

# Stash if dirty
STASHED=false
if ! require_clean_tree 2>/dev/null; then
  wf_info "Stashing uncommitted changes..."
  wf_run "git stash push -m 'wf: auto-stash before sync-main'"
  STASHED=true
fi

wf_run "git checkout $MAINLINE"
wf_run "git pull"
wf_run "git checkout $FEATURE"

wf_step "git merge $MAINLINE"
if ! git merge "$MAINLINE"; then
  wf_err "Merge conflicts detected. Resolve them, then run:"
  wf_info "  git merge --continue"
  [[ "$STASHED" == "true" ]] && wf_info "  git stash pop   # restore stashed changes"
  exit 1
fi

if [[ "$STASHED" == "true" ]]; then
  wf_info "Restoring stashed changes..."
  wf_run "git stash pop" || wf_warn "Stash pop had conflicts — resolve manually."
fi

wf_ok "$MAINLINE merged into $FEATURE"
