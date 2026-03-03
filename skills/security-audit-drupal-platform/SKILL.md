---
name: security-audit-drupal-platform
description: Audit Drupal platform security with production-safe remediation guidance. Use when tasks involve secrets/config hygiene, access control, input/output handling, dependency risk checks, security review before release, or incident-prevention hardening in Drupal modules/themes/pipeline config.
---

# Security Audit Drupal Platform

## Overview

Perform focused security reviews for Drupal projects and produce prioritized fixes with low regression risk.
Use this skill to convert broad "check security" requests into deterministic findings and remediation actions.

## Workflow

1. Define audit scope.
Map touched areas: custom modules/themes, settings/config exports, CI/deploy scripts, and dependencies.

2. Run surface checks.
Search for secret leakage patterns, unsafe rendering, missing access checks, and insecure defaults.

3. Validate dependency and configuration risks.
Review dependency freshness, known-risk package changes, and config handling of sensitive values.

4. Prioritize findings.
Assign severity (`Critical`, `High`, `Medium`, `Low`) with exploitability and blast-radius context.

5. Recommend safe remediation.
Provide minimal, reversible fixes and deployment notes for each finding.

## Review Categories

- Secrets and config hygiene.
- Input validation and output escaping.
- Access control and permission checks.
- Dependency and supply-chain exposure.
- CI/deploy security posture.

## Drupal-Specific Security Patterns

### Output Escaping
- Use `#plain_text` instead of `#markup` for user-supplied content.
- Use `{{ variable }}` in Twig (auto-escapes) — never `{{ variable|raw }}` for user data.
- Use `Xss::filter()` or `Xss::filterAdmin()` only when rich text is explicitly required.
- Prefer render arrays over string concatenation for HTML output.

### Input Validation
- Validate in `validateForm()` — never trust `$form_state->getValue()` without checks.
- Use typed constraints on entity fields instead of custom validation where possible.
- Sanitize file uploads: validate extensions, MIME types, and file size in form handlers.

### Access Control
- Every route must have `_permission`, `_role`, `_access_check`, or `_entity_access` requirement.
- Entity queries: always call `accessCheck(TRUE)` unless explicitly building admin-only views.
- Custom access checkers must return `AccessResult::allowed()` / `forbidden()` / `neutral()` with cacheability metadata.
- CSRF: use `\Drupal::csrfToken()` for non-form mutation endpoints (e.g., custom REST routes).

### Dependency Audit
- Run `composer audit` to check for known vulnerabilities.
- Monitor Drupal Security Advisories (SA-CORE, SA-CONTRIB) for installed modules.
- Flag stale contrib modules with no security coverage.

## Anti-Patterns

- Logging or committing secrets to version control.
- Disabling access checks for convenience.
- Using `#markup` with unsanitized user input.
- Using `|raw` Twig filter on user-controlled variables.
- Broadly trusting user input in Twig/PHP render paths.
- Omitting `accessCheck()` on entity queries.
- Ignoring dependency risk due to "non-production path" assumptions.
- Hardcoding API keys/secrets in `settings.php` instead of environment variables.

## References

- Read `references/security-audit-checklist.md` for concrete checks.
- Read `references/dry-run.md` for a worked example and output format.
