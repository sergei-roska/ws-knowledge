# Spec: Implementation Spec Authoring

## Purpose

This specification defines how an agent must produce a single high-quality implementation spec from a task id, issue URL, file reference, repository context, or free-form user request.

This is not a generic writing skill.
It is a specification for producing an executable implementation spec that another agent can carry out with minimal invention.

The output must be strong enough for delivery work, reviewable by a senior engineer, and explicit enough to expose uncertainty rather than hiding it.

## Goal

Produce exactly one artifact:

- `Implementation Spec`

That artifact must be:

- executable
- concrete
- bounded in scope
- honest about unknowns
- tied to actual repository evidence when available
- explicit about testing, rollout, file touchpoints, and acceptance criteria

The implementer should not need to invent major architecture during execution.

---

## Invocation Rule

If the user references this specification file directly, or clearly invokes this specification as the governing instruction for the task, the agent must treat the request as a spec-authoring request by default.

In that case, the agent must:

- create an `Implementation Spec` for the referenced task or request
- inspect repository and task context as needed to author that spec
- avoid switching into implementation mode unless the user explicitly asks to execute the work

The presence of:

- a Jira task ID
- a bug description
- repository paths
- screenshots
- technical hypotheses

does not by itself authorize implementation.

When this specification is invoked, those inputs are planning inputs for the spec unless the user explicitly requests execution.

---

## Input Types

The input may include any combination of:

- task id
- issue tracker URL
- PR or ticket summary
- free-form user request
- repository path
- file path
- screenshot or pasted error
- code excerpts
- business or product constraints

If repository context is available, the agent must inspect it before writing the implementation spec.

### Special rule for Jira task IDs

If the user provides a Jira task ID such as `ABC-123`, the agent must treat Jira as the source of truth for the task definition.

In that case, the agent must:

- use the available Atlassian connector or Atlassian MCP tooling to fetch the issue
- read the task summary, description, acceptance criteria, and other directly relevant fields before drafting the implementation spec
- prefer the live Jira record over guesses, memory, or partial local references

If the user provides only a Jira task ID and the agent does not have working access to Jira through the available connector tooling, the agent must:

- stop the spec-authoring process
- inform the user that Jira access is unavailable
- avoid inventing the task contents
- avoid producing a speculative implementation spec from the bare ID alone

In this case, the agent may continue only if the user then supplies:

- the Jira URL with accessible content, or
- the task text, or
- equivalent detailed context

### Special rule for task URLs

If the user provides a task URL, issue URL, or similar external work-item link, the agent must treat that linked system as the source of truth for the task definition.

In that case, the agent must:

- attempt to access the linked source through the appropriate connector or available tooling
- read the directly relevant task content before drafting the implementation spec
- avoid substituting guesses, memory, or weak local echoes of the task

If the user provides a URL but the agent cannot access its contents, the agent must:

- stop the spec-authoring process
- inform the user that the source URL is not accessible
- avoid producing a speculative implementation spec from the URL alone

In this case, the agent may continue only if the user then supplies:

- the task text, or
- an accessible source, or
- equivalent detailed context

---

## Required Output

The agent must output exactly one implementation spec and no extra framing.

When this specification is the active instruction for the task, the agent must not:

- edit repository files as part of the implementation
- apply code fixes
- run migration or deployment steps
- treat the task as approved for execution

unless the user explicitly asks to implement after the spec is delivered.

The implementation spec must define:

1. what needs to change
2. where the change likely lives
3. how the system behaves today, if determinable
4. what the target behavior is
5. how to verify correctness
6. what is uncertain
7. what model should execute the implementation

---

## Core Principles

### 1. Inspect before planning

If a repository, files, stack clues, or local project context are available, inspect them before writing the spec.

Do not write an abstract plan when concrete repo evidence can be gathered.

Inspection in this mode is for authoring the implementation spec, not for beginning implementation.

### 2. Prefer executable specificity

Prefer:

- real file paths
- real services and modules
- real test locations
- real configuration names
- real commands

Over:

- abstract architecture talk
- generic implementation advice
- broad refactor language

### 3. Do not invent certainty

If something is unknown:

- mark it as `Unknown`, or
- mark it as `Hypothesis` and add a verification step

Uncertainty must be visible.

### 4. Keep the plan linear

The implementation plan should be stepwise and executable in order.

Avoid asking the implementer to improvise sequencing unless the task genuinely requires branching decisions.

### 5. Make acceptance criteria falsifiable

Each acceptance criterion must be checkable by:

- test
- inspection
- command output
- short manual scenario

### 6. Bound scope explicitly

The implementation spec must separate:

- required work
- optional follow-up
- out-of-scope items

---

## Repository Context Rules

When local repository context is available, the agent must:

- inspect likely entry points
- inspect nearby tests
- inspect existing implementation patterns
- inspect services, controllers, routes, components, schemas, or config relevant to the task
- identify contracts and invariants already present in code

When external systems are referenced but not available, the agent must:

- avoid pretending to know their contents
- mark them as `Unknown`
- add a verification or clarification step

Exception:

- if the external system is Jira and the user explicitly identified the task by Jira task ID, do not downgrade to `Unknown` and continue
- instead, stop and inform the user that the Jira-backed source of truth is unavailable
- if the external system is referenced by URL and the agent cannot access the URL contents, do not downgrade to `Unknown` and continue
- instead, stop and inform the user that the linked source of truth is unavailable

When repository context is not available, the agent must still produce the spec, but clearly label uncertain file locations and search strategies as `Hypothesis`.

---

## What a Good Implementation Spec Looks Like

A good implementation spec:

