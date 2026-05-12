---
name: semantic-memory
description: Long-term semantic memory of the project for mcp server-memory. Use when the agent needs to understand the history of changes, architectural reasons, constraints, terminology, module boundaries, as well as when entering a task, dealing with uncertainty, before an architectural change, and before closing a task to distill durable knowledge.
---

# Semantic Memory

## Goal

Maintain a long-lived project memory as a biography and DNA of the system.

Store meaning, not code diffs:
- what problems have already occurred
- what decisions were made and why
- what constraints are currently in effect
- what terms, contracts, and standards are considered canonical
- what pivots, reverts, and incidents have already changed the project's course

Consider memory to be that which should survive chat clearance and the loss of local context.

## Memory Operational Model

Use a two-layer model.

### 1. Human Semantic Classes
Use them as the core philosophy of memory:
- `invariant` — persistent constraints and standards
- `milestone` — milestones and events that change the project's world
- `decision` — explanation of choices and architectural reasons

### 2. Graph Operational Entities
Use them as the working ontology of the graph:
- `project`
- `module`
- `capability`
- `problem`
- `decision`
- `invariant`
- `milestone`
- `incident`
- `experiment`
- `contract`
- `glossary-term`
- `open-question`

Do not strictly limit yourself to only the three top-level classes if the task requires a more precise entry in the graph.

## Main Rule

Prefer the memory of the project's world over the memory of the code.

Do not write:
- "added function x"
- "renamed file y"
- "created branch feature/z"

Write:
- what problem the change solved
- what new mechanism appeared
- what constraint is now in effect
- why this specific path was chosen
- what became the norm, and what turned out to be a mistake

## Mandatory Dimensions of Every Durable Record

Every memory record should ideally answer the following questions:
- `what` — what it is
- `why` — why it appeared
- `scope` — where it applies
- `status` — whether it is currently active
- `since` — since when this is true
- `source` — from which task, PR, ADR, release, or incident it stems
- `aliases` — what other words might be used to search for it

Do not store these fields as one large blob.
Avoid mixing them up; break them down into atomic observations.

## Observations Style

Write observations as short, atomic, search-friendly facts.

Good:
- `status: active`
- `scope: module/auth`
- `why: prevent session divergence after ssr refresh`
- `tradeoff: less client flexibility but stronger consistency`
- `aliases: auth login sign-in session cookie`

Bad:
- a long paragraph containing eight different meanings
- mixing reason, status, scope, and historical context in one line
- phrasing without terms that will be used for searching later

Always include words that people might intuitively use to search for this:
- module names
- capability names
- domain terms
- technical synonyms
- old and new names of a concept, if a rename occurred

## Entity Naming

Use stable canonical names.

Prefer the following patterns:
- `project/retro-futurism`
- `module/auth`
- `module/rendering`
- `capability/session-management`
- `problem/session-desync-on-refresh`
- `decision/http-only-session-cookie`
- `invariant/heading-scale`
- `milestone/release-0.9.0`
- `incident/session-cache-revert`
- `contract/post-schema-v2`
- `glossary-term/retro-card`

Do not create near-identical entities with different names if they represent the same semantic object.

## Relation Vocabulary

Use relation types as short, active verb links.

Prefer:
- `belongs_to`
- `affects`
- `depends_on`
- `constrains`
- `motivates`
- `introduces`
- `implements`
- `stabilizes`
- `documents`
- `supersedes`
- `reverts`
- `aliases`
- `uses`
- `breaks`
- `replaces`

Choose a relation type so that the connection reads as a simple statement:
- `problem/session-desync-on-refresh` `motivates` `decision/http-only-session-cookie`
- `decision/http-only-session-cookie` `constrains` `module/auth`
- `milestone/release-0.9.0` `introduces` `decision/http-only-session-cookie`
- `incident/session-cache-revert` `reverts` `experiment/client-side-session-cache`

## What Must Be Saved

Save memory if the task generated at least one of the following:
- a new durable `decision`
- a new or modified `invariant`
- a new or modified `contract`
- a `milestone` that alters the project's world
- an `incident`, `revert`, or `pivot`
- a new canonical term or redefinition of a term
- a new stable `problem` that is likely to resurface

## What Usually Should Be Saved

Save if the information:
- is hard to reconstruct from the current code
- explains architectural weirdness or oddities
- limits or constrains future changes
- captures a tradeoff
- describes a repeatable failure
- describes an experiment that is likely to be revisited
- will be useful a month from now without access to the current chat context

## What Should Not Be Saved

