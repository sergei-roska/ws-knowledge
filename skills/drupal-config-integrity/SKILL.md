---
name: drupal-config-integrity
description: Maintain Drupal architecture and configuration integrity with safe config sync behavior, recipe-aware changes, and environment-specific stability. Use when tasks touch modules/services/hooks, recipe config, `config/*`, `settings*.php`, `drush cim/cex`, `config_split`, `config_ignore`, Drupal Recipes, or when preventing config drift between local (Lando), CI (Azure), and hosting (Acquia).
---

# Drupal Config Integrity

## Overview

Plan and execute Drupal changes so configuration remains deterministic, deployable, and environment-safe.
Use this workflow to avoid config drift, unsafe imports, and hidden production-only behavior.

## Workflow

1. Classify the change scope before editing.
Decide whether the change is code-only, config-only, recipe-driven, or environment-specific.

2. Find the source of truth.
Identify if configuration is managed by module export, a Drupal Recipe, or `config_split`.
Prefer recipe and committed config as canonical source.

3. Isolate environment-specific values.
Keep env-specific settings in `settings.php` overrides or `config_split`, never in shared exports.

4. Design for import safety.
Ensure `drush cim` can run without manual production edits. Validate dependencies, schema compatibility, and ordering of updates.
Use `hook_update_N` or `hook_post_update_NAME` for data migrations that must precede config imports.

5. Execute minimal, reversible changes.
Prefer narrow diffs, idempotent update paths, and explicit rollback notes for risky operations.

6. Validate with project gates.
Run `drush cex` and confirm no unexpected diff. Run quality gates after changes.

## Environment Isolation Strategy

### settings.php overrides

Use `$config['system.performance']['css']['preprocess']` style overrides for values that differ per environment but should not be in config exports.

### Config Split

Use for environment-specific modules and config (e.g., `devel`, `stage_file_proxy` for local only).
Keep split config in a separate directory (e.g., `config/local/`, `config/dev/`).

### Drupal Recipes

Prefer Recipes for packaging discrete features as reusable units.
Use `core-recipe-unpack` to manage recipe dependencies cleanly.
Store recipes in `recipes/` directory at project root.

## Required Checks

- Confirm module/service/hook changes preserve backward compatibility unless explicitly approved.
- Confirm config schema consistency for new/changed settings.
- Confirm environment-specific values are not leaked into shared exports.
- Confirm deployment order: `hook_update_N()` → `drush updb` → `drush cim` → `drush cr`.
- Confirm `drush cex` produces no unexpected diff after `drush cim`.
- Confirm local-only modules (`devel`, `stage_file_proxy`) are in split config, not `core.extension.yml`.

## Decision Rules

- **Environment variability** → `settings.php` override or Config Split.
- **Feature packaging** → Drupal Recipe in `recipes/`.
- **Dynamic content config** (menus, webforms) → `config_ignore` as narrow, documented exception.
- **Everything else** → committed shared config as source of truth.

## config_ignore Policy

- Use only as a last resort when safer options are not viable.
- Scope each ignore entry as narrowly as possible.
- Document rationale for every `config_ignore` entry.
- Review ignores periodically — they may hide real drift.

## Anti-Patterns

- Exporting configuration that contains local secrets, hostnames, or environment-only credentials.
- Committing `devel` or `stage_file_proxy` in shared `core.extension.yml`.
- Mixing unrelated config churn into functional changes.
- Relying on manual admin UI toggles in production after deployment.
- Applying broad ignores that hide real architectural drift.
- Using `config_ignore` as the primary strategy instead of Config Split.

## References

- Read `references/project-config-integrity-patterns.md` and map it to the current repository.
- Read `references/dry-run.md` for a worked example and expected output shape.
