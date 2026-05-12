---
name: drupal-sdc-workflow
description: Design, create, compose, override, and validate Drupal Single-Directory Components using schema-first contracts, isolated Twig context, and risk-based theming decisions. Use when adding or changing `components/`, `*.component.yml`, SDC Twig composition, or SDC asset/override behavior.
---

# Drupal Single-Directory Components Workflow

## Goal

Create and maintain Drupal SDC components as explicit UI contracts.

Treat each component as a self-contained unit with:

- a predictable data contract in `*.component.yml`
- a stable identifier in `{provider}:{component}` form
- isolated template composition
- colocated assets
- clear override boundaries
- validation targeted at the exact risk introduced by the change

## Activation Triggers

Activate this skill when the task involves any of the following:

- adding or editing files under `components/`
- creating or updating `*.component.yml`, `*.twig`, `*.css`, or `*.js` for an SDC
- replacing legacy template fragments with SDC composition
- deciding between props, slots, `include()`, `embed`, or render-array usage
- overriding an upstream component or its assets
- defining schema, `libraryOverrides`, or `replaces`
- reviewing SDC usage for isolation, reuse, or override safety

If the task is mainly about accessibility semantics or keyboard behavior inside the component, pair this skill with `a11y-frontend-twig`.

## Scope and Status

- Scope: Drupal 10/11 SDC work in themes and modules.
- Status: active
- Bias: theme-first delivery unless the task clearly belongs in a reusable module.
- Excluded: broad design-system governance, Storybook setup, or frontend build tooling unless explicitly requested.

## Source Model

This skill is derived from the Drupal SDC documentation set. Use the connected guidance as one system. 

### AI Retrieval (Context7 MCP)
Preferred method for Agents. Use `/drupal/drupal` library for:
- SDC API and Component Lifecycle
- Props vs Slots usage
- Annotated `component.yml` patterns

