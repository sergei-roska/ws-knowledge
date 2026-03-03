#!/usr/bin/env bash

# Run a comprehensive security and code quality audit.
# Generates a detailed text report in the current directory.
#
# Usage:
#   security-audit                      # full audit on custom code (auto-detects docroot/web)
#   security-audit path/to/modules      # audit specific path

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/wf-common.sh"

require_git_repo

# Detect docroot (docroot/ or web/)
DOCROOT="docroot"
[[ -d "web/modules" ]] && DOCROOT="web"

CUSTOM_PATH="${1:-$DOCROOT/modules/custom}"
[[ ! -d "$CUSTOM_PATH" ]] && wf_die "Custom path not found: ${CUSTOM_PATH}"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="security_audit_${TIMESTAMP}.md"

wf_header "Security & Code Quality Analysis"
wf_info "Target path: $CUSTOM_PATH"
wf_info "Output file: $REPORT_FILE"

# Initialize report
echo "# DRUPAL PROJECT SECURITY ANALYSIS REPORT" > "$REPORT_FILE"
echo "**Generated:** $(date)" >> "$REPORT_FILE"
echo "**Project Path:** $(pwd)" >> "$REPORT_FILE"
echo "**Target Path:** $CUSTOM_PATH" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

log_section() {
  local section_name="$1"
  echo "## $section_name" >> "$REPORT_FILE"
  echo -e "${_B}→${_N} $section_name"
  echo "" >> "$REPORT_FILE"
}

# 1. PHPCS
log_section "1. PHPCS (PHP Code Sniffer) Analysis"
if command -v lando &> /dev/null && lando list 2>/dev/null | grep -q "Running"; then
  # Using '|| true' so pipefail doesn't crash the script on warnings/errors
  lando phpcs --standard=Drupal --extensions=php,module,inc,theme "$CUSTOM_PATH" 2>&1 | tee -a "$REPORT_FILE" || true
elif command -v phpcs &> /dev/null; then
  phpcs --standard=Drupal --extensions=php,module,inc,theme "$CUSTOM_PATH" 2>&1 | tee -a "$REPORT_FILE" || true
else
  echo "[Warning] PHPCS not installed or not in PATH (and lando not running)" | tee -a "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# 2. PHPStan
log_section "2. PHPStan Static Analysis"
if command -v lando &> /dev/null && lando list 2>/dev/null | grep -q "Running"; then
  lando php ./vendor/bin/phpstan analyse --configuration=phpstan.neon --level=1 "$CUSTOM_PATH" 2>&1 | tee -a "$REPORT_FILE" || true
elif [[ -x "./vendor/bin/phpstan" ]]; then
  ./vendor/bin/phpstan analyse --configuration=phpstan.neon --level=1 "$CUSTOM_PATH" 2>&1 | tee -a "$REPORT_FILE" || true
elif command -v phpstan &> /dev/null; then
  phpstan analyse --level=1 "$CUSTOM_PATH" 2>&1 | tee -a "$REPORT_FILE" || true
else
  echo "[Warning] PHPStan not installed (and lando not running)" | tee -a "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# 3. Semgrep
log_section "3. Semgrep Security Analysis"
if command -v semgrep &> /dev/null; then
  echo ">> Running XSS detection..." | tee -a "$REPORT_FILE"
  semgrep --config=p/xss "$CUSTOM_PATH" 2>&1 | tee -a "$REPORT_FILE" || true
  
  echo -e "\n>> Running SSRF detection..." | tee -a "$REPORT_FILE"
  SSRF_RULESET="$SCRIPT_DIR/semgrep-ssrf-rules.yml"
  if [[ -f "$SSRF_RULESET" ]]; then
    semgrep --config="$SSRF_RULESET" "$CUSTOM_PATH" 2>&1 | tee -a "$REPORT_FILE" || true
  else
    echo "[Warning] SSRF ruleset not found at $SSRF_RULESET" | tee -a "$REPORT_FILE"
  fi
  
  echo -e "\n>> Running security audit detection..." | tee -a "$REPORT_FILE"
  semgrep --config=p/security-audit "$CUSTOM_PATH" 2>&1 | tee -a "$REPORT_FILE" || true
else
  echo "[Warning] Semgrep not installed" | tee -a "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# 4. Composer Audit
log_section "4. Composer Security Audit"
if command -v lando &> /dev/null && lando list 2>/dev/null | grep -q "Running"; then
  lando composer audit 2>&1 | tee -a "$REPORT_FILE" || true
else
  composer audit 2>&1 | tee -a "$REPORT_FILE" || true
fi
echo "" >> "$REPORT_FILE"

# 5. Manual Pattern Search
log_section "5. Manual Security Pattern Search"
echo ">> Searching for potential XSS in #markup:" | tee -a "$REPORT_FILE"
grep -r "#markup.*\." "$CUSTOM_PATH" --include="*.php" --include="*.module" --include="*.theme" | tee -a "$REPORT_FILE" || true

echo -e "\n>> Searching for potential SSRF in HTTP calls:" | tee -a "$REPORT_FILE"
grep -rE "httpClient.*get|guzzle" "$CUSTOM_PATH" --include="*.php" --include="*.module" | tee -a "$REPORT_FILE" || true

echo -e "\n>> Searching for deprecated functions (e.g. drupal_set_message):" | tee -a "$REPORT_FILE"
grep -r "drupal_set_message" "$CUSTOM_PATH" --include="*.php" --include="*.module" | tee -a "$REPORT_FILE" || true
echo "" >> "$REPORT_FILE"

# 6. Dependency Analysis
log_section "6. Dependency Risk Analysis"
if [[ -f "composer.json" ]]; then
  echo "Development/Alpha/Beta dependencies found in composer.json:" | tee -a "$REPORT_FILE"
  grep -E "\"version\".*?(dev|alpha|beta|rc)" composer.json | tee -a "$REPORT_FILE" || true
  grep -E "(dev-|@dev|@alpha|@beta)" composer.json | tee -a "$REPORT_FILE" || true
else
  echo "composer.json not found in $(pwd)" | tee -a "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

echo "---" >> "$REPORT_FILE"
echo "**ANALYSIS COMPLETED:** $(date)" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"

wf_header "Audit Complete"
wf_ok "Analysis completed successfully!"
wf_info "Full report saved to: $REPORT_FILE"
wf_info "Report size: $(du -h "$REPORT_FILE" | cut -f1)"
