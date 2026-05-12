---
name: drupal-theming-workflow
description: Build and maintain Drupal 10/11 themes with Single Directory Components, libraries.yml, preprocess hooks, breakpoints, responsive images, and Twig debugging. Use when creating or editing themes, templates, asset pipelines, or responsive layouts.
---

# Drupal Theming Workflow

## Goal

Create and modify Drupal themes following modern patterns: Single Directory Components (SDC), structured asset libraries, minimal preprocess hooks, and responsive image strategies.

All theming work must preserve component isolation, follow Drupal's asset pipeline, and produce accessible, cache-safe output.

## Workflow — Decision Tree

Before writing any code, determine the task type:

| If the task is…                           | Then…                                           |
|-------------------------------------------|-------------------------------------------------|
| A new reusable UI element with props      | Create an **SDC component**                     |
| A layout or markup change to existing output | Create a **template override**                |
| Adding CSS/JS to an existing element      | Add or extend a **library**                     |
| Passing data that Twig can't compute      | Add a **preprocess hook**                       |
| Changing image rendering per breakpoint   | Configure **responsive image styles**           |
| Overriding base theme behavior            | Use `libraries-override` / `libraries-extend`   |

## Workflow — Phased Steps

### Phase 1: Scope

1. Identify the target theme (base or sub-theme). Never edit a base theme directly unless it is project-owned.
2. Check whether an existing component, template, or library already covers the need. Search `components/`, `templates/`, and `*.libraries.yml`.
3. Determine file placement using the theme file structure below.

### Phase 2: Implement

4. Create or modify the files according to the task type from the decision tree.
5. Register assets in `*.libraries.yml` (for non-SDC assets). SDC assets are auto-discovered.
6. Keep preprocess hooks thin — prepare variables, do not build markup. Delegate complex logic to services.

### Phase 3: Build & Validate

7. Detect and run the project's asset pipeline (see Asset Pipeline Detection below).
8. Clear Drupal cache: `drush cr`.
9. Execute the validation checklist.

## Theme File Structure

```text
my_theme/
├── components/                    # SDC components (D10.1+)
│   └── card/
│       ├── card.component.yml
│       ├── card.twig
│       ├── card.css
│       └── card.js
├── css/                           # Compiled global CSS
├── js/                            # Compiled global JS
├── templates/                     # Twig template overrides
│   ├── layout/
│   ├── node/
│   ├── paragraph/
│   ├── field/
│   └── block/
├── my_theme.info.yml
├── my_theme.libraries.yml
├── my_theme.theme                 # Preprocess hooks
├── my_theme.breakpoints.yml
└── config/
    └── install/                   # Default theme settings
```

## Single Directory Components (SDC)

- Each component lives in `components/{name}/` as a self-contained unit.
- `{name}.component.yml` defines metadata, props (with JSON Schema types), and slots.
- `{name}.twig` is the template — always use `{{ attributes }}` for Drupal attribute integration.
- CSS/JS files in the same directory are auto-discovered and attached.
- Use components via `{{ include('my_theme:card', { title: node.label }) }}`.
- Use `{% embed %}` when the component defines `slots`.
- Props are validated — define `required` and property `type` in `component.yml`.

```yaml
# card.component.yml
name: Card
status: stable
props:
  type: object
  required:
    - title
  properties:
    title:
      type: string
      title: Card title
    image_url:
      type: string
      title: Image URL
    link_url:
      type: string
      title: Link URL
slots:
  content:
    title: Card content
```

### SDC Accessibility Baseline

- All interactive elements must have keyboard support.
- Images require `alt` text (prop or slot).
- Use ARIA attributes for dynamic state (`aria-expanded`, `aria-hidden`).
- Use semantic HTML elements (`<nav>`, `<article>`, `<section>`, `<button>`).

## Libraries (*.libraries.yml)

```yaml
global:
  version: VERSION
  css:
    theme:
      css/style.css: {}
  js:
    js/script.js: {}
  dependencies:
    - core/drupal
    - core/once

accordion:
  css:
    component:
      css/components/accordion.css: {}
  js:
    js/components/accordion.js: {}
  dependencies:
    - core/drupal
    - core/once
```

- Attach in Twig: `{{ attach_library('my_theme/accordion') }}`.
- Attach in preprocess: `$variables['#attached']['library'][] = 'my_theme/accordion';`.
- Use `dependencies` to declare JS API requirements (e.g., `core/once`, `core/drupal`).
- CSS categories control render order: `base` → `layout` → `component` → `state` → `theme`.

### Library Override vs. Extend (Sub-Themes)

| Goal | Mechanism | Location |
|------|-----------|----------|
| Remove a base library entirely | `libraries-override: {lib}: false` | `my_theme.info.yml` |
| Replace a CSS/JS file | `libraries-override` with replacement path | `my_theme.info.yml` |
| Add CSS/JS to a base library | `libraries-extend` | `my_theme.info.yml` |

## Preprocess Hooks

