---
name: drupal-config-integrity
description: >
  Maintain Drupal architecture and configuration integrity with safe config sync,
  recipe-aware changes, and environment-specific stability. Use when tasks touch
  modules, services, hooks, recipe config, `config/*`, `settings*.php`,
  `drush cim/cex`, `config_split`, `config_ignore`, Drupal Recipes, content types,
  fields, views, or when preventing config drift between environments.
---

# Drupal Config Integrity

## Goal

Keep Drupal configuration deterministic, deployable, and environment-safe.
Prevent config drift, unsafe imports, and hidden production-only behavior.

## Activation Triggers

Activate this skill when the task involves any of the following:

- adding, removing, or modifying a Drupal module
- changing services, hooks, plugins, or event subscribers
- touching files under `config/sync/`, `config/local/`, `config/dev/`
- editing `settings.php`, `settings.local.php`, or environment overrides
- running or planning `drush cim`, `drush cex`, `drush updb`, `drush cr`
- adding or modifying a Drupal Recipe
- adding, changing, or removing a content type, field, view, or entity form
- changing `config_split` or `config_ignore` rules
- deploying to a new environment or debugging environment config differences
- discussing config drift, import failures, or unexpected export diffs

If in doubt, activate. False activation is cheap; missed config integrity is expensive.

## Core Workflow

Follow these six steps in order for every config-affecting task.

### Step 1 — Classify the Change

Determine the change type before editing any file:

| Type | Definition |
|------|------------|
| Code-only | PHP/Twig changes that do not alter config YAML |
| Config-only | Schema or setting changes exported to `config/sync/` |
| Recipe-driven | Packaged feature delivered via a Drupal Recipe |
| Environment-specific | Value that differs per environment (local, CI, prod) |
| Mixed | Combination of the above |

If the change is mixed, handle each dimension separately.

### Step 2 — Find the Source of Truth

Identify who owns the configuration:

- **Committed config** (`config/sync/`) → shared source of truth.
- **Drupal Recipe** (`recipes/`) → recipe is canonical; config is generated.
- **Config Split** (`config/local/`, `config/dev/`) → environment override.
- **settings.php** → runtime override, not in config exports.

Never modify config that a Recipe owns by hand-editing the export.
Apply the Recipe and re-export instead.

### Step 3 — Isolate Environment-Specific Values

- `$config['key']['subkey']` overrides in `settings.php` / `settings.local.php` for values that differ per environment.
- Config Split for modules that should only exist in certain environments (e.g., `devel`, `stage_file_proxy`).
- Never commit environment-specific secrets, hostnames, or credentials into `config/sync/`.

### Step 4 — Design for Import Safety

Ensure `drush cim` can run without manual production edits:

- Validate config schema compatibility.
- Verify dependency ordering (new modules must be enabled before their config is imported).
- If data migrations must precede config:
  - Write a `hook_update_N()` or `hook_post_update_NAME()`.
  - Ensure the update runs *before* `drush cim` in the deploy sequence.
- Check that no circular dependencies exist between module enable order and config import.

#### When to write a hook_update_N

Write one if any of these is true:
- existing data must be transformed before new config takes effect
- a field storage change requires data migration
- entity schema changes need programmatic handling
- a module must be enabled or uninstalled as part of a coordinated deploy step

#### When to write a hook_post_update_NAME

Write one if:
- the action should run after all `hook_update_N()` hooks AND after config import
- you need full entity/field API available (not just database)
- the task is a one-time data backfill or cleanup

### Step 5 — Execute Minimal, Reversible Changes

- Prefer narrow diffs — touch only the config objects directly affected.
- Prefer idempotent update paths — safe to re-run without side effects.
- Add rollback notes inline (code comments or commit message) for risky operations.
- Avoid mixing unrelated config churn into functional changes.

### Step 6 — Validate

- Run `drush cex` and confirm **no unexpected diff**.
- Run `drush cim` on a clean database and confirm no errors.
- Run the project quality gate (e.g., `run-code-analysis.sh`, CI pipeline).
- Run `drush cr` and confirm cache rebuild succeeds.

## Decision Rules

| Situation | Strategy |
|-----------|----------|
| Value differs per environment (API key, endpoint, perf flag) | `settings.php` override or Config Split |
| Module needed only in some environments (`devel`, proxies) | Config Split with env-specific directory |
| Discrete feature packaged for reuse or distribution | Drupal Recipe in `recipes/` |
| Content-admin-managed config (menus, webforms) rarely changed by code | `config_ignore` — narrow, documented exception |
| Everything else | Committed shared config in `config/sync/` |

## Environment Matrix

| Rule / Check | Local (Lando) | CI (Azure) | Hosting (Acquia) |
|-------------|:---:|:---:|:---:|
| `drush cim` must pass cleanly | ✓ | ✓ | ✓ |
| `drush cex` produces no unexpected diff | ✓ | ✓ | — |
| Dev-only modules in Split, not shared config | ✓ | ✓ | ✓ |
| Secrets in `settings.php`, not exports | ✓ | ✓ | ✓ |
| Quality gates pass | ✓ | ✓ | — |
| `hook_update_N` → `updb` → `cim` → `cr` order | ✓ | ✓ | ✓ |

Adapt this matrix to the project's actual environments.

## Recipe Lifecycle Rules

