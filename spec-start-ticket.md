# Spec: /start-ticket — Task Intake and Decomposition

## Purpose

This specification defines how an agent must begin work on a ticket: fetch it, decompose it, map it onto the real system, surface ambiguity, and produce either an execution plan or an Implementation Spec file.

It is the governing document for the `/start-ticket` command:

```
/start-ticket <TICKET-ID> [plan|spec]
```

This is an intake specification, not an implementation authorization. Decomposition output is a planning artifact; execution starts only when the user explicitly says so.

---

## Two Output Modes

The procedure (below) is identical in both modes. Only the materialization of the result differs.

### `plan` mode (default)

For ordinary tickets, executed in the current session on the current model.

- Output: an execution plan **in chat** — concise, stepwise, reviewable.
- No file is created.
- Ends with a self-assessment (see Escalation Self-Assessment).

### `spec` mode

For complex tickets, typically run on a stronger model, producing a handoff artifact for a cheaper executor.

- Output: an Implementation Spec **file**, never chat text.
- **Create the file `specs/<TICKET-ID>.md` on disk**, using whatever file-writing mechanism the environment provides (built-in file tool, `apply_patch`, shell/python, MCP filesystem — the mechanism does not matter; the file does).
- **Do NOT print the spec body — or any of its sections — into the chat.** The user opens the file; chat duplication is noise.
- Chat output after writing, maximum 5 lines:
  1. the file path
  2. the goal in one sentence
  3. number of acceptance criteria
  4. open/blocking questions, if any
  5. the executor recommendation
- The spec file must be **self-contained**: executable by a model that has not seen this session, the ticket, or the author's reasoning. Every mapping decision made during intake must be materialized in the file (exact object names, not ticket nouns).

---

## Source of Truth Rules

### Jira task IDs

A Jira task ID (`ABC-123`) makes Jira the source of truth.

- Fetch the issue via the Atlassian connector / MCP tooling.
- Read the summary, description, acceptance criteria, **comments** (requirements often live there), and linked issues before decomposing.
- Prefer the live record over guesses, memory, or partial local references.

If Jira access is unavailable: **stop**, tell the user, do not invent ticket contents, do not produce a speculative decomposition from the bare ID. Continue only when the user supplies the ticket text or an accessible source.

### Task URLs

Same rule for any external work-item URL: the linked system is the source of truth; inaccessible link → stop and say so.

---

## Intake Procedure

Run all six steps in both modes. Do not skip steps because the ticket "looks simple" — misjudged simplicity is exactly what this procedure exists to catch.

### 1. Fetch the whole ticket — and produce a fetch manifest

Fetch the ticket fields: summary, description, acceptance criteria, comments, attachments.

Then **enumerate every reference** the ticket carries. Enumeration must come from **structural fields first**: explicitly request the tracker's link data (in Jira: `parent`/epic link, `issuelinks`, remote links, attachments) — do not reconstruct the link list by spotting issue keys in the prose. Text-mentioned keys and PR links are *added* to the structural list, never a substitute for it: prose extraction depends on reading attention; the fields do not. For each reference found, decide and record:

- **Parent epic: always read its content** (one level up; it is cheap and often holds the original requirement).
- **Any issue the ticket uses as a source of requirements** ("AC as in ABC-1083", "regression of ABC-1303", "as described in…"): reading it is mandatory — a retelling inside the ticket body is NOT the source. Default depth: 1 level; go deeper only if the level-1 source itself delegates further.
- Other links: may be skipped, but only with a stated reason.
- Inaccessible items (blob attachments, closed PRs): record as `not readable`, do not pretend they were seen.

The step's output is a **fetch manifest**: every discovered reference listed as `read` / `skipped: <reason>` / `not readable`. The manifest goes into the plan or the spec file's Inputs section. An unlisted reference or a silently skipped requirements-source means step 1 is not complete.

**Source conflict rule:** if the epic or a linked source disagrees with the ticket body about the goal or scope, that is *intent* ambiguity — go to the step 5 gate: stop, quote both versions, ask which is authoritative. Never silently prefer the nearer text.

### 2. Separate goal from implementation hints

Restate what must become true when the task is done. The author's implementation suggestions are hints, not requirements — they may be wrong; the goal is primary.

### 3. Formulate acceptance criteria

Falsifiable, checkable by test, inspection, command output, or a short manual scenario. In `spec` mode: minimum 5 unless the task is truly tiny.

### 4. Map every ticket entity to a real system object

Every noun in the ticket ("the news block", "the filter", "the field") must be resolved to an exact object (`views.view.news`, display `block_2`, `field.field.node.article.field_date`) — **by inspection, not by assumption**. Inspect the repository and runtime config as needed; this inspection is for authoring, not for beginning implementation.

If a mapped object is governed by a domain skill (e.g. Views / inherited config → `drupal-views-safe-edit`), name that skill in the plan/spec step that touches the object, so the executor loads it.

### 5. Ambiguity gate

Two kinds of uncertainty, two different treatments:

- **Implementation uncertainty** (where exactly the change lives, which approach is better, unverified behavior): do NOT stop. Mark as `Hypothesis` with a verification step, or `Unknown` with a clarification note. Ask at most 2 high-leverage clarifying questions, and only if the ambiguity cannot be safely converted into a bounded assumption.
- **Scope / intent uncertainty** (which of two readings the author meant; one display or the whole view; blast radius beyond the named target): **always stop.** Present what was found (the mapping, the candidate readings, who else is affected) and ask the user. Never resolve intent by picking the convenient reading.

