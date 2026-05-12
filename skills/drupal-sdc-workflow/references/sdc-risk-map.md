# Drupal SDC Risk Map

This reference condenses the multi-page Drupal SDC documentation into operational risks that should shape skill and rule design.

## Source Set

- Canonical Main Guide: https://www.drupal.org/docs/develop/theming-drupal/using-single-directory-components
- Annotated `component.yml`: https://www.drupal.org/docs/develop/theming-drupal/using-single-directory-components/annotated-example-componentyml
- Props and Slots: https://www.drupal.org/docs/develop/theming-drupal/using-single-directory-components/what-are-props-and-slots-in-drupal-sdc-theming
- API: https://www.drupal.org/docs/develop/theming-drupal/using-single-directory-components/api-for-single-directory-components

## Agent Retrieval Guidance (Context7 MCP)

When this risk map does not provide enough detail, use **Context7 MCP** for targeted documentation and code examples.

### Configuration
- **Library ID**: `/drupal/drupal`
- **Related Library**: `/websites/project_pages_drupalcode_ui_patterns` (UI Patterns 2)

### Recommended Queries
- `How to use slots and props in Drupal SDC templates`
- `SDC component.yml required schema syntax`
- `How to override SDC assets and markup in a theme`
- `Using the SDC render element from PHP`
- `SDC variants and variants schema example`

The strongest risk-bearing constraints in this repository mapping come from the "Using your component", "Props and Slots", "API", and "FAQ" pages.

## Risk to Guidance Mapping

### Risk: the component API is implicit, undocumented, or impossible to validate

Use schema-first `*.component.yml` authoring.

Why:

- Drupal requires a correctly named YAML file for the component.
- Schema is not always enforced automatically, which means teams can drift into undocumented props unless they adopt a stricter project convention.
- Schema is required for safe component replacement workflows and tool integrations.

## Risk: callers pass the wrong kind of input

Separate props from slots.

Why:

- Props are for typed, structured data and optional UI logic.
- Slots are for free renderables: markup, nested components, render arrays, and renderable/stringable objects.
- Passing HTML through props leads to escaping or weak contracts.

## Risk: a component works only because it can see parent Twig variables

Prefer isolated context in composition.

Why:

- Drupal documentation recommends `with_context = false` to avoid side effects.
- Hidden parent dependencies make components harder to reuse, test, and override.

## Risk: component discovery breaks because naming and addressing are inconsistent

Keep discovery invariants explicit.

Why:

- The required template file is `{name}.twig`, not `.html.twig`.
- Components are addressed by the stable API form `{provider}:{component}`.
- Hardcoded file-path composition weakens portability and hides the provider boundary.

## Risk: render-array metadata is lost because composition happens too low in Twig

Prefer the render element from PHP where possible.

Why:

- Drupal documents the render element as the preferred path when assembling a component from PHP.
- It preserves normal render-array concerns such as `#cache` and `#attached`.
- It keeps data shaping out of presenter Twig templates.

## Risk: teams invent unsupported override flows

Keep override governance explicit.

Why:

- Only themes can override components.
- Modules may provide components, but cannot override them.
- Replacement requires `replaces` and a defined schema.

## Risk: asset behavior becomes fragmented or duplicated

Keep dependency decisions at the right boundary.

Why:

- SDC auto-generates a component library.
- Extra files and dependencies belong in `libraryOverrides` inside the component definition.
- Theme-level `libraries-override` and `libraries-extend` are the supported path for upstream asset changes.

## Risk: teams recreate old preprocess-heavy theming patterns inside SDC

Do not plan around preprocess hooks.

Why:

- Drupal FAQ states SDC does not support preprocessing variables by design.
- The component contract should carry the needed data explicitly.

## Risk: teams reintroduce output-safety problems by pushing HTML through props

Prefer slots and normal Twig escaping over `|raw` shortcuts.

Why:

- Rich markup belongs in slots, not typed props.
- Using `|raw` to compensate for the wrong contract weakens output safety and hides the real API mistake.

## Risk: component structure becomes rigid and impossible to compose

Prefer slots for extensibility.

Why:

- Drupal docs explicitly recommend passing children from the outside through slots rather than hardcoding child component calls in component templates.

## Risk: version-specific features are assumed to exist everywhere

Document version boundaries.

Why:

- Variants are available only in Drupal 11.2+.
- Broader SDC support and guidance differ across Drupal versions.

## Practical Standard for This Repository

- Treat schema as mandatory even when core does not strictly enforce it.
- Treat `with_context = false` as the safe default for component composition.
- Treat `embed ... only` as the safe default for slot-based composition.
- Treat props as structured data and slots as renderable content.
- Treat theme override mechanisms as the only supported override path.
- Treat component-local assets as the default unless there is a clear performance or architecture reason to broaden attachment.
