#!/usr/bin/env bash

# Full Drupal core update workflow:
#   branch check/create → cleanup → composer require → updb → cr → git add → commit
#
# Usage:
#   core-update <VERSION> <TICKET-ID>
#
# Examples:
#   core-update 10.6.3 ID-123
#   core-update 10.7.0 WEB-500

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

# Step 0: Ensure ticket branch
CURRENT_BRANCH="$(current_branch)"
if [[ "$CURRENT_BRANCH" != *"$TICKET"* ]]; then
  TARGET_BRANCH="${CURRENT_BRANCH//\//-}-$TICKET"
  [[ "$CURRENT_BRANCH" == "HEAD" ]] && TARGET_BRANCH="feature-$TICKET"
  wf_info "Current branch '$CURRENT_BRANCH' does not include ticket '$TICKET'."
  if git show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
    wf_run "git checkout $TARGET_BRANCH"
  else
    wf_run "git checkout -b $TARGET_BRANCH"
  fi
fi

# Step 1: Detect Drupal web root
WEBROOT="web"
if [[ -d "docroot" ]]; then
  WEBROOT="docroot"
elif [[ ! -d "web" && -d "core" ]]; then
  WEBROOT="."
fi
[[ "$WEBROOT" == "." || -d "$WEBROOT" ]] || wf_die "Unable to detect Drupal web root (expected 'web', 'docroot', or root-level 'core')."

# Step 2: Clean old core/contrib/vendor artifacts
wf_run "rm -rf $WEBROOT/modules/contrib/ $WEBROOT/core/ vendor/ composer.lock"

# Step 3: Composer update
wf_run "lando composer require drupal/core-recommended:$VERSION drupal/core-composer-scaffold:$VERSION drupal/core-project-message:$VERSION --update-with-all-dependencies"

# Step 4: Database updates
wf_run "lando drush updb -y"

# Step 5: Cache rebuild
wf_run "lando drush cr"

# Step 6: Stage files
wf_run "git add composer.json composer.lock"

# Stage only Composer-managed Drupal paths to avoid picking up custom code.
MANAGED_PATHS=(
  "$WEBROOT/core/"
  "$WEBROOT/modules/contrib/"
  "$WEBROOT/profiles/contrib/"
  "$WEBROOT/themes/contrib/"
)

for path in "${MANAGED_PATHS[@]}"; do
  [[ -e "$path" ]] || continue
  if git check-ignore -q "$path"; then
    wf_info "Skipping ignored path: $path"
    continue
  fi
  wf_run "git add -A $path"
done

# Stage scaffold files if they exist and are tracked/unignored.
SCAFFOLD_FILES=(.htaccess index.php update.php robots.txt web.config)
for file in "${SCAFFOLD_FILES[@]}"; do
  TARGET_FILE="$file"
  [[ "$WEBROOT" != "." ]] && TARGET_FILE="$WEBROOT/$file"
  [[ -f "$TARGET_FILE" ]] || continue
  if git check-ignore -q "$TARGET_FILE"; then
    wf_info "Skipping ignored file: $TARGET_FILE"
    continue
  fi
  wf_run "git add $TARGET_FILE"
done

# Step 7: Show what will be committed
wf_info "Staged changes:"
git diff --cached --stat

# Step 8: Commit
wf_run "git commit -m '$TICKET: Update Drupal core to $VERSION'"

wf_ok "Drupal core updated to $VERSION and committed"
