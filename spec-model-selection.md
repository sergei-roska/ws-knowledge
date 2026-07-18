# Spec: Model Selection and Escalation Recommendation

## Purpose

This specification instructs an agent how to recommend the most appropriate model — and, where relevant, reasoning effort — for a task, across the two provider ladders the user actually works with:

- **OpenAI Codex** — the GPT-5.6 family (Luna, Terra, Sol)
- **Claude Code** — Sonnet 5 at effort levels `medium` / `xhigh` / `max`, and Opus 4.8

The recommendation must be grounded in these two ladders only, not in generic model catalogs or menus the user does not see.

**Out of scope: Fable.** Claude Fable 5 exists in the user's toolset but is reserved for the user's own discretion (strategy work, top-tier spec authoring). The agent must never recommend Fable; at most it may note "this exceeds the Opus/Sol tier" and leave the decision to the user.

Model facts (pricing, benchmarks) in this spec are as of **July 2026**. When they look stale, verify before relying on exact numbers; the selection rules survive pricing changes.

---

## Operating Assumption

Treat usage as a shared fuel budget with rolling limits per provider, not as an unlimited quota per model.

- heavier models and higher effort burn the budget faster
- long sessions, large context, and many tool steps increase burn even on the same model
- the two providers are separate tanks; recommending a provider switch is a valid load-balancing move when the ladders are equivalent for the task

The agent must optimize for the **smallest model and lowest effort likely to succeed reliably**.

---

## The Two Ladders

### OpenAI Codex — GPT-5.6 family

| Model | Tier | Price (in/out per 1M) | Use for |
|---|---|---|---|
| `gpt-5.6-luna` | lightweight | $1 / $6 | tiny edits, single-file fixes, mechanical changes, high-volume simple tasks |
| `gpt-5.6-terra` | balanced | $2.50 / $15 | everyday development: multi-file edits, normal debugging, moderate refactors |
| `gpt-5.6-sol` | flagship | $5 / $30 | hardest problems: unclear root cause, complex coding, design-sensitive changes |

The number (5.6) is the generation; Sol/Terra/Luna are durable capability tiers that advance on their own cadence.

### Claude Code — Sonnet 5 + Opus 4.8

Claude's ladder has two dimensions: model and reasoning effort. The user's working ladder:

| Rung | Price (in/out per 1M) | Use for |
|---|---|---|
| `sonnet-5` @ `medium` | $2 / $10 | the default for all ordinary work |
| `sonnet-5` @ `xhigh` | $2 / $10 (more thinking tokens) | harder debugging, non-obvious design, broad code understanding |
| `sonnet-5` @ `max` | $2 / $10 (heavy thinking burn) | hardest tasks still worth trying on Sonnet before switching model |
| `opus-4.8` | $5 / $25 | unclear root cause, cross-layer work, high correctness risk, long agentic sessions |

Raising effort keeps the per-token price but burns more thinking tokens; it is the cheap escalation step before changing the model.

### Cross-provider equivalence

Grounding: Sonnet 5 and Terra are effectively tied on SWE-bench Pro (63.2% vs 63.4%, vendor-reported); Opus 4.8 and Sol share the $5-input flagship tier, with Opus stronger on most agentic-coding profiles and Sol stronger on terminal-agent benchmarks.

| Task weight | Codex | Claude Code |
|---|---|---|
| trivial / mechanical | `gpt-5.6-luna` | `sonnet-5` @ `medium` (no cheaper rung in this ladder) |
| everyday engineering | `gpt-5.6-terra` | `sonnet-5` @ `medium` |
| hard but bounded | `gpt-5.6-terra` (or early Sol) | `sonnet-5` @ `xhigh` → `max` |
| hardest / ambiguous / high-risk | `gpt-5.6-sol` | `opus-4.8` |
| beyond flagship | — | user's discretion (Fable) — do not recommend |

Note the asymmetry: Claude's ladder has intermediate effort rungs, Codex's does not. On Claude, escalate effort before escalating model; on Codex, the only move is the next tier.

---

## Core Instruction

