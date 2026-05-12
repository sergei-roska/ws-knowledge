# Security Audit Checklist for Drupal Platform

## Scope Discovery

- Identify touched custom modules, themes, settings, and deployment scripts.
- Identify integration points with external services and credentials.

## Secrets and Configuration Hygiene

- Ensure secrets are not committed in YAML, PHP settings, shell scripts, or docs.
- Ensure environment-only secrets are loaded via env vars/secret stores.
- Ensure exported config does not contain environment-specific sensitive values.

## Input and Output Handling

- Validate request/input boundaries in forms/controllers/services.
- Verify output escaping and safe rendering in Twig/PHP render arrays.
- Review user-controlled data paths for XSS/HTML injection risk.

## Access Control and Authorization

- Verify route/controller access checks are explicit and least-privilege.
- Verify entity and operation access is checked before mutation/read.
- Verify no bypasses are introduced for admin or API operations.

## Dependency and Supply Chain Risk

- Review dependency updates for security advisories and breaking changes.
- Flag stale critical dependencies in runtime or build chain.
- Confirm lockfile consistency and deterministic installs.

## CI/CD and Runtime Security Signals

- Ensure CI does not echo secrets in logs.
- Ensure deployment steps preserve secret boundaries.
- Ensure debug/dev settings are not enabled in production paths.

## Output Contract

- Findings by severity (`Critical`, `High`, `Medium`, `Low`).
- Evidence and impacted paths per finding.
- Minimal remediation with rollout notes.
- Residual risk summary after fixes.
