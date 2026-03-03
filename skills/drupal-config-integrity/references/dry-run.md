# Dry Run: Drupal Config Integrity

## Example Task

Add a new custom module setting for an external API endpoint while keeping local, CI, and production behavior stable.

## Applied Workflow

1. Classify scope as config + environment-specific override.
2. Keep committed default config environment-neutral.
3. Put environment-specific endpoint value in `settings*.php` override.
4. Verify config import safety and no unrelated config churn.
5. Run project quality gates and cache rebuild path.

## Expected Output

- Change summary listing touched config objects and files.
- Statement that shared export remains environment-agnostic.
- Import safety note (`drush cim` behavior) and deploy order.
- Rollback note for config/schema interactions, if any.
