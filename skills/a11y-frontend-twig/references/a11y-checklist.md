# Accessibility Checklist for Drupal Themes

## Structure
- [ ] Page has exactly one `<main>` landmark.
- [ ] `<nav>` elements have unique `aria-label` when multiple navs exist.
- [ ] Heading hierarchy is sequential (no skipped levels).
- [ ] Skip navigation link is the first focusable element.
- [ ] Language attribute is set on `<html>` element.

## Interactive Elements
- [ ] All buttons use `<button>` or `<input type="submit">`.
- [ ] All links use `<a href>` with descriptive text (no "click here").
- [ ] Form inputs have associated `<label>` elements (not just `placeholder`).
- [ ] Required fields are marked with `aria-required="true"` and visible indicator.
- [ ] Error messages reference the invalid field via `aria-describedby`.

## Keyboard
- [ ] All interactive elements are reachable via Tab.
- [ ] Tab order follows visual reading order.
- [ ] Modals trap focus and return it on close.
- [ ] Dropdown menus support Arrow key navigation.
- [ ] Escape key closes overlays/modals.
- [ ] Focus indicator is visible on all focusable elements.

## Images & Media
- [ ] Informative images have descriptive `alt` text.
- [ ] Decorative images have `alt=""` or `aria-hidden="true"`.
- [ ] SVG icons have `role="img"` with `aria-label` or `<title>`.
- [ ] Videos have captions or transcripts.

## Dynamic Content
- [ ] Status messages use `aria-live="polite"`.
- [ ] Error alerts use `role="alert"` or `aria-live="assertive"`.
- [ ] AJAX-loaded content announces itself to screen readers.
- [ ] `aria-expanded` toggles reflect actual open/close state.
- [ ] `aria-hidden` is synchronized with visual visibility.

## Color & Contrast
- [ ] Normal text has minimum 4.5:1 contrast ratio.
- [ ] Large text (18px+ bold or 24px+) has minimum 3:1 contrast ratio.
- [ ] Information is not conveyed by color alone.
- [ ] Focus indicators have sufficient contrast against background.

## Drupal-Specific
- [ ] Cache metadata is not stripping a11y-relevant dynamic attributes.
- [ ] BigPipe placeholders preserve accessible states during lazy load.
- [ ] SDC component props include a11y attributes where state varies.
- [ ] `{{ attach_library() }}` is used (not inline `<style>/<script>`).
