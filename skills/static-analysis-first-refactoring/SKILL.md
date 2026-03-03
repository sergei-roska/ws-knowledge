---
name: static-analysis-first-refactoring
description: Refactor Drupal/PHP code by treating static analysis as the primary quality gate. Use when tasks involve PHPCS, PHPCBF, PHPStan, Psalm, type-safety cleanup, suppressions cleanup, or quality baseline reduction, especially in projects with custom `run-code-analysis.sh` pipelines.
---

# Static Analysis First Refactoring

## Overview

Resolve quality findings without regressions and without silently weakening standards.
Apply this skill when code must pass style and static analysis gates before merge.

## Workflow

1. Identify active gates and scope.
Read project scripts/config for PHPCS, PHPStan, Psalm, and a11y checks before edits.
Look for `phpcs.xml.dist`, `phpstan.neon`, `psalm.xml`, `run-code-analysis.sh`, or CI pipeline config.

2. Fix automatically where safe.
Run `phpcbf` first. Review diffs for accidental behavior changes before committing.

3. Refactor by signal strength.
   - **PHPCS** — structural and formatting issues first.
   - **PHPStan** — type errors, API misuse, nullability gaps (target Level 8+).
   - **Psalm** — deeper type analysis, dead code detection, taint analysis for security-sensitive paths.

4. Re-run full pipeline.
Validate with project canonical script, not only ad-hoc single tools.

5. Keep intent and behavior stable.
Do not change runtime behavior unless explicitly required by the task.

## Tool-Specific Guidance

### PHPCS / PHPCBF
- Standards: `Drupal,DrupalPractice` for Drupal projects.
- Extensions: `php,module,inc,install,test,profile,theme`.
- Run `phpcbf` before `phpcs` — fixes formatting automatically, reduces noise.
- Separate formatting-only commits from logic-change commits.

### PHPStan
- Target Level 8 minimum; Level 9 (strict mixed) for greenfield code.
- Handle nullability explicitly: use `?Type` parameters, null coalescing, early returns.
- Treat every `@phpstan-ignore` as technical debt — resolve root cause first.
- Use `phpstan-drupal` extension for Drupal-aware analysis.

### Psalm
- Use for deeper type inference and dead-code detection beyond PHPStan.
- Enable taint analysis (`--taint-analysis`) for security-sensitive modules (forms, API endpoints).
- Resolve `PossiblyNull`, `MixedArgument`, `UnusedVariable` findings before suppressions.

## Refactoring Rules

- Prefer real fixes over ignore/suppress rules.
- Add or modify suppressions only with explicit rationale and minimal scope.
- Keep fixes localized to affected modules/themes whenever possible.
- Treat false positives as documented exceptions, not silent ignores.
- Do not mix formatting-only and behavior-changing edits in the same commit.

## Anti-Patterns

- Mass suppressions to make pipeline green.
- Global type weakening or broad `mixed` replacements without need.
- Using `mixed` to bypass type checks instead of declaring proper types.
- Mixing formatting-only and behavior-changing edits without clear separation.
- Skipping full-project validation after refactor.
- Bypassing CI quality gate with ad-hoc local fixes that don't match CI config.

## References

- Read `references/project-quality-gates.md` and resolve concrete commands/configs from the target repository.
- Read `references/dry-run.md` for a worked remediation example.
