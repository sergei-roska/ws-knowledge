# Evaluation of Draft: drupal-api-patterns

## 1. Diagnosis of the Draft

### Strengths
- The draft possesses a conceptually strong and accurate set of Drupal 10/11 API patterns.
- The separation of patterns by subsystem (Hooks, Form API, Entity API, etc.) is logical and human-readable.
- The "Anti-Patterns" section is highly valuable for preventing common agent mistakes like bypassing Dependency Injection or writing raw SQL for entities.
- It includes a solid Verification Checklist for code readiness.

### Gaps
- **Operational Triggers**: It says "Use when writing or reviewing...", which is vague for an autonomous agent. It does not map specific user intents (e.g., "create a form", "handle an entity save") to concrete steps.
- **Retrieval Rules**: The skill doesn't instruct the agent on *what* or *how* to search the existing codebase to provide context before implementing these patterns (e.g., checking for existing `EntityViewBuilder` implementations before writing one).
- **Persistence/Write Rules**: In the context of a coding pattern skill, persistence means *writing code*. While constraints are there (e.g., "Always declare `accessCheck()`"), there are no hard operational gates ("Must Not proceed if DI is not used").
- **Agent Focus**: The text is written like a markdown cheat-sheet for a human developer, rather than a behavioral guide for an AI agent equipped with tools.

### Risks
- An agent might read the skill but still hallucinate implementations because it doesn't know to check existing codebase examples (stale truth / inconsistent agent behavior).
- The agent could execute patterns incorrectly if it doesn't have an operational checklist to verify against before finalizing a tool call.

## 2. Preserved Ideas
- The 9 core sub-systems covered (Hooks, Forms, Entities, Render Arrays, Routing, Events, Plugins, Services, Queue).
- The "Decision: Which API Surface?" classification logic.
- The specific technical constraints (e.g., `#cache` metadata bubbles, `{node}` upcasting).
- The Anti-Patterns list.

## 3. Missing Pieces to Add
- **Explicit Triggers**: Clear conditions for when this skill becomes active.
- **Retrieval / Context Gathering Rules**: Instructions on how to search the codebase for similar implementations before writing new code.
- **Execution Rules (Write Gates)**: Formulated as Must/Should constraints for code generation and refactoring.
- **Validation**: Post-execution steps to check the generated code.

## 4. Rewrite Strategy
- Convert the "Cheat Sheet" style into an **Intent -> Retrieval -> Execution -> Validation** loop.
- Transform "Core Patterns" into operational rules applied during file writing.
- Keep the rich API technical details, but restructure them into actionable constraints.
