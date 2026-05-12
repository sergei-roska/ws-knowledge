---
name: drupal-module-scaffold
description: Scaffold new Drupal 10/11 custom modules, plugins, forms, controllers, services, and event subscribers with correct file structure, naming, and modern PHP patterns. Use when creating a new module from scratch or adding a new component to an existing module.
---

# Drupal Module Scaffold

## Overview

Generate the correct file structure, naming conventions, and boilerplate for new Drupal modules and components.
This skill ensures every new piece of code starts with proper PSR-4 layout, DI patterns, and attribute-based plugin discovery.

Also covers adding new components to existing modules without duplication or conflicts.

## Scope and Status

- **Scope:** All Drupal 10.2+ and 11.x custom module development.
- **Status:** active
- **PHP requirement:** 8.2+ (constructor promotion, readonly, enums available).
- **Plugin discovery:** Attribute-based (`#[Block]`, `#[QueueWorker]`). Use annotation (`@Block`) only if the project explicitly targets Drupal < 10.2.

> **Important:** Before scaffolding, confirm the project's Drupal core version and PHP version.
> These determine whether to use attributes or annotations, and which PHP features are safe.

## Workflow: New Module

1. **Determine scope.**
   Decide what the module needs: plugin(s), form(s), controller(s), service(s), event subscriber(s), hooks, config, templates.

   Decision checklist:
   - Does the module need a UI? → Controller and/or Form.
   - Does it need configuration? → ConfigFormBase + `config/install/` + `config/schema/`.
   - Does it react to events? → Event subscriber or hook.
   - Does it need background processing? → QueueWorker.
   - Does it add a block/field/formatter? → Plugin in `src/Plugin/`.
   - Does it expose reusable logic? → Service in `src/` + `services.yml`.

2. **Choose the docroot.**
   Detect whether the project uses `docroot/modules/custom/` or `web/modules/custom/`.

   Heuristic: check for `docroot/` first, then `web/`. If both exist, check `composer.json` for `extra.drupal-scaffold.locations.web-root`.

3. **Generate skeleton files.**
   Create minimum required files first (`info.yml` + `src/`), then add component files.

4. **Wire dependencies.**
   Register services in `*.services.yml`, routes in `*.routing.yml`, permissions in `*.permissions.yml`.

5. **Generate test skeleton.**
   Create at minimum one test class in the appropriate directory:
   - Unit test → `tests/src/Unit/`
   - Kernel test → `tests/src/Kernel/`
   - Functional test → `tests/src/Functional/`

6. **Validate structure.**
   Confirm PSR-4 autoloading, enable module with `drush en`, rebuild cache, verify no errors.

   If `drush en` fails:
   - Read the error message fully before acting.
   - Check: missing dependency? Service container error? PSR-4 mismatch?
   - Fix the root cause, then retry. Do not loop more than twice without reporting.

## Workflow: Add Component to Existing Module

1. **Inspect current module state.**
   Read `*.info.yml`, `*.services.yml`, `*.routing.yml`, and `src/` directory listing.

2. **Check for conflicts.**
   Before appending to any YAML file, verify that the service ID, route name, or permission key does not already exist.
   Before creating a class, verify no file exists at the target path.

3. **Generate component files.**
   Follow the same patterns as for a new module.

4. **Wire dependencies.**
   Append entries to existing YAML files. Do not overwrite the file; merge.

5. **Validate.**
   Rebuild cache (`drush cr`). Confirm no container errors or route conflicts.

## Module Skeleton (minimum)

Every custom module requires at minimum:

- `my_module.info.yml` — module metadata.
- `src/` — PSR-4 root for all PHP classes.

Additional files based on need:

- `my_module.module` — only for hooks that cannot be expressed as services/plugins.
- `my_module.install` — install/uninstall hooks, schema definitions, and `hook_update_N()`.
- `my_module.services.yml` — service definitions and event subscribers.
- `my_module.routing.yml` — route definitions for controllers and forms.
- `my_module.permissions.yml` — custom permissions.
- `my_module.links.menu.yml` — admin menu links.
- `my_module.links.task.yml` — local task tabs (secondary navigation).
- `my_module.libraries.yml` — JS/CSS asset libraries.
- `config/install/` — default configuration shipped with the module.
- `config/schema/` — config schema definitions for custom settings.
- `templates/` — Twig templates registered via `hook_theme()`.
- `tests/` — PHPUnit test classes.

## Component Scaffolding

### Block Plugin

```text
src/Plugin/Block/{BlockName}Block.php
```

- Use `#[Block]` attribute (D10.2+). Fall back to `@Block` annotation for D10.0–10.1.
- Extend `BlockBase`.
- Implement `ContainerFactoryPluginInterface` if injecting services.
- Include `#cache` metadata in `build()` return.

### Field Type / Widget / Formatter

```text
src/Plugin/Field/FieldType/{FieldName}Item.php
src/Plugin/Field/FieldWidget/{FieldName}Widget.php
src/Plugin/Field/FieldFormatter/{FieldName}Formatter.php
config/schema/{module}.schema.yml
```

### Form

```text
src/Form/{FormName}Form.php
my_module.routing.yml  (add route entry)
```

- Extend `FormBase`, `ConfigFormBase`, or `ConfirmFormBase`.
- For config forms: add `config/install/` and `config/schema/`.

### Controller

