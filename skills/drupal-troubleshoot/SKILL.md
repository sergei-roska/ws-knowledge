---
name: drupal-troubleshoot
description: Diagnose and resolve Drupal runtime issues — WSOD, PHP errors, watchdog entries, cache problems, configuration mismatches, and performance bottlenecks. Use when Drupal produces unexpected errors, blank pages, or broken behavior.
---

# Drupal Troubleshooting

## Context & Purpose
This skill transforms the agent into a systematic Drupal diagnostician.
Do not guess the cause of an error. Do not repeatedly clear caches hoping it will fix things.
Actively gather evidence from the environment, isolate the failing layer, apply a targeted fix, and verify.

## 1. Operational Execution Loop

When encountering a Drupal error or White Screen of Death (WSOD), autonomously execute these steps using your environment tools (`run_command`):

1. **Verify State (Gather Evidence)**
   - Check Drupal watchdog: `drush watchdog:show --severity=error --count=10`
   - Check PHP logs if Drush fails or WSOD occurs without watchdog entries. Look for `error_log` location via `php -i`.
   - Check configuration discrepancies: `drush config:status`

2. **Isolate the Layer**
   - **Infrastructure/Container:** Does `drush status` succeed? If not, the database or service container is broken.
   - **Application Code:** Are the errors in custom modules (`modules/custom/*`) or core?
   - **Theming/Rendering:** Are there Twig compiler errors?

3. **Apply Targeted Fix**
   - Fix the code based on the lowest stack trace frame in custom code.
   - Revert bad config.
   - Clear *only* the necessary cache (e.g., `drush cache:clear render`).

4. **Verify**
   - Re-run the failing action or request the broken route.
   - Verify watchdog is clean again.

## 2. Command Reference for Agents

Use these commands directly to extract facts. **Do not ask the user to run them.**

### Logging & Diagnostics
```bash
# Recent PHP/Critical errors
drush watchdog:show --type=php --count=20
drush watchdog:show --severity=error --count=5

# System Health
drush status
drush core:requirements --severity=error
```

### Fixing Broken Service Containers (WSOD)
If `drush cr` fails deeply because of a broken container or bad plugin:
```bash
# Delete compiled container manually
rm -rf sites/default/files/php/

# Delete compiled Twig templates
rm -rf sites/default/files/php/twig/
```

### Config & Schema Issues
```bash
drush config:status
drush config:diff system.site
drush entity:updates
```

## 3. Stack Trace Analysis Rules

When reading a PHP stack trace from Drupal:
1. **Start from the bottom** (where the call originates) and move **upward**.
2. Stop at the first frame referencing **custom code** (`modules/custom` or `themes/custom`). This is almost always the root cause.
3. **`Call to a member function on null`**: An entity or field failed to load. Do not just suppress the error; find out *why* the load failed (e.g., missing ID, wrong entity type).
4. **`Class not found`**: Missing namespace `use`, misspelled class, or the module defining it is disabled.

## 4. Agent Anti-Patterns (MUST AVOID)

- **The "Guess and Cache" Loop**: Do not run `drush cr` repeatedly after random code changes. Read the log to confirm the error changed.
- **Destructive Shortcuts**: Never run `drush sql:drop` or `drush site:install` without explicit user permission.
- **Modifying Core/Contrib**: Never edit files in `/core` or `/modules/contrib` directly. Create patches or extend classes.
- **Ignoring Missing State**: If a state value or config is missing and causes a null pointer, fix the calling code with a fallback (e.g., `?? []`) rather than just setting the state variable.
- **Suggesting IDE Setup**: Do not output instructions about Xdebug or IDE breakpoints to the user unless explicitly asked. Rely on your own ability to read logs and execute `drush`.

## 5. References
- Review `references/troubleshoot-checklist.md` for a structured triage list.
- Review `references/dry-run.md` for an example of successful agent diagnosis.