Do not save:
- raw diffs
- local intermediate implementation steps
- temporary guesses
- debug noise without long-term conclusions
- branch names by themselves
- facts that are obvious from reading the code's current state for a few seconds

## Worth-Saving Heuristics

Ask yourself five questions before writing to memory:
1. Will this be useful after the chat is cleared?
2. Is this hard to reconstruct from code, git, or tests?
3. Will this constrain future changes?
4. Does this explain why the architecture looks the way it does?
5. Does this capture a mistake, revert, pivot, or an important tradeoff?

If the answer is "yes" to at least two questions, the record is usually worth saving.
If the answer is "yes" to three or more questions, the record almost certainly must be saved.

## Retrieval Philosophy

Do not drag the entire memory into context constantly.
Dive into it only when there is a semantic gap.

Search memory by intent, not just by entity type.

### Mode 1: Constraint Search
Use before making a system change.

Search for:
- `invariant`
- `contract`
- active `decision`

Ask yourself:
- what constraints might I violate?
- what contracts cannot be broken?
- what decisions have already constrained the acceptable design?

### Mode 2: Rationale Search
Use when you do not understand the current structure.

Search for:
- `problem`
- `decision`
- `incident`
- `superseded` and `reverted` history

Ask yourself:
- why is the module structured this way?
- what problem does the current form protect against?
- what simpler path was already rejected?

### Mode 3: History Search
Use when entering a task on a familiar topic.

Search for:
- `milestone`
- `incident`
- `experiment`

Ask yourself:
- what has already been changed regarding this topic?
- what has already been tried?
- where was there already a revert or a change of course?

### Mode 4: Vocabulary Search
Use when terminology is floating or ambiguous.

Search for:
- `glossary-term`
- `aliases`
- canonical names for module and capability

Ask yourself:
- how is this properly called in this project?
- is there an old and a new name for the same concept?
- what terms are considered canonical in code and discussions?

## Query Strategy for search_nodes

Formulate queries shortly and pragmatically.
Combine:
- scope terms
- problem terms
- domain vocabulary
- canonical names
- aliases
- status words if necessary

Examples of good queries:
- `auth session refresh`
- `decision cookie session`
- `problem heading inconsistency`
- `invariant typography headings`
- `incident cache revert`
- `contract post schema`
- `glossary retro card`

Do not search just by an abstract type like `decision`.
Append a topic, module, or problem.

## Tool Usage Policy

### When Entering a Task
First, define the expected `scope`.
Then perform a few targeted searches using `search_nodes`:
- by module or capability
- by problem
- by constraints
- by history of similar changes

After getting relevant hits, open specific entities using `open_nodes`.

Do not use `read_graph` unless a broad revision of all knowledge is needed.
Prefer targeted extraction.

### When Facing Uncertainty
Stop and check memory if:
- the module's structure looks weird
- there's a temptation to simplify something that might have had a hidden reason
- you need to invent a new standard
- there are several plausible architectural paths
- terminology is floating/ambiguous

### Before Closing a Task
You must execute a semantic checkpoint:
1. `update timeline` — create or update a `milestone`
2. `extract invariants` — extract new or refined standards
3. `persist decisions` — record accepted decisions and reasons
4. `record incidents` — document reverts, pivots, failure modes, or hidden lessons
5. `link graph` — link new entities with problems, modules, contracts, and milestones
6. `mark status` — tag what is active, superseded, reverted, or experimental

## Status Policy

Every durable entity must have a clear status.

Prefer:
- `status: active`
- `status: experimental`
- `status: superseded`
- `status: reverted`
- `status: deprecated`
- `status: open`

Do not leave old decisions as if they are still relevant.
If a new decision replaces an old one, mark the old one as `superseded` and link them with the `supersedes` relation type.
If a decision is canceled, mark it as `reverted` and create a corresponding `incident` or `milestone`.

## Scope Policy

Explicitly tie every record to an area of effect (scope).

Prefer scopes like:
- `scope: project`
- `scope: module/auth`
- `scope: module/rendering`
- `scope: capability/session-management`
- `scope: contract/post-schema-v2`

If a record affects multiple areas, note this with separate observations or relations.
Do not leave the scope implicit.

## Update Policy

Before creating a new entity, double-check if an entity with a similar meaning already exists.

If the meaning already exists:
- do not create a duplicate
- add new observations
- update the status
- add a `supersedes`, `reverts`, or `replaces` relation if there was a change of course

Prefer the evolution of memory rather than its sprawling with duplicates.

## Decision Policy

