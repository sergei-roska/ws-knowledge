# Spec: Skill Evaluation and Rewrite

## Purpose

This specification defines how to evaluate a draft skill and how to rewrite it into a production-ready skill.

It was derived from the evaluation and rewrite of the **Semantic Memory** skill for an MCP `server-memory` setup based on a graph store.

The goal is not only to judge whether the draft is "good" or "bad", but to transform it into a skill that is:

- operationally useful for an agent
- aligned with the actual storage and retrieval model
- easy to trigger and easy to follow
- durable under long-term project use
- compact enough to guide behavior without becoming noise

---

## Task Definition

The task has two phases:

1. **Evaluate the draft skill**
   - identify strengths
   - identify ambiguity
   - identify missing operational rules
   - identify mismatch between philosophy and execution
   - identify parts that are elegant conceptually but weak for retrieval or agent behavior

2. **Rewrite the draft skill**
   - preserve the core philosophy when it is strong
   - add missing operational structure
   - remove vagueness that would cause inconsistent agent behavior
   - make the skill more searchable, more executable, and more robust over time

---

## Input

The input is a draft skill or draft design note that usually contains some combination of:

- purpose or philosophy
- categories or ontology
- lifecycle rules
- retrieval rules
- writing principles
- examples
- tool assumptions

The input may be elegant and insightful but still insufficiently formalized for an agent.

---

## Output

The output of evaluation and rewrite must produce:

1. a diagnosis of the draft
2. a list of preserved ideas
3. a list of missing pieces
4. a rewritten skill text
5. a compact operational version if needed
6. explicit rules for retrieval, persistence, and update behavior

---

## Evaluation Principles

### 1. Preserve the author's core philosophy

Do not rewrite merely for stylistic preference.

If the draft already contains a strong conceptual model, preserve it.
The rewrite should strengthen execution, not erase identity.

In the Semantic Memory case, the original triad was strong and worth preserving:

- `Invariant`
- `Milestone`
- `Decision`

These were treated as the human semantic layer of memory rather than discarded.

### 2. Evaluate from the agent's point of view, not the author's point of view

A draft may be understandable to its author while still being weak for an agent.

The key question is not:
- "Does this read well to a human?"

The key question is:
- "Will an agent know what to search, what to persist, and what to ignore?"

### 3. Prefer operational clarity over literary elegance

Poetic or philosophical language is useful only if it improves judgment.
If it hides execution rules, it must be translated into operational guidance.

### 4. Evaluate retrieval and write behavior separately

A memory skill has two distinct problems:

- **What should be written**
- **What should be searched and when**

A draft often handles one better than the other.
A rewrite must cover both.

### 5. Judge the skill against the actual storage model

Do not evaluate memory as an abstract concept only.
Evaluate it against the real backend model.

For Semantic Memory, the relevant assumptions were:

- graph-based memory
- entity-centered storage
- relation edges
- atomic observations
- text-based retrieval through search

This means a philosophically good memory model can still fail if it does not help search.

### 6. Prefer durable knowledge over local implementation history

A memory skill should preserve knowledge that survives chat reset.
It should not become a noisy duplicate of code, git history, or implementation diffs.

---

## Main Evaluation Questions

### A. Is the philosophy coherent?

Check whether the draft has a stable underlying worldview.

Questions:
- Does it distinguish durable knowledge from ephemeral work?
- Does it define what counts as project memory?
- Does it explain why memory exists?
- Does it avoid turning memory into a changelog clone?

### B. Is the ontology sufficient?

Check whether the entity categories are enough for real project reasoning.

Questions:
- Can the model represent problems?
- Can it represent constraints?
- Can it represent incidents and reversals?
- Can it represent terminology?
- Can it distinguish stable rules from experiments?

A draft often has elegant top-level categories but lacks operational entities needed for retrieval.

### C. Is retrieval well-defined?

Check whether the draft tells the agent **what to search for**, **when**, and **why**.

