---
name: a11y-frontend-twig
description: Build accessibility-first Drupal frontends with semantic Twig, keyboard-safe interactions, ARIA only where needed, and Single Directory Components. Use when editing themes, Twig templates, frontend JS/CSS that affects interaction or focus, or SDC components.
---

# Accessibility-First Frontend (A11y & Twig)

## Goal

Deliver Drupal frontend output that is semantic, keyboard-operable, screen-reader-safe, and cache-safe.

Use native HTML first. Add ARIA only when native semantics do not express the required relationship or state.

## Activation Triggers

Activate this skill when the task involves any of the following:

- editing Drupal theme templates, `*.html.twig`, or SDC component templates
- editing frontend JS or CSS that changes interaction, visibility, focus, or keyboard behavior
- building or fixing menus, accordions, dialogs, tabs, filters, alerts, forms, skip links, or other interactive UI
- reviewing output for keyboard, screen reader, landmark, focus, contrast, or live-region issues
- changing rendered markup in a way that could drop Drupal-provided attributes or accessibility state

If the task is mainly about theme structure, asset registration, template discovery, or build tooling, pair this skill with `drupal-theming-workflow`. This skill governs the accessibility decisions inside that theming work.

## Scope and Status

- Scope: Drupal themes, Twig templates, SDC components, and frontend behavior that affects accessibility.
- Status: active
- Minimum target: WCAG 2.1 AA
- Excluded: PHP-only service design, content authoring policy, or broad design-system governance unless the task explicitly asks for them.

## Task Entry Workflow

Follow this sequence before editing markup or behavior:

1. Identify the surface.
Determine whether the task changes page structure, content display, navigation, a form, or an interactive widget.

2. Retrieve local context first.
Search for the existing component, template, library, and JS behavior before creating or replacing anything.

3. Preserve Drupal attribute surfaces.
Find `attributes`, `title_attributes`, `content_attributes`, `row_attributes`, and similar variables. Do not drop them when restructuring Twig.

4. Map dynamic state and caching.
Determine whether expanded, selected, hidden, error, or personalized state is server-rendered, JS-managed, or placeholder-driven.

5. Choose the simplest accessible pattern.
Prefer native elements and the least complex interaction model that satisfies the task.

6. Implement and validate.
Update markup, state synchronization, focus behavior, and verification together.

## Retrieval Modes

Use these searches before writing code:

1. Structure search.
Find existing templates, overrides, and components for the same surface before creating a new one.

2. Attribute search.
Search for Drupal attribute variables so wrapper attributes, IDs, classes, and `aria-*` state are not lost during a rewrite.

3. Behavior search.
Find existing JS, `once()` handlers, `attach_library()`, and `aria-*` updates before adding new behavior or duplicating state logic.

4. Contract search.
For SDC work, inspect `.component.yml` props before adding new accessibility-related inputs such as labels, IDs, or state flags.

5. Validation search.
Find the project's existing a11y tooling or scripts before inventing a new validation path.

## Pattern Selection

Choose the simplest pattern that matches the task:

| If the UI need is... | Prefer... | Avoid... |
|---|---|---|
| Navigation | `<nav>` with labeled groups and real `<a href>` links | Buttons for navigation or unlabeled multiple nav landmarks |
| An action | Native `<button>` | Clickable `<div>` or `<span>` |
| Expand/collapse | `<button>` with `aria-expanded` and `aria-controls` | Static `aria-expanded` or custom roles without keyboard support |
| Dialog or modal | A complete dialog pattern with focus trap, close behavior, and return focus | Hidden overlay markup with no focus management |
| Status or error update | Visible text plus `aria-live` or `role="alert"` where needed | Silent AJAX updates |
| Tabs, menus, tree views | Full ARIA pattern only if the full keyboard model is implemented | Partial ARIA roles that imply behavior the UI does not provide |

## Semantic HTML First

- Use `<button>` for actions and `<a>` for navigation. Never use clickable generic containers.
- Ensure correct landmark structure: `<main>`, `<nav>`, `<header>`, `<footer>`, `<aside>`.
- Maintain heading hierarchy that reflects document structure, not visual styling.
- Use list and table semantics for actual lists and tabular data.
- Keep a skip link as the first focusable element when changing page shell or top-level navigation.
- Give icon-only controls an accessible name with visible text or appropriate assistive text.

## Twig and SDC Rules

- Preserve Drupal attribute objects by rendering `{{ attributes }}` and related variables instead of rebuilding wrapper markup by hand.
- Do not strip IDs, classes, `data-*`, `aria-*`, or cache-related attributes supplied by render arrays.
- Keep SDC templates self-contained. Pass accessibility state through props instead of reaching into parent scope.
- Declare accessibility-relevant props in `{name}.component.yml` with types and descriptions when state varies per instance.
- Ensure IDs used by `aria-controls`, `aria-labelledby`, `for`, and `describedby` relationships are unique within the rendered instance.
- Use `{{ attach_library() }}` or SDC assets for behavior. Do not add inline `<script>` or `<style>` blocks for accessibility logic.