```text
src/Controller/{ControllerName}Controller.php
my_module.routing.yml  (add route entry)
```

- Return render array or Response, never print.
- Use entity upcasting in route parameters.
- Define access requirements on every route (`_permission`, `_role`, `_custom_access`, or `_entity_access`).

### Service

```text
src/{ServiceName}.php
my_module.services.yml  (add service definition)
```

- Use constructor promotion with readonly typed properties.
- Inject via interface types, not concrete classes.
- For services intended for reuse by other modules, define an interface:
  `src/{ServiceName}Interface.php`

### Event Subscriber

```text
src/EventSubscriber/{SubscriberName}Subscriber.php
my_module.services.yml  (add tagged service)
```

- Implement `EventSubscriberInterface`.
- Tag: `{ name: event_subscriber }`.
- **Name the class after the event it handles**, not the entity operation.

### QueueWorker

```text
src/Plugin/QueueWorker/{WorkerName}Worker.php
```

- Use `#[QueueWorker]` attribute.
- Implement idempotent `processItem()`.

### Update / Post-update hooks

```text
my_module.install       (hook_update_N)
my_module.post_update.php  (hook_post_update_NAME)
```

### Test Classes

```text
tests/src/Unit/{ClassName}Test.php
tests/src/Kernel/{ClassName}Test.php
tests/src/Functional/{ClassName}Test.php
```

- Unit tests: extend `UnitTestCase`. No Drupal bootstrap.
- Kernel tests: extend `KernelTestBase`. Partial bootstrap.
- Functional tests: extend `BrowserTestBase`. Full bootstrap.
- Namespace: `Drupal\Tests\{module_name}\{Unit|Kernel|Functional}`.

## Naming Conventions

- Module machine name: `snake_case`, prefixed with project namespace if applicable.
- Classes: `PascalCase`, suffix matches component type (`Block`, `Form`, `Controller`, `Subscriber`, `Worker`).
- Services: `my_module.service_name` in `services.yml`.
- Routes: `my_module.route_name` in `routing.yml`.
- Permissions: `verb noun` style (`administer my module settings`).
- Config: `my_module.settings` for main config object.
- Templates: `kebab-case.html.twig`, matching theme hook name with underscores replaced by hyphens.
- Test classes: `{Subject}Test.php`, named after the class or behavior under test.

## info.yml Template

```yaml
name: 'My Module'
type: module
description: 'Brief description of module purpose.'
package: Custom
core_version_requirement: ^10.3 || ^11
dependencies:
  - drupal:node
```

> **Note:** Do not hardcode `php:` unless the module genuinely requires a specific minimum.
> Drupal's `core_version_requirement` already implies PHP compatibility.
> Set `php:` only when the module uses features beyond what core requires.

## Version and Compatibility Rules

| Drupal Version | Plugin Discovery | PHP Minimum | Notes |
|---|---|---|---|
| 10.0 – 10.1 | Annotations (`@Block`) | 8.1 | No attribute support in core |
| 10.2 – 10.3 | Attributes (`#[Block]`) | 8.1–8.2 | Dual syntax period |
| 11.0+ | Attributes only | 8.3 | Annotations deprecated |

Before scaffolding, check the project's `core_version_requirement` to select the right approach.

## Drush Generate Awareness

`drush generate` can scaffold many of these components automatically.

**Prefer manual scaffolding (this skill) when:**
- `drush generate` is not available in the project.
- The generated output requires significant modification.
- The project has custom conventions not covered by generators.
- You need to scaffold multiple related components in one pass.

**Prefer `drush generate` when:**
- It is available and the output matches project conventions.
- The component is standard and doesn't need customization.

## Required Checks

- `*.info.yml` has correct `core_version_requirement` and `type: module`.
- All classes follow PSR-4: `src/` maps to `Drupal\{module_name}\`.
- Services declared in `*.services.yml` resolve without container errors.
- Routes have access requirements defined.
- Config has matching schema in `config/schema/`.
- Module enables cleanly: `drush en my_module -y && drush cr`.
- No duplicate service IDs, route names, or permission keys.
- Event subscriber class names match their subscribed events.

## Error Recovery

If module enablement fails:

1. **Missing dependency:** Check `*.info.yml` dependencies. Ensure required modules are installed.
2. **Service container error:** Check `*.services.yml` for typos in class names, missing arguments, or unresolved service references.
3. **PSR-4 error:** Verify class file path matches namespace exactly.
4. **Config schema mismatch:** Verify config file keys match schema mapping keys.
5. **Route error:** Verify controller/form class references in `*.routing.yml` use full namespace with leading backslash.

Do not retry more than twice without reporting the error and its diagnosis.

## Anti-Patterns

- Putting class files outside `src/` or in wrong PSR-4 namespace.
- Creating `*.module` file with logic that should be a service or plugin.
- Missing `config/schema/` for custom config objects.
- Hardcoding dependencies instead of declaring them in `*.info.yml`.
- Using annotation syntax when project targets Drupal 10.2+.
- Creating services without type-hinted interfaces in arguments.
- Naming event subscriber classes after entities when they subscribe to kernel events.
- Appending to YAML files without checking for existing entries.
- Scaffolding without any test class.

## References

- Read `references/scaffold-templates.md` for complete file templates.
- Read `references/dry-run.md` for a worked scaffolding example.
