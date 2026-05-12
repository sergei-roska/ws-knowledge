---
name: spec-builder
description: generate a single strict implementation spec from a task id, issue url, or free-form request. use when the user asks for a spec, technical spec, implementation plan, execution plan, or realization outline in english or russian that should be executable by a junior delivery model. inspect the local repo and project context first when task ids, urls, files, or code context are available. default the execution recommendation to gpt-5-mini and escalate to gpt-5.2-codex only for concrete architectural, migration, security, concurrency, performance, or ambiguity risks.
---

# Spec Builder

## Goal

Produce exactly one artifact: an **Implementation Spec**.

The spec must be:

- executable by a junior delivery model
- concrete enough to implement without improvising architecture
- explicit about file touchpoints, tests, acceptance criteria, and rollout
- honest about uncertainty

The default target execution model is `gpt-5-mini`.
Recommend `gpt-5.2-codex` only when the task cannot be made safely executable for `gpt-5-mini` after reasonable repo inspection and scoping.
Do not recommend `gpt-5-nano` in this skill.

## Core Rules

- Inspect local repo and project context before planning when task ids, urls, file names, stack clues, or repository context are available.
- Prefer concrete paths, modules, services, tests, and configuration over abstract suggestions.
- Do not invent facts. If something is uncertain, either:
  - make a safe assumption and label it as `Hypothesis`, plus add a verification step, or
  - raise the model recommendation and explain why.
- Ask at most 2 high-leverage clarifying questions, and only when the ambiguity is truly blocking and cannot be handled safely with assumptions.
- When enough information exists, output only the artifact. No preface, no conclusion, no side commentary.
- Keep the plan as linear as possible. A junior model should be able to execute it step by step.
- Every acceptance criterion must be testable.
- Every model recommendation must be justified by concrete risk factors from the task or repo.

## Working Style

Prefer this order:

1. identify inputs
2. inspect repo and current implementation
3. identify constraints and invariants
4. define desired behavior and out of scope
5. write verifiable acceptance criteria
6. produce a linear implementation plan
7. list file touchpoints
8. define tests and verification
9. define rollout or migration when relevant
10. choose the execution model
11. emit the final artifact in the exact required format

## Repo Context Expectations

When repo context is available:

- inspect likely entry points, route handlers, services, components, data models, tests, and configuration
- look for existing patterns to reuse instead of inventing new structure
- cite concrete file paths whenever determinable
- identify important contracts or invariants already present in code

If external systems are referenced but inaccessible:

- do not pretend to know their contents
- write `Unknown`
- add a verification or clarification step under the relevant section

If repo context is not available:

- still produce the spec
- label uncertain paths and modules as `Hypothesis`
- state how to verify them quickly

## What Good Specs Look Like

A good spec:

- tells the implementer exactly what to change
- keeps scope bounded
- names the files or search locations to inspect
- distinguishes required work from optional follow-up
- makes rollback and verification possible
- exposes unknowns instead of hiding them

A bad spec:

- says "refactor as needed"
- says "improve architecture" without concrete changes
- gives acceptance criteria that cannot be tested
- recommends a stronger model without linking it to real risks
- leaves file touchpoints, tests, or rollout vague

## Model Selection Policy

### Default stance

Start from `gpt-5-mini`.
Assume the spec should be made executable for `gpt-5-mini` unless there is a concrete reason that this would be unsafe or too ambiguous.

Do not recommend `gpt-5-nano`.
This skill is optimized for reliable implementation specs with repo inspection, constraint handling, and non-trivial code reading. Even seemingly small tasks often require more reasoning and context discipline than `gpt-5-nano` safely provides.

### Keep `gpt-5-mini` when

Recommend `gpt-5-mini` when most of the following are true:

- the change is local or moderately scoped
- the repo already shows a clear pattern to follow
- contracts and invariants are understandable after inspection
- the implementation can be described as a linear plan
- tests are standard and local
- the number of hypotheses is low and each has a simple verification step
- there are no major security, migration, concurrency, or performance traps

### Escalate to `gpt-5.2-codex` when

Recommend `gpt-5.2-codex` when one or more of the following apply:

- the task spans many files, layers, or subsystems
- the architecture is ambiguous even after repo inspection
- the task involves risky migrations, backwards compatibility, or rollout coordination
- the task has meaningful security, auth, privacy, permissions, secrets, or compliance implications
- the task involves concurrency, caching consistency, background work, distributed behavior, or subtle state management
- the task is performance-sensitive or requires careful query or algorithm analysis
- the codebase appears highly coupled or under-documented
- the spec would otherwise depend on too many unverified assumptions
- the junior implementer would need to invent significant design details during execution

### Before escalating

Before recommending `gpt-5.2-codex`, first try to make the spec safe for `gpt-5-mini` by:

- reducing scope to the smallest correct slice
- turning ambiguity into explicit verification steps
- isolating risky areas into a limited change plan
- reusing existing repo patterns

Escalate only if the task remains unsafe or too open-ended after those reductions.

## Handling Uncertainty

Use this policy:

- if uncertainty is small and local, make a safe assumption and label it `Hypothesis`
- if uncertainty materially changes design, tests, or rollout, raise it in `Open Questions`
- if uncertainty blocks any safe plan at all, ask up to 2 clarifying questions instead of emitting a misleading spec

Never hide important unknowns inside the implementation plan.

## Output Requirements

Return exactly one artifact and follow this structure and heading order.
Populate every section.
If something is unknown, write `Unknown` and add a verification or clarification step.

```text
========================
Implementation Spec
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
- Target execution model: gpt-5-mini | gpt-5.2-codex
- Why (2–4 bullets tied to complexity/risks/unknowns/code-reading needs).
- Confidence: High/Medium/Low
- If gpt-5.2-codex: specify what could not be simplified to gpt-5-mini safely.
```

## Section Rules

### Problem Statement

State the job to be done, affected component or user, and explicit out-of-scope items.
Do not expand into solution details here.

### Inputs

Copy the actual inputs the user gave.
If a field was not provided, write `Unknown`.

### Current State

Describe only what you can support from available context.
If repo evidence is partial, separate confirmed facts from `Hypothesis` items.

### Desired Behavior

Translate the request into concrete requirements.
Prefer bullet points over prose.
Include edge cases only when they matter.
Do not add speculative product requirements.

### Acceptance Criteria

Make them falsifiable.
Good criteria can be checked by tests, inspection, or a short manual scenario.
Use at least 5 items unless the task is truly tiny.

### Implementation Plan

Make the plan linear.
For each step, include:

- goal
- files to touch
- exact change to make

Prefer "update X to do Y" over "refactor X".
If there are real risks, add a `Risks & Mitigations` subsection.

### File/Code Touchpoints

List likely files and modules explicitly.
If uncertain, label each uncertain item as `Hypothesis` and explain how to verify it.
Do not hide file uncertainty inside prose.

### Tests & Verification

Specify:

- which test layers to change
- likely commands to run
- how to discover the correct command if unknown
- one short manual verification scenario

### Rollout / Migration

Include this only when relevant, but always populate the section.
If nothing is needed, write `Not needed` and explain why.

### Open Questions

Separate blocking from non-blocking.
If the task can proceed safely with defaults, keep open questions non-blocking.
If safe execution is impossible without answers, mark them as blocking.

### Model Recommendation

Tie the choice directly to:

- scope size
- ambiguity after inspection
- coupling
- test complexity
- migration risk
- security/performance/concurrency concerns

Do not recommend `gpt-5.2-codex` just because the task is important.
Do not recommend `gpt-5-mini` if the implementer would still need to invent core design decisions.

## Quality Bar

Before finalizing, check that the spec:

- contains only one artifact
- uses the exact required heading order
- includes concrete file touchpoints or clearly labeled hypotheses
- contains verifiable acceptance criteria
- contains a step-by-step plan a junior model can follow
- includes tests and a manual verification path
- includes rollout guidance when relevant
- includes honest open questions
- recommends `gpt-5-mini` by default unless real risks justify escalation

## Final Rule

The spec must reduce execution-time thinking, not push complexity downstream.
If the implementer would still need to guess architecture, file locations, acceptance criteria, or risk handling, the spec is not finished.
