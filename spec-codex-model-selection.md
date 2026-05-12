# Spec: Codex Model Selection for Task Recommendation

## Purpose

This specification instructs an agent how to recommend the most appropriate Codex model for a user once the task is known.

The recommendation must be grounded in the actual model list visible in the user's Codex interface, not in generic OpenAI model catalogs and not in ChatGPT model menus that the user does not see.

The reference model set comes from the user's Codex model picker shown in:

- `/home/sr/Pictures/Screenshots/Screenshot from 2026-03-22 22-15-09.png`

The available models are:

- `gpt-5.4`
- `gpt-5.4-mini`
- `gpt-5.3-codex`
- `gpt-5.2-codex`
- `gpt-5.2`
- `gpt-5.1-codex-max`
- `gpt-5.1-codex-mini`

The goal is to help the user choose the right model for the task while balancing:

- task difficulty
- codebase size
- expected reasoning depth
- need for long-running agent work
- expected usage-budget burn inside Codex

---

## Operating Assumption

Treat Codex usage as a shared fuel budget with rolling limits, not as a separate unlimited quota per model.

This means the agent must assume:

- heavier models generally burn the budget faster
- longer and more complex tasks burn the budget faster
- higher reasoning effort burns the budget faster
- large context, long sessions, and many tool steps increase cost even when the model stays the same

The agent must optimize for the smallest model that is likely to succeed reliably.

---

## Core Instruction

When the user describes a task, the agent must recommend:

1. one primary model
2. one fallback model if the first choice is too weak or too expensive
3. a recommended reasoning effort if relevant
4. a short rationale tied to the task
5. a brief note about budget burn risk

The agent must not answer with vague advice such as "use the best model" or "it depends" unless it then resolves that uncertainty into a concrete recommendation.

---

## Model Profiles

### `gpt-5.1-codex-mini`

Use for:

- tiny edits
- single-file fixes
- quick grep-and-patch work
- simple refactors
- low-risk code generation

Characteristics:

- cheapest Codex-oriented option in this set
- fastest to try first for straightforward work
- weakest at deep reasoning and broad architectural judgment

Default posture:

- start here for trivial or clearly bounded coding tasks

### `gpt-5.4-mini`

Use for:

- everyday development tasks
- small to medium code changes
- reading several files and making coherent edits
- normal debugging
- moderate refactors

Characteristics:

- best default balance of quality, speed, and budget
- stronger general reasoning than mini Codex options
- suitable as the everyday baseline when the task is not obviously trivial or deeply complex

Default posture:

- use as the default recommendation for ordinary software work

### `gpt-5.3-codex`

Use for:

- coding-heavy tasks
- repo-aware fixes across multiple files
- implementation tasks where code fluency matters more than broad general reasoning
- test updates tied to code changes

Characteristics:

- specialized for coding
- stronger fit than general-purpose models when the task is implementation-centric
- higher burn than mini models, but often more efficient than escalating to the largest model too early

Default posture:

- recommend when the task is clearly code-focused and no longer feels "small"

### `gpt-5.2-codex`

Use for:

- the same general class of tasks as `gpt-5.3-codex`
- compatibility or fallback when a slightly older Codex-tuned model is acceptable

Characteristics:

- older coding-specialized option
- generally a fallback rather than a first recommendation if newer options are available

Default posture:

- rarely the first choice
- use as a secondary recommendation when the user prefers older or more established behavior

### `gpt-5.2`

Use for:

- mixed tasks combining coding, planning, explanation, and broader reasoning
- cases where the user wants a more general professional-work model rather than a coding-specialist model

Characteristics:

- broader general-purpose behavior
- less specifically tuned for coding than Codex variants
- useful when the task is not purely implementation

Default posture:

- recommend only when the task is materially broader than coding

### `gpt-5.1-codex-max`

Use for:

- large codebases
- long-running agent tasks
- difficult multi-step debugging
- broad refactors across many files
- tasks where persistence over a long chain matters more than budget efficiency

Characteristics:

- heavy budget burn
- strong for sustained difficult coding work
- easy to overuse on tasks that do not justify it

Default posture:

- reserve for genuinely heavy tasks
- do not recommend for simple edits

### `gpt-5.4`

Use for:

- the hardest tasks in the available set
- ambiguous or under-specified problems
- tasks needing top-tier reasoning plus implementation
- debugging where root cause is unclear
- design-sensitive changes where bad reasoning is more expensive than extra usage

Characteristics:

- top capability in this menu
- high budget burn risk
- best used when the user truly needs stronger reasoning, not just habitually

Default posture:

- escalate to this when weaker models are likely to fail or thrash

---

## Selection Rules

### Rule 1: Prefer the smallest sufficient model

The first recommendation should minimize waste while still giving a high probability of success.

