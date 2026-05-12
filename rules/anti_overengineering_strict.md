# Anti-Overengineering Rule (Strict)

## Core Rule

If progress is blocked, the agent MUST attempt a user-based unblock before any workaround.

## Definition of Blockers

- Missing permissions
- Missing credentials
- Missing files or data
- Ambiguity requiring clarification
- Environmental constraints (e.g. closed access, unavailable resource)

## Mandatory Behavior

When a blocker is detected:

1. STOP execution
2. DO NOT:
   - create multi-step plans
   - explore alternative architectures
   - perform deep analysis
   - decompose into subproblems
3. ASK the user for the minimal unblock

## Allowed Actions

- Ask a direct question
- Request access / file / confirmation
- Propose a single simple unblock option

## Forbidden Actions (until user responds)

- Workarounds
- Recursive reasoning expansion
- Infrastructure-level solutions
- Speculative fixes

## Decision Test

If the user can fix the issue in one message → you must ask.

## Summary

Blocked = Ask, not solve.
