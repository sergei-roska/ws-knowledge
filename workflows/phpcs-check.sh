#!/usr/bin/env bash

# Run PHP CodeSniffer with Drupal standards on custom modules and/or themes.
#
# Usage:
#   phpcs-check                    # scan custom modules + themes
#   phpcs-check --modules          # scan custom modules only
#   phpcs-check --themes           # scan custom themes only
#   phpcs-check --fix              # auto-fix with phpcbf first, then report
#   phpcs-check path/to/file.php   # scan specific path

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/wf-common.sh"

STANDARDS="Drupal,DrupalPractice"
EXTENSIONS="php,module,inc,install,test,profile,theme"
FIX=false
SCAN_MODULES=true
SCAN_THEMES=true
CUSTOM_PATH=""

for arg in "$@"; do
  case "$arg" in
    --modules) SCAN_THEMES=false ;;
    --themes)  SCAN_MODULES=false ;;
    --fix)     FIX=true ;;
    -h|--help)
      echo "Usage: phpcs-check [--modules|--themes|--fix] [path]"
      exit 0
      ;;
    -*)  wf_die "Unknown option: $arg" ;;
    *)   CUSTOM_PATH="$arg" ;;
  esac
done

# Detect docroot (docroot/ or web/)
DOCROOT="docroot"
[[ -d "web/modules" ]] && DOCROOT="web"

# Build scan paths
PATHS=()
if [[ -n "$CUSTOM_PATH" ]]; then
  PATHS+=("$CUSTOM_PATH")
else
  [[ "$SCAN_MODULES" == "true" && -d "$DOCROOT/modules/custom" ]] && PATHS+=("$DOCROOT/modules/custom/")
  [[ "$SCAN_THEMES" == "true"  && -d "$DOCROOT/themes/custom" ]] && PATHS+=("$DOCROOT/themes/custom/")
fi

[[ ${#PATHS[@]} -eq 0 ]] && wf_die "No custom modules or themes found in $DOCROOT/"

wf_header "PHPCS check"

if [[ "$FIX" == "true" ]]; then
  wf_info "Running phpcbf auto-fix..."
  phpcbf --standard="$STANDARDS" --extensions="$EXTENSIONS" "${PATHS[@]}" || true
  wf_ok "Auto-fix pass complete"
fi

wf_step "phpcs --standard=$STANDARDS --extensions=$EXTENSIONS ${PATHS[*]}"
phpcs --standard="$STANDARDS" --extensions="$EXTENSIONS" "${PATHS[@]}"

wf_ok "PHPCS passed"