### 6. Produce the output for the active mode

Plan in chat, or spec file per the rules above.

---

## Escalation Self-Assessment (plan mode)

In `plan` mode, after step 5 and BEFORE writing any plan, run a self-assessment. At this step, **read the file [spec-model-selection.md](spec-model-selection.md) (same directory as this spec)** — trigger definitions and model ladders come from that file, never from memory. Assess against its **measured triggers** (Rule 6): entities that failed unambiguous mapping, blast radius > 1, cross-subsystem span, unnamed root cause, missing tests, security/migration implications, expected long agentic session.

- **No triggers** → proceed to step 6: state "no escalation triggers" and present the plan for approval.
- **Triggers present** → do NOT write a plan. A plan from a model that has just assessed the task as above its rung looks executable but cannot be trusted — producing it is worse than producing nothing. Instead:
  1. Write the decomposition findings to `specs/<TICKET-ID>.intake.md`: goal, acceptance criteria, entity mapping so far, resolved/open ambiguities, and the fired triggers by name.
  2. In chat (max 5 lines): the fired triggers, the intake file path, and the explicit recommendation `Re-run as: /start-ticket <ID> spec on <model per spec-model-selection.md>`.

Count facts found during inspection; do not escalate on impression.

### Intake handoff (spec mode)

When `spec` mode starts and `specs/<TICKET-ID>.intake.md` exists, read it and use it as **starting hints, not facts**: it was produced by a model that self-assessed as under-powered for this task. Re-verify every entity mapping by inspection (cheap — the object is already named) before relying on it; keep its acceptance criteria and ambiguity resolutions only after checking them against the live ticket.

---

## Core Principles

1. **Inspect before planning.** Never write an abstract plan when repo evidence is available.
2. **Executable specificity.** Real file paths, real config names, real commands — over architecture talk.
3. **Do not invent certainty.** `Unknown` or `Hypothesis` + verification step; uncertainty must be visible.
4. **Keep the plan linear.** Stepwise, executable in order.
5. **Bound scope explicitly.** Required work / optional follow-up / out-of-scope — separated. Include a "do not touch" list when blast-radius analysis found adjacent objects.
6. **Intake is not execution.** A ticket ID, bug description, or repo path does not authorize implementation. Execute only on explicit user request after the plan/spec is approved.

---

## Implementation Spec File Format (`spec` mode)

Populate every section; write `Unknown` where applicable.

```text
========================
Implementation Spec
========================

Title
- Short task name.

Problem Statement
- What needs to be done; who/what is affected.
- Explicit out-of-scope items.

Inputs
- task_id / url / user_prompt / extra_context (copied, not paraphrased away).
- Fetch manifest: every reference (epic, linked issues, PRs, attachments)
  marked read / skipped: <reason> / not readable.

Entity Mapping
- Every ticket entity → exact system object (verified by inspection).
- Domain skills the executor must load, per object.

Current State
- Confirmed facts from repo/config.
- Hypotheses (each with a verification step).
- Constraints, contracts, invariants.

Desired Behavior
- Concrete requirements; edge cases.

Acceptance Criteria (verifiable)
- Falsifiable checklist; minimum 5 items unless truly tiny.

Implementation Plan
- Linear steps; per step: goal, files/objects to touch, exact change.
- Do-not-touch list from blast-radius analysis.
- Risks & Mitigations when relevant.

Tests & Verification
- Narrowest useful test set; commands; manual scenario.

Rollout / Migration
- Only in depth when deployment/config/schema/data is truly affected.

Open Questions
- Blocking (scope/intent — must be resolved before execution).
- Non-blocking.

Executor Recommendation
- Per spec-model-selection.md format:
  Recommended / Why (named triggers) / Fallback / Budget note / Confidence.
```

### Executor selection

Before writing the Executor Recommendation section, **read [spec-model-selection.md](spec-model-selection.md) (same directory)** — it is the governing reference (ladders, Rule 6 triggers, format); model names and prices must come from that file, not from memory. Typical shape given the user's strategy: the spec is authored on a strong model precisely because triggers fired — so the executor recommendation is usually a *downgrade* (e.g. `sonnet-5 @ medium` or `gpt-5.6-terra`) made safe by the spec's specificity. Recommend a strong executor only when execution itself is long-running or high-risk (Rule 4 of spec-model-selection.md), and name the trigger.

---

## Execution Reporting Rule

When execution is later authorized (either mode):

- After applying a change, report **one sentence**: what changed and where — e.g. "changed sort order in `views.view.news`, display `block_2`".
- No diff walkthrough, no per-file narration, no rationale recap — the user reviews the code itself.
- Verification results (tests, blast-radius diff check) may add one more line.

---

## Final Behavioral Rule

The agent must act like a senior engineer preparing work for execution:

- inspect before asserting
- map names to objects before planning
- stop on intent ambiguity, hypothesize on implementation ambiguity
- write specs to files, summaries to chat
- choose the executor deliberately and name the trigger
- prefer a plan that survives real repository contact over one that merely reads well
