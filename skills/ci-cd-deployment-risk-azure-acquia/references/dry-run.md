# Best Practice Example: Deployment Risk Dry Run (Azure + Acquia)

## Scenario: Feature "User Loyalty Program"
**Change Surface:** New entity type, custom module `loyalty_program`, config import for permissions, and two update hooks for data backfill.

---

## Step 1: Retrieval & Inquiry
**Intent:** "Identify similar past incidents."
- **Action:** Searching project memory for `update hook timeout` and `loyalty_program`.
- **Finding:** A previous deployment for `loyalty_program_v1` failed on Staging because `hook_update_9001` hit a 60s timeout on 50k users.

---

## Step 2: Risk Mapping Matrix

| Area | Risk Level | Mitigation Description |
| :--- | :--- | :--- |
| **Code** | Low | New controller routes verified for read-only FS compat. |
| **Config** | Medium | Permissions and Roles to be imported. Verified no SID/UID leaks. |
| **Schema** | **High** | Data backfill (80k users). **Blocker risk of timeout.** |
| **Cache** | Low | Simple entity cache tags used. Varnish purge confirmed. |
| **Pipeline** | Low | Tests passing in Azure CI. Parity with Lando is 100%. |

---

## Step 3: Mitigation & Command Order
1. **Pivoted Action:** Refactor `hook_update_9002` to use `Batch API` (chunks of 1,000) to avoid Acquia timeouts.
2. **Deploy Cycle:**
   - `ssh acquia@acquia-server 'drush @staging.prod updb -y'`
   - `ssh acquia@acquia-server 'drush @staging.prod cim -y'`
   - `ssh acquia@acquia-server 'drush @staging.prod cr'`
3. **Smoke Check:** Verify `/loyalty/dashboard` returns `200 OK` and has `Surrogate-Key` header.

---

## Step 4: Output Contract (Agent Report)

### Release Report: Loyalty Program v2
- **Scope:** Module: `loyalty_program` (Project-wide permissions impact).
- **Status:** **GO** (With Batched Update Mitigation).
- **Risk Table:** [As shown above].
- **Rollback Decision:** If `updb` fails, perform DB restore from snapshot `@staging-db-pre-deploy`.
- **Mitigations:** Use chunks of 1k for user updates. Verified permissions in `config/sync`.

### Knowledge Persistence Gate (Self-Instruction)
**Action:** Append the following to the project's Knowledge Graph (`knowledge-memory`):
- **Entity:** `loyalty_program_backfill_timeout`
- **Type:** `Decision` / `Incident`
- **Observation:** `Batched updates required for backfilling user loyalty data on Acquia. Chunks of 1k users avoided the 60s timeout limit.`
- **Related To:** `loyalty_program`, `acquia runtime limits`.

---

## Summary of Success
Following this protocol transformed a potential production outage (timeout) into a successful, batched release.