1. **Store recipes** in `recipes/` at the project root.
2. **Apply order matters** — if Recipe A depends on config from Recipe B, apply B first.
3. **Use `core-recipe-unpack`** to manage recipe dependencies cleanly.
4. **After applying a recipe**, run `drush cex` and commit the generated config.
5. **Never hand-edit config YAML** that a recipe is supposed to own — re-apply the recipe instead.
6. **Test recipe apply on a clean install** periodically to catch ordering and conflict issues.
7. **If two recipes conflict** (both try to set the same config key), resolve by choosing one as canonical and adjusting the other, or merge into a parent recipe.

## config_ignore Policy

- Use only as a last resort when Config Split and `settings.php` overrides are not viable.
- Scope each ignore entry as narrowly as possible (specific config key > wildcard).
- Document the rationale for every `config_ignore` entry in a code comment or README.
- Review ignores periodically — they may hide real drift.
- Never use `config_ignore` as the primary config management strategy.

## Anti-Patterns

- Exporting configuration that contains secrets, hostnames, or environment-only credentials.
- Committing `devel` or `stage_file_proxy` in shared `core.extension.yml`.
- Mixing unrelated config churn into functional changes.
- Relying on manual admin UI toggles in production after deployment.
- Applying broad `config_ignore` patterns that hide real drift.
- Hand-editing config YAML that a Recipe owns instead of re-applying the recipe.
- Running `drush cim` without running `drush updb` first when update hooks exist.

## Required Checks

Before marking a config-affecting task complete, verify all of these:

- [ ] Module/service/hook changes preserve backward compatibility unless explicitly approved.
- [ ] Config schema is consistent for new/changed settings.
- [ ] Environment-specific values are NOT in shared exports.
- [ ] Deploy order is correct: `hook_update_N()` → `drush updb` → `drush cim` → `drush cr`.
- [ ] `drush cex` produces no unexpected diff after `drush cim`.
- [ ] Local-only modules are in Split config, not in `core.extension.yml`.
- [ ] Recipe-owned config was generated by recipe apply, not hand-edited.
- [ ] Any `config_ignore` additions are narrowly scoped and documented.

## Rollback Playbook

### If `drush cim` fails

1. Read the error message — identify the failing config object and the reason (missing dependency, schema mismatch, UUID conflict).
2. If a missing dependency: check module enable order; write a `hook_update_N` if needed.
3. If a schema mismatch: check that config YAML matches the module's `config/schema/*.yml`.
4. If a UUID conflict: compare local and remote `core.extension.yml`; resolve split/ignore conflicts.
5. Fix the root cause, re-export, re-test. Do not force-import.

### If `drush cex` shows unexpected diff

1. Diff the output against the last clean export.
2. Identify the source:
   - Environment bleed (a `settings.php` override missing, causing the active value to differ).
   - Config ignore drift (an ignored key changed on the server).
   - Unintended side effect of a module enable/disable.
3. Fix the source, not the symptom. Do not just re-commit the diff without understanding it.

## Output Contract

For every config-affecting task, produce at minimum:

1. **Change summary** — list of touched config objects, files, and modules.
2. **Source of truth statement** — which config is committed, which is recipe-owned, which is split/overridden.
3. **Import safety statement** — confirm `drush cim` behavior and any required update hook ordering.
4. **Environment note** — confirm environment-specific values are properly isolated.
5. **Rollback note** — for risky operations, describe how to reverse the change.

## Scope & Status

### Scope

Every rule in this skill applies **project-wide** unless stated otherwise.
When recording config-related decisions in project memory, always specify scope:

- `scope: project` — applies to all modules and environments
- `scope: module/<name>` — applies to a specific module's config
- `scope: environment/<name>` — applies to a specific environment (local, CI, prod)
- `scope: recipe/<name>` — applies to a specific recipe

### Status

Rules in this skill are `status: active` unless marked otherwise.
When recording config decisions in memory, use:

- `status: active` — currently enforced
- `status: experimental` — being tested, may change
- `status: superseded` — replaced by a newer rule/decision
- `status: deprecated` — will be removed

## Entity Naming for Memory

When persisting config-related knowledge to project memory, use these naming patterns:

- `decision/config-split-<purpose>` — e.g., `decision/config-split-local-dev-modules`
- `invariant/config-<rule>` — e.g., `invariant/config-no-secrets-in-exports`
- `incident/config-<event>` — e.g., `incident/config-cim-failure-uuid-conflict`
- `problem/config-<issue>` — e.g., `problem/config-drift-stage-file-proxy`
- `milestone/config-<event>` — e.g., `milestone/config-recipe-adoption`

Include aliases with Drupal-specific terms: `cim`, `cex`, `config_split`, `config_ignore`, `drush`, `recipe`, and relevant module names.

## Memory Integration

### Must Persist

- A new config management decision (e.g., adopting Config Split for a new concern).
- A new invariant (e.g., "all API endpoints must be in settings.php overrides").
- A config-related incident (failed import, drift discovery, recipe conflict).
- A revert or pivot in config strategy.
- A new `config_ignore` entry and its rationale.

### Should Persist

- Tradeoffs considered when choosing Split vs. Recipe vs. override.
- Lessons from unexpected `drush cex` diffs.
- Environment-specific quirks (e.g., "Acquia requires X before cim").
- Recipe ordering discoveries.

### Must Not Persist

- Raw config YAML diffs — these are in git.
- Routine `drush cex` / `drush cim` runs with no surprises.
- Temporary local config experiments not promoted to shared config.

## References

- Read `references/project-config-integrity-patterns.md` and map it to the current repository.
- Read `references/dry-run.md` for a worked example and expected output shape.
