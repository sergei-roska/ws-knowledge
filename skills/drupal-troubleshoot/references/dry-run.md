# Dry Run: Drupal Troubleshooting

## Example Task

After deploying a new release, the /services page returns a WSOD. Other pages work fine.

## Applied Workflow

1. Reproduce: confirmed WSOD at `/services` on staging. Homepage and admin pages load normally.

2. Gather evidence:
   ```bash
   drush watchdog:show --severity=error --count=10
   ```
   Found: `TypeError: Argument 1 passed to Drupal\my_module\Plugin\Block\ServicesBlock::build() must be of type array, null given in /app/docroot/modules/custom/my_module/src/Plugin/Block/ServicesBlock.php:45`

3. Isolate the layer:
   - Error is in custom module code (`my_module`), not core or theme.
   - The `ServicesBlock::build()` method receives `null` for a parameter that expects an array.
   - Checked `git log --oneline -3` — the latest commit changed the block plugin to accept a typed array parameter.

4. Root cause analysis:
   - The block's `build()` method was refactored to accept `array $config` but the calling code passes the result of `\Drupal::state()->get('services_config')` which returns `null` when the state value doesn't exist.
   - Fix: add a null coalesce fallback.

5. Fix applied:
   ```php
   $config = \Drupal::state()->get('services_config') ?? [];
   ```

6. Verify:
   ```bash
   drush cr
   # Browse /services — page loads correctly.
   drush watchdog:show --severity=error --count=5
   # No new errors.
   ```

## Output

- Root cause: null state value passed to typed parameter.
- 1 line fix in `ServicesBlock.php`.
- Verified fix on staging, no new errors in watchdog.
- Recommended: add a Kernel test for `ServicesBlock` to catch null config in the future.
