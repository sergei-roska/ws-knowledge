# Troubleshoot Checklist

## Phase 1: Triage (< 2 min)

- [ ] What is the HTTP status code? (200, 403, 404, 500, 503)
- [ ] Is the issue on all pages or a specific route?
- [ ] Did anything change recently? (deployment, config import, module update)
- [ ] Can you reproduce it reliably?
- [ ] Which environment? (local, staging, production)

## Phase 2: Gather Evidence (< 5 min)

### Error Logs

```bash
drush watchdog:show --severity=error --count=20
tail -100 /var/log/php-error.log   # or lando equivalent
```

### System Status

```bash
drush status
drush core:requirements --severity=error
```

### Recent Changes

```bash
git log --oneline -10
drush config:status
drush entity:updates
```

### Database

```bash
drush sql:query "SELECT 1;"          # connectivity
drush updatedb:status                 # pending updates
```

## Phase 3: Isolate (5–15 min)

### By Layer

1. **Infrastructure**: Can PHP execute at all?
   ```bash
   drush ev "echo phpversion();"
   ```

2. **Database**: Is the connection alive, are tables intact?
   ```bash
   drush sql:connect
   drush sql:query "SHOW TABLES LIKE 'node%';"
   ```

3. **Bootstrap**: Does Drupal boot?
   ```bash
   drush ev "echo \Drupal::VERSION;"
   ```

4. **Module**: Is a specific module causing the issue?
   ```bash
   # Check if disabling a module fixes it
   drush pm:uninstall suspect_module -y && drush cr
   ```

5. **Theme**: Is it a rendering issue?
   ```bash
   # Switch to default admin theme temporarily
   drush config:set system.theme default claro -y && drush cr
   ```

6. **Permissions**: File system access?
   ```bash
   ls -la sites/default/files/
   drush ev "echo (is_writable('sites/default/files') ? 'writable' : 'NOT writable');"
   ```

### By Symptom

**WSOD (White Screen)**
→ PHP fatal error. Check error log. Enable verbose errors in settings.local.php.

**"Access denied" (403)**
→ Permission issue. Check `drush role:perm:list`, `node_access_rebuild()`.

**"Page not found" (404)**
→ Route issue. Check `drush route:list --path=/your/path`, clear router cache.

**"This site is under maintenance" (503)**
→ Maintenance mode stuck. `drush state:set system.maintenance_mode 0 -y && drush cr`.

**Slow pages**
→ Check for N+1 queries, missing cache tags, Views without caching.

**Broken layout / missing styles**
→ Library not attached, CSS aggregation issue. `drush cr`, check libraries.yml.

**Form submission errors**
→ CSRF token expired, validation hook throwing exception. Check watchdog for form_id.

**Cron not running**
→ `drush state:get system.cron_last`, `drush core:cron --verbose`.

## Phase 4: Fix and Verify

- [ ] Apply the minimal fix (one change at a time).
- [ ] Clear caches: `drush cr`.
- [ ] Verify the fix on the affected page/route.
- [ ] Check watchdog for new errors: `drush watchdog:show --severity=error --count=5`.
- [ ] If on staging/prod, check that other pages still work (smoke test).

## Phase 5: Prevent Recurrence

- [ ] Add a test case that covers the failure scenario.
- [ ] Update documentation if the issue stems from unclear setup steps.
- [ ] If it's a deployment issue, add it to the deployment checklist.
- [ ] If it's a contrib module bug, check the issue queue and consider a patch/upstream report.

## Quick Reference: Emergency Commands

```bash

# Kill maintenance mode

drush state:set system.maintenance_mode 0 -y && drush cr

# Rebuild container (when service definitions change)

drush cr

# Delete compiled Twig cache

rm -rf sites/default/files/php/twig/ && drush cr

# Delete compiled container

rm -rf sites/default/files/php/ && drush cr

# Reset admin password

drush user:password admin "temp_password_change_me"

# Enable a module stuck in broken state

drush sql:query "DELETE FROM key_value WHERE collection='system.schema' AND name='broken_module';"
drush cr

# Re-run updates

drush updatedb -y && drush cr

# Full nuclear reset (local dev only)

drush sql:drop -y && drush site:install -y && drush cr
```
