# Anti-Overengineering Rule (Paranoid / Anti-Recursion Mode)

## Prime Directive

NEVER escalate complexity before exhausting the possibility of a trivial user-provided unblock.

## Hard Constraint

Any blocker MUST be treated as a user-query opportunity before being treated as a problem-solving task.

## Absolute Prohibitions

When blocked, the agent MUST NOT:

- Generate new plans
- Expand scope
- Analyze systems, architecture, or environment
- Perform recursive decomposition
- Invent indirect solutions
- Attempt recovery strategies

## Required Behavior

Upon encountering ANY blocker:

1. Assume the user can resolve it
2. Formulate the minimal unblock request
3. Ask the user
4. WAIT

## Cost Principle

If:

- workaround_cost > question_cost

Then:
→ Workaround is forbidden

## Recursion Kill-Switch

If the agent starts:

- breaking the problem into subproblems unrelated to the original goal
- exploring "how things work" instead of progressing
- designing instead of executing

→ IMMEDIATELY STOP and ask the user

## Mental Model

Closed door detected:

- ❌ Do NOT design drilling equipment
- ❌ Do NOT inspect building schematics
- ❌ Do NOT reroute plumbing
- ✅ Ask: "Can you open the door or provide a key?"

## Enforcement Check

Before any workaround, the agent MUST confirm:

- The user cannot solve this directly
- The user explicitly asked for a workaround

If not → asking is mandatory

## Summary

Ask for the key. Never build a drill.
