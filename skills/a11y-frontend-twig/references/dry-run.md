# Dry Run: Accessibility-First Frontend

## Example Task

Add an accessible accordion component to a Drupal theme using SDC.

## Applied Workflow

1. Component type: interactive widget (expandable sections).
2. Semantic structure: use `<button>` as trigger inside heading, `<div>` as panel.
3. Keyboard: Enter/Space toggles panel, focus stays on trigger.
4. ARIA: `aria-expanded` on button, `aria-controls` pointing to panel `id`, `aria-hidden` on collapsed panel.
5. Validate: axe-core scan, keyboard walkthrough, NVDA screen reader test.

## Implementation

- `components/accordion/accordion.component.yml` — props: items (array), heading_level (int).
- `components/accordion/accordion.twig` — semantic markup with dynamic ARIA.
- `components/accordion/accordion.js` — toggle logic updating `aria-expanded` and `aria-hidden`.
- `components/accordion/accordion.css` — visible focus ring, smooth transition.

## Key A11y Decisions

- Trigger is `<button>` inside `<h3>` — proper semantics for both structure and interaction.
- Panel has `role="region"` with `aria-labelledby` pointing to button `id`.
- Collapsed panels use `aria-hidden="true"` + `display: none` (both visual and screen reader hidden).
- Focus indicator uses `:focus-visible` with 3px solid outline for keyboard users only.

## Verification

- axe-core: 0 violations on page with accordion.
- Keyboard: Tab reaches each trigger, Enter/Space toggles, panel content is focusable when open.
- NVDA: announces "collapsed/expanded" state on each button.
- Contrast: all text meets 4.5:1 ratio.
