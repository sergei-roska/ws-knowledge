---
id: drupal-sdc-asset-discipline
description: Keep Drupal SDC asset loading deliberate and colocated to prevent duplicate libraries, broken dependency chains, and accidental global payload inflation.
priority: 80
scope:
  - "**/components/**"
  - "**/*.component.yml"
  - "**/*.info.yml"
  - "**/*.twig"
triggers:
  - adding SDC css or js
  - defining libraryOverrides for a component
  - attaching SDC libraries manually
  - evaluating broad component asset loading
---

# Drupal SDC Asset Discipline

R1. You MUST keep component-specific CSS and JS with the component unless the asset is genuinely cross-component or global.

R2. You MUST define component-local dependencies and extra files in `libraryOverrides` inside `{name}.component.yml`.

R3. You MUST use theme-level `libraries-override` or `libraries-extend` for upstream library changes rather than editing upstream component files.

R4. You SHOULD avoid manually attaching the component’s generated library in the same render path that already renders the component, unless the task explicitly requires asset-only attachment.

R5. You MAY attach only the generated component library when the use case is asset-only and that intent is explicit.

R6. You MUST evaluate `core/components.all` as a performance strategy with tradeoffs, not as a universal default.

R7. You SHOULD prefer the narrowest asset attachment that still keeps runtime behavior correct and cache-friendly.

Correct:

```yaml
libraryOverrides:
  dependencies:
    - core/drupal
    - core/once
  js:
    tabs.js:
      attributes:
        defer: true
```

```twig
{{ attach_library('core/components.my_theme--my-banner') }}
```

Incorrect:

```text
Copy the upstream component CSS into the local component directory and attach both versions.
```

The incorrect approach creates duplicate styling sources and obscures the real asset owner.
