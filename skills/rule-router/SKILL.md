---
name: rule-router
description: "Select and apply the right local rules and skills for the current request by dynamic discovery, scoring triggers, resolving conflicts by priority, and returning a deterministic routing contract before execution."
---

# Rule Router

## Goal

Route each user request to the smallest valid set of rules and skills, then produce a deterministic routing contract before execution.

## Inputs

- user request text
- optional repository context (changed files, target subsystem, task type)
- available rules and skills discovered at runtime

## Runtime Discovery (required each turn)

1. Discover rules from project-local rule locations (for example `.cursor/rules/`).
2. Discover skills from both locations:
- user/global skills: `~/.codex/skills/*/SKILL.md`
- project-local skills: `.cursor/skills/*/SKILL.md`
3. Never rely on a cached/static skill list across turns.
4. If a new skill folder appears, include it in candidate evaluation immediately.

## Candidate Scoring

### Rules

- `+3` if trigger directly matches request intent.
- `+2` if scope aligns with requested operation.
- `+2` if request explicitly mentions the rule domain.
- `+1` if rule supports safety/compliance for this task.
- `-2` if rule conflicts with explicit user instruction.

### Skills

- `+4` if user explicitly names the skill.
- `+3` if skill description directly matches user intent.
- `+2` if required artifacts/tools in request match the skill workflow.
- `-3` if skill scope conflicts with explicit user instruction.

## Selection Logic

1. Select rules with score `>= 3`.
2. Select skills with score `>= 3`.
3. If user explicitly names a skill, force-include it unless impossible.
4. Keep selection minimal; exclude unrelated candidates.

## Conflict Resolution

### Rule conflicts

- Use higher `priority` first.
- If equal priority, choose more specific scope.
- If still unresolved, keep both and set `needs_clarification: true`.

### Skill conflicts

- Prefer explicitly requested skill over inferred skill.
- If two inferred skills conflict, prefer narrower scope skill.
- If still unresolved, set `needs_clarification: true`.

## Output Contract (required)

```yaml
selected_rules:
  - id: <rule-id>
    why: <short reason>
selected_skills:
  - name: <skill-name>
    source: codex|cursor
    why: <short reason>
excluded_rules:
  - id: <rule-id>
    why: <short reason>
excluded_skills:
  - name: <skill-name>
    source: codex|cursor
    why: <short reason>
needs_clarification: true|false
```

## Hard Rules

- Do not fabricate metadata when rule/skill metadata is missing.
- Do not silently ignore conflicts.
- Re-run discovery each turn; do not assume prior inventory is current.
- Keep selection deterministic and minimal.
- Keep generated repository artifacts in English unless user explicitly requests another language.
