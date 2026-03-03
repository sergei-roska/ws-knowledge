# Rule Format Reference

## Frontmatter Schema

```yaml
---
id: string
version: number
description: string
priority: number
scope: string[]
triggers: string[]
actions: string[]
---
```

## Notes

- `id` should be unique across all rule files.
- `priority` resolves conflicts; larger value wins.
- `scope` describes where rule applies.
- `triggers` define activation signals.
- `actions` define expected behavior when selected.

## Recommended Naming

- Rule filenames: `<id>.rules.md`
- IDs: lowercase-hyphen style

## Validation Checklist

- Frontmatter exists and parses.
- Required keys are present.
- Arrays are non-empty where expected.
- `priority` is an integer.
- No duplicate `id` values.
