# Dry Run: Drupal Module Scaffold

## Example Task

Create a new custom module `gc_salesforce_webform` that intercepts webform submissions, transforms data, and sends it to Salesforce via a queue.

## Applied Workflow

1. Determine scope:
   - Service: transform webform data to Salesforce payload.
   - Event subscriber: react to webform submission event.
   - QueueWorker: async send to Salesforce API.
   - Config form: admin settings for Salesforce endpoint URL.
   - Config + schema: store endpoint URL.
   - Permissions: admin access to settings form.

2. Docroot: project uses `docroot/modules/custom/`.

3. Generate skeleton:

   ```text
   gc_salesforce_webform/
   ├── config/
   │   ├── install/
   │   │   └── gc_salesforce_webform.settings.yml
   │   └── schema/
   │       └── gc_salesforce_webform.schema.yml
   ├── src/
   │   ├── EventSubscriber/
   │   │   └── WebformSubmitSubscriber.php
   │   ├── Form/
   │   │   └── SettingsForm.php
   │   ├── Plugin/
   │   │   └── QueueWorker/
   │   │       └── SalesforceSubmitWorker.php
   │   └── SalesforcePayloadBuilder.php
   ├── gc_salesforce_webform.info.yml
   ├── gc_salesforce_webform.routing.yml
   ├── gc_salesforce_webform.services.yml
   └── gc_salesforce_webform.permissions.yml
   ```

4. Wire dependencies:
   - `SalesforcePayloadBuilder` → service with `@http_client`, `@config.factory`.
   - `WebformSubmitSubscriber` → event subscriber injecting `@queue` and payload builder.
   - `SalesforceSubmitWorker` → QueueWorker injecting payload builder and http_client.
   - `SettingsForm` → route under `/admin/config/services/salesforce-webform`.

5. Validate:
   - `lando drush en gc_salesforce_webform -y`
   - `lando drush cr`
   - Verify settings form renders at expected route.
   - Submit test webform, verify queue item created.

## Key Decisions

- Queue over synchronous HTTP: isolates webform UX from Salesforce latency/failures.
- Event subscriber over hook: webform module provides events, cleaner than `hook_webform_submission_insert`.
- Config schema required: endpoint URL must validate as `uri` type.
- No `.module` file: all logic lives in services and plugins.

## Files Created: 9

## Estimated time to scaffold: 15-20 minutes with this skill
