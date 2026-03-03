# Dry Run: CI/CD Deployment Risk (Azure + Acquia)

## Example Task

Deploy a feature that includes a new update hook, config changes, and theme asset rebuild.

## Applied Workflow

1. Map change surfaces: code, config, schema/data, cache, artifacts.
2. Verify pipeline contains required quality gates and asset build steps.
3. Evaluate idempotency of updates and config import order.
4. Assign risk levels and mitigations by area.
5. Produce go/no-go recommendation with rollback triggers.

## Expected Output

- Risk matrix (`Low`/`Medium`/`High`/`Blocker`) for code, config, schema/data, cache, dependencies.
- Pre-deploy checklist and ordered command sequence.
- Post-deploy smoke checks.
- Final recommendation with clear conditions.
