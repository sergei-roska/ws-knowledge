---
name: spec-builder
description: "Generate a single, strict \"Implementation Spec\" artifact (with acceptance criteria, file touchpoints, tests, and rollout plan) from a task_id/URL or free-form request; use when the user asks for a spec/technical spec/implementation plan (\"spec builder\", \"Implementation Spec\", \"сделай спецификацию\", \"план реализации\") that should be executable by a junior/cheap execution model."
---

# Spec Builder

## Goal

Turn an incoming task (task_id, URL, or free-form description) + optional user context into exactly one structured artifact: an "Implementation Spec" that a junior/cheap execution model can follow.

Primary goal: make the spec executable by `gpt-5-nano`. If that is not safely possible, recommend `gpt-5-mini`; only then `gpt-5.2-codex`.

## Hard Rules

- If the user provides a `task_id` and/or `url`, first extract as much context as possible from the local repo/project context (existing patterns, relevant modules, config, code locations).
- Do not invent facts. For any uncertainty: either (a) make a safe assumption + include a verification step, or (b) raise the model recommendation and state why.
- Ask only 1–2 high-leverage clarifying questions if needed. Do not ask many questions at once.
- Output must be only the "Implementation Spec" artifact in the exact format below. No preface, no postscript, no extra commentary.

## Output Format (Required)

Return exactly one artifact and follow this structure (headings and order). Populate all sections; if something is unknown, write `Unknown` and add a verification/clarification step.

```text
========================
Implementation Spec (REQUIRED FORMAT)
========================

Title
- Short task name.

Problem Statement
- What needs to be done (1–3 sentences).
- Who it is for / which component(s).
- Out of scope.

Inputs
- task_id: …
- url: …
- user_prompt: …
- extra_context: …

Current State (if determinable)
- Where in code this lives (paths/modules).
- How it works today.
- Constraints/contracts/invariants.

Desired Behavior
- Clear bullet list of requirements.
- Edge cases.
- Non-functional requirements (perf/security/i18n/logging/DX) — only if relevant.

Acceptance Criteria (verifiable)
- Use Given/When/Then or a checklist.
- Minimum 5 items unless the task is truly tiny.

Implementation Plan (for a junior model)
- Step-by-step, as linear as possible.
- For each step: goal, files to touch, exact change to make.
- Include a “Risks & Mitigations” subsection if there are notable risks.
- Forbidden: vague refactors, “improve architecture” without concrete steps.

File/Code Touchpoints (assumptions)
- List or table of files: existing/new, what changes, why.
- If unsure: label as Hypothesis and state how to verify.

Tests & Verification
- What tests to add/update (unit/integration/e2e).
- Commands to run (if unknown, list likely commands and how to find them).
- Short manual verification scenario.

Rollout / Migration (if needed)
- Feature flags, migrations, backwards compatibility, rollback plan.

Open Questions (blocking vs non-blocking)
- Blocking: cannot proceed safely without answers.
- Non-blocking: can proceed with defaults.

Model Recommendation
- Target execution model: gpt-5-nano | gpt-5-mini | gpt-5.2-codex
- Why (2–4 bullets tied to complexity/risks/unknowns/code-reading needs).
- Confidence: High/Medium/Low
- If not nano: specify what could not be simplified to nano safely.
```

## Model Choice Rubric (Must Apply)

- Prefer `gpt-5-nano` if: local changes (1–3 modules), clear criteria, no deep architectural ambiguity, minimal dependencies, no subtle security/concurrency pitfalls.
- Use `gpt-5-mini` if: multiple subsystems, higher regression risk, non-trivial tests/mocks, moderate repo investigation required.
- Use `gpt-5.2-codex` if: architectural complexity, many files, tricky types/concurrency/security/perf, or spec cannot be made safe without substantial code reading/reasoning.

## Repo Context Expectations

- When possible, cite concrete paths, modules, services, or configuration by inspecting the repo.
- If external systems (Jira/Confluence/etc.) are referenced but not accessible, state what is unknown and what must be clarified.

## Quick Use

Users can trigger this skill by saying something like:

- "Use `spec-builder` for: <task>"
- "Сделай Implementation Spec для: <описание задачи>"
