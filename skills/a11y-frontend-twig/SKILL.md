---
name: a11y-frontend-twig
description: Build accessibility-first Drupal frontends with semantic Twig, ARIA, and Single Directory Components. Use when editing themes, Twig templates, frontend assets, or SDC components.
---

# Accessibility-First Frontend (A11y & Twig)

## Overview

Deliver inclusive user experiences that meet WCAG 2.1 AA standards. Use semantic HTML and context-aware ARIA patterns as the primary building blocks.

## Workflow

1. Assess the component type.
Determine if this is a page layout, interactive widget, content display, or navigation element.

2. Choose semantic structure.
Use correct landmark elements, heading hierarchy, and native interactive elements before ARIA.

3. Implement keyboard interaction.
Ensure all interactive elements are focusable and operable via keyboard.

4. Add ARIA where native semantics are insufficient.
Use dynamic ARIA attributes that reflect actual component state.

5. Validate.
Run automated a11y checks, test with keyboard navigation, verify with screen reader.

## Semantic HTML First

- Use `<button>` for actions, `<a>` for navigation — never `<div onclick>`.
- Ensure correct landmark structure: `<main>`, `<nav>`, `<header>`, `<footer>`, `<aside>`.
- Use heading hierarchy (`<h1>`–`<h6>`) that reflects content structure, not visual styling.
- Use `<ul>`/`<ol>` for lists, `<table>` for tabular data.
- Provide skip navigation link as first focusable element.

## Context-Aware ARIA

- Use dynamic `aria-expanded`, `aria-hidden`, `aria-pressed` based on current JS state.
- Prioritize native accessible names (`<label>`, `alt`, `<caption>`) over `aria-label`.
- Use `aria-live` regions for dynamic content updates (alerts, status messages, AJAX results).
- Use `aria-describedby` to associate help text with form inputs.
- Use `role="alert"` for error messages that need immediate screen reader announcement.

## Keyboard & Focus Management

- All interactive elements must be reachable via Tab key.
- Implement focus trapping for modals and dialogs.
- Return focus to trigger element when modal closes.
- Provide visible focus indicators (`:focus-visible` CSS) — never `outline: none` without replacement.
- Use `tabindex="0"` for custom interactive elements, `tabindex="-1"` for programmatic focus targets.

## Single Directory Components (SDC)

- Define component in `components/{name}/` with `{name}.component.yml`, `{name}.twig`, and optional CSS/JS.
- Declare all props with types and descriptions in `component.yml` for documentation and validation.
- Keep component templates self-contained — avoid reaching into parent scope.
- Include `aria-*` attributes as component props when accessibility state varies per instance.

## Drupal Cache Integrity

- Ensure Cache Tags, Contexts, and max-age are correctly bubbled in Twig via `{{ attach_library() }}` and render array metadata.
- Use BigPipe placeholders for personalized content inside cached pages to avoid stale a11y states.

## Validation Pipeline

- Every template change must pass the project's a11y checks (axe-core, pa11y, or equivalent).
- Check: contrast ratios (4.5:1 text, 3:1 large text), focus indicators, screen reader announcements.
- Test keyboard navigation flow for new interactive components.
- Verify `alt` text on all informative images; `alt=""` or `aria-hidden="true"` on decorative ones.

## Anti-Patterns

- Using `<div>` with `onClick` instead of native `<button>`.
- Hardcoding static ARIA attributes that don't reflect component state.
- Removing focus outlines without providing visible alternative.
- Skipping a11y validation for "minor" CSS-only changes.
- Using `aria-label` when a visible `<label>` element would suffice.
- Nesting interactive elements (`<a>` inside `<button>` or vice versa).

## References

- Read `references/a11y-checklist.md` for a concrete validation checklist.
- Read `references/dry-run.md` for a worked component accessibility example.
