---
name: a11y-frontend-twig
description: Build accessibility-first Drupal frontends with semantic Twig, Drupal attribute preservation, SDC a11y props, and cache-safe interactive state. Use when editing themes, Twig templates, frontend JS/CSS affecting interaction or focus, or SDC components.
---

# Accessibility-First Frontend (A11y & Twig)

## Goal

Deliver Drupal frontend output that is semantic, keyboard-operable, screen-reader-safe, and cache-safe without dropping Drupal-provided attribute objects or caching personalized state.

## Activation Triggers

Activate when editing:
- Drupal theme templates (`*.html.twig`) or SDC component templates
- Frontend JS/CSS affecting interaction, visibility, focus, or keyboard behavior
- Menus, accordions, dialogs, tabs, filters, alerts, skip links, or interactive widgets
- Rendered markup where Drupal-provided attributes or accessibility state might be dropped

---

## 1. Drupal Attribute Surfaces (CRITICAL)

- **Preserve Drupal attributes:** Always render `{{ attributes }}`, `{{ title_attributes }}`, `{{ content_attributes }}`, and `{{ row_attributes }}` in Twig templates.
- **Do not strip attributes:** Never rebuild wrapper markup by hand without rendering `{{ attributes }}`. Stripping them breaks contextual links, module-added `aria-*` attributes, classes, and cache tags.
- **Attribute modification:** Use Twig attribute methods (`attributes.addClass()`, `attributes.setAttribute()`) instead of raw HTML string concatenation.

---

## 2. Single Directory Components (SDC) A11y Contracts

- **Self-contained components:** Pass accessibility state into SDC templates via props instead of reaching into parent scope.
- **Prop declaration:** Declare a11y props in `{name}.component.yml` with explicit types (e.g., `aria_expanded: { type: boolean }`, `label: { type: string }`).
- **Unique IDs:** Ensure IDs generated for `aria-controls`, `aria-labelledby`, `for`, and `aria-describedby` are unique per rendered component instance.
- **No inline scripts:** Attach behavior via `{{ attach_library('theme/lib') }}` or auto-attached SDC JS assets. Never insert inline `<script>` blocks.

---

## 3. Cache & Dynamic State Safety

- **Shared cache isolation:** Do not bake session-specific or user-specific accessibility state (`aria-expanded`, `aria-selected`, personalized labels) into shared cached markup.
- **Late-loaded fragments:** Use BigPipe or client-side JS enhancement (`core/once`) for late-loaded/personalized states so announced ARIA states match actual user state.
- **AJAX & Live updates:** Use `aria-live` regions (`polite` / `assertive`) for dynamic updates. Ensure AJAX updates preserve keyboard focus or move focus to the updated container.

---

## 4. Interaction & Focus Management

- **Visible focus:** Never remove focus outlines without a visible `:focus-visible` replacement.
- **Modal focus trapping:** Dialogs and overlays MUST trap focus while open and return focus to the triggering element upon closure (handling Escape key).
- **Control semantics:** Use native `<button>` for actions and real `<a>` for navigation. Do not use `<div onclick>`.
- **Keyboard navigation:** All interactive widgets must be operable via keyboard (Tab, Enter, Space, Arrows, Escape).

---

## 5. Verification Checklist

Before finalizing Twig or SDC changes:
- [ ] `{{ attributes }}` is rendered on wrapper markup.
- [ ] No inline `<script>` or `<style>` tags added.
- [ ] Keyboard navigation and `:focus-visible` states verified.
- [ ] SDC `.component.yml` declares a11y props with schema types.
- [ ] Dynamic `aria-*` states are synchronized with JS state and safe for caching.
- [ ] Project build/cache rebuild completed: `drush cr`.
