#!/usr/bin/env bash

# Export Drupal configuration and stage config files for commit.
#
# Usage:
#   config-export              # export and git add config/default/
#   config-export --diff       # also show git diff of staged config

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/wf-common.sh"

require_lando_running
require_git_repo

SHOW_DIFF=false
for arg in "$@"; do
  case "$arg" in
    --diff) SHOW_DIFF=true ;;
    -h|--help) echo "Usage: config-export [--diff]"; exit 0 ;;
    *) wf_die "Unknown option: $arg" ;;
  esac
done

wf_header "Config export"

wf_run "lando drush cex -y"

# Detect config directory from drush or fall back to config/default
CONFIG_DIR="config/default"
if [[ -d "config/sync" ]]; then
  CONFIG_DIR="config/sync"
fi

wf_run "git add $CONFIG_DIR/"

if [[ "$SHOW_DIFF" == "true" ]]; then
  wf_info "Staged config changes:"
  git diff --cached --stat -- "$CONFIG_DIR/"
fi

wf_ok "Config exported and staged from $CONFIG_DIR/"