Questions:
- Does the agent search only at task entry, or also during uncertainty?
- Are there retrieval modes such as constraints, rationale, history, and vocabulary?
- Are search queries grounded in actual likely terms?
- Does the draft help the agent bridge semantic gaps?

### D. Is persistence well-defined?

Check whether the draft tells the agent what must be saved and what must not.

Questions:
- Are there must/should/may/never rules?
- Is there a durability threshold?
- Is there protection against noisy writes?
- Is there a rule for capturing pivots, reverts, and failures?

### E. Is time handled honestly?

Check whether the draft handles truth drift.

Questions:
- Can the model express that something is no longer true?
- Can it mark old decisions as superseded?
- Can it capture reverts and pivots as first-class knowledge?

A memory that only stores positive assertions but cannot mark change becomes misleading.

### F. Is scope explicit?

Check whether the draft makes it clear where each memory applies.

Questions:
- Project-wide or module-local?
- Capability-level or contract-level?
- One module or several?

Without scope, retrieval becomes noisy and future reasoning becomes unsafe.

### G. Is the skill search-friendly?

Check whether the wording supports future retrieval.

Questions:
- Are observations atomic?
- Are aliases encouraged?
- Are canonical names stable?
- Are likely query terms present?

This matters especially for graph memory backed by text search.

### H. Is the skill compact enough to be followed?

A long skill may be insightful but hard to use.

Questions:
- Does the skill separate philosophy from execution?
- Can a compact operational version be extracted?
- Are the core rules visible quickly?

---

## Rewrite Principles

### 1. Keep the semantic core, add the missing skeleton

The rewrite should preserve the original meaning while adding missing operational structure.

In Semantic Memory, the semantic core was:
- `Invariant`
- `Milestone`
- `Decision`

The missing operational skeleton was:
- `Problem`
- `Scope`
- `Status`
- `Aliases`
- concrete retrieval modes
- update rules
- duplicate prevention

### 2. Convert abstract philosophy into agent decisions

Every philosophical statement should be transformed into at least one executable rule.

Example:
- philosophical statement: memory stores meaning, not code
- executable rule: do not persist raw diffs, temporary implementation steps, or branch names alone

### 3. Add missing dimensions that control retrieval quality

For Semantic Memory, the critical missing dimensions were:

- **Problem** — why the decision exists
- **Scope** — where it applies
- **Status** — whether it is still true
- **Aliases** — how it can be found later

These are not cosmetic additions.
They directly improve retrieval quality and reduce false memory confidence.

### 4. Distinguish semantic classes from graph entities

A draft may define high-level conceptual classes that are useful for humans.
That does not mean they are sufficient as storage entities.

Rewrite rule:
- preserve human semantic classes
- expand graph entities where agent reasoning requires more precision

### 5. Add write gates

The agent should not rely on taste alone when deciding what to store.

The rewrite should add explicit persistence thresholds such as:
- must persist
- should persist
- must not persist

This gives the agent controlled freedom instead of rigid overformalization or chaotic writing.

### 6. Add retrieval modes by intent

A good memory skill should not tell the agent only **what exists**.
It should tell the agent **what kind of question maps to what kind of search**.

For Semantic Memory, the retrieval modes were rewritten as:
- constraint search
- rationale search
- history search
- vocabulary search

### 7. Make observations atomic and searchable

The rewrite should favor short, retrieval-friendly observations over dense prose.

Preferred format:
- one fact per observation
- explicit `status`
- explicit `scope`
- explicit `why`
- explicit `aliases`

### 8. Add update semantics, not only create semantics

A weak draft often focuses on writing new memory.
A stronger rewrite must also cover:
- status changes
- supersession
- reverts
- replacements
- avoiding duplicates

### 9. Make failure part of memory

A mature project memory must store:
- incidents
- reverts
- failed experiments
- lessons
- course corrections

Do not treat failures as noise.
Treat them as high-value historical and architectural knowledge.

### 10. Separate full version and compact version when needed

If the philosophy is rich, keep it.
But also derive a shorter operational version that an agent can follow with less overhead.

Recommended pattern:
- full version for philosophy and examples
- compact version for daily execution

---

