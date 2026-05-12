#!/usr/bin/env bash

# Import a database dump and run the full Drupal rebuild cycle.
#
# Usage:
#   db-reset                           # uses default dump file
#   db-reset path/to/dump.sql.gz       # use specific dump file
#
# Default dump: database.sql.gz (in project root)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/wf-common.sh"

DEFAULT_DUMP="database.sql.gz"
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  echo "Usage: db-reset [path/to/dump.sql.gz]"
  exit 0
fi

require_lando_running

DUMP="${1:-$DEFAULT_DUMP}"

[[ ! -f "$DUMP" ]] && wf_die "Dump file not found: $DUMP"

wf_header "Database reset from $DUMP"

wf_run "lando db-import $DUMP"
wf_run "lando drush updb -y"
wf_run "lando drush cim -y"
wf_run "lando drush cr"

wf_ok "Database reset complete"
