#!/usr/bin/env bash

# Full Drupal core update workflow:
#   composer require → updb → cex → git add → commit
#
# Usage:
#   core-update <VERSION> <TICKET-ID>
#
# Examples:
#   core-update 10.6.3 GC-400
#   core-update 10.7.0 IDW-500

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/wf-common.sh"

VERSION="${1:-}"
TICKET="${2:-}"

[[ -z "$VERSION" ]] && wf_die "Usage: core-update <VERSION> <TICKET-ID>"
[[ -z "$TICKET" ]]  && wf_die "Usage: core-update <VERSION> <TICKET-ID>"

require_git_repo
require_lando_running

wf_header "Drupal core update to $VERSION"

# Step 1: Composer update
wf_run "lando composer require drupal/core-recommended:$VERSION drupal/core-composer-scaffold:$VERSION drupal/core-project-message:$VERSION --update-with-all-dependencies"

# Step 2: Database updates
wf_run "lando drush updb -y"

# Step 3: Export config (may capture schema changes)
wf_run "lando drush cex -y"

# Step 4: Cache rebuild
wf_run "lando drush cr"

# Step 5: Stage files
CONFIG_DIR="config/default"
[[ -d "config/sync" ]] && CONFIG_DIR="config/sync"

wf_run "git add composer.json composer.lock"
wf_run "git add $CONFIG_DIR/"

# Step 6: Show what will be committed
wf_info "Staged changes:"
git diff --cached --stat

# Step 7: Commit
wf_run "git commit -m '$TICKET: Update Drupal core to $VERSION'"

wf_ok "Drupal core updated to $VERSION and committed"
