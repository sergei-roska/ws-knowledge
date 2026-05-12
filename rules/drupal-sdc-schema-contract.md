---
id: drupal-sdc-schema-contract
description: Require explicit schema-first component contracts for Drupal Single-Directory Components to prevent implicit APIs, invalid props, and unsafe replacement behavior.
priority: 90
scope:
  - .codex/skills/drupal-sdc-workflow/**
  - "**/components/**"
  - "**/*.component.yml"
triggers:
  - adding or editing a Drupal SDC component definition
  - expanding or reviewing SDC props or slots
  - introducing component replacement or schema enforcement decisions
---

# Drupal SDC Schema Contract

R1. You MUST define the component contract in `{name}.component.yml` before expanding the Twig API.

R2. You MUST model structured inputs as `props` and renderable content as `slots`.

R3. You MUST treat schema as project-mandatory even though Drupal core can technically run with looser definitions.

R4. You MUST declare `required` props for any value the component cannot render correctly without.

R5. You MUST declare empty props explicitly when a component has no props.

R6. You MUST keep prop types JSON-schema-friendly. You MUST NOT send arbitrary PHP objects as props unless there is a documented and justified Drupal-specific exception.

R7. You SHOULD use enums, booleans, integers, and arrays where they express a tighter contract than plain strings.

R8. You MUST have a defined schema before using `replaces` or participating in replacement workflows.

Correct:

```yaml
name: Alert
props:
  type: object
  required:
    - heading_level
  properties:
    heading_level:
      type: integer
      enum: [2, 3, 4, 5, 6]
    dismissible:
      type: boolean
slots:
  message:
    title: Message
```

Incorrect:

```yaml
name: Alert
props:
  type: object
  properties:
    message:
      type: string
    anything:
      type: string
```

The incorrect example mixes free markup into props and leaves the contract too weak to validate safely.
