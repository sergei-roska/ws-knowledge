---
id: drupal-sdc-override-governance
description: Enforce Drupal-supported override boundaries for SDC components and libraries so teams do not invent unsupported module overrides or unsafe replacement paths.
priority: 88
scope:
  - "**/components/**"
  - "**/*.component.yml"
  - "**/*.info.yml"
triggers:
  - overriding an upstream SDC component
  - replacing a component from a theme or module
  - changing SDC asset override behavior
---

# Drupal SDC Override Governance

R1. You MUST treat themes as the only supported layer for overriding components.

R2. You MUST NOT use modules to override other components.

R3. You MUST use the top-level `replaces` key in `{name}.component.yml` when intentionally replacing another component.

R4. You MUST verify that both the replacement intent and schema compatibility are present before declaring a component replaceable.

R5. You MUST use `libraries-override` or `libraries-extend` in `THEME.info.yml` when the task is to alter an upstream component library.

R6. You SHOULD change an upstream component’s library without replacing its markup when the requirement is asset-only.

R7. You MUST distinguish between component override and library override. They solve different risks and should not be mixed by default.

Correct:

```yaml
replaces: 'upstream_theme:promo-card'
name: Promo Card
props:
  type: object
  properties:
    title:
      type: string
```

```yaml
libraries-override:
  core/components.upstream_theme--promo-card: my_theme/promo-card-overrides
```

Incorrect:

```text
Put a replacement component in a module and assume Drupal will prefer it.
```

The incorrect approach depends on unsupported override behavior.
