# Workflow: Code Review

## Objective

Provide a thorough, structured review of the provided code. The review should be **opinionated but constructive** — flag real problems, skip nitpicks, and always explain *why* something matters.

## How to Proceed

### 1. Scope

- Review only the code the user provides (file, diff, or snippet).
- If reviewing a merge request or a set of changes → focus on the **diff**, not the entire file history.

### 2. First Pass — Intent & Architecture

- **What does this code do?** Summarize in 1-2 sentences.
- **Does the approach make sense?** Is there a simpler or more idiomatic way to achieve the same result?
- **Does it fit the project?** Check naming conventions, file placement, and architectural patterns already established in the codebase.

### 3. Second Pass — Correctness & Safety

Go through the code with a critical eye for:

| Category | What to look for |
| :--- | :--- |
| **Bugs** | Off-by-one errors, null/undefined access, race conditions, wrong operator precedence. |
| **Edge cases** | Empty inputs, boundary values, unexpected types, large datasets. |
| **Security** | SQL injection, XSS, unsanitized user input, exposed secrets, insecure defaults. |
| **Error handling** | Missing try/catch, swallowed errors, unhelpful error messages, missing fallbacks. |
| **Type safety** | Implicit type coercion, missing type annotations (if the project uses them), unsafe casts. |

### 4. Third Pass — Performance & Scalability

- **Algorithmic complexity** — Is there an unnecessary O(n²) loop? Could a lookup map help?
- **Resource management** — Are connections, file handles, or event listeners properly cleaned up?
- **Caching** — Is there repeated expensive computation that could be memoized?
- **Bundle impact** (frontend) — Does this add a heavy dependency for a simple task?

### 5. Fourth Pass — Readability & Maintainability

- Naming: Are variable/function names self-documenting?
- Structure: Can long functions be broken down? Is nesting too deep?
- Comments: Are they helpful or just noise? Is there missing documentation on non-obvious logic?
- Testability: Is the code structured in a way that makes it easy to test?

## Output Format

Structure your review as follows:

### Summary
>
> One-paragraph high-level assessment. State whether the code is good to merge, needs minor tweaks, or requires significant changes.

### Issues Found

List issues grouped by severity:

- 🔴 **Critical** — Must fix before merge. Bugs, security holes, data loss risks.
- 🟡 **Suggestion** — Strong recommendations that improve quality. Not blockers.
- 🟢 **Nit** — Minor style or preference items. Optional.

For each issue, include:

1. **What** — The problem, with a file/line reference.
2. **Why** — Why it matters.
3. **Fix** — A concrete suggested fix (code snippet when helpful).

### Verdict

End with one of:

- ✅ **LGTM** — Looks good to merge as-is.
- ✅ **LGTM with nits** — Good to merge, minor optional improvements noted.
- 🔄 **Changes requested** — Needs fixes before merge, issues listed above.
- 🚫 **Needs rework** — Fundamental approach issues, suggest an alternative direction.

## What NOT to Do

- Do **not** rewrite the code yourself unless the user explicitly asks for fixes.
- Do **not** comment on things that are already established project conventions (even if you'd do it differently).
- Do **not** flood the review with trivial formatting nitpicks — focus on substance.
