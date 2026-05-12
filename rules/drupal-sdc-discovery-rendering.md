---
id: drupal-sdc-discovery-rendering
description: Preserve Drupal SDC discovery and rendering invariants so components remain discoverable, cache-safe, and provider-addressable across themes and modules.
priority: 86
scope:
  - "**/components/**"
  - "**/*.component.yml"
  - "**/*.twig"
  - "**/*.php"
triggers:
  - creating a new Drupal SDC component
  - renaming SDC files or directories
  - rendering an SDC from PHP or Twig
---

# Drupal SDC Discovery and Rendering

R1. You MUST place SDC components under a `components/` directory in a theme or module.

R2. You MUST provide `{name}.component.yml` and `{name}.twig` as the required component files. You MUST NOT use `.html.twig` as the component template filename.

R3. You MUST reference components by `{provider}:{component}` when composing them from Twig or render arrays. You MUST NOT hardcode file paths as a substitute for the component ID.

R4. You MUST keep component names unique within a provider.

R5. You SHOULD prefer the component render element when assembling an SDC from PHP or render arrays, because it preserves Drupal render metadata such as `#cache` and `#attached`.

R6. You MAY use Twig composition from presenter templates when the render element is not the right integration point, but the data contract must remain explicit.

Correct:

```text
components/card/card.component.yml
components/card/card.twig
```

```php
[
  '#type' => 'component',
  '#component' => 'my_theme:card',
  '#props' => [
    'title' => $title,
  ],
]
```

Incorrect:

```text
components/card/card.html.twig
```

```twig
{% include 'components/card/card.twig' %}
```

The incorrect examples break SDC discovery or bypass the API-stable component identifier.
