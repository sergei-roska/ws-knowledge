# Skill Count: Computer Science Category (Updated)

## Total Skills: 30

After removing the most obsolete/vulnerable-to-obsolescence skills (excluding `provision-ddev` and `provision-lando` as requested), **30 skills** remain in the `skills/` folder. All 30 relate to computer science.

### Removed Skills (3 total):
- `php84-systems-design` — High risk: PHP 8.4 version-specific
- `drupal-views-safe-edit` — High risk: Drupal-specific, version-dependent
- `a11y-frontend-twig` — Medium risk: Frontend accessibility tooling, domain-specific

### Remaining Skills: 30

#### Fundamental CS Patterns & Algorithms: 22 skills
Core concepts that are highly enduring:
- **Concurrency & Parallelism:** actor-model, finite-state-machine, fork-join, supervisor-tree
- **Algorithmic Patterns:** divide-and-conquer, hierarchical-work-decomposition, work-decomposition
- **Reliability Patterns:** circuit-breaker, rate-limiter-throttler, idempotency-key-filter, saga-transaction-manager, two-phase-commit, dead-letter-queue
- **Software Methodology:** design-by-contract
- **Data Structures & Processing:** pipes-and-filters, serial-item-processor, copy-on-write
- **Code Intelligence:** codebase-indexing, codebase-search, entity-query-analyzer
- **Distributed Systems:** event-sourcing, blast-radius-analyzer

#### Applied Domain Skills: 8 skills
Skills applying CS fundamentals to domains:
- **Drupal & PHP:** performance-maintainability-drupal
- **DevOps/Platform:** provision-ddev, provision-lando, provision-local-platform
- **Skill Management:** skill-creator
- **Mockup-to-Spec:** mockup-to-spec

### Summary
| Metric | Count |
|--------|-------|
| Total skills (after removal) | 30 |
| All relate to computer science | ✓ Yes |
| Fundamental CS patterns | 22 |
| Applied domain skills | 8 |

### Notes
- `provision-ddev` and `provision-lando` were preserved as requested
- `provision-local-platform` remains (more generic)
- Core methodological skills (actor-model, FSM, DBC, etc.) are all intact — these are the enduring CS fundamentals