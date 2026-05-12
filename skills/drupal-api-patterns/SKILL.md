---
name: drupal-api-patterns
description: Apply correct Drupal 10/11 API patterns for hooks, Form API, Entity API, Render arrays, Routing, Events, Plugin system, Services, and Queue API. Use when planning, writing, or reviewing any Drupal PHP code that interacts with core subsystems.
---

# Drupal API Patterns

## 1. Intent & Scope (Triggers)
Activate this skill whenever you are tasked with creating, altering, or reviewing code interacting with Drupal Core subsystems, including:
- Data changes (Entities)
- Business logic overrides (Hooks/Events)
- Output delivery (Controllers/Render Arrays)
- User input (Forms)
- Background processing (Queue)
- Extension mechanisms (Plugins, Services)

## 2. Decision Matrix: Which API Surface?
Before writing any implementation, map the task to the correct API surface.
**MUST-Do Check:**
- **React to data changes** → Entity hooks (`hook_entity_presave`, `hook_entity_insert`) or Event subscribers for decoupled logic.
- **Alter existing behavior** → Alter hooks (`hook_form_alter`, `hook_views_query_alter`) with narrow targeting.
- **Build a page or response** → Controller + routing.yml.
- **Collect user input** → Form API (`FormBase`, `ConfigFormBase`, `ConfirmFormBase`).
- **Extend a system with variants** → Plugin API (Block, Field, Action, QueueWorker, Constraint).
- **Render structured output** → Render arrays with `#cache` metadata.
- **Run background work** → Queue API (`QueueWorkerBase`).
- **Cross-cutting concerns** → Service + Event subscriber, not hooks in `.module`.

## 3. Retrieval & Context Gathering (Before Execution)
Before generating new code, the agent MUST understand the existing project context.
- **Codebase Search**: Use codebase search tools to find existing implementations of the target API in the current real-world codebase (e.g., search for `extends FormBase`, `implements EventSubscriberInterface`).
- **Dependencies**: Identify existing custom modules where the new code belongs, or verify if a new module needs scaffolding.

## 4. Execution Rules (Write Gates)

### A. Dependency Injection (DI) & Services
- **MUST**: Inject services using `ContainerInterface` + `create()` for Classes/Plugins/Forms/Controllers, or via constructor for standard Services.
- **MUST NOT**: Use static calls like `\Drupal::service()`, `\Drupal::entityTypeManager()` inside classes that support DI.
- **SHOULD**: Define services in `*.services.yml` with explicit class mapping and typed arguments. Tag collector patterns when required.

### B. Entity API & Operations
- **MUST**: Use `EntityTypeManagerInterface` for storage loading (`getStorage()`).
- **MUST NOT**: Use static `$entity::load()` or bypass the Entity API with raw `db_query()` / SQL.
- **MUST**: Always append `->accessCheck(TRUE|FALSE)` to entity queries. Omitting this triggers deprecations/errors in D10/11.
- **SHOULD**: Utilize view modes and `EntityViewBuilder` instead of extracting and manually formatting `$entity->get('field')->value` for templating.

### C. Forms & Verification
- **MUST**: Create Forms by extending `FormBase`, `ConfigFormBase`, or `ConfirmFormBase`.
- **MUST NEVER**: Mix validation and submission logic. Validate in `validateForm()`, persist in `submitForm()`.
- **MUST**: `buildForm()` must only return the `$form` array structure. Do not render HTML strings statically within it.

### D. Render Arrays & Output
- **MUST**: Carry `#cache` metadata (`tags`, `contexts`, `max-age`) for every render array varying by context.
- **MUST NEVER**: Strip or flatten `#cache` bubbles from child elements.
- **SHOULD**: Use `#lazy_builder` for personalized blocks inside cache-able pages.
- **SHOULD**: Define output with `#theme` pointing to Twig templates over inline `#markup` for anything non-trivial.

### E. Hooks vs. Events
- **MUST**: Match core `*.api.php` hook signatures perfectly. Keep hooks tiny and delegate complex logic to injected services.
- **SHOULD**: Prefer Event Subscribers over hooks when logic spans modules, needs strict priority ordering, or needs isolated testability.
- **FUTURE (D11+)**: Use event Hook Attributes (if targeting Drupal 11+).

### F. Routing & Access
- **MUST**: Include `_access_check: 'TRUE'` (or false) and specific `_permission` or `_entity_access` for every route.
- **MUST NOT**: Print output directly from a Controller. Return a render array or `Response`/`JsonResponse`.
- **SHOULD**: Upcast path parameters accurately (e.g., `{node}` in `*.routing.yml` paths).

### G. Plugin API & Queues
- **MUST**: Use PHP 8 Attributes (`#[Block(...)]`, `#[Action(...)]`) for Drupal 10.3/11 Plugins.
- **MUST**: Only drop to Annotations if supporting historical versions (< 10.3).
- **SHOULD**: Process Queue items idempotently. Throw `RequeueException` (retry) or `SuspendQueueException` (halt) for failures.

## 5. Agent Verification Checklist
Before finishing the task, the agent MUST verify:
- [ ] Has Dependency Injection been used consistently instead of static `\Drupal::` calls?
- [ ] Are parameter types strict and signatures aligned with Core APIs?
- [ ] Did I explicitly define access checks (`accessCheck()`) on entity queries and routing definitions?
- [ ] Is my render caching logic resilient and carrying required metadata?
- [ ] Have I cleanly separated Form validation from Form submission?
- [ ] Does no unencapsulated business logic float aimlessly in `.module` hooks?

## 6. References
- Find concrete code shapes in `references/drupal-api-quick-ref.md`.
- Read `references/dry-run.md` for a worked example applying multiple API surfaces.
