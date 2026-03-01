#!/usr/bin/env bash

# Create a new feature (or bugfix/hotfix/test) branch from a fresh mainline.
#
# Usage:
#   feature-start <TICKET-ID> [category]
#
# Examples:
#   feature-start GC-400            # → feature/GC-400
#   feature-start GC-400 bugfix     # → bugfix/GC-400
#   feature-start GC-400 hotfix     # → hotfix/GC-400

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/wf-common.sh"

TICKET="${1:-}"
CATEGORY="${2:-feature}"

[[ -z "$TICKET" ]] && wf_die "Usage: feature-start <TICKET-ID> [feature|bugfix|hotfix|test]"

# Validate category
case "$CATEGORY" in
  feature|bugfix|hotfix|test) ;;
  *) wf_die "Invalid category '$CATEGORY'. Use: feature, bugfix, hotfix, or test." ;;
esac

require_git_repo

MAINLINE=$(detect_mainline)
BRANCH="${CATEGORY}/${TICKET}"

wf_header "Starting branch: $BRANCH"

# Stash if dirty
STASHED=false
if ! require_clean_tree 2>/dev/null; then
  wf_info "Stashing uncommitted changes..."
  wf_run "git stash push -m 'wf: auto-stash before feature-start'"
  STASHED=true
fi

wf_run "git checkout $MAINLINE"
wf_run "git pull"
wf_run "git checkout -b $BRANCH"

if [[ "$STASHED" == "true" ]]; then
  wf_info "Restoring stashed changes..."
  wf_run "git stash pop" || wf_warn "Stash pop failed — resolve manually with: git stash pop"
fi

wf_ok "Branch $BRANCH created from $MAINLINE"
