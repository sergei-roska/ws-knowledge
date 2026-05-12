# Granular Deployment Risk Matrix (Azure + Acquia)

## Purpose

Use this matrix for deep-dive risk assessments. Map these failure modes to the specific custom modules or configurations being deployed.

---

## 1. Code & Environment Parity

| Feature | Risk Scenario | Mitigation | Knowledge Trigger |
| :--- | :--- | :--- | :--- |
| **PHP Version** | Lando (8.3) vs Acquia (8.2) runtime mismatch. | Synchronize `composer.json` `platform.php` with hosting. | `PHP version drift`, `hosting constraints` |
| **Extensions** | Missing `php-gd` or `imagick` on Acquia for new feature. | Validate `extension_loaded()` in `hook_requirements()`. | `missing PHP extensions`, `runtime failure` |
| **Filesystem** | Code tries to write temp files to `/tmp` instead of private FS. | Use `\Drupal::service('file_system')->getTempDirectory()`. | `read-only FS`, `tmp writes` |

## 2. Config & Drift Management

| Feature | Risk Scenario | Mitigation | Knowledge Trigger |
| :--- | :--- | :--- | :--- |
| **Env Config** | API Keys for Staging leaked into Production config. | Use `config_split` or `Settings.php` overrides. | `config leakage`, `security risk` |
| **Schema Drift** | Config import (`cim`) fails because DB schema is stale. | Run `updb` BEFORE `cim`. Ensure `updb` is idempotent. | `config vs schema drift`, `cim failure` |
| **Deleted Config** | Accidental deletion of critical system config (e.g., SMTP). | Audit `git diff` for `config/sync` deletions. | `config deletion`, `release rollback` |

## 3. Database & Schema Safety

| Feature | Risk Scenario | Mitigation | Knowledge Trigger |
| :--- | :--- | :--- | :--- |
| **Long Update** | `hook_update_N` takes >60s and hits Acquia timeout. | Use `Batch API` or chunk updates (1000 items/pass). | `update hook timeout`, `DB lock risk` |
| **Data Loss** | Update hook deletes data before verifying migration. | Include "Dry Run" mode. Backup table before modification. | `data loss risk`, `migration failure` |
| **Idempotency** | Deployment fails halfway; retry fails due to unique index. | Wrap logic in `if (!$already_exists)`. | `non-idempotent update`, `deploy retry failure` |

## 4. Performance & Cache Layers

| Feature | Risk Scenario | Mitigation | Knowledge Trigger |
| :--- | :--- | :--- | :--- |
| **Edge Cache** | New custom routes bypass Varnish (stale content). | Verify `Cache-Control` headers and Tags. | `varnish purge`, `edge caching` |
| **N+1 SQL** | Views/Block introduced with heavy SQL per-row. | Use `hook_entity_load()` or `#cache` contexts. | `SQL performance bottleneck`, `N+1 syndrome` |
| **Asset Build** | CSS/JS not aggregated on Acquia due to pipeline error. | Verify `asset-build` step in Azure Pipeline. | `unaggregated assets`, `build pipeline failure` |

---

## 5. Knowledge Update Logic

If any **Blocker** or **High** risk scenario is identified during a dry run:
1. **RECORD** the risk as a "Decision" or "Discovery" in the project's knowledge graph.
2. **LINK** it to the specific `Problem` (e.g., "Deployment Failure on Staging") and `Scope` (e.g., "Module: custom_checkout").
3. **MARK** the mitigation as a "Project Invariant."
