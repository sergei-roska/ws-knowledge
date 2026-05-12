# Memory Write Policy

Write to `memory` autonomously when the result should survive chat loss.

## Save

- user preferences
- stable project rules
- durable decisions and tradeoffs
- recurring problems and their meaning
- important environment facts
- canonical terminology

## Do Not Save

- raw diffs
- temporary debug steps
- obvious code facts
- large document content
- transient implementation chatter

## Write Style

- prefer atomic observations
- use stable entity names
- write search-friendly facts
- store meaning, not narration

## Trigger

After solving, reviewing, or clarifying a task, ask:

- Will this matter in a later session?
- Is it hard to reconstruct quickly?
- Does it change how future work should be done?

If yes, write to `memory`.
