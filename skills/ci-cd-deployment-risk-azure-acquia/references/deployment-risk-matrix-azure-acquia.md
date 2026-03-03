# Deployment Risk Matrix for Azure CI and Acquia Runtime

## Scope

Use this matrix when a Drupal project deploys through Azure pipelines and runs on Acquia.

## Pre-Deploy Checks

- Pipeline definition exists and includes quality gates.
- Build artifacts include required compiled assets.
- Composer and PHP compatibility are aligned across local, CI, and hosting.
- Database/config update order is explicitly defined.

## Risk Matrix

1. Code Compatibility
- Risk: Runtime differences between CI and Acquia PHP/extensions.
- Mitigation: Verify platform constraints and lock dependency compatibility.

2. Config Drift
- Risk: Environment-only values leaked into shared config.
- Mitigation: Use env overrides/splits and validate import behavior.

3. Schema/Data Updates
- Risk: Non-idempotent updates or unsafe sequencing.
- Mitigation: Validate update hooks and define exact deploy order.

4. Cache and Runtime
- Risk: Stale caches after config/schema deployment.
- Mitigation: Include cache rebuild strategy and smoke checks.

5. Pipeline Gating
- Risk: Local pass but CI fail due missing steps/commands.
- Mitigation: Align local validation with the same canonical CI gates.

## Go/No-Go Output Template

- Change summary
- Risk level (`Low`, `Medium`, `High`, `Blocker`) by area
- Mitigation checklist
- Required commands and order
- Rollback triggers
- Final recommendation (`Go` or `No-Go`)
