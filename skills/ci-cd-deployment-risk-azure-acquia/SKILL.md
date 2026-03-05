---
name: ci-cd-deployment-risk-azure-acquia
description: Analyze CI/CD and deployment risk for Drupal projects running Azure pipelines and Acquia hosting. Use when tasks touch deployment scripts, pipeline config, release sequencing, update hooks, environment compatibility, database migrations, or when preparing go/no-go recommendations for production release.
---

# CI/CD Deployment Risk (Azure + Acquia)

## Overview

Assess release risk before merge/deploy and produce concrete mitigations.
Focus on compatibility between local dev tooling (Lando), Azure CI steps, and Acquia runtime constraints.

## Workflow

1. Map the change to deploy surfaces.
Identify code, config, schema/data updates, cache behavior, and environment assumptions.

2. Inspect pipeline and hosting contracts.
Check Azure pipeline steps, artifact build behavior, and Acquia deployment/runtime expectations.

3. Evaluate failure modes.
Look for non-idempotent updates, environment-specific config leakage, missing dependency steps, and cache invalidation risks.

4. Assign risk level with mitigation.
Use `Low`, `Medium`, `High`, or `Blocker` and include precise preventive actions.

5. Define release checklist.
Provide pre-deploy checks, deploy order, post-deploy verification, and rollback triggers.

## Acquia Runtime Constraints

- **Read-only filesystem** — no file writes except to `sites/default/files/`. Generated assets must be built in CI, not at runtime.
- **Varnish cache layer** — validate that Cache Tags and `Surrogate-Key` headers are correctly set for edge invalidation.
- **Deploy hooks** — Acquia runs `post-code-deploy` and `post-code-update` hooks. Ensure `drush updb`, `drush cim`, `drush cr` are in the correct hook.
- **PHP version parity** — confirm PHP version matches between Lando, Azure CI, and Acquia runtime.
- **Memory/timeout limits** — heavy `hook_update_N` operations may hit Acquia's process limits. Plan chunked updates for large data sets.

## Database Migration Safety

- Analyze `drush updb` and `hook_update_N` for potential timeouts or table lock risks on large data sets.
- Ensure update hooks are idempotent — safe to re-run if deployment is retried.
- Plan rollback strategies: document whether a failed update can be reversed or requires DB restore.
- Isolate heavy data migrations into separate deployment phases when possible.
- Always verify deploy order: `drush updb` → `drush cim` → `drush cr`.

## Performance Risk Signals

- N+1 query patterns in Views or entity load paths introduced by the change.
- Missing `#cache` metadata on new render arrays → uncacheable pages behind Varnish.
- New asset libraries without aggregation → increased HTTP requests in production.
- Use `#lazy_builder` / BigPipe placeholders for personalized fragments inside cached pages.

## Output Contract

Return a short, actionable release note with:

- change scope;
- risk matrix by area (code/config/schema/cache/dependencies);
- mitigations and required commands;
- go/no-go recommendation.

## Anti-Patterns

- Deploying config/data changes without documented order and rollback criteria.
- Assuming local Lando behavior guarantees Azure/Acquia parity.
- Ignoring a failing quality gate because it is "non-blocking locally".
- Bundling unrelated risky operations into one release.
- Running long `drush updb` on production without testing on a DB dump first.
- Over-caching (stale content) or under-caching (server overload) without validation.

## References

- Read `references/deployment-risk-matrix-azure-acquia.md` and map checks to the target repository.
- Read `references/dry-run.md` for an example go/no-go risk assessment.
