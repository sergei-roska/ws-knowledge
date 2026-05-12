# Reference: Operational Rule Format

## Goal

This reference defines the strict schema for authoring **Rules** in agent environments, ensuring they are instantly readable, deeply searchable, and highly deterministic for the `rule-router`. Rules govern persistent behavioral patterns, constraints, and operational context.

## 1. File Naming Standard

Rule filenames must act as the first filtering gate (Surface Scan) for the `rule-router`.

- **Format:** `[domain]-[action-or-scope].md` (e.g., `drupal-dependency-injection.md`, `git-commit-standards.md`).
- **Constraint:** Use lowercase ASCII, hyphen-separated. Avoid non-descriptive names like `rule1.md` or `general.md`.

## 2. YAML Frontmatter Schema

Every rule MUST include a parseable YAML frontmatter block. This structured data allows the router to evaluate the rule during its Deep Scan phase accurately.

```yaml
---
id: <string>               # Unique rule identifier (lowercase, hyphen-separated)
description: <string>      # Core purpose; must be concise and keyword-rich for the deep scan.
priority: <number>         # Integer for conflict resolution. Higher values override lower ones.
scope:                     # Define where this rule applies (e.g., "Drupal Core APIs", "Frontend Twig").
  - <path-pattern-or-subsystem> 
triggers:                  # Specific intents or file changes that mandate including this rule (evaluates to Tier 1 / Tier 2 inclusion).
  - <intent-or-condition>
---
```

## 3. Structural Constraints (The Markdown Body)

The body of the rule must utilize imperative, numbered guidelines to ensure the agent processes them predictably.

- **Use Rule IDs (`R1`, `R2`, etc.):** Itemize constraints so they can be easily cited in logs and `rule-router` conflict resolutions.
- **Differentiate MUST vs SHOULD:** Use strict operational terminology (MUST, MUST NOT, SHOULD, MAY) to clarify the rigidity of validation to the agent reading it.
- **Isolate Code Samples:** Provide clear "Correct" and "Incorrect" code examples using standard markdown fenced code blocks.

## 4. Validation Checklist for Authors

Before saving a new rule, an agent or human author MUST verify:
- [ ] The filename explicitly mentions the impacted domain/subsystem.
- [ ] The YAML frontmatter exists and contains no syntax errors.
- [ ] The `id` is unique across all active skill/rule directories within the current agent's execution environment.
- [ ] `priority` is explicitly defined as an integer.
- [ ] `description` clearly signals to the router exactly when it is relevant.
- [ ] `triggers` list explicit conditions instead of vague aspirations.
