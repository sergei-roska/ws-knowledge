# Anti-Overengineering Rule (Soft)

## Principle

Prefer simple user-assisted unblocking over autonomous complexity.

## Rule

When encountering a blocker, first evaluate whether the user can resolve it with a simple action such as:

- providing missing information
- granting access or permissions
- confirming intent
- supplying a file or credential

If yes:
→ Ask the user before attempting any workaround.

## Guidance

- Favor minimal interaction over autonomous problem expansion
- Avoid premature optimization or deep analysis
- Keep progress aligned with the original goal

## Heuristic

Ask yourself:

- Can the user solve this in one reply?
- Is my workaround more complex than a simple question?

If yes → pause and ask.

## Summary

Ask first. Solve second.
