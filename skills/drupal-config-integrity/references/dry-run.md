# Dry Run: Drupal Config Integrity

## Example Task

Add a new custom module setting for an external API endpoint (`mymodule.settings:api_endpoint`) while keeping local, CI, and production behavior stable.

## Applied Workflow

### Step 1 — Classify the Change

- **Type: Mixed** — config-only (new setting in `config/sync/`) + environment-specific (endpoint value differs per environment).

### Step 2 — Find the Source of Truth

- The module's config is committed to `config/sync/mymodule.settings.yml`.
- No Recipe owns this config.
- The endpoint value is environment-specific → requires override.

### Step 3 — Isolate Environment-Specific Values

- Add a default (empty or placeholder) value in committed config:
  ```yaml
  # config/sync/mymodule.settings.yml
  api_endpoint: ''
  ```
- Add per-environment overrides in `settings.php`:
  ```php
  // settings.php (or settings.local.php)
  $config['mymodule.settings']['api_endpoint'] = getenv('MYMODULE_API_ENDPOINT') ?: 'https://api.example.com';
  ```
- No secrets in `config/sync/`.

### Step 4 — Design for Import Safety

- No data migration needed — this is a new key with a safe default.
- No `hook_update_N()` required.
- `drush cim` will apply the new key with the default value; `settings.php` override takes effect at runtime.
- No dependency ordering concerns.

### Step 5 — Execute Minimal, Reversible Changes

- Files touched:
  - `config/sync/mymodule.settings.yml` — add `api_endpoint: ''`
  - `config/schema/mymodule.schema.yml` — add schema entry for `api_endpoint`
  - `settings.php` — add `$config` override
- Rollback: remove the key from config and schema, remove the `$config` line.

### Step 6 — Validate

- `drush cex` → no unexpected diff (only the new key).
- `drush cim` on clean DB → no errors.
- `drush cr` → success.
- Quality gate → pass.

## Expected Output (per Output Contract)

### 1. Change Summary

| Object | Action |
|--------|--------|
| `mymodule.settings.yml` | Added `api_endpoint` key with empty default |
| `mymodule.schema.yml` | Added schema definition for `api_endpoint` (string) |
| `settings.php` | Added `$config['mymodule.settings']['api_endpoint']` override |

### 2. Source of Truth Statement

- `mymodule.settings.yml` is committed shared config — source of truth for the key's existence and default.
- The runtime value is set by `settings.php` override — not stored in config exports.

### 3. Import Safety Statement

- `drush cim` applies the new key with an empty default. No errors, no dependency issues.
- No `hook_update_N()` required — the setting is new and optional.
- Deploy order: standard (`drush updb` → `drush cim` → `drush cr`).

### 4. Environment Note

- The API endpoint value is isolated in `settings.php` using `getenv()`.
- No secrets or environment-specific values leaked into `config/sync/`.
- Local, CI, and production each resolve the endpoint from their environment variables.

### 5. Rollback Note

- Low risk. To rollback: remove the `api_endpoint` key from `mymodule.settings.yml`, remove the schema entry, remove the `$config` line from `settings.php`, run `drush cim && drush cr`.
