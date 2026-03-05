---
name: drupal-theming-workflow
description: Build and maintain Drupal 10/11 themes with Single Directory Components, libraries.yml, preprocess hooks, breakpoints, responsive images, and Twig debugging. Use when creating or editing themes, templates, asset pipelines, or responsive layouts.
---

# Drupal Theming Workflow

## Overview

Develop Drupal themes using modern patterns: Single Directory Components (SDC), structured asset libraries, minimal preprocess hooks, and responsive image strategies.

## Workflow

1. Determine the component or template scope.
Identify whether this is a new SDC component, a template override, an asset addition, or a layout change.

2. Follow the theme file structure.
Place files in the correct directories following Drupal conventions.

3. Register assets and templates.
Use `*.libraries.yml` for CSS/JS, `hook_theme()` for custom templates, SDC `component.yml` for components.

4. Build and validate.
Compile assets, clear cache, test across breakpoints.

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
- `{name}.component.yml` defines metadata, props (with types), and slots.
- `{name}.twig` is the template — use `{{ attributes }}` for Drupal integration.
- CSS/JS files in the same directory are auto-discovered and attached.
- Use components via `{{ include('my_theme:card', { title: node.label }) }}`.
- Props are validated — define `schema` in `component.yml` for type checking.

```yaml

# card.component.yml

name: Card
status: stable
props:
  type: object
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

## Preprocess Hooks

- Keep preprocess hooks thin — prepare variables, don't build markup.
- Delegate complex logic to services.
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

- Follow Drupal naming: `node--article.html.twig`, `paragraph--hero.html.twig`.
- Use `{% extends %}` for layout inheritance, `{% block %}` for overridable regions.
- Enable Twig debugging: set `twig.config.debug: true` in `development.services.yml`.
- Template suggestions appear as HTML comments when debugging is enabled.

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

## Responsive Images

- Define image styles for each breakpoint in admin UI or config.
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

Useful Twig functions:

- `{{ dump(variable) }}` — inspect variable content.
- `{{ kint(variable) }}` — structured debug output (requires Devel + Kint).
- Template suggestions appear as `<!-- FILE NAME SUGGESTIONS -->` in HTML source.

## Required Checks

- All CSS/JS goes through `*.libraries.yml`, never inline `<style>`/`<script>`.
- Template overrides follow correct naming convention for suggestions.
- SDC components have valid `component.yml` with typed props.
- Breakpoints file matches CSS media queries.
- Assets are compiled before commit (`gulp build` or `npm run build`).
- Cache is cleared after template/library changes (`drush cr`).

## Anti-Patterns

- Inline CSS/JS in templates instead of using libraries.
- Complex logic in `.theme` preprocess hooks instead of services.
- Hardcoding breakpoint values in CSS instead of using `breakpoints.yml`.
- Overriding core templates without checking for upstream changes on update.
- Forgetting to compile assets before committing.
- Putting per-component CSS/JS in global library instead of SDC or targeted library.

## References

- Read `references/theming-patterns.md` for SDC and library templates.
- Read `references/dry-run.md` for a worked theming example.
