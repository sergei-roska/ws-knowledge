# Dry Run: Drupal Testing

## Example Task

Write tests for `gc_salesforce_webform` module covering payload building (unit), queue processing (kernel), and settings form (functional).

## Applied Workflow

1. Classify:
   - `PayloadBuilder::build()` — pure PHP transform → Unit test.
   - `SalesforceSubmitWorker::processItem()` — needs queue + http_client → Kernel test.
   - Settings form at `/admin/config/services/salesforce-webform` — needs HTTP → Functional test.

2. Create structure:
   ```
   tests/src/Unit/PayloadBuilderTest.php
   tests/src/Kernel/SalesforceQueueTest.php
   tests/src/Functional/SettingsFormTest.php
   ```

3. Write tests:
   - Unit: test payload structure, required fields, edge cases (empty input).
   - Kernel: install module, enqueue item, process it, verify HTTP client was called with correct payload (mocked).
   - Functional: test access control (anonymous 403, admin 200), form submission saves config.

4. Run:
   ```
   lando php vendor/bin/phpunit docroot/modules/custom/gc_salesforce_webform/tests/src/Unit/
   lando php vendor/bin/phpunit docroot/modules/custom/gc_salesforce_webform/tests/src/Kernel/
   lando php vendor/bin/phpunit docroot/modules/custom/gc_salesforce_webform/tests/src/Functional/
   ```

## Output

- 3 test classes, 8 test methods total.
- Unit: 3 tests (valid payload, empty input exception, optional fields).
- Kernel: 3 tests (queue item creation, processing success, processing failure with requeue).
- Functional: 2 tests (access control, form submission).
- All green in both Lando and CI.
