# Project Quality Gates Playbook

## Discover the Real Gate Sequence

Before attempting any static-analysis refactor, an agent must correctly identify the canonical command chain. This is typically defined in repository scripts or CI configurations:
- formatting/fixing (`phpcbf` or equivalent)
- coding standards (`phpcs` or equivalent)
- static analysis (`phpstan` and/or equivalent)
- deep type analysis (`psalm` and/or equivalent)
- optional frontend/a11y checks

If a project script exists (e.g., `run-code-analysis.sh`), treat it as the **primary source of truth**.

## Discovery Targets

When fulfilling rule **R1 (Locate Configs)**, check these locations:
- **Scripts:** `scripts/run-code-analysis.sh`, `bin/quality.sh`
- **Config files:** `phpcs.xml`, `phpcs.xml.dist`, `phpstan.neon`, `phpstan.neon.dist`, `psalm.xml`, `psalm_local.xml`
- **CI Pipelines:** `.gitlab-ci.yml`, `.github/workflows/`, `azure-pipelines.yml`, `bitbucket-pipelines.yml`

## Decoding CI for Local Parity

Often, CI runs a specific container or requires specific CLI arguments. Extract the *exact* CLI arguments from the CI pipeline files to ensure local verification (Rule **R9**) perfectly mirrors the deployment gate.

## Risk Signals During Discovery

- **Misaligned Environments:** Running a local PHP version that differs from the CI container, leading to false positives/negatives in PHPStan.
- **Ignoring the Baseline:** Failing to check for a `phpstan-baseline.neon` file, attempting to fix thousands of legacy errors instead of restricting the scope.

## Minimum Baseline Output for Gate Discovery

When taking on a refactoring task, always declare:
- **Tools discovered** (e.g., PHPCS 3.7.2, PHPStan 1.10).
- **Gate levels** (e.g., PHPStan Level 8).
- **Baseline protection** (e.g., Found `phpstan-baseline.neon`, adhering to baseline constraints).
