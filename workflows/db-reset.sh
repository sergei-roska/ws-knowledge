#!/usr/bin/env bash

# Import a database dump and run the full Drupal rebuild cycle.
#
# Usage:
#   db-reset                           # uses default dump file
#   db-reset path/to/dump.sql.gz       # use specific dump file
#
# Default dump: sunstatespecialists.sql.gz (in project root)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/wf-common.sh"

require_lando_running

DEFAULT_DUMP="sunstatespecialists.sql.gz"
DUMP="${1:-$DEFAULT_DUMP}"

[[ ! -f "$DUMP" ]] && wf_die "Dump file not found: $DUMP"

wf_header "Database reset from $DUMP"

wf_run "lando db-import $DUMP"
wf_run "lando drush updb -y"
wf_run "lando drush cim -y"
wf_run "lando drush cr"

wf_ok "Database reset complete"
