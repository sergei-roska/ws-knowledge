# Workflow: Refactor

## Objective

Improve the quality, readability, and maintainability of the provided code **without altering its external behavior**. Every change must be safe and verifiable.

## How to Proceed

### 1. Scope — Define What You're Working On

- If the user provides a specific file, class, or function → refactor **only** that scope.
- If the user says "refactor this module" or points at a directory → scan the full directory, build a mental map of dependencies, and propose a refactoring plan **before** touching anything.
- If the scope is ambiguous → **ask** the user to clarify before proceeding.

### 2. Analyze — Understand Before Changing

- Read the code thoroughly. Trace data flow and identify all callers/consumers.
- Note the **test coverage** situation: are there tests? Do they pass? If not, flag this before refactoring.
- Identify the **code smells** present. Common targets:
  - **Duplication** — repeated logic that can be extracted.
  - **Long methods** — functions doing more than one thing.
  - **Deep nesting** — complex conditionals that can be flattened (early returns, guard clauses).
  - **God objects** — classes with too many responsibilities.
  - **Magic values** — hardcoded strings/numbers that should be constants.
  - **Dead code** — unused variables, functions, or imports.
  - **Tight coupling** — dependencies that should be injected or abstracted.

### 3. Plan — Describe the Strategy

Before making changes, present a **brief summary** (3-5 sentences max) of:

- What you found.
- What you intend to change and why.
- Any potential risks or trade-offs.

Wait for user confirmation unless the changes are trivially safe (e.g., renaming a local variable, removing an unused import).

### 4. Implement — Surgical, Minimal Changes

- Apply changes **incrementally**, one logical refactoring step at a time.
- Prefer **small, reviewable diffs** over large rewrites.
- Preserve existing formatting conventions and code style of the project.
- Never rename public APIs, exported symbols, or database-facing identifiers without explicit approval.

### 5. Verify

- If tests exist → run them and confirm they pass.
- If a linter/formatter is configured → run it.
- If neither exists → do a final read-through and confirm behavioral equivalence.

## Principles to Apply

| Principle | In Practice |
| :--- | :--- |
| **DRY** | Extract shared logic into reusable helpers or constants. |
| **SRP** | Each function/class should have one clear reason to change. |
| **Clean Code** | Descriptive names, short functions (≤20 lines ideal), minimal comments (code should explain itself). |
| **Consistent style** | Match the project's existing conventions, not your own preferences. |
| **Least surprise** | Refactored code should behave identically to the original from the caller's perspective. |

## What NOT to Do

- Do **not** add new features or change behavior under the refactoring umbrella.
- Do **not** refactor test files unless explicitly asked.
- Do **not** over-abstract. If a pattern is used only once, leave it concrete.
