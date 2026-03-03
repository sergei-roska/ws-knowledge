# Project Config Integrity Patterns

## Detect Project Signals

Check for these signals in the target repository:
- `config/` directory with committed exports
- `recipes/` directory for recipe-managed behavior
- environment overrides in `settings*.php`
- project quality script (for example `run-code-analysis.sh` or equivalent CI command)

## Baseline Workflow

1. Identify change type: code-only, config-only, recipe-driven, or environment-specific.
2. Verify source of truth for config and recipe ownership.
3. Ensure config is import-safe and reproducible in CI and production.
4. Validate with project quality gates after change.

## Integrity Rules

- Keep shared config deterministic and portable.
- Keep environment-specific values in overrides, not committed exports.
- Keep update paths idempotent and ordered when mixing schema/data/config changes.
- Keep diffs focused and avoid unrelated config churn.

## `config_ignore` Policy

- Use as a narrow exception, not as the main strategy.
- Document rationale and scope.
- Confirm that ignores do not hide actual drift.

## Minimum Output for Any Change

- List of touched config domains.
- Import/export safety statement.
- Deploy order and rollback notes for risky operations.
