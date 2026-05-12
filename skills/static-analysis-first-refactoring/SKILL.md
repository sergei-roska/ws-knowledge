---
name: static-analysis-first-refactoring
description: Refactor Drupal/PHP code by treating static analysis as the primary quality gate. Use when tasks involve PHPCS, PHPCBF, PHPStan, Psalm, type-safety cleanup, or resolving CI pipeline failures.
---

# Static Analysis First Refactoring

## 1. Purpose & Philosophy

Resolve quality findings without regressions and without silently weakening standards.
Apply this skill when code must pass style and static analysis gates before merge. 
- **Formatting is mechanical**: Let `phpcbf` do it.
- **Typing is intentional**: Fix root causes; avoid `mixed` or `@phpstan-ignore`.
- **Behavior is sacred**: Refactoring must not change runtime business logic.

## 2. Context Gathering & Retrieval Rules

- **R1 (Locate Configs):** Before editing, locate active quality gates in the repository. Look for `phpcs.xml.dist`, `phpcs.xml`, `phpstan.neon`, `psalm.xml`, or CI scripts (e.g., `run-code-analysis.sh`).
- **R2 (Check Baselines):** Identify if a baseline file exists (e.g., `phpstan-baseline.neon`). Do not blindly add new errors to the baseline.
- **R3 (Target Scope):** Determine the scope of the refactoring task. **Only target the files explicitly assigned, or files modified in the current branch.** DO NOT run formatters globally across the entire codebase unless explicitly instructed.

## 3. Execution Rules

- **R4 (Auto-Format First):** Run `phpcbf` on the target scope *before* applying manual fixes. Review the diffs to ensure no unintended structural changes occurred.
- **R5 (Commit Formatting Separate):** If `phpcbf` made changes, commit them separately as a "Formatting" or "Code Style" commit. Do not mix formatting with behavior or type-safety changes.
- **R6 (Resolve PHPCS):** Run `phpcs` using the project's standard (typically `Drupal,DrupalPractice`). Fix remaining structural and formatting issues manually to match PSR-12 and Drupal Core standards.
- **R7 (Resolve PHPStan):** Run PHPStan at the project's defined level (target Level 8+). Fix type errors, API misuse, and nullability gaps. Use explicit types instead of suppressing errors.
- **R8 (Resolve Psalm):** If Psalm is active, use it for deeper type inference and dead-code detection. Enable taint analysis (`--taint-analysis`) for security-sensitive paths.
- **R9 (Validate Locally):** Re-run the full pipeline script (e.g., `run-code-analysis.sh`) to ensure the changes pass the CI-equivalent gates.

## 4. Write & Update Behavior (Persistence)

- **R10 (No Fake Types):** Do not replace missing types with `mixed` just to clear errors, unless the incoming data is genuinely untyped and cannot be inferred.
- **R11 (Justify Suppressions):** Treat every `@phpstan-ignore` or `@psalm-suppress` as technical debt. If suppression is unavoidable (e.g., false positive from vendor code or Core), you **MUST** add a comment explaining *why* it is suppressed.
- **R12 (No Logic Changes):** Do not change runtime behavior unless explicitly required by the user to fix a bug. Type constraint additions must be verified against real data inputs.

## References

- Read `references/project-quality-gates.md` and resolve concrete commands/configs from the target repository.
- Read `references/dry-run.md` for a worked remediation example.