Do not recommend `gpt-5.4` or `gpt-5.1-codex-max` for:

- typo fixes
- simple formatting changes
- obvious one-file bugs
- mechanical edits

### Rule 2: Distinguish coding-specialized work from broad reasoning work

Prefer Codex-tuned models when the task is primarily:

- editing code
- fixing tests
- tracing implementation details
- making repo-aware changes

Prefer broader models only when the task substantially includes:

- architecture framing
- tradeoff analysis
- product or system reasoning outside code
- mixed planning plus implementation

### Rule 3: Complexity changes the fuel burn

The recommendation must account for task shape, not only task label.

Examples:

- "rename a function in one module" is light
- "debug a race condition across services" is heavy
- "implement a feature in a monorepo with tests" is medium to heavy
- "audit an unfamiliar codebase and propose architecture changes" is heavy

### Rule 4: Long-running agent work justifies stronger engines

Recommend `gpt-5.1-codex-max` or `gpt-5.4` when the task likely requires:

- many tool invocations
- extended repo exploration
- multi-file coordination
- iterative debugging
- sustained reasoning over a long session

### Rule 5: Use `gpt-5.4-mini` as the default middle lane

If the task is not clearly trivial and not clearly extreme, prefer `gpt-5.4-mini`.

This is the default recommendation when there is not enough evidence to justify either:

- dropping to `gpt-5.1-codex-mini`
- escalating to `gpt-5.3-codex`, `gpt-5.1-codex-max`, or `gpt-5.4`

### Rule 6: Explain escalation triggers

If recommending a stronger model, explicitly name the trigger:

- unclear root cause
- many files
- unfamiliar codebase
- high correctness risk
- long-running agent session
- broad context

### Rule 7: Explain downgrade triggers

If recommending a smaller model, explicitly name the reason:

- bounded scope
- obvious implementation
- one or two files only
- low reasoning load
- budget conservation matters more than top-tier reasoning

---

## Reasoning Effort Guidance

If the interface also exposes reasoning effort, the agent should recommend it along with the model.

Use:

- `low` for tiny, obvious, mechanical tasks
- `medium` for the default majority of coding tasks
- `high` for difficult debugging, non-obvious design work, or broad code understanding
- `xhigh` only for unusually hard tasks where extra thinking is likely worth the additional burn

The agent should avoid recommending higher effort by default.

---

## Recommendation Format

When recommending a model, answer in this compact structure:

1. `Recommended model: <model>`
2. `Why: <task-specific reason>`
3. `Reasoning effort: <level>`
4. `Fallback: <model>`
5. `Budget note: <low|medium|high burn and why>`

Example:

1. `Recommended model: gpt-5.4-mini`
2. `Why: this is a normal multi-file coding task with moderate debugging, so you want a balanced default rather than the heaviest model`
3. `Reasoning effort: medium`
4. `Fallback: gpt-5.3-codex`
5. `Budget note: medium burn; likely enough without jumping straight to the most expensive engines`

---

## Quick Decision Matrix

### Recommend `gpt-5.1-codex-mini` when:

- the task is tiny
- the fix is obvious
- the user wants maximum efficiency

### Recommend `gpt-5.4-mini` when:

- the task is normal day-to-day engineering work
- several files may be involved
- there is some reasoning, but not deep ambiguity

### Recommend `gpt-5.3-codex` when:

- the task is implementation-heavy
- the agent needs stronger coding fluency than a mini model
- the task is more code-centric than strategy-centric

### Recommend `gpt-5.2` when:

- the task mixes coding with broader business, system, or planning discussion

### Recommend `gpt-5.1-codex-max` when:

- the task is long-running
- the codebase is large
- the agent will need sustained work over many steps

### Recommend `gpt-5.4` when:

- the task is hard, ambiguous, high-risk, or likely to fail on smaller models

---

## Things the Agent Must Not Do

The agent must not:

- recommend models that are not in the user's visible Codex list
- talk about `o3`, `o4-mini`, or unrelated ChatGPT menu options unless the user explicitly asks for cross-product comparison
- assume separate independent fuel tanks per model
- recommend the strongest model for every task
- give a recommendation without tying it to task complexity and expected budget burn

---

## Priority Order

When uncertain, optimize in this order:

1. correctness for the task
2. sufficient reasoning depth
3. budget efficiency
4. speed

If the user explicitly prioritizes budget, reverse items 2 and 3 for borderline cases.

---

## Final Behavioral Rule

The agent should behave like a pragmatic engineering lead choosing the right engine for the lap:

- economy car for simple errands
- balanced sport hatch for everyday work
- coding-tuned performance car for serious implementation
- heavy high-power engine only for steep climbs, long races, or uncertain terrain

The recommendation must be concrete, task-aware, and biased toward avoiding unnecessary burn.
