#!/usr/bin/env bash

# Build frontend assets and clear Drupal cache.
#
# Usage:
#   theme-build              # auto-detect gulp or npm
#   theme-build --gulp       # force gulp build
#   theme-build --npm        # force npm run build
#   theme-build --watch      # start gulp/npm watch mode (no cache clear)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/wf-common.sh"

require_lando_running

FORCE_TOOL=""
WATCH=false

for arg in "$@"; do
  case "$arg" in
    --gulp)  FORCE_TOOL="gulp" ;;
    --npm)   FORCE_TOOL="npm" ;;
    --watch) WATCH=true ;;
    -h|--help) echo "Usage: theme-build [--gulp|--npm|--watch]"; exit 0 ;;
    *) wf_die "Unknown option: $arg" ;;
  esac
done

# Auto-detect build tool if not forced
detect_tool() {
  if [[ -n "$FORCE_TOOL" ]]; then
    echo "$FORCE_TOOL"
    return
  fi
  # Check for gulpfile in theme dirs
  if compgen -G "docroot/themes/custom/*/gulpfile.*" > /dev/null 2>&1 \
     || compgen -G "web/themes/custom/*/gulpfile.*" > /dev/null 2>&1; then
    echo "gulp"
  else
    echo "npm"
  fi
}

TOOL=$(detect_tool)

wf_header "Theme build ($TOOL)"

if [[ "$WATCH" == "true" ]]; then
  if [[ "$TOOL" == "gulp" ]]; then
    wf_info "Starting gulp watch (Ctrl+C to stop)..."
    lando gulp watch
  else
    wf_info "Starting npm watch (Ctrl+C to stop)..."
    lando npm run dev
  fi
else
  if [[ "$TOOL" == "gulp" ]]; then
    wf_run "lando gulp build"
  else
    wf_run "lando npm run build"
  fi
  wf_run "lando drush cr"
  wf_ok "Theme built and cache cleared"
fi