Every durable `decision` should ideally contain:
- `what`
- `why`
- `scope`
- `status`
- `chosen`
- `rejected`
- `tradeoff`
- `since`
- `source`
- `aliases`

Do not log a decision without a problem, if the problem is known.
Whenever possible, link a `decision` to a `problem` using the `motivates` relation type.

## Invariant Policy

Consider an `invariant` to be any rule that must constrain future changes.

Typical invariants:
- code standards important to the project
- design tokens and naming conventions
- module composition rules
- forbidden dependencies
- API and schema compatibility rules
- canonical patterns for repeatable tasks

If a rule is merely being tested, do not call it an invariant.
Create an `experiment` or a `decision` with an `experimental` status.

## Milestone Policy

Consider a `milestone` as a change in the project's world, rather than just a fact of activity.

Good milestones:
- release
- transition to a new architectural model
- completion of a major migration
- change of a canonical interface
- significant revert
- ending an experimental period and stabilizing a new path

Bad milestones:
- minor refactor without long-term semantic meaning
- a local file edit
- an ordinary branch without a semantic impact

## Incident Policy

Treat an `incident` as valuable memory, not noise.

Create an `incident` if:
- expectations were violated
- a revert occurred
- hidden coupling surfaced
- a decision led to regressions
- an experiment proved its unsuitability
- the team pivoted due to a real problem

Store not just the fact of the failure, but the lesson:
- what exactly went wrong
- what this tells us about the system
- how this affects future decisions

## Glossary Policy

Create a `glossary-term` if:
- there's a specialized term in the project
- an old and a new name are competing
- the same concept is named differently across code, docs, and discussions
- correct terminology affects the quality of searches and design decisions

Use aliases aggressively.
Terminology is part of memory, not just cosmetics.

## Minimal Write Checklist

Before writing, verify:
- does the entity have a clear canonical name?
- is the `scope` clear?
- is the `status` clear?
- is the reason or problem logged?
- is there a relation to a module, capability, problem, milestone, or contract?
- are observations formulated atomically?
- are terms and aliases added by which this will be searched later?

## Examples of Good Memory

### Problem
Entity:
- `problem/session-desync-on-refresh`

Observations:
- `status: active`
- `scope: module/auth`
- `what: session state diverges after server-side refresh`
- `impact: creates inconsistent logged-in state across client and server`
- `since: 2026-03`
- `aliases: auth refresh session mismatch ssr session desync`

### Decision
Entity:
- `decision/http-only-session-cookie`

Observations:
- `status: active`
- `scope: module/auth`
- `what: use http-only cookie as canonical session store`
- `why: prevent client-server divergence after refresh`
- `chosen: cookie-backed session`
- `rejected: localstorage session cache`
- `tradeoff: less client flexibility but stronger consistency and security`
- `since: 2026-03`
- `source: adr-007 pr-142`
- `aliases: auth login sign-in cookie session`

Relations:
- `problem/session-desync-on-refresh` `motivates` `decision/http-only-session-cookie`
- `decision/http-only-session-cookie` `constrains` `module/auth`

### Invariant
Entity:
- `invariant/heading-scale`

Observations:
- `status: active`
- `scope: module/rendering`
- `what: all heading sizes must derive from shared heading scale tokens`
- `why: prevent renderer and export divergence`
- `since: 2026-03`
- `aliases: heading typography title scale`

Relations:
- `invariant/heading-scale` `constrains` `module/rendering`

### Incident
Entity:
- `incident/client-session-cache-revert`

Observations:
- `status: active`
- `scope: module/auth`
- `what: reverted client-side session cache experiment`
- `why: created stale auth state after refresh and tab sync issues`
- `lesson: client cache must not become canonical session source`
- `since: 2026-03`
- `source: pr-143`
- `aliases: auth cache revert stale session`

Relations:
- `incident/client-session-cache-revert` `reverts` `experiment/client-side-session-cache`
- `incident/client-session-cache-revert` `stabilizes` `decision/http-only-session-cookie`

## Default Behavior

For any new task:
1. determine the scope
2. perform a constraint search
3. perform a rationale search
4. if necessary, perform a history search
5. if terminology is floating, perform a vocabulary search
6. only then make a new architectural decision

Before closing a task:
1. distill the meaning
2. record durable knowledge
3. update the status of old entities if the truth has changed
4. link everything with relation edges
5. do not leave memory in a half-true state

## Final Rule

Write to memory in such a way that a future agent, reading it a month from now without access to this chat, will be able to answer three questions:
- what is important here?
- why is it this way here?
- what must not be broken, repeated, or forgotten?