## Specific Rules Used in the Semantic Memory Rewrite

These are the exact rules that guided the rewrite.

### Rule 1. Do not destroy a strong model just because it is incomplete

The original semantic triad was preserved because it was conceptually strong.
The rewrite added missing layers instead of replacing the original philosophy.

### Rule 2. Add what retrieval needs, not what sounds impressive

Every added concept had to justify itself through future usefulness.

`Problem`, `Scope`, `Status`, and `Aliases` were added because they improve:
- search precision
- truth maintenance
- explanation quality
- future recall

### Rule 3. Optimize for future search, not only current readability

The skill was rewritten so that future queries would have lexical anchors.
This is why atomic observations, canonical names, and aliases were emphasized.

### Rule 4. Make time visible

The rewrite explicitly introduced status and update logic because durable memory without temporal truth management becomes misleading.

### Rule 5. Make reverts and pivots first-class memories

The rewrite treated rollback, supersession, and course change as valuable knowledge rather than embarrassing leftovers.

### Rule 6. Tie every important memory to a scope

The rewrite avoided floating statements.
A memory should say whether it applies to:
- the whole project
- a module
- a capability
- a contract
- a bounded area of the system

### Rule 7. Separate project-world facts from implementation facts

A fact deserved memory when it changed the project world, not merely the local code surface.

### Rule 8. Prefer rules that survive context loss

Every retained rule had to answer this test:
- would this still help a future agent one month later without this chat?

### Rule 9. Convert elegant prose into executable checks

Whenever the draft used a conceptual formulation, the rewrite tried to express it as:
- a checklist
- a persistence rule
- a retrieval mode
- a status rule
- a naming rule

### Rule 10. Preserve freedom through bounded heuristics

The rewrite did not force the agent into a rigid schema for every case.
Instead, it gave controlled freedom through heuristics such as:
- worth-saving questions
- must/should/must-not persistence gates
- retrieval by intent

---

## Draft Diagnosis Template

Use this template when analyzing a draft skill.

### Strengths
- Which ideas are conceptually strong?
- Which parts should definitely be preserved?

### Gaps
- What is missing for execution?
- What is missing for retrieval?
- What is missing for status, time, scope, or update behavior?

### Risks
- Where could the agent become inconsistent?
- Where could it over-write noisy memory?
- Where could it fail to retrieve the right thing?
- Where could truth become stale?

### Rewrite Actions
- What should be preserved as-is?
- What should be clarified?
- What should be added?
- What should be shortened?
- What should move into a compact operational version?

---

## Rewrite Procedure

1. Read the draft as philosophy.
2. Extract the semantic core.
3. Identify missing operational dimensions.
4. Identify likely retrieval failures.
5. Identify likely persistence failures.
6. Add rules for scope, status, and update semantics.
7. Add must/should/must-not write gates.
8. Add intent-based retrieval modes.
9. Add naming and observation rules.
10. Produce a full rewritten version.
11. Produce a compact operational version if the full one is too heavy.

---

## Acceptance Criteria for the Rewritten Skill

A rewritten skill is acceptable when:

- it preserves the strong ideas of the original draft
- it tells the agent what to search and when
- it tells the agent what to persist and what to ignore
- it prevents obvious duplication and stale truth
- it makes failures, reverts, and pivots representable
- it defines scope and status explicitly
- it improves searchability through canonical names and aliases
- it can be followed in day-to-day execution

---

## Recommended Use of This Spec

Use this spec when:
- reviewing a draft skill before adoption
- rewriting a philosophical skill into an operational one
- evaluating whether a memory skill matches its backend model
- checking whether a long skill should be split into full and compact versions
- reviewing semantic memory, project biography, ADR-like memory, or graph-based project context skills

---

## Final Standard

A skill rewrite is successful when it does not merely make the text cleaner.
It must make the agent more reliable.

For semantic memory specifically, the final test is simple:

Can a future agent, without this chat, reliably answer:
- what matters here
- why it is this way
- what must not be broken, repeated, or forgotten

If yes, the rewrite succeeded.
