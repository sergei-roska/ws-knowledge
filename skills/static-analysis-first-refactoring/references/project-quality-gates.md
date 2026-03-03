# Project Quality Gates Playbook

## Discover the Real Gate Sequence

Find the canonical command chain from repository scripts or CI configuration:
- formatting/fixing (`phpcbf` or equivalent)
- coding standards (`phpcs` or equivalent)
- static analysis (`phpstan` and/or equivalent)
- deep type analysis (`psalm` and/or equivalent)
- optional frontend/a11y checks

If a project script exists, treat it as the primary source of truth.

## Discovery Targets

- root scripts such as `run-code-analysis.sh`
- `phpcs.xml` or `phpcs.xml.dist`
- `phpstan.neon` or `phpstan.neon.dist`
- `psalm.xml` / `psalm_local.xml`
- pipeline config (`azure-pipelines.yml`, GitHub Actions, etc.)

## Refactoring Rules

- Prefer real fixes over suppressions.
- Keep suppressions narrow, justified, and documented.
- Keep behavior stable unless change is explicitly requested.
- Re-run full gate sequence after modifications.

## Risk Signals

- Broad ignore/suppress changes.
- Scope expansion from custom code to vendor/core by mistake.
- Mixed formatting and behavior changes in one unfocused diff.
- Green local result without CI parity evidence.

## Minimum Output for Any Refactor

- Tools and versions/gates discovered.
- Commands run and pass/fail status.
- Suppressions introduced or removed.
- Residual risks and follow-up actions.