### Documentation References
- [Main Guide](https://www.drupal.org/docs/develop/theming-drupal/using-single-directory-components)
- [Props and Slots](https://www.drupal.org/docs/develop/theming-drupal/using-single-directory-components/what-are-props-and-slots-in-drupal-sdc-theming)
- [API Documentation](https://www.drupal.org/docs/develop/theming-drupal/using-single-directory-components/api-for-single-directory-components)

See `references/sdc-risk-map.md` for the condensed source-to-risk mapping and more detailed Retrieval Guidance.

## Core Operating Model

1. Build components as contracts, not loose Twig snippets.
2. Keep structured data in props and free renderable content in slots.
3. Prefer the render element when assembling components from PHP or render arrays.
4. Isolate component calls from ambient Twig context unless there is a deliberate exception.
5. Keep assets and dependencies attached at the component boundary.
6. Use theme overrides only where Drupal actually supports them.

## Decision Tree

Use this before editing:

| If the task is... | Then... | Main risk |
|---|---|---|
| A reusable UI unit with its own markup and assets | Create or update an SDC | Contract drift and duplicated markup |
| A one-off page/template adjustment with no reuse value | Prefer a normal template override | Unnecessary component abstraction |
| Passing typed flags, enums, booleans, counts, URLs, labels | Use props | Unvalidated data contract |
| Passing rich markup, nested render arrays, or child components | Use slots | Escaped markup or over-typed contracts |
| Reusing a component from Twig | Use `include()` or `embed` with isolated context | Hidden coupling to parent variables |
| Rendering a component from PHP/render arrays | Use the SDC render element | Reimplementing template wiring manually |
| Changing upstream component markup | Override the component in a theme | Unsupported module override path |
| Changing upstream component assets only | Use `libraries-override` / `libraries-extend` in the theme | Asset drift or duplicate libraries |

## Retrieval Workflow

Before editing:

1. Find the existing component call sites.
Search for `include('provider:component'` / `embed 'provider:component'` / `#type: component`.

2. Read the local component contract first.
Inspect `*.component.yml` before touching Twig.

3. Inspect asset and override surfaces.
Check colocated `*.css` / `*.js`, `libraryOverrides`, and theme `*.info.yml`.

4. Confirm whether the component lives in a theme or module.
This determines whether override and extension paths are legal.

5. Check whether the change is about structured data or renderable content.
That determines props versus slots.

## Workflow

### Phase 1: Place the Component Correctly

1. Put SDCs under a `components/` directory in a theme or module.
2. Nested subdirectories are allowed when they improve taxonomy, but keep the component itself self-contained in one directory.
3. Use ASCII, stable machine names for component directories and files.
4. The minimum component files are `{name}.component.yml` and `{name}.twig`. Do not use `.html.twig` for the SDC template file itself.
5. Use the component by its API-stable ID: `{provider}:{component}`.
6. Keep component names unique within the provider.

### Phase 2: Define the Contract First

7. Create or update `{name}.component.yml` before changing Twig.
8. Define `props` as JSON-schema-like typed data.
9. Define `slots` only for free renderables or nested content.
10. Declare `required` props when the component cannot render correctly without them.
11. If there are no props, declare empty props explicitly rather than omitting the section.
12. In design-system-oriented themes, prefer `enforce_prop_schemas: true` in the theme `.info.yml` so schema drift fails early.

### Phase 3: Implement Twig with Isolation

13. Write the template so it can render from declared inputs alone.
14. Use `{{ attributes }}` for the wrapper unless there is a clear reason not to.
15. Prefer the `include()` function with `with_context = false` when passing props directly.
16. Use `embed ... only` when the component exposes slots as Twig blocks.
17. For arbitrary HTML, nested markup, or child components, pass content through slots rather than raw string props.
18. Avoid `|raw` in component templates and call sites unless the value is already intentionally trusted and reviewed at the source.

### Phase 4: Attach Assets and Dependencies Deliberately

19. Keep component-local CSS/JS beside the component when the behavior belongs only to that component.
20. Use `libraryOverrides` inside `*.component.yml` for dependencies or extra files at the component boundary.
21. If the task is to change only an upstream component library, use theme-level `libraries-override` or `libraries-extend`.
22. Evaluate whether broad attachment of `core/components.all` is a project performance strategy, not a default reflex.

### Phase 5: Respect Override Boundaries

23. Only themes may override components.
24. Use `replaces` only when deliberately overriding another component.
25. Only schema-defined components can replace or be replaced safely.
26. Modules may provide components, but they cannot override other components.

### Phase 6: Validate the Exact Risk

27. Validate the schema shape and required props.
28. Verify the component renders with isolated context.
29. Verify slot content renders unescaped when intended.
30. Verify assets load exactly once and from the intended source.
31. Clear caches in the project’s normal way before concluding.

## Contract Rules

### Props

- Use props for typed, predictable values such as strings, booleans, integers, arrays, enums, URLs, and labels.
- Keep props serializable and schema-friendly.
- Avoid PHP objects in props. The main documented exception is specific `Attribute`-style escape hatches, but prefer standard schema types whenever possible.

### Slots

- Use slots for HTML, nested components, render arrays, and renderable/stringable objects.
- Use slots when the template should only test emptiness or render provided content, not perform complex data logic.
- Prefer passing child components from the outside through slots rather than hardcoding child component calls deep inside a component template.

## Composition Rules

- `include()` is the default for prop-driven composition.
- Prefer the `include()` function over the `{% include %}` tag.
- `embed ... only` is the default when the component exposes slot blocks.
- `with_context = false` is the safe default to avoid unexpected side effects from parent Twig variables.
- Do not depend on ambient variables that are not part of the component contract.

## Rendering from PHP

When the component is assembled from PHP or a render array, prefer the documented component render element instead of reproducing Twig composition manually.

Why:

- it keeps Drupal aware of the component usage
- it preserves normal render-array features such as `#cache` and `#attached`
- it keeps data shaping in PHP and presentation in the component contract

## Important Drupal Constraints

- A correctly named YAML file is mandatory for an SDC.
- Full schema is not always enforced by Drupal automatically, but schema is still the safer project standard.
- Components without schema cannot participate safely in override/replacement workflows.
- SDC does not support preprocess variables by design.
- `attributes` is added automatically if missing, but other classic theme-manager variables should not be assumed.
- Variants are available only in Drupal 11.2 and newer.
- Some SDC documentation pages are still evolving, so local project rules should prefer explicit safety over relying on undocumented behavior.

## Must / Should / Must Not

### Must

- Define or update `*.component.yml` before expanding a component API.
- Keep props and slots semantically separate.
- Render components from declared inputs rather than parent-template leakage.
- Use theme-level override mechanisms for upstream asset changes.
- Validate the exact data and asset contract changed by the task.

### Should

- Treat schema as mandatory even where Drupal core technically allows looser definitions.
- Prefer `enforce_prop_schemas: true` in themes that act as design-system providers.
- Keep component templates small and declarative.
- Use slots to keep child composition flexible.
- Keep component assets colocated unless they are genuinely global.

### Must Not

- Use modules to override components.
- Push arbitrary HTML strings through props when a slot is the correct interface.
- Depend on preprocess hooks for SDC data shaping.
- Hardcode child components in a way that blocks external composition without a clear reason.
- Rely on implicit parent Twig variables when `with_context = false` would expose the missing contract.
- Introduce `|raw` as a shortcut for getting HTML through a prop.

## Validation Checklist

1. `*.component.yml` exists and matches the component machine name.
2. Required props are declared and exercised by at least one real call site.
3. Slot content renders through `embed` or slot variables, not escaped string props.
4. The component still renders when parent Twig context is removed.
5. Asset attachments and dependencies resolve from the intended library source.
6. No new `|raw` shortcut was introduced where a slot or renderable input would be safer.
7. Cache rebuild completed through the project’s standard command path.
8. If replacement is involved, `replaces` and schema compatibility were both reviewed.

## Anti-Patterns

- Empty or placeholder YAML paired with a large implicit Twig API.
- Using props for rich markup because it is faster than defining a slot.
- Manually attaching duplicate component libraries after rendering the component itself.
- Treating SDC as a generic include folder instead of a typed component contract.
- Reaching for preprocess because the contract was not designed cleanly.
- Treating presenter-template Twig composition as the default when a PHP render element would preserve cache metadata better.

## References

- Read `references/sdc-risk-map.md` for the source-backed rationale.
- Pair with `a11y-frontend-twig` when markup or interaction semantics are part of the change.
