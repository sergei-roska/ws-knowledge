# Theming Patterns Quick Reference

## SDC component.yml — Full Schema

```yaml
name: Component Name
status: stable  # stable | experimental | deprecated
description: Brief description of the component.
props:
  type: object
  required:
    - title
  properties:
    title:
      type: string
      title: Title
      description: The main heading text.
    variant:
      type: string
      title: Variant
      enum:
        - default
        - highlight
        - dark
    count:
      type: integer
      title: Count
    visible:
      type: boolean
      title: Visible
      default: true
slots:
  content:
    title: Main content
    description: The body content of the component.
  footer:
    title: Footer
libraryOverrides:
  dependencies:
    - core/drupal
    - core/once
```

## SDC Twig Template Pattern

```twig
{# hero.twig #}
<div{{ attributes.addClass('hero', 'hero--' ~ variant|default('default')) }}>
  {% if image_url %}
    <div class="hero__media">
      <img src="{{ image_url }}" alt="{{ image_alt|default('') }}" loading="lazy" />
    </div>
  {% endif %}
  <div class="hero__content">
    {% if title %}
      <h2 class="hero__title">{{ title }}</h2>
    {% endif %}
    {% block content %}{% endblock %}
  </div>
  {% if cta_url and cta_text %}
    <a href="{{ cta_url }}" class="hero__cta btn">{{ cta_text }}</a>
  {% endif %}
</div>
```

## Using SDC Components

```twig
{# In a parent template or another component #}
{{ include('my_theme:hero', {
  title: 'Welcome',
  image_url: file_url(node.field_image.entity.fileuri),
  cta_text: 'Learn more',
  cta_url: url('entity.node.canonical', {'node': node.id}),
}) }}

{# With slots #}
{% embed 'my_theme:card' with { title: node.label } %}
  {% block content %}
    {{ content.body }}
  {% endblock %}
  {% block footer %}
    <span class="card__date">{{ node.created.value|date('M d, Y') }}</span>
  {% endblock %}
{% endembed %}
```

## Libraries.yml Patterns

### CSS categories (render order, top to bottom)

```yaml
my_library:
  css:
    base:                    # CSS resets, normalize (weight: CSS_BASE)
      css/base/reset.css: {}
    layout:                  # Grid, page structure (weight: CSS_LAYOUT)
      css/layout/grid.css: {}
    component:               # Reusable components (weight: CSS_COMPONENT)
      css/components/card.css: {}
    state:                   # States, toggles (weight: CSS_STATE)
      css/state/is-active.css: {}
    theme:                   # Skin, colors, typography (weight: CSS_THEME)
      css/theme/colors.css: {}
```

### JS with attributes

```yaml
my_library:
  js:
    js/app.js:
      attributes:
        defer: true
    js/analytics.js:
      attributes:
        async: true
      preprocess: false      # Don't aggregate
```

### Conditional library loading

```yaml
# In *.libraries.yml — external library
cdn-fontawesome:
  css:
    theme:
      https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css:
        type: external
        minified: true
```

### Library overrides in info.yml

```yaml
# my_theme.info.yml
libraries-override:
  # Remove a library entirely
  classy/node: false
  # Replace a CSS file
  core/drupal.dialog:
    css:
      theme:
        dialog.theme.css: css/my-dialog.css
  # Remove a specific CSS file
  core/drupal.vertical-tabs:
    css:
      component:
        misc/vertical-tabs.css: false

libraries-extend:
  core/drupal.dialog:
    - my_theme/dialog-extras
```

## Preprocess Patterns

### Adding variables to templates

```php
/**
 * Implements hook_preprocess_HOOK() for node templates.
 */
function my_theme_preprocess_node(array &$variables): void {
  /** @var \Drupal\node\NodeInterface $node */
  $node = $variables['node'];

  // Add reading time estimate.
  if ($node->bundle() === 'article' && $node->hasField('body')) {
    $text = strip_tags($node->get('body')->value ?? '');
    $word_count = str_word_count($text);
    $variables['reading_time'] = max(1, (int) ceil($word_count / 200));
  }
}
```

### Adding suggestions

```php
/**
 * Implements hook_theme_suggestions_HOOK_alter() for node templates.
 */
function my_theme_theme_suggestions_node_alter(array &$suggestions, array $variables): void {
  /** @var \Drupal\node\NodeInterface $node */
  $node = $variables['elements']['#node'];
  $view_mode = $variables['elements']['#view_mode'];
  // Add: node--{bundle}--{view_mode}.html.twig
  $suggestions[] = 'node__' . $node->bundle() . '__' . $view_mode;
}
```

### Adding body classes

```php
/**
 * Implements hook_preprocess_HOOK() for html templates.
 */
function my_theme_preprocess_html(array &$variables): void {
  $route = \Drupal::routeMatch()->getRouteName();
  if ($route === 'entity.node.canonical') {
    $node = \Drupal::routeMatch()->getParameter('node');
    if ($node instanceof \Drupal\node\NodeInterface) {
      $variables['attributes']['class'][] = 'page-node-type-' . $node->bundle();
    }
  }
}
```

## Responsive Image Config Pattern

```yaml
# responsive_image.styles.hero.yml
id: hero
label: 'Hero Banner'
image_style_mappings:
  - image_mapping_type: sizes
    image_mapping:
      sizes: '(min-width: 1024px) 100vw, (min-width: 768px) 100vw, 100vw'
      sizes_image_styles:
        - hero_mobile
        - hero_tablet
        - hero_desktop
    breakpoint_id: my_theme.mobile
    multiplier: 1x
breakpoint_group: my_theme
fallback_image_style: hero_desktop
```

## Twig Filters and Functions — Drupal-Specific

```twig
{# Translation #}
{{ 'Hello @name'|t({'@name': user.displayname}) }}
{% trans %}Welcome back, {{ user_name }}{% endtrans %}

{# URL generation #}
{{ path('entity.node.canonical', {'node': nid}) }}
{{ url('entity.node.canonical', {'node': nid}) }}

{# File URL #}
{{ file_url(node.field_image.entity.fileuri) }}

{# Rendering #}
{{ content.field_name }}                   {# Render a field #}
{{ content.field_name|render|striptags }}  {# Get plain text #}

{# Attach library #}
{{ attach_library('my_theme/my_library') }}

{# Link generation #}
{{ link('Click me', url('entity.node.canonical', {'node': 1})) }}

{# Active theme path #}
{{ active_theme_path() }}
{{ active_theme() }}
```

## Drupal.behaviors Pattern (JS)

```js
(function (Drupal, once) {
  'use strict';

  Drupal.behaviors.myThemeAccordion = {
    attach(context) {
      once('accordion', '.accordion__trigger', context).forEach((trigger) => {
        trigger.addEventListener('click', (e) => {
          const panel = trigger.nextElementSibling;
          const expanded = trigger.getAttribute('aria-expanded') === 'true';
          trigger.setAttribute('aria-expanded', String(!expanded));
          panel.hidden = expanded;
        });
      });
    },
    detach(context, settings, trigger) {
      if (trigger === 'unload') {
        // Cleanup if needed.
      }
    },
  };
})(Drupal, once);
```