- Keep hooks thin — prepare variables, don't build markup.
- Delegate complex logic to services via dependency injection.
- Common hooks: `hook_preprocess_node()`, `hook_preprocess_paragraph()`, `hook_preprocess_page()`.

```php
function my_theme_preprocess_node(&$variables): void {
  $node = $variables['node'];
  if ($node->bundle() === 'article') {
    $variables['has_image'] = !$node->get('field_image')->isEmpty();
  }
}
```

## Template Overrides

### Discovery Procedure

1. Enable Twig debugging (see below).
2. Clear cache: `drush cr`.
3. Inspect HTML source — template suggestions appear as `<!-- FILE NAME SUGGESTIONS -->`.
4. Copy the desired suggestion and create the file in `templates/{type}/`.
5. Naming pattern: `node--article.html.twig`, `paragraph--hero.html.twig`, `field--field-name.html.twig`.

### Rules

- Use `{% extends %}` for layout inheritance, `{% block %}` for overridable regions.
- Always check the parent template in `core/modules/` or the base theme before overriding.
- After a Drupal core update, audit overridden templates for upstream changes.

## Breakpoints

```yaml
# my_theme.breakpoints.yml
my_theme.mobile:
  label: Mobile
  mediaQuery: '(max-width: 767px)'
  weight: 0
  multipliers:
    - 1x
    - 2x
my_theme.tablet:
  label: Tablet
  mediaQuery: '(min-width: 768px) and (max-width: 1023px)'
  weight: 1
  multipliers:
    - 1x
    - 2x
my_theme.desktop:
  label: Desktop
  mediaQuery: '(min-width: 1024px)'
  weight: 2
  multipliers:
    - 1x
    - 2x
```

- Breakpoint values in CSS must match `breakpoints.yml` definitions.
- After editing `breakpoints.yml`, clear cache and verify responsive image mappings.

## Responsive Images

- Define image styles for each breakpoint in admin UI or config YAML.
- Create responsive image style mapping breakpoints to image styles.
- Use `responsive_image` formatter on image fields.
- Generates `<picture>` element with `<source>` per breakpoint.

## Twig Debugging

Enable in `sites/development.services.yml`:

```yaml
parameters:
  twig.config:
    debug: true
    auto_reload: true
    cache: false
```

Useful functions:

- `{{ dump(variable) }}` — inspect variable content.
- `{{ kint(variable) }}` — structured debug output (requires Devel + Kint).
- Template suggestions appear as `<!-- FILE NAME SUGGESTIONS -->` in HTML source.

## Asset Pipeline Detection

Before compiling, detect the project's build tool:

| Look for…         | Then run…                    |
|-------------------|------------------------------|
| `gulpfile.js`     | `gulp build` (or `lando gulp build`) |
| `webpack.config.js` | `npm run build`             |
| `vite.config.js`  | `npm run build`              |
| `package.json` only | Check `scripts` section for the build command |
| None of the above | No compilation needed — raw CSS/JS |

Always run the build command before committing.

## Cache Protocol

| After…                          | Run…       |
|---------------------------------|------------|
| Adding/editing a template       | `drush cr` |
| Adding/editing `*.libraries.yml` | `drush cr` |
| Adding/editing `breakpoints.yml` | `drush cr` |
| Adding/editing an SDC component | `drush cr` |
| CSS/JS content change only      | Hard-refresh browser (Ctrl+Shift+R) |
| Adding/editing `*.info.yml`     | `drush cr` |

Always clear cache before testing after structural changes.

## Validation Checklist

Execute after completing any theming task:

- [ ] All CSS/JS is registered in `*.libraries.yml` or auto-discovered via SDC. No inline `<style>` or `<script>`.
- [ ] Template overrides follow correct Drupal naming convention.
- [ ] SDC components have valid `component.yml` with typed props and `required` fields.
- [ ] Breakpoints in CSS match `breakpoints.yml` definitions.
- [ ] Assets are compiled with the project's build tool.
- [ ] Cache is cleared (`drush cr`).
- [ ] Output renders correctly at mobile, tablet, and desktop widths.
- [ ] Interactive elements have keyboard support and ARIA attributes.
- [ ] Empty fields and missing images are handled gracefully in Twig (use `{% if %}` guards).

## Anti-Patterns

- Inline CSS/JS in templates instead of using libraries.
- Complex logic in `.theme` preprocess hooks instead of services.
- Hardcoding breakpoint values in CSS instead of using `breakpoints.yml`.
- Overriding core templates without checking for upstream changes on update.
- Forgetting to compile assets before committing.
- Putting per-component CSS/JS in global library instead of SDC or targeted library.
- Editing a base theme directly when a sub-theme override is appropriate.
- Creating an SDC component for a one-off template that will never be reused.
- Skipping `drush cr` after structural changes and assuming the old cache is fine.

## References

- Read `references/theming-patterns.md` for SDC and library templates.
- Read `references/dry-run.md` for a worked theming example.