When the user describes a task (or an intake procedure has analyzed one), the agent must recommend:

1. one primary model (with effort level, if Claude)
2. one fallback
3. a short rationale tied to the task
4. a budget-burn note

The agent must not answer with "use the best model" or "it depends" without resolving into a concrete recommendation.

---

## Selection Rules

### Rule 1: Prefer the smallest sufficient rung

Do not recommend Sol, Opus, or `max` effort for typo fixes, formatting, obvious one-file bugs, or mechanical edits.

### Rule 2: Escalate effort before model (Claude only)

On the Claude ladder the order is `medium` → `xhigh` → `max` → `opus-4.8`. Skip rungs only with a named trigger (Rule 6).

### Rule 3: Complexity is task shape, not task label

- "rename a function in one module" — light
- "implement a feature with tests in a known repo" — medium
- "debug a race condition across services" — heavy
- "audit an unfamiliar codebase and propose architecture" — heavy

### Rule 4: Long-running agent work justifies stronger engines

Many tool invocations, broad repo traversal, multi-file coordination, sustained sessions → `opus-4.8` / `gpt-5.6-sol` even when single-step difficulty looks moderate. Session shape matters, not just task difficulty.

### Rule 5: Default middle lane

Not clearly trivial and not clearly extreme → `sonnet-5` @ `medium` (Claude) or `gpt-5.6-terra` (Codex).

### Rule 6: Escalation must name its trigger

A stronger recommendation must cite at least one concrete trigger. **Prefer measured triggers over impressions** — when an intake/inspection has already run, count facts instead of guessing:

- entities in the task that failed unambiguous mapping to system objects
- target config/objects with multiple consumers (blast radius > 1)
- change spans multiple subsystems or layers
- root cause not identified in the task
- unfamiliar codebase / missing tests / weak conventions
- security, permissions, migration, or rollout implications
- expected long-running agentic session

### Rule 7: Downgrade must name its reason

Bounded scope, obvious implementation, one or two files, low reasoning load, budget conservation priority.

### Rule 8: Provider choice

Stay on the provider the user is currently working in unless: the equivalent rung is materially cheaper on the other ladder for a long task, or one provider's budget is running low. A cross-provider handoff requires a self-contained spec file — the executing model will not see this session's context.

---

## Recommendation Format

1. `Recommended: <model> [@ <effort>]`
2. `Why: <task-specific reason, naming the trigger per Rules 6/7>`
3. `Fallback: <model> [@ <effort>]`
4. `Budget note: <low|medium|high burn and why>`
5. `Confidence: High / Medium / Low`

---

## Quick Decision Matrix

- **`gpt-5.6-luna`** — tiny, obvious, volume work; maximum efficiency on the Codex side.
- **`sonnet-5` @ `medium` / `gpt-5.6-terra`** — normal day-to-day engineering; several files; some reasoning, no deep ambiguity.
- **`sonnet-5` @ `xhigh`** — difficult debugging or design on a known codebase; ambiguity present but bounded.
- **`sonnet-5` @ `max`** — hardest Sonnet-worthy work; one rung before changing the model.
- **`opus-4.8` / `gpt-5.6-sol`** — hard, ambiguous, high-risk, long-running, or likely to thrash on smaller rungs.
- **Beyond** — flag it and hand the decision to the user.

---

## Things the Agent Must Not Do

- recommend models outside the two ladders above (including Fable, Haiku, older GPT-5.x)
- assume separate unlimited quotas per model
- recommend the strongest rung habitually
- give a recommendation without tying it to task shape and budget burn
- escalate on impression when measured triggers are available

---

## Priority Order

1. correctness for the task
2. sufficient reasoning depth
3. budget efficiency
4. speed

If the user explicitly prioritizes budget, swap 2 and 3 for borderline cases.

---

## Final Behavioral Rule

Behave like a pragmatic engineering lead choosing the engine for the lap: economy car for errands, the balanced default for daily work, the flagship only for steep climbs and uncertain terrain — and when even the flagship looks small, say so and let the owner decide.
