---
id: drupal-sdc-composition-isolation
description: Keep Drupal SDC composition isolated and explicit to prevent parent-context coupling, escaped markup bugs, and rigid child-component nesting.
priority: 85
scope:
  - "**/components/**/*.twig"
  - "**/templates/**/*.twig"
  - "**/*.component.yml"
triggers:
  - composing one SDC inside another
  - rendering an SDC from Twig templates
  - deciding between props, slots, include, or embed
---

# Drupal SDC Composition Isolation

R1. You MUST prefer the `include()` function for prop-driven composition and `embed ... only` when the component exposes slot blocks.

R2. You SHOULD call components with `with_context = false` unless there is a deliberate, documented reason to inherit parent context.

R3. You MUST design component templates to render from declared props, slots, and `attributes`, not from ambient parent variables.

R4. You MUST use slots for arbitrary HTML, nested components, render arrays, and other free renderables.

R5. You MUST NOT pass raw HTML as a normal string prop when a slot is the correct contract.

R6. You SHOULD prefer passing child components from the outside through slots instead of hardcoding child includes deep inside a component template.

R7. You MUST NOT rely on preprocess hooks to inject hidden variables into an SDC. If the component needs data, add it to the contract or assemble it before render.

R8. You SHOULD avoid the `{% include %}` tag for SDC composition. Use the `include()` function so context passing stays explicit at the call site.

R9. You MUST NOT introduce `|raw` as a workaround for passing markup through props. Use slots or renderable inputs instead.

Correct:

```twig
{{ include('my_theme:button', {
  label: node.label,
  url: path('entity.node.canonical', {node: node.id}),
}, with_context = false) }}
```

```twig
{% embed 'my_theme:card' with { title: node.label } only %}
  {% block body %}
    {{ content.body }}
  {% endblock %}
{% endembed %}
```

Incorrect:

```twig
{{ include('my_theme:button') }}
```

```twig
{{ include('my_theme:card', {
  body: '<p><em>HTML</em></p>'
}) }}
```

```twig
{{ include('my_theme:card', {
  body: dangerous_html|raw
}, with_context = false) }}
```

The incorrect examples hide the data contract and risk escaped markup or accidental parent-context dependency.