## Context-Aware ARIA

- Use dynamic `aria-expanded`, `aria-hidden`, `aria-pressed`, `aria-selected`, and similar attributes only when they reflect actual state.
- Prioritize native accessible names such as `<label>`, link text, button text, `alt`, and `<caption>` over `aria-label`.
- Use `aria-live` regions for dynamic content updates such as alerts, status messages, and AJAX results.
- Use `aria-describedby` to associate help text and error text with form inputs.
- Use `role="alert"` only for messages that need immediate announcement.
- Do not apply `aria-hidden="true"` to focusable or interactive elements.
- Do not use `menu`, `menubar`, `tablist`, `tree`, or `grid` roles unless the full keyboard interaction model is implemented.

## Keyboard & Focus Management

- All interactive elements must be reachable via Tab key.
- Tab order must follow the visual and logical reading order.
- Implement focus trapping for modals and dialogs.
- Return focus to the trigger element when a modal or overlay closes.
- Provide visible focus indicators with `:focus-visible`. Never remove outlines without a clear replacement.
- Use `tabindex="0"` only when no native control can represent the interaction.
- Use `tabindex="-1"` only for programmatic focus targets.
- Support keyboard activation and dismissal patterns that match the widget type, including Escape where appropriate.

## Cache and Dynamic State

- Do not bake user-specific or session-specific accessibility state into shared cached markup.
- For personalized or late-loaded fragments, use BigPipe, placeholders, or client-side enhancement so the announced state matches the actual user state.
- Ensure lazy-loaded or AJAX content updates preserve focus and announce meaningful changes.
- Keep render-array metadata and library attachments intact so accessibility-related state is not lost during caching.

## Must / Should / Must Not Rules

### Must

- Preserve existing Drupal attribute surfaces unless there is a specific reason to change them.
- Use native semantics before ARIA roles.
- Keep dynamic `aria-*` state synchronized with real JS or server state.
- Validate keyboard flow for every new or changed interactive element.
- Verify accessible names for controls, links, form fields, images, and landmarks.

### Should

- Reuse existing project markup and behavior patterns instead of inventing a second widget model.
- Prefer visible labels or screen-reader-only helper text over relying on `aria-label` alone.
- Keep assistive text translatable when it is rendered in Twig.
- Treat CSS-only changes as potentially accessibility-relevant if they affect contrast, focus, visibility, or reading order.

### Must Not

- Use `<div onclick>` or similar generic containers as interactive controls.
- Hardcode static ARIA attributes that can drift from the real component state.
- Remove focus outlines without a visible replacement.
- Nest interactive elements inside each other.
- Ship pointer-only or hover-only interaction without a keyboard path.
- Introduce duplicate IDs that break `aria-*` relationships.
- Drop Drupal attribute variables during template rewrites.

## Validation Pipeline

1. Run the project's a11y tool if one exists (`axe-core`, `pa11y`, or equivalent).
2. Test keyboard navigation for the changed flow, including open, close, submit, and escape paths where relevant.
3. Verify focus indicators, visible labels, contrast, and reading order.
4. Verify `alt` text on informative images and empty `alt=""` on decorative ones.
5. Smoke-test screen reader behavior for new widgets if a screen reader is available. If not, inspect roles, names, and states in browser accessibility tooling and report that limitation.
6. For structural Twig or SDC changes, follow the project's cache rebuild or theme build process before final verification.

## Memory Integration

### Must Persist

- A project-wide accessibility invariant such as skip-link policy, focus-ring policy, or landmark convention.
- The rationale for using a custom widget pattern when native HTML was insufficient.
- A cache or BigPipe decision required to keep accessibility state truthful.
- An accessibility incident where a template override dropped attributes, broke keyboard flow, or caused stale announced state.

### Should Persist

- A reusable focus-management contract adopted across multiple components.
- A naming convention for assistive text or accessibility-related component props.
- A decision to simplify a design because the richer interaction was not accessible enough.

### Must Not Persist

- Routine alt-text, label, or attribute fixes that are obvious from the code.
- Ordinary `aria-*` wiring with no architectural significance.
- Raw Twig diffs or CSS changes that are already captured in git.

## Anti-Patterns

- Using `<div>` with `onclick` instead of native `<button>`.
- Hardcoding static ARIA attributes that do not reflect component state.
- Removing focus outlines without providing a visible alternative.
- Skipping accessibility validation for "minor" CSS-only changes.
- Using `aria-label` when visible text or a real `<label>` would suffice.
- Nesting interactive elements such as `<a>` inside `<button>`.
- Adding ARIA widget roles without the matching keyboard behavior.
- Rebuilding Twig wrapper markup and accidentally dropping Drupal attributes.

## References

- Read `references/a11y-checklist.md` for a concrete validation checklist.
- Read `references/dry-run.md` for a worked component accessibility example.
