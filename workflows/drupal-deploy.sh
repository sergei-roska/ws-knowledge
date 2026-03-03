#!/usr/bin/env bash

# Run the Drupal post-deploy cycle: database updates, config import, cache rebuild.
#
# Usage:
#   drupal-deploy          # full cycle: composer + updb + cim + cr
#   drupal-deploy --cr     # cache rebuild only
#   drupal-deploy --no-updb  # skip database updates
#   drupal-deploy --no-composer # skip composer install

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/wf-common.sh"

require_lando_running

DO_COMPOSER=true
DO_UPDB=true
DO_CIM=true
DO_CR=true

for arg in "$@"; do
  case "$arg" in
    --cr)      DO_COMPOSER=false; DO_UPDB=false; DO_CIM=false ;;
    --no-updb) DO_UPDB=false ;;
    --no-cim)  DO_CIM=false ;;
    --no-composer) DO_COMPOSER=false ;;
    -h|--help) echo "Usage: drupal-deploy [--cr|--no-composer|--no-updb|--no-cim]"; exit 0 ;;
    *) wf_die "Unknown option: $arg" ;;
  esac
done

wf_header "Drupal deploy cycle"

[[ "$DO_COMPOSER" == "true" ]] && wf_run "lando composer install"
[[ "$DO_UPDB" == "true" ]] && wf_run "lando drush updb -y"
[[ "$DO_CIM" == "true" ]]  && wf_run "lando drush cim -y"
[[ "$DO_CR" == "true" ]]   && wf_run "lando drush cr"

wf_ok "Deploy cycle complete"
