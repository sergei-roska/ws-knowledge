---
name: drupal-api-patterns
description: Apply correct Drupal 10/11 API patterns for hooks, Form API, Entity API, Render arrays, Routing, Events, Plugin system, Services, and Queue API. Use when writing or reviewing any Drupal PHP code that interacts with core subsystems.
---

# Drupal API Patterns

## Overview

Select the correct Drupal API surface for each task and implement it using modern, type-safe patterns.
This skill prevents common API misuse: wrong hook signatures, broken render caching, unsafe entity access, and legacy patterns that bypass DI.

## Decision: Which API Surface?

Before writing code, classify the task:

- **React to data changes** → Entity hooks (`hook_entity_presave`, `hook_entity_insert`) or Event subscribers for decoupled logic.
- **Alter existing behavior** → Alter hooks (`hook_form_alter`, `hook_views_query_alter`) with narrow targeting.
- **Build a page or response** → Controller + routing.yml.
- **Collect user input** → Form API (`FormBase`, `ConfigFormBase`, `ConfirmFormBase`).
- **Extend a system with variants** → Plugin API (Block, Field, Action, QueueWorker, Constraint).
- **Render structured output** → Render arrays with correct cache metadata.
- **Run background work** → Queue API (`QueueWorkerBase`).
- **Cross-cutting concerns** → Service + Event subscriber, not hooks in `.module`.

## Core Patterns

### 1. Hooks

- Keep `.module` hooks thin: validate arguments, delegate to an injected service.
- Always match exact hook signature from `*.api.php`; verify with Context7 or core source when unsure.
- Prefer `hook_entity_*` over `hook_node_*` unless node-specific behavior is required.
- Transition plan: hooks that contain business logic should migrate to event subscribers when Drupal 11 hook events are available.

### 2. Form API

- Extend `FormBase` for custom forms, `ConfigFormBase` for admin settings, `ConfirmFormBase` for destructive actions.
- Inject services via `create()` + `ContainerInterface`, never `\Drupal::service()`.
- Validate in `validateForm()`, act in `submitForm()` — never mix.
- Return `$form` array from `buildForm()`; do not render HTML strings.

### 3. Entity API

- Use `EntityTypeManagerInterface` for storage and access, not static `Node::load()`.
- Use entity query (`\Drupal::entityQuery` or injected `QueryFactory`) with explicit `accessCheck(TRUE|FALSE)`.
- Always declare `accessCheck()` — omitting it triggers deprecation in D10 and error in D11.
- For field access: `$entity->get('field_name')->value` for scalars, `->entity` for references.
- Prefer `EntityViewBuilder` and view modes over manual field rendering.

### 4. Render Arrays

- Every render array that varies by context must carry `#cache` metadata: `tags`, `contexts`, `max-age`.
- Bubble cache metadata from child elements — never strip or flatten.
- Use `#lazy_builder` for personalized or uncacheable fragments inside otherwise cacheable pages.
- Prefer `#theme` with a Twig template over inline `#markup` for anything beyond trivial output.

### 5. Routing

- Define routes in `*.routing.yml` with typed parameters and `_access_check` or `_permission`.
- Controller methods return a render array or `Response`/`JsonResponse`, not printed output.
- Use `_entity_access` requirement for entity routes instead of custom access logic.
- Parameter upcasting: use `{node}` (not `{nid}`) to get automatic entity loading.

### 6. Event System

- Implement `EventSubscriberInterface` with `getSubscribedEvents()` returning event class constants.
- Register as tagged service: `tags: [{ name: event_subscriber }]`.
- Prefer events over hooks for logic that: crosses module boundaries, requires priority ordering, or needs testable isolation.
- Drupal 11: hook-based events (`Hook` attribute) — use when the project targets D11+.

### 7. Plugin API

- Use PHP attributes (`#[Block(...)]`, `#[Action(...)]`) for Drupal 10.3+/11.
- Fall back to annotations only if project requires Drupal < 10.3 compatibility.
- Plugin classes live in `src/Plugin/{Type}/` following PSR-4.
- Inject services via `ContainerFactoryPluginInterface` + `create()`.

### 8. Services & DI

- Define in `*.services.yml` with explicit class, typed arguments.
- Use constructor injection with promoted properties.
- Use service decoration to alter core services instead of monkey-patching.
- Tag services for collector patterns (e.g., `event_subscriber`, `breadcrumb_builder`).

### 9. Queue API

- Extend `QueueWorkerBase` with `#[QueueWorker(...)]` attribute.
- Implement `processItem($data)` with idempotent logic.
- Handle failures gracefully — throw `RequeueException` for retryable, `SuspendQueueException` for systemic issues.

## Verification Checklist

- [ ] Hook signatures match core `*.api.php` definitions exactly.
- [ ] Forms use DI, not `\Drupal::` static calls.
- [ ] Entity queries include explicit `accessCheck()`.
- [ ] Render arrays carry appropriate `#cache` metadata.
- [ ] Routes have access requirements defined.
- [ ] Event subscribers are registered as tagged services.
- [ ] No business logic lives directly in `.module` files.

## Anti-Patterns

- Using `\Drupal::service()` or `\Drupal::entityTypeManager()` inside classes that can use DI.
- Rendering entities manually instead of using view modes and `EntityViewBuilder`.
- Omitting `#cache` metadata on render arrays that vary by user, route, or query.
- Writing form logic in `buildForm()` instead of `submitForm()`.
- Using `db_query()` / `Database::getConnection()->query()` for entity data instead of Entity API.
- Hardcoding permissions in access callbacks instead of using route-level `_permission`.

## References

- Read `references/drupal-api-quick-ref.md` for condensed patterns with code shapes.
- Read `references/dry-run.md` for a worked example applying multiple API surfaces.
