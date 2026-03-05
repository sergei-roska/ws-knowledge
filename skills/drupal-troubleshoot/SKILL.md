---
name: drupal-troubleshoot
description: Diagnose and resolve Drupal runtime issues — WSOD, PHP errors, watchdog entries, cache problems, configuration mismatches, and performance bottlenecks. Use when Drupal produces unexpected errors, blank pages, or broken behavior.
---

# Drupal Troubleshooting

## Overview

Systematic approach to diagnosing Drupal 10/11 issues: gather evidence from logs and error output, isolate the failing layer, apply targeted fixes, and verify.

## Workflow

1. Reproduce the issue.
Determine exact steps, URL, user role, and environment (local/staging/prod).

2. Gather evidence.
Check PHP error log, Drupal watchdog, browser console, and HTTP response code.

3. Isolate the layer.
Determine whether the failure is in PHP, Drupal bootstrap, module code, theme rendering, or infrastructure (DB/file system/permissions).

4. Apply fix.
Targeted repair based on the root cause — code fix, config change, cache rebuild, or permission correction.

5. Verify and prevent.
Confirm the fix, add tests or monitoring to prevent recurrence.

## White Screen of Death (WSOD)

### Immediate Steps

1. Check PHP error log:

   ```bash
   # Lando
   lando ssh -c "tail -50 /tmp/drupal-error.log"
   # Or check PHP error log location
   lando php -i | grep error_log
   ```

2. Enable error display temporarily:

   ```php
   // In sites/default/settings.local.php
   $config['system.logging']['error_level'] = 'verbose';
   error_reporting(E_ALL);
   ini_set('display_errors', TRUE);
   ```

3. Try minimal bootstrap:

   ```bash
   drush status
   drush ev "echo 'Bootstrap OK';"
   ```

4. If drush fails, check `settings.php` and database connection:

   ```bash
   drush sql:connect
   ```

### Common WSOD Causes

- Fatal PHP error in a module — check recent deployments, `git log --oneline -5`.
- Memory limit exceeded — increase `memory_limit` in `php.ini`.
- Broken container — `drush cr` or delete `sites/default/files/php/` (compiled container).
- Missing module files — module enabled in DB but code removed from filesystem.
- Twig compilation error — delete `sites/default/files/php/twig/` cache.

## Watchdog / Logging

### Reading Logs

```bash

# Recent watchdog entries

drush watchdog:show --count=20

# Filter by severity

drush watchdog:show --severity=error --count=50

# Filter by type

drush watchdog:show --type=php --count=20

# Tail mode (continuous)

drush watchdog:tail
```

### Syslog vs DBLog

- `dblog` — stores in database, accessible via admin/reports/dblog. Good for dev, adds DB load in prod.
- `syslog` — writes to system log. Preferred for production.
- Check which is enabled: `drush pm:list --filter=name=dblog,syslog`.

## Xdebug Setup

### Lando Configuration

```yaml

# .lando.yml

config:
  xdebug: true
  config:
    php: .lando/php.ini
```

```ini

# .lando/php.ini

[xdebug]
xdebug.mode = debug
xdebug.start_with_request = yes
xdebug.client_host = host.docker.internal
xdebug.client_port = 9003
xdebug.log = /tmp/xdebug.log
xdebug.idekey = VSCODE
```

### Debugging Drush Commands

```bash

# Trigger Xdebug for drush

XDEBUG_SESSION=1 drush cr

# Or with lando

lando drush cr  # Xdebug auto-triggers if enabled in .lando.yml
```

### IDE Breakpoint Strategy

- Set breakpoint in the specific hook/controller/service method.
- For routing issues: breakpoint in `Drupal\Core\Routing\RouteProvider::getRoutesByPattern()`.
- For access denied: breakpoint in `Drupal\Core\Access\AccessManager::check()`.
- For entity load issues: breakpoint in `Drupal\Core\Entity\EntityStorageBase::load()`.

## Stack Trace Analysis

### Reading PHP Stack Traces

1. Start from the **bottom** — that is where the call originates.
2. Move **upward** to find the first frame in custom code (not core/contrib).
3. Check the function arguments for unexpected values.

### Common Patterns

- `Call to a member function on null` → entity/field not loaded, check the load call above it.
- `Class not found` → missing `use` statement, wrong namespace, or module not enabled.
- `Maximum function nesting level` → infinite loop in hooks or recursive rendering.
- `Allowed memory size exhausted` → N+1 query, loading too many entities, or view returning too many results.

## Common Drupal Errors

### "The website encountered an unexpected error"

```bash

# Check recent log entries for the actual error

drush watchdog:show --severity=error --count=5
```

### "Access denied" unexpectedly

```bash

# Check permissions for a specific route

drush user:role:list
drush role:perm:list <role>

# Rebuild permissions

drush php-eval "node_access_rebuild();"
```

### Entity/Field errors

```bash

# Check for mismatched entity/field definitions

drush entity:updates
drush updatedb --no-cache-clear
drush cr
```

### Configuration sync errors

```bash

# Check config status

drush config:status

# Import with verbose output

drush config:import -y --diff

# Show a specific config difference

drush config:diff system.site
```

### Module enable/disable issues

```bash

# Check for missing modules

drush pm:list --status=enabled --no-core | grep -i "missing"

# Remove missing module from DB

drush sql:query "DELETE FROM key_value WHERE collection='system.schema' AND name='broken_module';"
drush cr
```

### Cache issues

```bash

# Full cache rebuild (the nuclear option)

drush cr

# Selective cache clear

drush cache:clear render
drush cache:clear discovery
drush cache:clear menu

# If drush itself fails, clear via filesystem

rm -rf sites/default/files/php/
```

## Drush Diagnostic Commands

```bash

# System status overview

drush status
drush core:requirements --severity=error

# PHP info

drush php:eval "phpinfo();"

# Database connectivity

drush sql:connect
drush sql:query "SELECT 1;"

# Cron status

drush core:cron

# Queue diagnostics

drush queue:list
drush queue:run <queue_name>

# State values

drush state:get system.cron_last
drush state:get system.maintenance_mode

# Route debugging

drush route:list --path=/node/1

# Service container check

drush ev "\Drupal::service('entity_type.manager');"
```

## Performance Diagnostics

```bash

# Enable query logging temporarily

drush ev "\Drupal::database()->startLog(); /* run operation */ print_r(\Drupal::database()->getLog());"

# Check cache hit rates

drush ev "print_r(\Drupal::cache('render')->get('some_cid'));"

# Views query inspection

# Enable Views UI query display in admin/structure/views

```

## Required Checks

- Always check error logs before making assumptions.
- Verify the environment matches expected state (correct branch, config imported, caches cleared).
- Confirm the issue is reproducible before debugging.
- After fixing, clear caches and verify the fix in a clean state.
- Document the root cause for the team.

## Anti-Patterns

- Clearing all caches repeatedly without reading error logs first.
- Enabling `display_errors` on production.
- Editing core or contrib code directly to "fix" issues instead of proper patches/overrides.
- Ignoring deprecation warnings — they become fatal errors on major version upgrades.
- Debugging on production without a plan for cleanup.
- Assuming the issue is Drupal when it might be infrastructure (DNS, file permissions, PHP version).

## References

- Read `references/troubleshoot-checklist.md` for a structured diagnostic checklist.
- Read `references/dry-run.md` for a worked troubleshooting example.
