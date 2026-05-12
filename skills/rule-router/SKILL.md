---
name: rule-router
description: route a request to the smallest necessary set of skills and repo rules when the user explicitly asks to choose, compare, audit, or minimize applied instructions, or when multiple candidate skills or rules overlap and routing needs deterministic resolution. use for multi-skill orchestration, routing audits, conflict resolution, or repo-specific rule selection. do not use for ordinary requests where one relevant skill is already obvious.
---

# Rule Router

## Goal

Select the smallest sufficient instruction set for the current task.

Prefer one primary skill. Add supporting rules only when each adds a distinct necessary constraint, output contract, or verification step.

Keep routing internal by default. Expose a routing contract only when the user explicitly asks for a routing audit, trace, explanation, or machine-readable selection output.

## Definitions

- `skill` — a reusable workflow bundle with an entrypoint instruction file and optional supporting resources.
- `rule` — a narrower instruction source such as a repo-local policy, convention, checklist, or guardrail.
- `candidate` — any skill or rule that appears potentially relevant after a surface scan.
- `routing audit` — a user-visible explanation of which skills or rules were selected or excluded and why.

## Core Routing Principles

- **Minimality:** select the smallest set that can complete the task safely and correctly.
- **Specificity:** prefer the narrower and more task-specific instruction over a broader one.
- **Evidence-first:** infer relevance from documented metadata and entrypoint instructions, not from guessed capabilities.
- **Environment-native discovery:** use the host application's native skill or rule discovery mechanisms. Never assume a specific folder layout or tool unless the current environment actually provides it.
- **Repo-first for repo conventions:** when both global skills and repo-local rules exist, prefer repo-local rules for project-specific conventions and global skills for reusable workflows.
- **No recursive routing:** do not re-route the router itself.
- **Silent by default:** do not force routing metadata into normal user-facing answers unless the user asked for it.

## Discovery Workflow

1. **Parse the request**
   Determine whether the task is:
   - a normal single-skill request with an obvious best match
   - a multi-skill or multi-rule request
   - a routing audit or skill-selection request
   - a repo-specific change that may require project rules

2. **Decide whether this skill should act at all**
   Use this skill only when routing is genuinely ambiguous, audited, or potentially expensive.
   If one clearly relevant skill already fits the request, do not add router overhead.

3. **Discover candidates using native mechanisms**
   Use the environment's supported discovery APIs, metadata, or registries.
   If repo-local rules are available, inspect their names and short descriptions first.
   If only platform skills are available, inspect platform skill metadata first.

4. **Surface scan**
   Review only lightweight signals first:
   - file or resource names
   - display names
   - descriptions
   - tags or metadata if available

5. **Shortlist candidates**
   Keep only candidates whose names or descriptions strongly match the user's intent, affected subsystem, requested output, or safety constraints.

6. **Read entrypoints, not everything**
   For shortlisted candidates, read only the main entrypoint instruction file first.
   Read deeper resources only if the entrypoint indicates they are needed for the current decision.

7. **Stop early**
   Stop discovery as soon as the routing choice is safe and clear.
   Do not exhaustively scan every available skill or rule.

## Selection Gates

Use qualitative gates, not scoring.

### Tier 1 — Must Include

Include a candidate when at least one of the following is true:

- the user explicitly named it
- the task cannot be completed correctly without it
- it provides a required safety, compliance, or architectural guardrail
- it governs the exact subsystem or artifact being modified

### Tier 2 — Should Include

Include a candidate only if it adds distinct necessary value such as:

- repo-specific conventions not covered elsewhere
- a required output format or acceptance contract
- a verification or validation step that materially reduces regression risk

### Tier 3 — Exclude

Exclude a candidate when any of the following is true:

- it is tangential to the actual task
- it duplicates behavior already covered by a selected candidate
- it is broader than a more specific selected candidate
- it increases context without adding distinct value
- it conflicts with an explicit user instruction
- it governs a subsystem that is not being changed

When in doubt between two equally safe options, choose the smaller set.

## Selection Limits

Default routing target:

- `1` primary skill
- `0–2` supporting rules or supporting skills

Exceed this only when each additional selected item contributes a distinct non-overlapping requirement.
If two candidates overlap heavily, choose the narrower one.
If no candidate materially improves execution, select none and proceed normally.

## Conflict Resolution

Resolve conflicts in this order:

1. explicit user instruction
2. safety or compliance requirements
3. repo-local or project-specific rule with narrower scope
4. documented priority metadata, if the environment actually provides it
5. narrower scope over broader scope
6. smaller and cheaper instruction set when both options are equally safe and correct

Additional rules:

- Explicitly requested skills override inferred skills unless that would violate safety requirements.
- Do not invent `priority` or other metadata when it is absent.
- If the conflict is not blocking, choose the safer and narrower option and record the assumption in routing audit mode.
- If the conflict is blocking and cannot be resolved safely, ask at most one focused clarifying question.

## Uncertainty Policy

Do not ask clarifying questions unless the ambiguity is genuinely blocking.

Prefer this order:

1. make a conservative routing choice
2. state assumptions in routing audit mode if needed
3. ask one focused question only when safe execution is impossible without it

## Output Modes

### Default Mode

Do not expose routing metadata.
Proceed with the selected minimal instruction set and answer the user's actual request.

### Audit Mode

When the user explicitly asks any of the following:

- which skills or rules were used
- why a skill or rule was selected or excluded
- to show routing
- to provide a machine-readable routing contract

Emit this YAML block before execution or explanation:

```yaml
selected_rules:
  - id: <rule-name>
    reason: <why included>
selected_skills:
  - name: <skill-name>
    source: <platform-skill|repo-rule|other-native-source>
    reason: <why included>
conflict_resolutions:
  - item: <skill-or-rule>
    decision: <included|excluded>
    reason: <why>
needs_clarification: true|false
assumptions:
  - <only when needed>
confidence: high|medium|low
```

Only include excluded items when they were serious borderline candidates or part of conflict resolution.

## Hard Constraints

- Do not fabricate capabilities, scope, or metadata.
- Do not read the full contents of clearly irrelevant candidates.
- Do not force a routing audit into ordinary user-facing responses.
- Do not recursively route this router skill.
- Do not ignore conflicts silently; document them in audit mode.
- Keep repository artifacts in English unless the user explicitly requests another language.

## Practical Decision Rules

Use these shortcuts:

- If the user explicitly names a skill, include it unless it is unsafe or clearly irrelevant.
- If one skill cleanly matches the request and no repo-local rule is needed, use only that skill.
- If a repo-local rule constrains naming, architecture, formatting, or tests for the touched subsystem, include it.
- If two skills both match, prefer the one with the more specific trigger and narrower task scope.
- If a candidate only adds generic advice already covered by system instructions, exclude it.

## Final Rule

The router succeeds when it reduces context, preserves correctness, and makes skill selection more deterministic without becoming visible noise.
