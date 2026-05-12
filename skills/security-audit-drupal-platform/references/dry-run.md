# Dry Run: Security Audit Drupal Platform

## Example Task

Review a feature branch that adds a custom API integration and new admin form settings.

## Applied Workflow

1. Scope custom module/theme/settings and deploy script changes.
2. Check secret storage and config exports for credential leaks.
3. Check input validation and output escaping in new form/render paths.
4. Verify access checks on admin routes and mutation endpoints.
5. Review dependencies touched by the integration.

## Expected Output

- Severity-ranked findings with evidence.
- Fix recommendations with minimal blast radius.
- Deployment caution notes for sensitive config changes.
- Residual risk statement after remediation.
