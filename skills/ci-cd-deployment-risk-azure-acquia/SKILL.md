---
name: ci-cd-deployment-risk-azure-acquia
description: Analyze release risk for Drupal on Azure + Acquia. Use when tasks touch deployment scripts, pipelines, release sequencing, update hooks, or environment parity.
---

# CI/CD Deployment Risk (Azure + Acquia)

## Purpose & Philosophy
This skill governs the assessment of release-readiness and the mitigation of deployment failure. It bridges the gap between local development (Lando), CI automation (Azure Pipelines), and the production runtime (Acquia Cloud).

The core philosophy is **"Deployment as a First-Class Knowledge Object."** Every deployment evaluation should contribute to a durable history of project risks, incidents, and successful mitigations.

---

## Retrieval Rules (When to Search)

Trigger this skill and search the project's knowledge graph in these modes:

### 1. Constraint Search
- **Intent:** "What are the hard limits of this stack?"
- **Triggers:** New custom module, large file/data migrations, changes to `php.ini` or host settings.
- **Search terms:** `Acquia constraints`, `Azure pipeline limits`, `read-only FS`, `memory limits`, `varnish layers`.

### 2. Rationale Search
- **Intent:** "Why is our deployment sequence ordered this way?"
- **Triggers:** Modifications to `bitbucket-pipelines.yaml`, `azure-pipelines.yml`, or `post-code-deploy` scripts.
- **Search terms:** `deploy order rationale`, `rollback decision`, `drush cim order`.

### 3. History Search
- **Intent:** "Have we broken this before?"
- **Triggers:** PR review, production incident, new release cycle planning.
- **Search terms:** `deployment failure staging`, `deployment incident production`, `pivot release sequence`.

### 4. Verification Mode
- **Intent:** "Is my current task at risk of environmental drift?"
- **Triggers:** PR creation, before merge.
- **Search terms:** `Lando parity`, `Acquia PHP version`, `CI gates drift`.

---

## Detailed References & Manuals

Use these for granular lookup and scenario modeling:
- **[Deployment Risk Matrix](references/deployment-risk-matrix-azure-acquia.md)**: Deep-dive risk lookup for code, config, schema, and performance failure modes.
- **[Example Dry Run](references/dry-run.md)**: A gold-standard walkthrough showing the correct evaluation workflow and Output Contract.

---

## Persistence Rules (What to Save)

Every high-risk release task must record its findings in the project's semantic memory.

### Must Persist (Durable Invariants)
- **Deployment Incidents:** Any failure in Staging/Production that required a revert or course correction.
- **Structural Pivots:** Changes to the deployment trigger logic or CI build process.
- **Critical Constraints:** Project-specific limits (e.g., "Max execution time on Staging is 60s").

### Should Persist (Decisions & Milestones)
- **Go/No-Go Recommendations:** The summary and logic of a major feature release.
- **Performance Rationale:** Why a certain caching strategy was chosen for edge invalidation.

### Must Not Persist (Ephemeral Noise)
- Raw CI logs or debug output.
- Low-risk "clean" deployment reports.
- Branch-specific transient CI failures.

---

## Operational Workflow

1. **Map Change Surfaces:** Identify Code, Config, Schema (hooks), Cache (Varnish/Drupal), and Artifact (Sass/JS) changes.
2. **Retrieve Past Incidents:** Search history for similar changes (e.g., "update hook timeout").
3. **Audit Against Constraints:** Check against the **Acquia Runtime Matrix** (below).
4. **Determine Order & Idempotency:** Validate `drush` sequence and re-run safety.
5. **Issue Risk Report:** Use the **Output Contract** format.

---

## The Acquia/Azure Runtime Matrix (Core Invariants)

- **Storage (Read-Only FS):** Any file generation MUST happen in CI. Runtime folders (except `sites/default/files`) are immutable.
- **Edge Cache (Varnish):** Validate `Surrogate-Key` and `Cache-Tags`. Check purge logic for new custom routes.
- **Deployment Hooks:** `post-code-deploy` and `post-code-update` are the source of truth for `drush updb -> cim -> cr`.
- **Environment Parity:** Verify `Lando` vs `Azure` vs `Acquia` PHP version and extension compatibility.
- **Process Limits:** Identify "Heavy" `hook_update_N` steps. Plan chunked updates if processing >10,000 entities.

---

## Database Migration & Safety Rules

- **Idempotency:** All `hook_update_N` and `hook_post_update_NAME` MUST be safe to re-run.
- **Ordering:** Maintain strict sequence: `drush updb` → `drush cim` → `drush cr`.
- **Reversion:** Explicitly document IF an update is reversible OR requires a DB backup restore.
- **Isolation:** Heavy schema changes should be in a dedicated "Database Release" separate from large feature code.

---

## Output Contract (Release Report Template)

Return a report containing:
- **Scope:** [Project-wide | Module-local | Capability-specific]
- **Status:** [Evaluated | Go | No-Go | Superseded]
- **Risk Matrix:** Table showing Area (Code/Config/Schema/Cache) vs Risk (Low-Blocker).
- **Mitigation Checklist:** Specific `drush` commands and verification steps.
- **Rollback Decision Path:** "If X fails, pivot to Y."
- **Knowledge Update:** Mention the observation name to be persisted in semantic memory.

---

## Compact Operational Checklist (The "Pre-Flight")

| Area | Check |
| :--- | :--- |
| **Files** | Does it write to non-public FS? (Blocker if yes) |
| **Schema** | Is `hook_update_N` idempotent? (Must be yes) |
| **Cache** | Are `#cache` tags set for new render arrays? |
| **Order** | `updb` -> `cim` -> `cr` confirmed in hook? |
| **Parity** | PHP version matches Acquia runtime? |
| **History** | Checked knowledge graph for "release incidents"? |
