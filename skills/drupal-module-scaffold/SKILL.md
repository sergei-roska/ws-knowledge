---
name: drupal-module-scaffold
description: Scaffold new Drupal 10/11 custom modules, plugins, forms, controllers, services, and event subscribers with correct file structure, naming, and modern PHP patterns. Use when creating a new module from scratch or adding a new component to an existing module.
---

# Drupal Module Scaffold

## Overview

Generate the correct file structure, naming conventions, and boilerplate for new Drupal modules and components.
This skill ensures every new piece of code starts with proper PSR-4 layout, DI patterns, and attribute-based plugin discovery.

## Workflow

1. Determine scope.
   Decide what the module needs: plugin(s), form(s), controller(s), service(s), event subscriber(s), hooks, config, templates.

2. Choose the docroot.
   Detect whether the project uses `docroot/modules/custom/` or `web/modules/custom/`.

3. Generate skeleton files.
   Create minimum required files first, then add components.

4. Wire dependencies.
   Register services in `*.services.yml`, routes in `*.routing.yml`, permissions in `*.permissions.yml`.

5. Validate structure.
   Confirm PSR-4 autoloading, enable module with `drush en`, rebuild cache, verify no errors.

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

## Component Scaffolding

### Block Plugin

```text
src/Plugin/Block/{BlockName}Block.php
```

- Use `#[Block]` attribute (D10.2+).
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

### Service

```text
src/{ServiceName}.php
my_module.services.yml  (add service definition)
```

- Use constructor promotion with readonly typed properties.
- Inject via interface types, not concrete classes.

### Event Subscriber

```text
src/EventSubscriber/{SubscriberName}Subscriber.php
my_module.services.yml  (add tagged service)
```

- Implement `EventSubscriberInterface`.
- Tag: `{ name: event_subscriber }`.

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

## Naming Conventions

- Module machine name: `snake_case`, prefixed with project namespace if applicable.
- Classes: `PascalCase`, suffix matches component type (`Block`, `Form`, `Controller`, `Subscriber`, `Worker`).
- Services: `my_module.service_name` in `services.yml`.
- Routes: `my_module.route_name` in `routing.yml`.
- Permissions: `verb noun` style (`administer my module settings`).
- Config: `my_module.settings` for main config object.
- Templates: `kebab-case.html.twig`, matching theme hook name with underscores replaced by hyphens.

## info.yml Template

```yaml
name: 'My Module'
type: module
description: 'Brief description of module purpose.'
package: Custom
core_version_requirement: ^10.3 || ^11
php: 8.3
dependencies:
  - drupal:node
```

## Required Checks

- `*.info.yml` has correct `core_version_requirement` and `type: module`.
- All classes follow PSR-4: `src/` maps to `Drupal\{module_name}\`.
- Services declared in `*.services.yml` resolve without container errors.
- Routes have access requirements defined.
- Config has matching schema in `config/schema/`.
- Module enables cleanly: `drush en my_module -y && drush cr`.

## Anti-Patterns

- Putting class files outside `src/` or in wrong PSR-4 namespace.
- Creating `*.module` file with logic that should be a service or plugin.
- Missing `config/schema/` for custom config objects.
- Hardcoding dependencies instead of declaring them in `*.info.yml`.
- Using annotation syntax when project targets Drupal 10.3+.
- Creating services without type-hinted interfaces in arguments.

## References

- Read `references/scaffold-templates.md` for complete file templates.
- Read `references/dry-run.md` for a worked scaffolding example.
