# Project Config Integrity Patterns

## Purpose

Use this reference at the start of a config-affecting task to map the skill's rules to the target repository.
This is a **detection and adaptation** checklist, not a copy of the main SKILL.md.

## Detect Project Signals

Check for these signals in the target repository to understand its config architecture:

| Signal | Where to look | What it tells you |
|--------|--------------|-------------------|
| Committed config exports | `config/sync/` or `config/default/` | Shared source of truth exists |
| Environment split directories | `config/local/`, `config/dev/`, `config/stage/` | Config Split is in use |
| Recipe directory | `recipes/` | Recipe-driven features exist |
| Environment overrides | `settings.php`, `settings.local.php` | Runtime overrides in use |
| Quality gate script | `run-code-analysis.sh`, `.github/workflows/`, `azure-pipelines.yml` | CI validation exists |
| `config_ignore` settings | `config/sync/config_ignore.settings.yml` | Ignored config keys exist — review carefully |
| Hosting platform files | `.acquia/`, `pantheon.yml`, `.platform.app.yaml` | Platform-specific deploy rules apply |

## Adaptation Checklist

After detecting project signals, confirm:

1. [ ] Which config directory is the shared source of truth?
2. [ ] Which Config Split environments are defined?
3. [ ] Are there active Drupal Recipes? Which features do they own?
4. [ ] What quality gate must pass before merge?
5. [ ] What is the deploy command sequence for this project?
6. [ ] Are there any `config_ignore` entries? Are they documented?
7. [ ] Does the project use a specific hosting platform with deploy hooks?

## Integrity Rules (Summary)

These summarize the main SKILL.md rules for quick reference during project mapping:

- Shared config must be deterministic and portable.
- Environment-specific values belong in overrides, not committed exports.
- Update paths must be idempotent and ordered when mixing schema/data/config changes.
- Diffs must be focused — no unrelated config churn.
- `config_ignore` is a narrow exception, not a strategy.

## Minimum Output for Any Change

Every config-affecting task must produce:

1. List of touched config domains.
2. Import/export safety statement.
3. Deploy order and rollback notes for risky operations.
4. Source of truth and environment isolation confirmation.