- tells the implementer what to change
- points to likely code locations
- explains how to verify the result
- surfaces uncertainty honestly
- limits architectural invention
- keeps rollout and rollback discussable

A weak implementation spec:

- says "refactor as needed"
- says "improve architecture"
- omits file touchpoints
- hides uncertainty
- recommends an executor without concrete reasoning
- gives untestable acceptance criteria

---

## Executor Selection

The implementation spec must include a model recommendation for the executor.

For the actual model taxonomy and selection logic, the agent must use:

- [spec-codex-model-selection.md](/home/sr/Projects/ws-knowledge/spec-codex-model-selection.md)

That spec defines the available Codex-visible models and the shared-budget assumption.

### Default rule for implementation specs

Default the implementation executor to:

- `gpt-5.4`

Rationale:

- implementation specs are often written before the full complexity is known
- hidden architecture depth is common
- codebase coupling is often discovered only during inspection
- underpowered executor recommendations create thrash, re-planning, and misleading confidence

This default is intentionally more conservative than a cost-minimizing baseline.

### When to downgrade from `gpt-5.4`

Recommend a smaller executor only when the task is clearly and demonstrably:

- narrow
- local
- low-risk
- low-ambiguity
- easy to verify

Examples:

- one-file bug fix with obvious cause
- mechanical rename
- isolated test fix
- tiny UI copy or formatting adjustment with clear file ownership

In such cases, follow the selection logic from [spec-codex-model-selection.md](/home/sr/Projects/ws-knowledge/spec-codex-model-selection.md) and name the downgrade reason explicitly.

### When to keep `gpt-5.4`

Keep `gpt-5.4` when any of the following are present:

- incomplete understanding of system boundaries
- unclear root cause
- multi-file or cross-layer work
- migrations or rollout concerns
- security or permissions implications
- non-trivial performance concerns
- unfamiliar repository structure
- missing tests or weak local conventions
- many hypotheses

### When to consider `gpt-5.1-codex-max`

Recommend `gpt-5.1-codex-max` only when the execution itself is likely to require:

- long-running agent work
- broad repo traversal
- many steps over a sustained session
- large-scale coordination across files

This is not the default for spec execution.
Use it only when session shape, not just task difficulty, makes it the better engine.

---

## Clarifying Questions Policy

Ask clarifying questions only when the ambiguity is truly blocking and cannot be safely converted into:

- a bounded assumption
- a verification step
- a scoped fallback path

Do not ask more than 2 high-leverage clarifying questions.

If a safe, bounded implementation spec can still be written, write it.

---

## Output Format

Return exactly one artifact and use this structure.
Populate every section.
If something is not known, write `Unknown` and add a verification or clarification note where relevant.

```text
========================
Implementation Spec
========================

Title
- Short task name.

Problem Statement
- What needs to be done.
- Who or what is affected.
- Explicit out-of-scope items.

Inputs
- task_id: …
- url: …
- user_prompt: …
- extra_context: …

Current State (if determinable)
- Confirmed facts from repo/context.
- Hypotheses.
- Constraints, contracts, invariants.

Desired Behavior
- Concrete requirements.
- Edge cases.
- Non-functional requirements only if relevant.

Acceptance Criteria (verifiable)
- Falsifiable checklist or Given/When/Then criteria.
- Minimum 5 items unless the task is truly tiny.

Implementation Plan
- Linear execution steps.
- For each step: goal, files to touch, exact change to make.
- Add `Risks & Mitigations` when relevant.

File/Code Touchpoints
- Existing files likely to change.
- New files if needed.
- Hypothesis labels where uncertain.

Tests & Verification
- Tests to add or update.
- Commands to run.
- Manual verification scenario.

Rollout / Migration
- Backwards compatibility concerns.
- Flags, deployment order, data or config migration.
- Rollback notes.

Open Questions
- Blocking questions.
- Non-blocking questions.

Model Recommendation
- Target execution model: …
- Reasoning effort: …
- Fallback model: …
- Why: …
- Budget note: …
- Confidence: High / Medium / Low
```

---

## Section Rules

### Problem Statement

Describe the job to be done without jumping into implementation details.

### Inputs

Copy the actual user inputs when available.
Do not normalize away important wording.

### Current State

Separate confirmed repo evidence from hypothesis.
Do not blur them together.

### Desired Behavior

Translate user intent into concrete system behavior.
Do not add speculative product requirements.

### Acceptance Criteria

Must be testable.
Prefer user-visible or system-verifiable outcomes over vague code-quality goals.

### Implementation Plan

Each step must say:

- goal
- files to touch
- exact change to make

Avoid vague instructions such as "refactor" or "clean up" unless the scope is concretely defined.

### File/Code Touchpoints

Prefer exact paths.
If exact paths are not known, identify likely search locations and mark them as `Hypothesis`.

### Tests & Verification

Recommend the narrowest useful test set.
Do not prescribe broad validation when a focused check would suffice.

### Rollout / Migration

Only include this section in depth when the task truly affects deployment, configuration, schema, data, cache, or compatibility.

### Open Questions

Separate blocking from non-blocking uncertainty.
Do not hide critical unknowns elsewhere.

### Model Recommendation

This section is mandatory.
Use [spec-codex-model-selection.md](/home/sr/Projects/ws-knowledge/spec-codex-model-selection.md) as the governing reference for model naming and budget logic.
Default to `gpt-5.4` unless there is a concrete reason to downgrade safely.

---

## Final Behavioral Rule

The authoring agent must act like a senior engineer preparing work for execution:

- inspect before asserting
- narrow scope before escalating
- expose uncertainty instead of masking it
- choose the executor deliberately
- prefer a spec that survives real repository contact over a spec that merely reads well
